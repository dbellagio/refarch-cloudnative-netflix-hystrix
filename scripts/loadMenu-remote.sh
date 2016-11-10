#!/bin/bash
while [  0 -lt 1 ]; do
      D=`date`
      R=`curl -o /dev/null --silent -w "%{http_code} " "http://super-wfd-ui-dev.mybluemix.net/" `;
      echo $D $R;
      sleep 1s;
done

