#!/usr/bin/env bash

IP=127.0.0.1
PORT=52542
BASE_URL="http://$IP:$PORT"
# Default hash to calculate coins with
my_hash=1000


RRDTOOL="/usr/bin/rrdtool"
RRD_DB_ROOT="/var/lib/rrdtool"
WEB_ROOT="/var/www/html"
RRD_DB="$(basename $0 .sh)"
RPC_GETINFO="$BASE_URL/getinfo -H 'Content-Type: application/json'"
RPC_JSON="$BASE_URL/json_rpc"
RPC_APP_TYPE="'Content-Type: application/json'"
function initialize_rrd() {
        if ! [ -f $RRD_DB_ROOT/$RRD_DB.rrd ] ; then
        rrdtool create $RRD_DB_ROOT/$RRD_DB.rrd \
        --step 60 \
        DS:diff:GAUGE:120:0:999999999999999999 \
        DS:nthsh:GAUGE:120:0:999999999999999999 \
        DS:reward:GAUGE:120:0:999999999999999999 \
        DS:minert:GAUGE:120:0:999999999999999999 \
        RRA:MAX:0.5:1:1500
        fi
        chown www-data.www-data $RRD_DB_ROOT/$RRD_DB.rrd
}

function difficulty_out() {
        curl -s -X POST $RPC_GETINFO | jq '.difficulty'
}

function nethash_out() {
        curl -s -X POST $RPC_GETINFO | jq '.difficulty, .target' | xargs | awk '{print $1"/"$2}' | bc
}

function block_height() {
        local height=$(curl -s -X POST $RPC_GETINFO -H 'Content-Type: application/json' | jq '.height')
        echo $((height-5))
}

function number_coins_mined() {
        block_time=$(curl -s -X POST $RPC_GETINFO -H 'Content-Type: application/json' | jq '.target')
        blocks_day=$(expr 86400 / $block_time)
        echo "$blocks_day*$(block_height)" | bc -l
}

function reward_out_post_data() {
        cat <<EOF
{
 "jsonrpc":"2.0",
  "id":"0",
  "method":"get_coinbase_tx_sum",
  "params":{
    "height":$(block_height),
    "count":1 }
}
EOF
}

function reward_out() {

        curl -s -X POST $RPC_JSON -d "$(reward_out_post_data $i)" -H 'Content-Type: application/json' | jq '.result.emission_amount' | awk '{print $0/1000000000000}'
}

function mining_rate() {
        # Mining rewards per 1000H, adjust by changing $my_hash
	# Formula: blocks/day=(24*60*60/block_time) * block_reward / (nethash * my hash)

        block_time=$(curl -s -X POST $RPC_GETINFO -H 'Content-Type: application/json' | jq '.target')
        blocks_day=$(expr 86400 / $block_time)
        block_reward=$(reward_out)
        nethash=$(nethash_out)
        echo "$blocks_day*$block_reward/$nethash*$my_hash" | bc -l
}

function update_rrd_data() {
        DATA=$(echo $(difficulty_out):$(nethash_out):$(reward_out):$(mining_rate))
        $RRDTOOL update $RRD_DB_ROOT/$RRD_DB.rrd --template diff:nthsh:reward:minert N:$DATA >/dev/null
}

function graph_output() {
        ## Graph for last 24 hours
        rm -f ${WEB_ROOT}/${RRD_DB}*png
        for i in 00_Difficulty 01_NetHash 04_MineCoin24h1KH 03_Reward
        do
        # Define metric in rrd source
        if [[ $i == "00_Difficulty" ]]; then
                metric=diff
                label="Difficulty"
        elif [[ $i == "01_NetHash" ]]; then
                metric=nthsh
                label="Network Hashes"
        elif [[ $i == "03_Reward" ]]; then
                metric=reward
                label="Block Reward"
        elif [[ $i == "04_MineCoin24h1KH" ]]; then
                metric=minert
                label="Coins Mined @ 1kh/s in 24 hours"
        fi
$RRDTOOL graph ${WEB_ROOT}/${RRD_DB}_${i}.png \
-w 1085 -h 320 -a PNG \
--slope-mode \
--start -86400 --end now \
--font DEFAULT:7: \
--title "Blur Stats: $i" \
--watermark "${i}" \
--vertical-label "$label" \
--right-axis-label "date" \
--lower-limit 0 \
--right-axis 1:0 \
--x-grid MINUTE:10:HOUR:1:MINUTE:120:0:%R \
--alt-y-grid --rigid \
DEF:${i}=$RRD_DB_ROOT/$RRD_DB.rrd:$metric:MAX \
AREA:${i}#BBD1EE:"${metric}" \
LINE2:${i}#000FFF:"${metric}" \
GPRINT:${i}:LAST:"Cur\: %5.2lf" \
GPRINT:${i}:AVERAGE:"Avg\: %5.2lf" \
GPRINT:${i}:MAX:"Max\: %5.2lf" \
GPRINT:${i}:MIN:"Min\: %5.2lf\t\t\t"  >/dev/null
chown www-data.www-data ${WEB_ROOT}/${RRD_DB}_${i}.png
done
}

function main() {
initialize_rrd
update_rrd_data
}

"$@"
