#!/bin/sh

echo "Creating jquery.anim8.js"
coffee -c -p src/jquery.anim8.coffee > dist/jquery.anim8.js

echo "Creating jquery.anim8.min.js"
coffee -c -p src/jquery.anim8.coffee  | uglifyjs > dist/jquery.anim8.min.js
