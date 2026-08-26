if test $# -lt 7
then
  echo usage: sh make_dataset.sh \
    fred_dir \
    new_dataset_name \
    new_dataset_parent_dir \
    num_images_per_sequence \
    spiking\|regular \
    seed \
    threads 1>&2
  exit 1
fi

if test ! -d "$1"
then
  echo error: bad FRED directory: "$1" 1>&2
  exit 2
else
  fred="$1"
fi

if test "$2" = ""
then
  echo error: empty string given for new dataset name 1>&2
  exit 3
else
  name="$2"
fi

if test ! -d "$3"
then
  echo error: bad new dataset parent directory: "$3" 1>&2
  exit 4
else
  parent="$3"
  dir="$parent"/"$name"
  if test -d "$dir"
  then
    echo error: dataset already exists 1>&2
    exit 5
  else
    mkdir \
      "$dir" \
      "$dir"/train \
      "$dir"/test
  fi
fi

if test "$4" -lt 0
then
  echo error: bad number of images per sequence: $4 1>&2
  exit 6
else
  n=$4
fi

case "$5" in
spiking) type=spiking ;;
regular) type=regular ;;
*) echo error: bad YOLO type: "$5": \
               should be \"spiking\" or \"regular\" 1>&2
   exit 7 ;;
esac

if ! echo "$6" | awk '{
                   if ($0 !~ /^[0-9][0-9]*$/) {
                     exit 1
                   }
                 }'
then
  echo error: bad seed: "$6" 1>&2
  exit 8
else
  seed=$6
fi

if test "$7" -lt 1
then
  echo error: bad number of threads: $7 1>&2
  exit 9
else
  np=0
  threads=$7
fi

for i in train test
do
  for j in `cd "$fred"/$i ; ls *.zip`
  do
    ( ( cd "$fred"/$i ; unzip $j > /dev/null )
    k=`echo $j | sed 's/.zip//'`
    mkdir -p "$dir"/$i/$k
    for l in rgb event
    do
      if test $l = rgb
      then
        mkdir \
          "$dir"/$i/$k/$l \
          "$dir"/$i/$k/$l/data \
          "$dir"/$i/$k/$l/labels
        if test $k -eq 68
        then
          ( cd "$fred"/$i/$k/RGB
          for m in *
          do
            mv $m `echo $m | sed 's/^/Video_68_/'`
          done )
        fi
        ls "$fred"/$i/$k/RGB
      else
        mkdir \
          "$dir"/$i/$k/$l \
          "$dir"/$i/$k/$l/data \
          "$dir"/$i/$k/$l/labels
        ( cd "$fred"/$i/$k/Event/Frames
        for m in *
        do
          if ! echo $m | grep -q frame
          then
            mv $m `echo $m | sed 's/_/_frame_/2'`
          fi
        done )
        ls "$fred"/$i/$k/Event/Frames |
        sed 's/_/_ /3
             s/.png/ .png/' |
        sort -n -k 2 |
        sed 's/ //g'
      fi | cat -n | tail -n +301 |
      awk \
        -v seed=$seed \
      'BEGIN {
        srand(seed)
        while (getline) {
          printf("%lf %d %s\n", rand(), $1, $2)
        }
      }' | sort -n | head -n $n |
      while read junk pos df
      do
        if test $l = rgb
        then
          cp "$fred"/$i/$k/RGB/$df "$dir"/$i/$k/$l/data
          if test $type = spiking
          then
            lf=`echo $df | sed 's/jpg/json/'`
          else
            lf=`echo $df | sed 's/jpg/txt/'`
          fi
        else
          cp "$fred"/$i/$k/Event/Frames/$df "$dir"/$i/$k/$l/data
          if test $type = spiking
          then
            lf=`echo $df | sed 's/png/json/'`
          else
            lf=`echo $df | sed 's/png/txt/'`
          fi
        fi
        t=`expr $pos \* 33333`
        sed 's/\(\....\):/\1000/
             s/\(\.....\):/\100/
             s/\(\......\):/\10/
             s/\.//
             s/://
             s/,//g' "$fred"/$i/$k/coordinates.txt |
        grep "^$t " |
        if test $type = spiking
        then
          awk \
            -v df=$df \
            -v lf=$lf \
            -v labels="$dir"/$i/$k/$l/labels \
          'BEGIN {
            cmd = "echo '\''a\n"
            cmd = cmd "["
            cmd = cmd "{"
            cmd = cmd "\"labels\":["
            if (getline) {
              do {
                cmd = cmd "{"
                cmd = cmd "\"box2d\":{"
                cmd = cmd "\"x1\":" $2 ","
                cmd = cmd "\"y1\":" $3 ","
                cmd = cmd "\"x2\":" $4 ","
                cmd = cmd "\"y2\":" $5
                cmd = cmd "},"
                cmd = cmd "\"category\":\"" $7
                for (j = 8; j <= NF; j++) {
                  cmd = cmd " " $j
                }
                cmd = cmd "\""
                cmd = cmd "}"
                if (getline) {
                  cmd = cmd ","
                } else {
                  cmd = cmd "],"
                  done = "yes"
                }
              } while (!done)
            } else {
              cmd = cmd "],"
            }
            cmd = cmd "\"name\":\"" df "\""
            cmd = cmd "}"
            cmd = cmd "]\n"
            cmd = cmd ".\n"
            cmd = cmd "w " labels "/" lf "'\'' | ed -s"
            system(cmd)
          }'
        else
          awk \
            -v lf=$lf \
            -v labels="$dir"/$i/$k/$l/labels \
          'BEGIN {
            cmd = "echo '\''a\n"
            while (getline) {
              label = $7
              for (i = 8; i <= NF; i++) {
                label = label " " $i
              }
              switch (label) {
              case /Betafpv air75/:          cmd = cmd 0
                                             break
              case /DarwinFPV cineape20/:    cmd = cmd 1
                                             break
              case /DarwinFPV cineape20ger/: cmd = cmd 2
                                             break
              case /DJI Mini 2/:             cmd = cmd 3
                                             break
              case /DJI Mini 3/:             cmd = cmd 4
                                             break
              case /DJI Tello EDU/:          cmd = cmd 5
                                             break
              }
              cmd = cmd " " ($2 + ($4 - $2) / 2) / 1280
              cmd = cmd " " ($3 + ($5 - $3) / 2) / 720
              cmd = cmd " " ($4 - $2) / 1280
              cmd = cmd " " ($5 - $3) / 720
              cmd = cmd "\n"
            }
            cmd = cmd ".\n"
            cmd = cmd "w " labels "/" lf "'\'' | ed -s"
            system(cmd)
          }'
        fi
      done
    done
    ( cd "$fred"/$i ; rm -rf $k ) ) &
    np=$((np+1))
    if test $np -eq $threads
    then
      wait
      np=0
    fi
  done
done
