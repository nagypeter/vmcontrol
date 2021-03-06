#!/bin/sh

ORACLE_PROXY_SERVER="www-proxy-adcq7.us.oracle.com"
ORACLE_PROXY_PORT="80"
ORACLE_HTTP_PROXY="http:\/\/$ORACLE_PROXY_SERVER:$ORACLE_PROXY_PORT"
ORACLE_HTTPS_PROXY="https://$ORACLE_PROXY_SERVER:$ORACLE_PROXY_PORT"

#=========================================================
MAVENCONF_FILE=~/.m2/settings.xml

mvnresult=$(grep -c "<proxies>" $MAVENCONF_FILE -s)

if [[ $mvnresult == 1 ]]
then
    # maven configured for proxy
    echo "Maven is already configured for proxy."
else
    # maven not configured for proxy, need to uncomment
    sed "s|<!--proxies>|<proxies>|g" -i $MAVENCONF_FILE
    sed "s|</proxies-->|</proxies>|g" -i $MAVENCONF_FILE
    echo "Maven now has been configured for proxy."
fi
#=========================================================
YUMCONF_FILE=/etc/yum.conf

grepresult=$(grep -c "proxy=$ORACLE_HTTP_PROXY" $YUMCONF_FILE -s)

if [ $grepresult == 1 ]
then
    # yum configured for proxy, need to delete
    echo "yum is already configured for proxy."
else
    # yum not configured for proxy, need to add
    sudo sed -i '$ a\'"proxy=$ORACLE_HTTP_PROXY"'' $YUMCONF_FILE
    echo "yum now has been configured for proxy."
fi
#=========================================================
BASHRC_FILE=/home/oracle/.bashrc

grepresult=$(grep -c "export http_proxy=$ORACLE_HTTP_PROXY" $BASHRC_FILE -s)

if [ $grepresult == 1 ]
then
    # bashrc configured for proxy, need to delete
    echo "~/.bashrc is already configured for proxy."
else
    # bashrc not configured for proxy, need to add
    sudo sed -i '/unset http_proxy/d' $BASHRC_FILE
    sudo sed -i '/unset https_proxy/d' $BASHRC_FILE
    sudo sed -i '/unset HTTP_PROXY/d' $BASHRC_FILE
    sudo sed -i '/unset HTTPS_PROXY/d' $BASHRC_FILE
    sudo sed -i '$ a\'"export http_proxy=$ORACLE_HTTP_PROXY"'' $BASHRC_FILE
    sudo sed -i '$ a\'"export https_proxy=$ORACLE_HTTPS_PROXY"'' $BASHRC_FILE
    sudo sed -i '$ a\'"export HTTP_PROXY=$ORACLE_HTTP_PROXY"'' $BASHRC_FILE
    sudo sed -i '$ a\'"export HTTPS_PROXY=$ORACLE_HTTPS_PROXY"'' $BASHRC_FILE
        
    echo "~/.bashrc now has been configured for proxy."
fi

sudo mkdir -p /etc/systemd/system/docker.service.d

DOCKER_HTTPS_CONFIG=/etc/systemd/system/docker.service.d/https-proxy.conf
DOCKER_HTTP_CONFIG=/etc/systemd/system/docker.service.d/http-proxy.conf
sudo rm -f $DOCKER_HTTPS_CONFIG
sudo rm -f $DOCKER_HTTP_CONFIG

echo '[Service]' | sudo tee --append $DOCKER_HTTPS_CONFIG > /dev/null
echo 'Environment="HTTPS_PROXY='"$ORACLE_HTTPS_PROXY/"'"' | sudo tee --append $DOCKER_HTTPS_CONFIG > /dev/null

# remove escape chars ('\') from proxy URL
ORACLE_HTTP_PROXY=$(echo $ORACLE_HTTP_PROXY|sed "s@\\\\@@g")

echo '[Service]' | sudo tee --append $DOCKER_HTTP_CONFIG > /dev/null
echo 'Environment="HTTP_PROXY='"$ORACLE_HTTP_PROXY/"'"' | sudo tee --append $DOCKER_HTTP_CONFIG > /dev/null

sudo systemctl daemon-reload

sudo systemctl restart docker

echo "Docker has been configured for proxy:"

systemctl show --property="Environment docker"

#=========================================================

sudo git config --system http.proxy ${ORACLE_HTTP_PROXY}
sudo git config --global http.proxy ${ORACLE_HTTP_PROXY}

export http_proxy=$ORACLE_HTTP_PROXY
export https_proxy=$ORACLE_HTTPS_PROXY

echo "http_proxy set to: [${http_proxy}]"
echo "https_proxy set to: [${https_proxy}]"

echo "Proxy Configured for Oracle Network!!!"

echo "This window will close automatically/or continue running in 3s..."
sleep 3
