#!/bin/sh -e

COUNT=`ls tests/*_test.rb | wc -l`

parallel_test tests -n $COUNT