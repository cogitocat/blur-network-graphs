#!/usr/bin/env bash

/usr/local/bin/blur_collect_stats.sh graph_output
echo "Content-type: text/html"
echo ""

echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<meta http-equiv="refresh" content="60;url=/cgi-bin/" />'
echo '<link rel="SHORTCUT ICON" href="http://www.megacorp.com/favicon.ico">'
echo '<link rel="stylesheet" href="http://www.megacorp.com/style.css" type="text/css">'

#PATH="/bin:/usr/bin:/usr/local/cgi-bin"
#export $PATH

echo '<title>BLUR.network Blockchain Stats</title>'
echo '</head>'
echo '<body>'

for i in $(cd /var/www/html && ls blur_collect_*.png); do
echo '<h3>'
echo "<img src=../$i?$RANDOM >"
echo '</h3>'
done

echo '</body>'
echo '</html>'

exit 0
