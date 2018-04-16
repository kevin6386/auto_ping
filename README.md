# auto_ping
基于**MySQ**L 、**InfluxDB**、**Grafana** 互联网多机房互ping，简单，高效、分布式ping

## 背景：
  1、多个机房需要了解网络丢包及延迟状态，开始采用SmokePing但是每次部署非常麻烦，需要编写模板，当机房达到非常多的时候，采用此方法非常不方便，为此为了能
简化网络监控特采取最原始的ping方式，将ping的结果汇报，对于多个ip是可以采用并行ping工具Fping。<br>
  2、如果要监控本机房到各地网络情况时，可以采用此方案，将目标地址由机房改为监控地域的网络DNS即可。<br>
  
## 想法：
  1、不要侵入式操作<br>
  2、监控机房或地域IP可自由定制，无需客户端进行写死<br>
  3、将获取的信息通过API接口进行回传，方便数据汇总及绘图<br>
  4、简单、简单、简单<br>
  
## 思路：

   1、创建一个数据库，存放需要监控的ip<br>
   2、client 通过api获取ip列表<br>
   3、调用本地Fping 探测ip列表获取结果信息<br>
   4、通过api上传数据<br>


## 方案：
**采用下面方案是因为流行度，大家多采用InfluxDB+Grafana方式进行运维监控为此没有做单独UI二次开发，减少工作量**

  1、采用Grafana展示因为使用者多无需二次开发<br>
  2、InfluxDB时序数据库，可进行多维度绘制数据，基于现有使用者<br>
  3、MySQL存储监控ip简单<br>
  4、PHP编写接口，可采用其他语言<br>
  5、客户端为SHELL直接定时使用方便，可以使用其他语言<br>

## 前提：
  服务端需要部署PHP WEB环境

## 使用方法

### 1、创建数据库：
``` MySQL
CREATE TABLE `fa_ipmoninfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uptime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `source_addr` varchar(255) DEFAULT NULL,
  `target_addr` varchar(255) NOT NULL,
  `province` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `network_type` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_uiq_ip` (`target_addr`) USING BTREE,
  KEY `idx_city` (`city`),
  KEY `idx_net` (`network_type`)
) ENGINE=InnoDB AUTO_INCREMENT=669 DEFAULT CHARSET=utf8;

插入数据
INSERT INTO `morefun`.`fa_ipmoninfo` (`uptime`, `source_addr`, `target_addr`, `province`, `city`, `network_type`) VALUES (now(), NULL, '211.13.xx.xx', '浙江', '丽水机房', '电信');

```
图例：
![ip数据信息](https://github.com/kevin6386/auto_ping/blob/master/ip%E6%95%B0%E6%8D%AE%E4%BF%A1%E6%81%AF.png)

### 2、编写PHP获取IP接口
```PHP
<?php
$page_no = $user_name = $class_name =$db_ip = $int_ip ="";
extract ( $_GET, EXTR_IF_EXISTS );
$timezone_identifier = "PRC";  //本地时区标识符
date_default_timezone_set($timezone_identifier);
$msdate=date("Y_m_d_H_i");
$mysql_conf = array(
    'host'    => '127.0.0.1:3306', 
    'db'      => 'morefun', 
    'db_user' => 'root', 
    'db_pwd'  => 'mysql*()', 
    );
$mysql_conn = @mysql_connect($mysql_conf['host'], $mysql_conf['db_user'], $mysql_conf['db_pwd']);
if (!$mysql_conn) {
    die("could not connect to the database:\n" . mysql_error());//诊断连接错误
}
$type=$_GET['type'];
if($type=='yd'){
	$where="where network_type='移动'";
}elseif($type=='dx'){
	$where="where network_type='电信'";
}elseif($type=='lt'){
	$where="where network_type='联通'";
}elseif($type=='serverip'){
	$where="where network_type='serverip'";
}elseif($type=='T'){
	$where="where network_type='T'";
}elseif($type=='pbs'){
	$where="where network_type='鹏博士'";
}elseif($type=='all'){
	$where="";
}
if($type){
	$select_db = mysql_select_db($mysql_conf['db']);
	if (!$select_db) {
		 die("could not connect to the db:\n" .  $mysqli->error);
	}
	
	$sql = "SELECT
		target_addr,province,city,network_type
	FROM
	morefun.fa_ipmoninfo $where;";
	$res = mysql_query($sql);
	if (!$res) {
		die("sql error:\n" . $mysqli->error);
	}
	 while ($row = mysql_fetch_assoc($res)) {
			echo($row[target_addr]."-".$row[province]."-".$row[city]."-".$row[network_type])."\n\r";
		}
$res->free();
$mysqli->close();
}else{
	echo("请输入参数:如type=ld");
}
```
### 3、部署InfluxDB
  此处略可参考官网即可。https://www.influxdata.com/

### 4、客户端
可做成定时任务，每5分钟执行，**此处脚本为同事协助编写，再次感谢！**
```
*/5 * * * * /root/shell/traceIP.sh dx
*/5 * * * * /root/shell/traceIP.sh lt
*/5 * * * * /root/shell/traceIP.sh yd
```
### 5、部署Grafana 

略，并配置InfluxDB 数据源 可参考官网

### 6、配置Grafana
从InfluxDB 数据库中获取相关信息SQL。
```MySQL
SELECT "loss" FROM "network" WHERE ("Host_IP" = '60.XX.XX.XX' AND "Target" = '119.XX.XX.XX') AND $timeFilter GROUP BY "Host_IP", "city", "Target"
```

![网络展示](https://github.com/kevin6386/auto_ping/blob/master/%E7%BD%91%E7%BB%9C%E5%B1%95%E7%A4%BA.png)

### 7、效果展示
![效果展示](https://github.com/kevin6386/auto_ping/blob/master/%E5%B1%95%E7%A4%BA2.png)


