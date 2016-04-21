#!/bin/bash
compiler=iverilog
engine=vvp

for f in test/testbench/*.v 
do
    base=${f%.v}
    testname=${base##*/}
    outname=$base.out
    echo "--> $testname"
    sed -n '/__START TB__/,$!p' < pipe.v > pre.v
    sed -n '/__END TB__/,$p' < pipe.v > post.v
    cat pre.v $f post.v > temp.v
    $compiler temp.v -o temp
    $engine temp > $outname
    rm pre.v temp.v post.v temp
done
