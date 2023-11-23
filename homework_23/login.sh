#!/bin/bash 

  if [ $(date +%A) = "Saturday" ] || [ $(date +%A) = "Sunday" ]; then

        if getent group admin | grep -qw "$PAM_USER" ; then
		echo "IF - Exit 0"
                exit 0
            else
		echo "IF-ELSE - Exit 1"
                exit 1
            fi
  else
    echo "END IF = Exit 0"
    exit 0
  fi