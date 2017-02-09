#!/bin/bash
while [  0 -lt 1 ]; do
      D=`date`
      R=`curl -o /dev/null --silent -w "%{http_code} " "http://localhost:8180/menu" `;
      # R=`curl -o /dev/null --silent -w "%{http_code} " "http://localhost:8080/whats-for-dinner" `;
      echo $D $R;
      sleep 1s;
done

