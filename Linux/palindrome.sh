#!/bin/bash

echo "please enter the string"

read string

string_new=$string

reverse_string=`echo $string|rev`
echo "$reverse_string"
# if [$string1 -eq $reversal]
# echo "Palindrome"
# else
# echo "not palin"
#
# fi
