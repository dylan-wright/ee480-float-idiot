#!/bin/bash
compiler=iverilog
engine=vvp

numgood=0
numbad=0
bads=()

plain () { tput sgr0; }
bold () { tput bold; }
red () { tput setaf 1; }
green () { tput setaf 2; }
brown () { tput setaf 3; }
ltred () { bold; red; }
ltgreen () { bold; green; }
yellow () { bold; brown; }

showdiff () {
    local difffile="$1"
    sed -e "s/^+.*/$(green)&$(plain)/ ;
            s/^-.*/$(red)&$(plain)/ ;
            s/^/   /" "$difffile"
}
success () {
    local testname="$1"
    local msg="$2"
    echo "  --> $(green)${msg:-Success}$(plain)"
    let ++numgood
}
failure () {
    local testname="$1"
    echo "  --> $(ltred)Failure:$(plain)"
    let ++numbad
    bads+=("$testname")
}

summarize () {
    echo -n "$(ltgreen)$numgood good$(plain), "
    echo  "$(ltred)$numbad bad$(plain)"

    if (( numbad > 0)); then
        echo -n " --> Failed tests:$(ltred)"
        printf " %s" "${bads[@]}"
        echo "$(plain)"
    fi
}

echo "==> Executing testbenches"
for f in test/testbench/*.v 
do
    base=${f%.v}
    testname=${base##*/}
    outname=$base.out
    expected=$base.expected.out
    echo " --> Executing $testname"
    sed -n '/__START TB__/,$!p' < pipe.v > pre.v
    sed -n '/__END TB__/,$p' < pipe.v > post.v
    cat pre.v $f post.v > temp.v
    $compiler temp.v -o temp
    $engine temp > temp.out
    sed '/^WARNING.*$/d' < temp.out > $outname
    
    if [ -r "$expected" ]; then
        echo " --> Checking output..."
        if diff -u "$expected" $outname > $outname.diff; then
            success "$testname"
        else 
            failure "$testname"
            echo "  --> Diff results:"
            showdiff $outname.diff
        fi
    fi
done

echo
echo "==> Executing testprogs"
for f in test/testprogs/*.text.vmem
do
    base=${f%.text.vmem}
    testname=${base##*/}
    outname=$base.out
    expected=$base.expected.out
    echo " --> Executing $testname"
    #sed 's/pipe.vmem0/'${f//\//\\\/}'/' < pipe.v > temp
    cat $f ${base}.data.vmem > $testname.vmem
    sed 's/pipe.vmem1/'$testname.vmem'/' < pipe.v > temp.v
    $compiler temp.v -o temp
    $engine temp > temp.out
    sed '/^WARNING.*$/d' < temp.out > $outname
    
    if [ -r "$expected" ]; then
        echo " --> Checking output..."
        if diff -u "$expected" $outname > $outname.diff; then
            success "$testname"
        else 
            failure "$testname"
            echo "  --> Diff results:"
            showdiff $outname.diff
        fi
    fi
    rm $testname.vmem
done

echo
echo "==> Removing temp files..."
rm -f pre.v temp.v post.v temp temp.out
echo
echo -n "==> Testing has finished: "
summarize

if (($numbad != 0)); then
    exit 1
fi
