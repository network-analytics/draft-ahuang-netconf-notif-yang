#!/bin/bash --posix

# This script may need some adjustments to work on a given system.
# For instance, the utility `gsed` may need to be installed.
# Also, please be advised that `bash` (not `sh`) must be used.

# Copyright (c) 2019 IETF Trust, Kent Watsen, and Erik Auerswald.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials
#     provided with the distribution.
#
#   * Neither the name of Internet Society, IETF or IETF Trust, nor
#     the names of specific contributors, may be used to endorse or
#     promote products derived from this software without specific
#     prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

print_usage() {
  printf "\n"
  printf "Folds or unfolds the input text file according to RFC 8792.\n"
  printf "\n"
  printf "Usage: rfcfold [-h] [-d] [-q] [-s <strategy>] [-c <col>]"
  printf " [-r] -i <infile> -o <outfile>\n"
  printf "\n"
  printf "  -s: strategy to use, '1' or '2' (default: try 1,"
  printf " else 2)\n"
  printf "  -c: column to fold on (default: 69)\n"
  printf "  -r: reverses the operation\n"
  printf "  -i: the input filename\n"
  printf "  -o: the output filename\n"
  printf "  -d: show debug messages (unless -q is given)\n"
  printf "  -q: quiet (suppress error and debug messages)\n"
  printf "  -h: show this message\n"
  printf "\n"
  printf "Exit status code: 1 on error, 0 on success, 255 on no-op."
  printf "\n\n"
}

# global vars, do not edit
strategy=0 # auto
debug=0
quiet=0
reversed=0
infile=""
outfile=""
maxcol=69  # default, may be overridden by param
col_gvn=0  # maxcol overridden?
hdr_txt_1="NOTE: '\\' line wrapping per RFC 8792"
hdr_txt_2="NOTE: '\\\\' line wrapping per RFC 8792"
equal_chars="======================================================="
space_chars="                                                       "
temp_dir=""
prog_name='rfcfold'

# functions for diagnostic messages
prog_msg() {
  if [[ "$quiet" -eq 0 ]]; then
    format_string="${prog_name}: $1: %s\n"
    shift
    printf -- "$format_string" "$*" >&2
  fi
}

err() {
  prog_msg 'Error' "$@"
}

warn() {
  prog_msg 'Warning' "$@"
}

dbg() {
  if [[ "$debug" -eq 1 ]]; then
    prog_msg 'Debug' "$@"
  fi
}

# determine name of [g]sed binary
type gsed > /dev/null 2>&1 && SED=gsed || SED=sed

# warn if a non-GNU sed utility is used
"$SED" --version < /dev/null 2> /dev/null | grep -q GNU || \
warn 'not using GNU `sed` (likely cause if an error occurs).'

cleanup() {
  rm -rf "$temp_dir"
}
trap 'cleanup' EXIT

fold_it_1() {
  # ensure input file doesn't contain the fold-sequence already
  if [[ -n "$("$SED" -n '/\\$/p' "$infile")" ]]; then
    err "infile '$infile' has a line ending with a '\\' character."\
        "This script cannot fold this file using the '\\' strategy"\
        "without there being false positives produced in the"\
        "unfolding."
    return 1
  fi

  # where to fold
  foldcol=$(expr "$maxcol" - 1) # for the inserted '\' char

  # ensure input file doesn't contain whitespace on the fold column
  grep -q "^\(.\{$foldcol\}\)\{1,\} " "$infile"
  if [[ $? -eq 0 ]]; then
    err "infile '$infile' has a space character occurring on the"\
        "folding column. This file cannot be folded using the"\
        "'\\' strategy."
    return 1
  fi

  # center header text
  length=$(expr ${#hdr_txt_1} + 2)
  left_sp=$(expr \( "$maxcol" - "$length" \) / 2)
  right_sp=$(expr "$maxcol" - "$length" - "$left_sp")
  header=$(printf "%.*s %s %.*s" "$left_sp" "$equal_chars"\
                   "$hdr_txt_1" "$right_sp" "$equal_chars")

  # generate outfile
  echo "$header" > "$outfile"
  echo "" >> "$outfile"
  "$SED" 's/\(.\{'"$foldcol"'\}\)\(..\)/\1\\\n\2/;t M;b;:M;P;D;'\
    < "$infile" >> "$outfile" 2> /dev/null
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  return 0
}

fold_it_2() {
  # where to fold
  foldcol=$(expr "$maxcol" - 1) # for the inserted '\' char

  # ensure input file doesn't contain the fold-sequence already
  if [[ -n "$("$SED" -n '/\\$/{N;s/\\\n[ ]*\\/&/p;D}' "$infile")" ]]
  then
    err "infile '$infile' has a line ending with a '\\' character"\
        "followed by a '\\' character as the first non-space"\
        "character on the next line.  This script cannot fold"\
        "this file using '\\\\' strategy without there being"\
        "false positives produced in the unfolding."
    return 1
  fi

  # center header text
  length=$(expr ${#hdr_txt_2} + 2)
  left_sp=$(expr \( "$maxcol" - "$length" \) / 2)
  right_sp=$(expr "$maxcol" - "$length" - "$left_sp")
  header=$(printf "%.*s %s %.*s" "$left_sp" "$equal_chars"\
                   "$hdr_txt_2" "$right_sp" "$equal_chars")

  # generate outfile
  echo "$header" > "$outfile"
  echo "" >> "$outfile"
  "$SED" 's/\(.\{'"$foldcol"'\}\)\(..\)/\1\\\n\\\2/;t M;b;:M;P;D;'\
    < "$infile" >> "$outfile" 2> /dev/null
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  return 0
}

fold_it() {
  # ensure input file doesn't contain a TAB
  grep -q $'\t' "$infile"
  if [[ $? -eq 0 ]]; then
    err "infile '$infile' contains a TAB character, which is not"\
        "allowed."
    return 1
  fi

  # folding of input containing ASCII control or non-ASCII characters
  # may result in a wrong folding column and is not supported
  if type gawk > /dev/null 2>&1; then
    env LC_ALL=C gawk '/[\000-\014\016-\037\177]/{exit 1}' "$infile"\
    || warn "infile '$infile' contains ASCII control characters"\
            "(unsupported)."
    env LC_ALL=C gawk '/[^\000-\177]/{exit 1}' "$infile"\
    || warn "infile '$infile' contains non-ASCII characters"\
            "(unsupported)."
  else
    dbg "no GNU Awk, skipping checks for special characters."
  fi

  # check if file needs folding
  testcol=$(expr "$maxcol" + 1)
  grep -q ".\{$testcol\}" "$infile"
  if [[ $? -ne 0 ]]; then
    dbg "nothing to do; copying infile to outfile."
    cp "$infile" "$outfile"
    return 255
  fi

  if [[ "$strategy" -eq 1 ]]; then
    fold_it_1
    return $?
  fi
  if [[ "$strategy" -eq 2 ]]; then
    fold_it_2
    return $?
  fi
  quiet_sav="$quiet"
  quiet=1
  fold_it_1
  result=$?
  quiet="$quiet_sav"
  if [[ "$result" -ne 0 ]]; then
    dbg "Folding strategy '1' didn't succeed, trying strategy '2'..."
    fold_it_2
    return $?
  fi
  return 0
}

unfold_it_1() {
  temp_dir=$(mktemp -d)

  # output all but the first two lines (the header) to wip file
  awk "NR>2" "$infile" > "$temp_dir/wip"

  # unfold wip file
  "$SED" '{H;$!d};x;s/^\n//;s/\\\n *//g' "$temp_dir/wip" > "$outfile"

  return 0
}

unfold_it_2() {
  temp_dir=$(mktemp -d)

  # output all but the first two lines (the header) to wip file
  awk "NR>2" "$infile" > "$temp_dir/wip"

  # unfold wip file
  "$SED" '{H;$!d};x;s/^\n//;s/\\\n *\\//g' "$temp_dir/wip"\
    > "$outfile"

  return 0
}

unfold_it() {
  # check if file needs unfolding
  line=$(head -n 1 "$infile")
  line2=$("$SED" -n '2p' "$infile")
  result=$(echo "$line" | fgrep "$hdr_txt_1")
  if [[ $? -eq 0 ]]; then
    if [[ -n "$line2" ]]; then
      err "the second line in '$infile' is not empty."
      return 1
    fi
    unfold_it_1
    return $?
  fi
  result=$(echo "$line" | fgrep "$hdr_txt_2")
  if [[ $? -eq 0 ]]; then
    if [[ -n "$line2" ]]; then
      err "the second line in '$infile' is not empty."
      return 1
    fi
    unfold_it_2
    return $?
  fi
  dbg "nothing to do; copying infile to outfile."
  cp "$infile" "$outfile"
  return 255
}

process_input() {
  while [[ "$1" != "" ]]; do
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
      print_usage
      exit 0
    elif [[ "$1" == "-d" ]]; then
      debug=1
    elif [[ "$1" == "-q" ]]; then
      quiet=1
    elif [[ "$1" == "-s" ]]; then
      if [[ "$#" -eq "1" ]]; then
        err "option '-s' needs an argument (use -h for help)."
        exit 1
      fi
      strategy="$2"
      shift
    elif [[ "$1" == "-c" ]]; then
      if [[ "$#" -eq "1" ]]; then
        err "option '-c' needs an argument (use -h for help)."
        exit 1
      fi
      col_gvn=1
      maxcol="$2"
      shift
    elif [[ "$1" == "-r" ]]; then
      reversed=1
    elif [[ "$1" == "-i" ]]; then
      if [[ "$#" -eq "1" ]]; then
        err "option '-i' needs an argument (use -h for help)."
        exit 1
      fi
      infile="$2"
      shift
    elif [[ "$1" == "-o" ]]; then
      if [[ "$#" -eq "1" ]]; then
        err "option '-o' needs an argument (use -h for help)."
        exit 1
      fi
      outfile="$2"
      shift
    else
      warn "ignoring unknown option '$1'."
    fi
    shift
  done

  if [[ -z "$infile" ]]; then
    err "infile parameter missing (use -h for help)."
    exit 1
  fi

  if [[ -z "$outfile" ]]; then
    err "outfile parameter missing (use -h for help)."
    exit 1
  fi

  if [[ ! -f "$infile" ]]; then
    err "specified file '$infile' does not exist."
    exit 1
  fi

  if [[ "$col_gvn" -eq 1 ]] && [[ "$reversed" -eq 1 ]]; then
    warn "'-c' option ignored when unfolding (option '-r')."
  fi

  if [[ "$strategy" -eq 0 ]] || [[ "$strategy" -eq 2 ]]; then
    min_supported=$(expr ${#hdr_txt_2} + 8)
  else
    min_supported=$(expr ${#hdr_txt_1} + 8)
  fi
  if [[ "$maxcol" -lt "$min_supported" ]]; then
    err "the folding column cannot be less than $min_supported."
    exit 1
  fi

  # this is only because the code otherwise runs out of equal_chars
  max_supported=$(expr ${#equal_chars} + 1 + ${#hdr_txt_1} + 1\
       + ${#equal_chars})
  if [[ "$maxcol" -gt "$max_supported" ]]; then
    err "the folding column cannot be more than $max_supported."
    exit 1
  fi
}

main() {
  if [[ "$#" -eq "0" ]]; then
     print_usage
     exit 1
  fi

  process_input "$@"

  if [[ "$reversed" -eq 0 ]]; then
    fold_it
    code=$?
  else
    unfold_it
    code=$?
  fi
  exit "$code"
}

main "$@"
