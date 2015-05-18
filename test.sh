#!/bin/bash 

function cont()
{
        echo "continue (y/n/s(kip)) ?"
        read a
        a=`echo $a| tr '[A-Z]' '[a-z]' `
        [ "$a" == "n" ]  && exit 1
        [ "$a" == "s" ]  && return 1
        [ "$a" == "y" ]  && return 0

}
message()
{
        echo "$*" | sed -e "s/^/[ `date` ]   /"
        cont
        return $?
}

cd carbon;   
pwd	  
message aaaa && echo ya 
