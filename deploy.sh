#!/bin/bash
APP_PATH=/home/aviasales/builder/hades

ssh -A aviasales@wwa.int.avs.io << EOF
  cd $APP_PATH
  git checkout .
  git pull --rebase
  mix release.clean && mix deps.get --only prod && brunch build --production && MIX_ENV=prod mix phoenix.digest && MIX_ENV=prod mix release && scp rel/hades/releases/0.0.2/hades.tar.gz aviasales@yasen2.int.avs.io:~/hades/hades.tar.gz
EOF


ssh -A aviasales@yasen2.int.avs.io << EOF
  cd ~/hades
  tar -xvf hades.tar.gz
EOF
