#!/bin/bash -e

# -------------------------------------------------------------------------------------------------
# Function
# -------------------------------------------------------------------------------------------------
BASEDIR=$(dirname $(readlink -f ${0}))
BASENAME=$(basename ${0})

function usage {
  echo "Usage: ${BASENAME} <file> <dir> [<index>]"
  echo "Read URL line by line from <file>, convert to markdown file with name a<index>.md and save to to <dir>"
  exit 0
}

function dieUsage {
  local mesg=$1
  echo "Error: ${mesg}"
  usage
  exit 1
}

# -------------------------------------------------------------------------------------------------
# ParseArg
# -------------------------------------------------------------------------------------------------
if [[ $# -eq 1 && ("$1" == "-h" || "$1" == "--help") ]]
then
  usage
fi

if [[ $# -ne 3 ]]
then
  dieUsage "Error: Invalid argument count -- $#"
fi

fileQ=$1
dirA=$2
startIndex=$3

# -------------------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------------------
mkdir -p $dirA
i=$startIndex
while read currQ
do
  echo "--------------------------------------------------------------------------------------------------------------"
  echo "$currQ"
  time bash quoraToMd.sh "$currQ" "$dirA/a${i}.md"
  (( ++i ))
done < <(cat $fileQ)

