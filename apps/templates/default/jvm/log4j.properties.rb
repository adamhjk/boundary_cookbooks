# for production, you should probably set the root to INFO
# and the pattern to %c instead of %l.  (%l is slower.)

# output messages into a rolling log file as well as stdout
/*log4j.rootLogger=INFO,stdout*/

# stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%5p [%t] %d{HH:mm:ss,SSS} %m%n

# rolling log file
log4j.appender.R=org.apache.log4j.RollingFileAppender
log4j.appender.file.maxFileSize=50MB
log4j.appender.file.maxBackupIndex=20
log4j.appender.R.layout=org.apache.log4j.PatternLayout
log4j.appender.R.layout.ConversionPattern=%5p [%t] %d{ISO8601} %m%n
# Edit the next line to point to your logs directory
log4j.appender.R.File=/var/log/<%= @deploy_config["id"] %>/<%= @deploy_config["id"] %>.log