#!/bin/bash

[ -z "${SMTP_SERVER}" ] && echo "SMTP_SERVER is not set" && exit 1
[ -z "${SMTP_PORT:587}" ] && echo "SMTP_PORT is not set" && echo "Default is set port 587"
[ -z "${SMTP_SENDER}" ] && echo "SMTP_SENDER is not set" && exit 1
[ -z "${SMTP_USERNAME}" ] && echo "SMTP_USERNAME is not set" && exit 1
[ -z "${SMTP_PASSWORD}" ] && echo "SMTP_PASSWORD is not set" && exit 1

#Get the domain from the server host name
DOMAIN=`echo $SERVER_HOSTNAME |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//'`

#Comment default mydestination, we will set it bellow
sed -i -e '/mydestination/ s/^#*/#/' /etc/postfix/main.cf

echo "myhostname=$SERVER_HOSTNAME"  >> /etc/postfix/main.cf
echo "mydomain=$DOMAIN"  >> /etc/postfix/main.cf
echo 'mydestination=$myhostname'  >> /etc/postfix/main.cf
echo 'myorigin=$mydomain'  >> /etc/postfix/main.cf
echo "relayhost = [$SMTP_SERVER]:${SMTP_PORT}" >> /etc/postfix/main.cf
echo "smtp_use_tls=yes" >> /etc/postfix/main.cf
echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> /etc/postfix/main.cf
echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
echo "[$SMTP_SERVER]:${SMTP_PORT} $SMTP_USERNAME:$SMTP_PASSWORD" >> /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

if [ ! -z "${SMTP_SENDER}" ]; then
  echo "smtp_generic_maps = regexp:/etc/postfix/generic_maps" >> /etc/postfix/main.cf
  echo "/^(.*@).*$/ ${SMTP_SENDER}" >> /etc/postfix/generic_maps
  postmap /etc/postfix/generic_maps
fi

/etc/init.d/rsyslog start
/etc/init.d/postfix start

tail -f /var/log/maillog
