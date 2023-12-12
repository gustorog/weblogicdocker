#First stage conf java and install WebLogic

FROM redhat/ubi8:latest as builder

# ENV TO USE
ENV LANG=C.utf8 \
INSTALL_JAVA_DIR=/u01/oracle/java \
DOMAIN=DOMAIN_APP \
USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
JAVA_HOME=/u01/oracle/java/jdk \
OPATCH_NO_FUSER=true \
ASERVER=/u01/oracle/Domains/aserver/$DOMAIN \
LOGS=/u01/oracle/logs/$DOMAIN

## Copy installers
COPY ./Install_JAVA/* /tmp/

## Install tar and zip
RUN dnf install -y tar zip \
## Extract and install java
&& set -eux \
&& mkdir -p $INSTALL_JAVA_DIR \
&& mv "$(ls /tmp/jdk-11*_linux-x64_bin.tar.gz)" $INSTALL_JAVA_DIR \
&& tar --extract --file "$(ls "$INSTALL_JAVA_DIR"/jdk-11*_linux-x64_bin.tar.gz)" --directory $INSTALL_JAVA_DIR \
&& rm "$(ls "$INSTALL_JAVA_DIR"/jdk-11*.gz)" \ 
&& mv $INSTALL_JAVA_DIR/"$(ls "$INSTALL_JAVA_DIR")" "$INSTALL_JAVA_DIR/jdk" \
&& alternatives --install /usr/bin/java java /u01/oracle/java/jdk/bin/java 1 \
&& alternatives --install /usr/bin/javaws javaws /u01/oracle/java/jdk/bin/javaws 1 \
&& alternatives --install /usr/bin/javac javac /u01/oracle/java/jdk/bin/javac 1 \
&& alternatives --install /usr/bin/jar jar /u01/oracle/java/jdk/bin/jar 1 \
## Create group and user weblogic
&& groupadd -g 101 oracle \
&& useradd -u 3001 -b /u01 -g oracle -d /u01/oracle -m -s /bin/bash weblogic \
## Create directories
&& mkdir -p /u01/oracle/Domains/aserver/$DOMAIN \
&& mkdir -p /u01/oracle/logs/$DOMAIN \
&& mkdir -p /u01/oracle/Middleware/$DOMAIN \
&& mkdir -p /u01/oracle/install_files \
&& chown -R weblogic:oracle /u01

## INSTALL WLS ##
ENV ORACLE_HOME=/u01/oracle/Middleware/$DOMAIN/wlserver \
OPATCH_HOME=/u01/oracle/Middleware/$DOMAIN/wlserver/OPatch 
## COPY install_files to Image
COPY  ./install_files /u01/oracle/install_files
RUN chown -R weblogic:oracle /u01/oracle/install_files

USER weblogic

##Unzip installer weblogic
RUN  unzip /u01/oracle/install_files/WLS/fmw_14.1.1.0.0_wls_lite_slim_Disk1_1of1.zip -d /u01/oracle/install_files/WLS \
&& rm -fr /u01/oracle/install_files/WLS/fmw_14.1.1.0.0_wls_lite_slim_Disk1_1of1.zip \
## Install WLS
&& cd /u01/oracle/Domains/aserver/$DOMAIN \
&& $JAVA_HOME/bin/java -Xmx1024m -jar /u01/oracle/install_files/WLS/fmw_14.1.1.0.0_wls_lite_quick_slim_generic.jar -silent ORACLE_BASE=/u01/oracle/Middleware/$DOMAIN ORACLE_HOME=$ORACLE_HOME INVENTORY_LOCATION=/u01/oracle/Middleware/$DOMAIN/oraInventory -novalidation -ignoreSysPrereqs -force \
## Install update OPATCH
&& cd /u01/oracle/install_files/WLS/Patches/opatch \
&& for x in *.zip; do unzip $x; done \
&& rm -fr /u01/oracle/install_files/WLS/Patches/opatch/*zip \
&& java -jar /u01/oracle/install_files/WLS/Patches/opatch/"$(ls /u01/oracle/install_files/WLS/Patches/opatch/)"/opatch_generic.jar -silent -force -novalidation oracle_home=$ORACLE_HOME \
## install security updates
&& cd /u01/oracle/install_files/WLS/Patches/wl \
&& for x in *.zip; do unzip $x; done \
&& rm -fr /u01/oracle/install_files/WLS/Patches/wl/*zip \
&& for filename in $(ls /u01/oracle/install_files/WLS/Patches/wl); do cd /u01/oracle/install_files/WLS/Patches/wl/"$filename"; $OPATCH_HOME/opatch apply -silent; done \
&& rm -fr /u01/oracle/install_files/WLS \
## Create domain
&& cd /u01/oracle/install_files/Domain \
&& chmod 700 create-wls-domain.py \
&& $ORACLE_HOME/oracle_common/common/bin/wlst.sh -loadProperties domain.properties create-wls-domain.py \
&& mkdir -p  /u01/oracle/Domains/aserver/$DOMAIN/servers/AdminServer/security/ \
&& cp -p /u01/oracle/install_files/Domain/domain.properties /u01/oracle/Domains/aserver/$DOMAIN/servers/AdminServer/security/ \
&& cd /u01/oracle/Domains/aserver/$DOMAIN/servers/AdminServer/security/ \
&& mv domain.properties boot.properties

#Second stage, to reduce the size of image
FROM redhat/ubi8:latest

ENV DOMAIN=DOMAIN_APP \
TZ=America/Bogota \
LANG=C.utf8 \
USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
JAVA_HOME=/u01/oracle/java/jdk \
OPATCH_NO_FUSER=true \
APP=APP_NAME

ENV ORACLE_HOME=/u01/oracle/Middleware/$DOMAIN/wlserver \
OPATCH_HOME=/u01/oracle/Middleware/$DOMAIN/wlserver/OPatch \
ASERVER=/u01/oracle/Domains/aserver/$DOMAIN \
LOGS=/u01/oracle/logs/$DOMAIN

#Update Redhat and install necessary libraries 
RUN dnf -y update && dnf install freetype fontconfig -y && dnf clean all \
&& mkdir -p /u01/oracle \
&& groupadd -g 101 oracle \
&& useradd -u 3001 -b /u01 -g oracle -d /u01/oracle -m -s /bin/bash weblogic \
&& chown -R weblogic:oracle /u01 \
&& alternatives --install /usr/bin/java java /u01/oracle/java/jdk/bin/java 1 \
&& alternatives --install /usr/bin/javaws javaws /u01/oracle/java/jdk/bin/javaws 1 \
&& alternatives --install /usr/bin/javac javac /u01/oracle/java/jdk/bin/javac 1 \
&& alternatives --install /usr/bin/jar jar /u01/oracle/java/jdk/bin/jar 1 \
&& rm -if /etc/localtime && ln -s /usr/share/zoneinfo/America/Bogota /etc/localtime && echo $TZ > /etc/timezone

COPY --from=builder --chown=weblogic:oracle /u01 /u01
COPY --chown=weblogic:oracle ./DeployApp /u01/oracle/DeployApp
USER weblogic

#Install App
RUN cd /u01/oracle/DeployApp \
&& $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ./app-deploy.py

##Install datasource
#RUN cd /u01/oracle/DeployApp \
#&& $ORACLE_HOME/oracle_common/common/bin/wlst.sh -loadProperties ./datasource-lab.properties ./ds-deploy.py 

CMD /u01/oracle/Domains/aserver/$DOMAIN/bin/startWebLogic.sh
