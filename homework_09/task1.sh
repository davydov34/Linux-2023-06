#!/bin/bash



cat >> /etc/sysconfig/watchlog << EOF
WORD="ALERT"
LOG=/var/log/watchlog.log
EOF

cat >> /var/log/watchlog.log << EOF
It is not the strongest of the species that survives, nor the most intelligent, but the one most responsive to change
And I snuck onto his laptop and, uh, might've disabled his "Serena Van Der Woodsen" Google ALERT.
Success is the child of audacity.
ALERT
The will to win, the desire to succeed, the urge to reach your full potential… these are the keys that will unlock the door to personal excellence.
Her eyes were ALERT now, insolently guilty, like the eyes of a child who has just perpetrated some nasty little joke
"ALERT"
Curtsey while you're thinking what to say. It saves time.
EOF

cat >> /opt/watchlog.sh << EOF
#!/bin/bash

WORD=\$1
LOG=\$2
DATE=\`date\`

if grep \$WORD \$LOG &> /dev/null
then
    logger "\$DATE: i found word, Master!"
else
    exit 0
fi
EOF

chmod 755 /opt/watchlog.sh

cat >> /etc/systemd/system/watchlog.service << EOF
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh \$WORD \$LOG
EOF

chmod 664 /etc/systemd/system/watchlog.service

cat >> /etc/systemd/system/watchlog.timer << EOF
[Unit]
Description=Run watchlog script every 30 second

[Timer]
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
EOF

systemctl start watchlog.timer
systemctl enable watchlog.timer
systemctl start watchlog.service