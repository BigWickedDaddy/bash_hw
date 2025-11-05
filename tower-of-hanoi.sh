#!/bin/bash

MAX=8

A=(8 7 6 5 4 3 2 1)
B=()
C=()

move=1
goal="8 7 6 5 4 3 2 1"

trap 'echo; echo "Завершить работу можно, введя q или Q.";' INT

print_board() {
  echo
  for ((r=MAX-1; r>=0; r--)); do
    local la=${#A[@]} lb=${#B[@]} lc=${#C[@]}
    local va=" " vb=" " vc=" "
    (( r < la )) && va=${A[r]}
    (( r < lb )) && vb=${B[r]}
    (( r < lc )) && vc=${C[r]}
    printf "|%-2s| |%-2s| |%-2s|\n" "$va" "$vb" "$vc"
  done
  echo "+-+-+ +-+-+ +-+-+"
  echo "  A      B     C"
  echo
  printf "Ход № %d (откуда, куда): " "$move"
}


top_of() {
  case $1 in
    a) (( ${#A[@]} )) && echo "${A[$((${#A[@]}-1))]}" || echo 99 ;;
    b) (( ${#B[@]} )) && echo "${B[$((${#B[@]}-1))]}" || echo 99 ;;
    c) (( ${#C[@]} )) && echo "${C[$((${#C[@]}-1))]}" || echo 99 ;;
  esac
}

POPVAL=
pop_from() {
  local len idx
  case $1 in
    a) len=${#A[@]}; ((len==0)) && return 1; idx=$((len-1)); POPVAL=${A[$idx]}; unset A[$idx]; A=("${A[@]}");;
    b) len=${#B[@]}; ((len==0)) && return 1; idx=$((len-1)); POPVAL=${B[$idx]}; unset B[$idx]; B=("${B[@]}");;
    c) len=${#C[@]}; ((len==0)) && return 1; idx=$((len-1)); POPVAL=${C[$idx]}; unset C[$idx]; C=("${C[@]}");;
  esac
  return 0
}

push_to() {
  case $1 in
    a) A+=("$2");;
    b) B+=("$2");;
    c) C+=("$2");;
  esac
}

arr_to_string() {
  case $1 in
    a) echo "${A[*]}";;
    b) echo "${B[*]}";;
    c) echo "${C[*]}";;
  esac
}

while true; do
  print_board
  IFS= read -r line || exit 1
  norm=$(printf "%s" "$line" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

  if [[ "$norm" == "q" ]]; then
    echo "Выход по запросу пользователя."
    exit 1
  fi

  if [[ "$norm" =~ ^([abc])([abc])$ ]]; then
    from=${BASH_REMATCH[1]}
    to=${BASH_REMATCH[2]}
    if [[ "$from" == "$to" ]]; then
      echo "Нужно указать разные стеки."
      continue
    fi

    if ! pop_from "$from"; then
      echo "Стек '${from^^}' пуст."
      continue
    fi

    top_to=$(top_of "$to")
    if (( POPVAL > top_to )); then
      echo "Такое перемещение запрещено!"
      push_to "$from" "$POPVAL"   # откатываем
      continue
    fi

    push_to "$to" "$POPVAL"
    ((move++))

    if [[ "$(arr_to_string b)" == "$goal" || "$(arr_to_string c)" == "$goal" ]]; then
      print_board
      echo "Победа!"
      exit 0
    fi
  else
    echo "Ошибка ввода. Примеры: A C, ac, bA, или q."
  fi
done
