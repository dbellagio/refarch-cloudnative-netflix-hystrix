#!/bin/bash
while [  0 -lt 1 ]; do
      D=`date`
      R=`curl -o /dev/null --silent -w "%{http_code} " "http://super-zuul-dev.mybluemix.net/whats-for-dinner" `;
      echo $D $R;
      sleep 1s;
done

