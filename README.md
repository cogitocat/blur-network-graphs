# blur-network-graphs
# RRDTool graphs based on RPC calls to a BLUR.cash node RPC endpoint.

### Instructions

* Place index.cgi in your web servers path that allows for ExecCGI.
https://httpd.apache.org/docs/2.4/howto/cgi.html

* Place `blur_collect_stats.sh` in a path for the CGI and cron to execute.

```cp blur_collect_stats.sh /usr/local/bin```

* Install or append cron entry to collect stats.

```(crontab -l && cat crontab.example)| crontab -```

### Dependencies

* Permissions to execute and access CGI scripts, RRD directories, and files.
