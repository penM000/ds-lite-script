#!/bin/sh
cp ./dslite.sh /usr/local/bin/dslite.sh
chmod +x /usr/local/bin/dslite.sh
cp ./dslite-auto-start.service /etc/systemd/system/dslite-auto-start.service
systemctl enable dslite-auto-start.service
