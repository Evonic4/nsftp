#!/bin/bash

f1=/usr/share/nsftp/


cd $f1
perl -pi -e "s/\r\n/\n/" ./*.sh
chmod +rx ./*.sh
