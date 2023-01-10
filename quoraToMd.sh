#!/bin/bash -e

# -------------------------------------------------------------------------------------------------
# Function
# -------------------------------------------------------------------------------------------------
BASEDIR=$(dirname $(readlink -f ${0}))
BASENAME=$(basename ${0})

function usage {
  echo "Usage: ${BASENAME} <url-to-quora-answer> <name-of-markdown-file>"
  echo "Convert QuoraAnswer to MarkDown"
  exit 0
}

function dieUsage {
  local mesg=$1
  echo "Error: ${mesg}"
  usage
  exit 1
}

function rmQuotes {
  if [[ $# -eq 0 ]]
  then
    str=$(cat)
  else
    str="$1"
  fi

  str=$(echo "$str" | sed -re 's%"(.*)"%\1%')
  echo "$str"
}

# -------------------------------------------------------------------------------------------------
# ParseArg
# -------------------------------------------------------------------------------------------------
if [[ $# -eq 1 && ("$1" == "-h" || "$1" == "--help") ]]
then
  usage
fi

if [[ $# -ne 2 ]]
then
  dieUsage "Invalid arguments"
fi

url=$1
fileMD=$2

# -------------------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------------------

# Get answer
curl --silent $url --output answer.html

##
# Format
# ------
#  - Look for the line with .push(\\"data\\":{\\"answer\\"
#  - Find substring between .push(" and ,\\"isVisibleToViewer
#  - Replace 1 or 3 occurence of '\' followed by " with "
#  - Replace 4 occurence of " with '
#  - Replace many occurences of \ and unicode with ''
##
grep '.push("{\\"data\\":{\\"answer\\"' answer.html |\
  sed -re 's%.*.push\(\"(.*)\\",\\"isVisibleToViewer.*%\1%' |\
  sed -re 's%(\\{1}|\\{3})"%"%g' |\
  sed -re 's%\\{4}"%\x27%g' |\
  sed -re 's%[\]+u201[cd9]%\x27%g' |\
  sed -re 's%[\]+u2013%\-%g' |\
  sed -re 's%[\]+u2014%\--%g' |\
  sed -re 's%.*"content":"%%' > answer.raw.json

# Format raw.json using jq
cat answer.raw.json | jq > answer.json

# Question
question=$(echo "$url" | sed -re "s%https://www.quora.com/([^/]+)/.*%\1%" | sed -re "s%-% %g")

# Paragraph Index
pIndex=0

# Array of footnotes
footerText=()
footerLink=()

# Section arrays
mapfile -t section       <<< "$(jq -c '.sections[].spans | length' answer.json)"
mapfile -t sectionQuoted <<< "$(jq -c '.sections[].quoted' answer.json)"
mapfile -t sectionType   <<< "$(jq -c '.sections[].type' answer.json | rmQuotes)"

# echo "--- debug --- ${sectionType[@]}" >&2

# Span arrays
mapfile -t spanText     <<< "$(jq -c '.sections[].spans[].text'                answer.json | rmQuotes)"
mapfile -t spanItalic   <<< "$(jq -c '.sections[].spans[].modifiers.italic'    answer.json | sed 's%null%false%')"
mapfile -t spanBold     <<< "$(jq -c '.sections[].spans[].modifiers.bold'      answer.json | sed 's%null%false%')"
mapfile -t spanLink     <<< "$(jq -c '.sections[].spans[].modifiers.link.url'  answer.json | rmQuotes)"
mapfile -t spanEmbed    <<< "$(jq -c '.sections[].spans[].modifiers.embed'     answer.json)"
mapfile -t spanCitation <<< "$(jq -c '.sections[].spans[].modifiers.citation'  answer.json)"

# Head of the answer
# ------------------
echo "# ${question}"         > $fileMD
echo "Quora [answer]($url)" >> $fileMD
echo ""                     >> $fileMD
echo "---"                  >> $fileMD

# Body of the answer
# ------------------

j=0
maxSpanCount=0
sectionPrefix=""
for (( i=0; i<${#section[@]}; i++))
do
  currP=""
  (( maxSpanCount += ${section[$i]} ))

  # The section is a quote and needs highlight
  prevSectionPrefix="$sectionPrefix"
  sectionPrefix=""
  if [[ "${sectionQuoted[$i]}" == "true" ]]
  then
    sectionPrefix="> "
  fi

  sectionBullet=""
  if [[ "${sectionType[$i]}" == "ordered-list" || "${sectionType[$i]}" == "unordered-list" ]]
  then
    sectionBullet=" - "
  fi

  for (( j=j; j < maxSpanCount; j++ ))
  do
    currText="${spanText[$j]}"

    # Italic
    if [[ "${spanItalic[$j]}" == "true" ]]
    then
      currText="*$currText*"
    fi

    # Bold
    if [[ "${spanBold[$j]}" == "true" ]]
    then
      currText="**$currText**"
    fi

    # Link
    if [[ "${spanLink[$j]}" != "null" ]]
    then
      url="${spanLink[$j]}"
      currText="[$currText]($url)"
    fi

    # Embed
    if [[ "${spanEmbed[$j]}" != "null" ]]
    then
      url=$(echo "${spanEmbed[$j]}"   | jq ".url"   | rmQuotes)
      title=$(echo "${spanEmbed[$j]}" | jq ".title" | rmQuotes)
      if [[ "$title" == "null" ]]
      then
        title="click here"
      fi
      currText="[$title]($url)"

    fi

    # Embed
    if [[ "${spanCitation[$j]}" != "null" ]]
    then

      url=$(echo "${spanCitation[$j]}"   | jq ".target.url" | rmQuotes)
      index=$(echo "${spanCitation[$j]}" | jq ".index"      | rmQuotes)
      title=$(echo "${spanCitation[$j]}" | jq ".title"      | rmQuotes)

      currText="[[$index]]($url)"

      footerText[$index-1]="$title"
      footerLink[$index-1]="$url"
    fi

    currP="${currP}${currText}"
  done

  # Add empty line if section changed from quote to plain
  if [[ "$sectionPrefix" == "" && "$prevSectionPrefix" != "" ]]
  then
    echo "" >> $fileMD
  fi

  if [[ "${sectionType[$i]}" == "horizontal-rule" ]]
  then
    echo "---" >> $fileMD
    echo ""  >> $fileMD
  else
    echo "${sectionPrefix}${sectionBullet}${currP}" >> $fileMD
    echo "${sectionPrefix}" >> $fileMD
  fi

done

if [[ ${#footerText[@]} -gt 0  ]]
then
  echo "" >> $fileMD
  echo "**Footnotes**" >> $fileMD
  echo "" >> $fileMD
  for ((i=0; i<${#footerText[@]}; i++));
  do
    num=$(( i + 1 ))
    text="[$num] ${footerText[$i]}"
    link="${footerLink[$i]}"
    echo "[$text]($link)" >> $fileMD
  done
fi
