# auto_ping
互联网多机房互ping，简单，高效、分布式ping

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
   
## 使用方法

1、创建数据库：
``` MySQL
CREATE TABLE `fa_ipmoninfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uptime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `source_addr` varchar(255) DEFAULT NULL,
  `target_addr` varchar(255) NOT NULL,
  `province` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `network_type` varchar(255) NOT NULL COMMENT '联通CU,电信CT,移动CM',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_uiq_ip` (`target_addr`) USING BTREE,
  KEY `idx_city` (`city`),
  KEY `idx_net` (`network_type`)
) ENGINE=InnoDB AUTO_INCREMENT=669 DEFAULT CHARSET=utf8;
