#!/bin/bash
for token in `echo $*|rev`
do
  echo $token
done 
