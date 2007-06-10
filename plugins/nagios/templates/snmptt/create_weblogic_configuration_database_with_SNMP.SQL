SET NAMES utf8;

SET SQL_MODE='';

create database if not exists `weblogicConfig`;

USE `weblogicConfig`;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';

/*Table structure for table `ADMIN_CONFIG` */

CREATE TABLE `ADMIN_CONFIG` (
  `ADMIN_NAME` varchar(45) NOT NULL default '',
  `HOST` varchar(45) NOT NULL default '',
  `PORT` int(5) default NULL,
  `VERSION` char(2) NOT NULL default 'v2',
  `COMMUNITY` varchar(45) default NULL,
  `ENV` varchar(4) NOT NULL default '',
  `ACTIVATED` tinyint(1) unsigned default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ADMIN_NAME`,`ENV`(1))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*Table structure for table `CLUSTER_CONFIG` */

CREATE TABLE `CLUSTER_CONFIG` (
  `CLUSTER_NAME` varchar(45) NOT NULL default '',
  `CLUSTER_SERVERS` varchar(254) default NULL,
  `ENV` varchar(4) NOT NULL default '',
  `ACTIVATED` tinyint(1) unsigned default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `VIRTUAL_CLUSTER_ID` int(11) unsigned NOT NULL default '0',
  `UKEY` varchar(11) default NULL,
  PRIMARY KEY  (`CLUSTER_NAME`,`ENV`(1)),
  KEY `VIRTUAL_CLUSTER_ID` (`VIRTUAL_CLUSTER_ID`),
  KEY `UKEY` (`UKEY`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*Table structure for table `SERVER_CONFIG` */

CREATE TABLE `SERVER_CONFIG` (
  `DOMAIN_NAME` varchar(45) NOT NULL default '',
  `SERVER_NAME` varchar(45) NOT NULL default '',
  `LISTEN_ADDRESS` varchar(45) default NULL,
  `LISTEN_PORT` int(5) default NULL,
  `MACHINE` varchar(45) default NULL,
  `CLUSTER_NAME` varchar(45) default NULL,
  `EXPECTED_TO_RUN` tinyint(1) default '0',
  `ENV` varchar(4) NOT NULL default '',
  `ACTIVATED` tinyint(1) unsigned default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `VIRTUAL_SERVER_ID` int(11) unsigned NOT NULL default '0',
  `UKEY` varchar(11) default NULL,
  PRIMARY KEY  (`DOMAIN_NAME`,`SERVER_NAME`,`ENV`(1)),
  KEY `CLUSTER_NAME` (`CLUSTER_NAME`),
  KEY `VIRTUAL_SERVER_ID` (`VIRTUAL_SERVER_ID`),
  KEY `UKEY` (`UKEY`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

SET SQL_MODE=@OLD_SQL_MODE;