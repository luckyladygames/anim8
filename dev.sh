#!/bin/bash

# like a simple dev mode ... :) 
# just run this in the background while in development so coffee will
# automatically recompile into js for the demo/ 

# sometimes coffee crashes / exists so let's keep it going...
while true
do
    clear
    coffee -w -c -o demo/ src
    echo -n "RESTARTING IN: "
    for i in 3 2 1 
    do
        echo -n "$i "
        sleep 1
    done
done

