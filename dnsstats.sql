.headers on
.mode column
.width 19 18 18 50 5

--create a temp table of occurences
CREATE TEMPORARY TABLE TEMP1 AS
SELECT timestamp,mac_src,ip_src,url,count(*) AS cnt
FROM DNS
GROUP BY mac_src,ip_src,url
ORDER BY timestamp,ip_src,cnt,url DESC;

.print 'MOST FREQUENT DNS REQUESTS BY MAC ADDRESSES'
--Then use a classic limit per group query
SELECT datetime(timestamp,'unixepoch') as TIME,T1.mac_src as MAC_SRC,T1.ip_src as IP_SRC,T1.url as URL,T1.cnt as CNT
FROM TEMP1 AS T1
WHERE T1.url in (
      SELECT T2.url
      FROM TEMP1 AS T2
      WHERE T2.ip_src=T1.ip_src and T2.cnt>=T1.cnt
      ORDER BY T2.cnt DESC
      LIMIT 5 --Or whatever you want it to be
)
ORDER BY ip_src ASC,cnt DESC;

------ a brief sumup of the last requested URLs
.print ''
.print 'LAST DNS REQUESTS'
SELECT datetime(timestamp,'unixepoch') as TIME, mac_src, ip_src, url
FROM DNS
ORDER BY time DESC LIMIT 50;
