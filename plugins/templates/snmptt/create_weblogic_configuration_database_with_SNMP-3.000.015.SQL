# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2007/10/21, v3.000.015, create_weblogic_configuration_database_with_SNMP-3.000.015.SQL
# ---------------------------------------------------------------------------------------------------------

create database if not exists `weblogicConfig`;

USE `weblogicConfig`;

#
# Table structure for table `ADMIN_CONFIG`
#

CREATE TABLE `ADMIN_CONFIG` (
  `ADMIN_NAME` varchar(32) NOT NULL default '',
  `HOST` varchar(64) default NULL,
  `PORT` int(5) default NULL,
  `VERSION` char(2) NOT NULL default 'v2',
  `COMMUNITY` varchar(32) default NULL,
  `ENV` varchar(4) NOT NULL default '',
  `ACTIVATED` tinyint(1) unsigned default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL,
  `uKey` varchar(11) default NULL,
  `holidayBundleID` int(11) default '0',
  `step` smallint(6) NOT NULL default '10',
  `minute` varchar(167) NOT NULL default '*/10',
  `hour` varchar(61) NOT NULL default '*',
  `dayOfTheMonth` varchar(83) NOT NULL default '*',
  `monthOfTheYear` varchar(26) NOT NULL default '*',
  `dayOfTheWeek` varchar(13) NOT NULL default '*',
  `adminConsoleCheck` tinyint(1) NOT NULL default '1',
  PRIMARY KEY (`ADMIN_NAME`),
  UNIQUE KEY `uKey` (`uKey`)
) ENGINE=MyISAM;

#
# Table structure for table `CLUSTERS`
#

DROP TABLE IF EXISTS `CLUSTERS`;

CREATE TABLE `CLUSTERS` (
  `CLUSTER_NAME` varchar(45) default NULL,
  `CLUSTER_SERVERS` varchar(254) default NULL,
  `ENV` varchar(4) default NULL,
  `ACTIVATED` tinyint(1) unsigned default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL,
  `VIRTUAL_CLUSTER_ID` int(11) unsigned NOT NULL default '0',
  `UKEY` varchar(11) default NULL,
  PRIMARY KEY (`CLUSTER_NAME`,`ENV`(1)),
  KEY `VIRTUAL_CLUSTER_ID` (`VIRTUAL_CLUSTER_ID`),
  KEY `UKEY` (`UKEY`)
) ENGINE=MyISAM;

#
# Table structure for table `SERVERS`
#

DROP TABLE IF EXISTS `SERVERS`;

CREATE TABLE `SERVERS` (
  `DOMAIN_NAME` varchar(45) default NULL,
  `SERVER_NAME` varchar(45) default NULL,
  `LISTEN_ADDRESS` varchar(45) default NULL,
  `LISTEN_PORT` int(5) default NULL,
  `MACHINE` varchar(45) default NULL,
  `CLUSTER_NAME` varchar(45) default NULL,
  `EXPECTED_TO_RUN` tinyint(1) default '0',
  `ENV` varchar(4) default NULL,
  `ACTIVATED` tinyint(1) unsigned default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL,
  `VIRTUAL_SERVER_ID` int(11) unsigned NOT NULL default '0',
  `UKEY` varchar(11) default NULL,
  PRIMARY KEY (`DOMAIN_NAME`,`SERVER_NAME`,`ENV`(1)),
  KEY `CLUSTER_NAME` (`CLUSTER_NAME`),
  KEY `VIRTUAL_SERVER_ID` (`VIRTUAL_SERVER_ID`),
  KEY `UKEY` (`UKEY`)
) ENGINE=MyISAM;

#
# Table structure for table `wls_snmp_CONFIG`
#

DROP TABLE IF EXISTS `wls_snmp_CONFIG`;

CREATE TABLE `wls_snmp_CONFIG` (
  `event_name` varchar(64) NOT NULL default '',
  `event_oid` varchar(64) default NULL,
  PRIMARY KEY (`event_name`)
) ENGINE=MyISAM;

#
# Data for the table `wls_snmp_CONFIG`
#

insert into `wls_snmp_CONFIG` (`event_name`,`event_oid`) values ('wlsAttributeChange','.1.3.6.1.4.1.140.625.0.80');
insert into `wls_snmp_CONFIG` (`event_name`,`event_oid`) values ('wlsLogNotification','.1.3.6.1.4.1.140.625.0.60');
insert into `wls_snmp_CONFIG` (`event_name`,`event_oid`) values ('wlsMonitorNotification','.1.3.6.1.4.1.140.625.0.75');
insert into `wls_snmp_CONFIG` (`event_name`,`event_oid`) values ('wlsServerShutDown','.1.3.6.1.4.1.140.625.0.70');
insert into `wls_snmp_CONFIG` (`event_name`,`event_oid`) values ('wlsServerStart','.1.3.6.1.4.1.140.625.0.65');

#
# Table structure for table `wls_snmptt_CONFIG`
#

DROP TABLE IF EXISTS `wls_snmptt_CONFIG`;

CREATE TABLE `wls_snmptt_CONFIG` (
  `trapMBeanType` varchar(64) NOT NULL default '',
  `trapMBeanType_MATCH` char(2) default NULL,
  `trapAttributeName` varchar(64) NOT NULL default '',
  `trapAttributeName_MATCH` char(2) default NULL,
  `trapMonitorType` varchar(64) NOT NULL default '',
  `trapMonitorType_MATCH` char(2) default NULL,
  `severity` varchar(8) NOT NULL default '',
  `snmpgetOID` varchar(255) default NULL,
  `destination` char(1) NOT NULL default '0',
  `event_name` varchar(64) NOT NULL default '',
  `category` varchar(32) NOT NULL default '',
  `format_string` varchar(255) NOT NULL default '',
  `command_string` varchar(255) default NULL,
  `regular_expression` varchar(255) default NULL,
  `sources_list` varchar(64) NOT NULL default '',
  `mode` char(3) NOT NULL default '',
  `description` text,
  `activated` tinyint(1) NOT NULL default '1',
  `CURRENT_TIMESTAMP` timestamp NOT NULL,
  `action_on_65` varchar(255) default NULL,
  PRIMARY KEY (`trapMBeanType`,`trapAttributeName`,`trapMonitorType`,`event_name`,`category`,`sources_list`,`mode`)
) ENGINE=MyISAM;

#
# Data for the table `wls_snmptt_CONFIG`
#

insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'UNKNOWN',NULL,'0','wlsAttributeChange','LOGONLY','Observed attribute change received from $2, $3, $4, $5, $6, $7, $8, $9',NULL,NULL,'','','This trap is generated when an attribute change is observed.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"\r\n  3: trapMBeanName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The Name of the MBean \"\r\n  4: trapMBeanType\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The type of the MBean \"\r\n  5: trapAttributeName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The name of an attribute \"\r\n  6: trapAttributeType\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The type of an attribute \"\r\n  7: trapAttributeChangeType\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The type of Change, an attribute has gone thru. It can be either ADD, or REMOVE, or UPDATE \"\r\n  8: trapAttributeOldVal\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The OLD value of an attribute \"\r\n  9: trapAttributeNewVal\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The NEW value of an attribute \"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'UNKNOWN',NULL,'0','wlsLogNotification','LOGONLY','Server log received from $2, $3, $4, $5, $6, $7, $8, $9, $10',NULL,NULL,'','','The server log.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"\r\n  3: trapMachineName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the machine where the trap is generated\"\r\n  4: trapLogThreadId\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" An integer that indicates the if of the thread in which the trap is generated\"\r\n  5: trapLogTransactionId\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the transactions from which the trap is generated\"\r\n  6: trapLogUserId\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the user id from which the trap is generated\"\r\n  7: trapLogSubsystem\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the subsystem from which the trap is generated\"\r\n  8: trapLogMsgId\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" An intefer that indicates the trap\'s message id\"\r\n  9: trapLogSeverity\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the severity of the trap\'s message\"\r\n 10: trapLogMessage\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that includes the body of the log message\"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'UNKNOWN',NULL,'0','wlsMonitorNotification','LOGONLY','JMX Monitor Notification received from $2, $3, $4, $5, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','NEG','This trap is generated when any JMX Monitor Notification is received.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"\r\n  3: trapMonitorType\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that should be either CounterMonitor, or GaugeMonitor, or StringMonitor\"\r\n  4: trapMonitorThreshold\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" An ASCII-string representation of the value which triggerd this monitor\"\r\n  5: trapMonitorValue\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" An ASCII-string representation, which is the derived value \"\r\n  6: trapMBeanName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The Name of the MBean \"\r\n  7: trapMBeanType\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The type of the MBean \"\r\n  8: trapAttributeName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\"The name of an attribute \"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'CRITICAL',NULL,'0','wlsServerShutDown','ASNMTAP','This trap is generated when the server $2 has been shut down $1',NULL,NULL,'snmptt-nodes-weblogic','POS','This trap is generated when the server has been shut down.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'CRITICAL',NULL,'0','wlsServerShutDown','PENDING','This trap is generated when the server $2 has been shut down $1',NULL,NULL,'snmptt-nodes-weblogic','NEG','This trap is generated when the server has been shut down.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'OK',NULL,'0','wlsServerStart','ASNMTAP','This trap is generated when the server $2 was started on $1',NULL,NULL,'snmptt-nodes-weblogic','POS','This trap is generated when the server was started.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'',NULL,'OK',NULL,'0','wlsServerStart','PENDING','This trap is generated when the server $2 was started on $1',NULL,NULL,'snmptt-nodes-weblogic','NEG','This trap is generated when the server was started.\r\nVariables:\r\n  1: trapTime\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the time\"\r\n  2: trapServerName\r\n     Syntax=\"OCTETSTR\"\r\n     Descr=\" A string that indicates the server which generated the trap\"',1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('',NULL,'',NULL,'jmx.monitor.error.(\\w+)','$3','WARNING',NULL,'0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('ExecuteQueueRuntime','$6','ExecuteThreadCurrentIdleCount','$8','jmx.monitor.gauge.high','$3','OK','.1.3.6.1.4.1.140.625.180.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('ExecuteQueueRuntime','$6','ExecuteThreadCurrentIdleCount','$8','jmx.monitor.gauge.low','$3','CRITICAL','.1.3.6.1.4.1.140.625.180.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('ExecuteQueueRuntime','$6','PendingRequestCurrentCount','$8','jmx.monitor.gauge.high','$3','CRITICAL','.1.3.6.1.4.1.140.625.180.1.35','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('ExecuteQueueRuntime','$6','PendingRequestCurrentCount','$8','jmx.monitor.gauge.low','$3','OK','.1.3.6.1.4.1.140.625.180.1.35','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JDBCConnectionPoolRuntime','$6','ActiveConnectionsCurrentCount','$8','jmx.monitor.gauge.high','$3','CRITICAL','.1.3.6.1.4.1.140.625.190.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JDBCConnectionPoolRuntime','$6','ActiveConnectionsCurrentCount','$8','jmx.monitor.gauge.low','$3','OK','.1.3.6.1.4.1.140.625.190.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JDBCConnectionPoolRuntime','$6','WaitingForConnectionCurrentCount','$8','jmx.monitor.gauge.high','$3','CRITICAL','.1.3.6.1.4.1.140.625.190.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JDBCConnectionPoolRuntime','$6','WaitingForConnectionCurrentCount','$8','jmx.monitor.gauge.low','$3','OK','.1.3.6.1.4.1.140.625.190.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JMSDestinationRuntime','$6','MessagesCurrentCount','$8','jmx.monitor.gauge.high','$3','CRITICAL','.1.3.6.1.4.1.140.625.220.1.40','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JMSDestinationRuntime','$6','MessagesCurrentCount','$8','jmx.monitor.gauge.low','$3','OK','.1.3.6.1.4.1.140.625.220.1.40','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JVMRuntime','$6','HeapFreeCurrent','$8','jmx.monitor.gauge.high','$3','OK','.1.3.6.1.4.1.140.625.340.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('JVMRuntime','$6','HeapFreeCurrent','$8','jmx.monitor.gauge.low','$3','CRITICAL','.1.3.6.1.4.1.140.625.340.1.25','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('MessagingBridgeRuntime','$6','Description','$8','jmx.monitor.string.differs','$3','CRITICAL','.1.3.6.1.4.1.140.625.354.1.22','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);
insert into `wls_snmptt_CONFIG` (`trapMBeanType`,`trapMBeanType_MATCH`,`trapAttributeName`,`trapAttributeName_MATCH`,`trapMonitorType`,`trapMonitorType_MATCH`,`severity`,`snmpgetOID`,`destination`,`event_name`,`category`,`format_string`,`command_string`,`regular_expression`,`sources_list`,`mode`,`description`,`activated`,`CURRENT_TIMESTAMP`,`action_on_65`) values ('MessagingBridgeRuntime','$6','Description','$8','jmx.monitor.string.matches','$3','OK','.1.3.6.1.4.1.140.625.354.1.22','0','wlsMonitorNotification','ASNMTAP','JMX Monitor Notification: $2, $3, $6, $7, $8',NULL,NULL,'snmptt-nodes-weblogic','POS',NULL,1,'2007-08-08 09:33:04',NULL);

