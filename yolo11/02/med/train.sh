#!/bin/sh
#SBATCH --account=ACF-UTK0011
#SBATCH --partition=campus-gpu-large
#SBATCH --qos=campus-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --gpus=1
#SBATCH --time=24:00:00
#SBATCH --output=train.out
#SBATCH --error=train.err

set -x

cd ../../..

source venv/bin/activate

python=`pwd`/venv/bin/python

rm -rf /tmp/jhanna8

mkdir \
  /tmp/jhanna8 \
  /tmp/jhanna8/datasets

sh scripts/make_dataset.sh \
  $proj/datasets/FRED \
  fred \
  /tmp/jhanna8/datasets \
  60 \
  regular \
  2 \
  48

find \
  /tmp/jhanna8/datasets/fred \
  -type f \
  -name '*.txt' \
  -exec \
    sh \
      -c \
      'if test `wc -l < $1` -ne 0
      then
        awk '\''{
          printf("0 %s %s %s %s\n", $2, $3, $4, $5)
        }'\'' $1 > tmp.txt
        mv tmp.txt $1
      fi' sh {} \;

cd yolo11/02/med

time $python train.py

rm -rf /tmp/jhanna8

deactivate

set +x
