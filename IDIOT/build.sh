#!/bin/bash

for f in progs/*.c
do
    base=${f%.c}
    idiot=${base}.idiot
    echo "-> compiling $base"
    cat $f | ./idiocc > $idiot
done

for f in progs/*.idiot
do
    base=${f%.idiot}
    text=${base}.text.vmem
    data=${base}.data.vmem
    echo "-> assembling $base"
    echo $f | ./aik.py > $text 2> $data
done
