#!/usr/bin/env bash

if test -z "$1"; then
  echo "$0: Please provide the number of virtual cpus"
  exit
fi

nvcpus=$1

# Chosing to sort in such a way that it is easier to see if there is a bug in the program :)
CPUS_DATA=$(lscpu --all --parse=SOCKET,CORE,CPU | grep -vP '^(#)' | sort -t ',' -k 1,1n -k 2,2n -k 3,3n)

declare CPUS_ENTRY
i=0; while read cpu_entry; do
  CPUS_ENTRY[$i]=$cpu_entry
  i=$(($i + 1))
done <<< "$CPUS_DATA"
cpus=$(nproc)

THREADS=$(echo "$CPUS_DATA" | wc -l)
CORES=$(echo "$CPUS_DATA" | cut -d ',' -f 2 | sort | uniq | wc -l)
SOCKETS=$(echo "$CPUS_DATA" | cut -d ',' -f 1 | sort | uniq | wc -l)

# A bit of a wild guess, ...
threads=$(($THREADS/$CORES))
cores=$(($(($nvcpus + 1))/$threads))

QEMU_SMP="  -smp $nvcpus,cores=$cores,threads=$threads"

for vcpu in $(seq 0 $(($nvcpus - 1))); do
  affinity=$(echo ${CPUS_ENTRY[$(($vcpu%$cpus))]} | cut -d ',' -f 3)
  QEMU_AFFINITIES="$QEMU_AFFINITIES  \\
  -vcpu vcpunum=$vcpu,affinity=$affinity"
done

echo "$QEMU_SMP $QEMU_AFFINITIES"
