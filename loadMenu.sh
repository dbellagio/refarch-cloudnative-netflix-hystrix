#!/bin/bash
while [  0 -lt 1 ]; do
      D=`date`
      R=`curl -o /dev/null --silent -w "%{http_code} " "http://localhost:8181/" `;
      echo $D $R;
      sleep 1s;
done

