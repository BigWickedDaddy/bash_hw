#!/bin/bash

declare -a stack_A=(8 7 6 5 4 3 2 1)
declare -a stack_B=()
declare -a stack_C=()

move_count=0

sigint_handler() {
    echo ""
    echo "Для завершения игры введите 'q' или 'Q'"
}

trap sigint_handler SIGINT

display_stacks() {
    local max_height=${#stack_A[@]}
    if [ ${#stack_B[@]} -gt $max_height ]; then
        max_height=${#stack_B[@]}
    fi
    if [ ${#stack_C[@]} -gt $max_height ]; then
        max_height=${#stack_C[@]}
    fi
    
    for ((i=max_height-1; i>=0; i--)); do
        if [ $i -lt ${#stack_A[@]} ]; then
            printf "|%d|" "${stack_A[$i]}"
        else
            printf "| |"
        fi
        
        printf "\t"
        
        if [ $i -lt ${#stack_B[@]} ]; then
            printf "|%d|" "${stack_B[$i]}"
        else
            printf "| |"
        fi
        
        printf "\t"
        
        if [ $i -lt ${#stack_C[@]} ]; then
            printf "|%d|" "${stack_C[$i]}"
        else
            printf "| |"
        fi
        
        echo ""
    done
    
    echo "+-+	+-+	+-+"
    echo " A 	 B 	 C "
}

peek_stack() {
    local stack_name=$1
    local -n stack="stack_$stack_name"
    
    if [ ${#stack[@]} -eq 0 ]; then
        echo -1
    else
        echo "${stack[-1]}"
    fi
}

pop_stack() {
    local stack_name=$1
    local -n stack="stack_$stack_name"
    
    if [ ${#stack[@]} -eq 0 ]; then
        return 1
    fi
    
    local value="${stack[-1]}"
    unset 'stack[-1]'
    echo "$value"
    return 0
}

push_stack() {
    local stack_name=$1
    local value=$2
    local -n stack="stack_$stack_name"
    
    stack+=("$value")
}

check_win() {
    local win_sequence=(8 7 6 5 4 3 2 1)
    
    if [ ${#stack_B[@]} -eq 8 ]; then
        local match=1
        for ((i=0; i<8; i++)); do
            if [ "${stack_B[$i]}" -ne "${win_sequence[$i]}" ]; then
                match=0
                break
            fi
        done
        if [ $match -eq 1 ]; then
            return 0
        fi
    fi
    
    if [ ${#stack_C[@]} -eq 8 ]; then
        local match=1
        for ((i=0; i<8; i++)); do
            if [ "${stack_C[$i]}" -ne "${win_sequence[$i]}" ]; then
                match=0
                break
            fi
        done
        if [ $match -eq 1 ]; then
            return 0
        fi
    fi
    
    return 1
}

validate_stack_name() {
    local name=$1
    name=$(echo "$name" | tr '[:lower:]' '[:upper:]')
    
    if [ "$name" = "A" ] || [ "$name" = "B" ] || [ "$name" = "C" ]; then
        echo "$name"
        return 0
    fi
    
    return 1
}

echo "=== Ханойская башня (Tower of Hanoi) ==="
echo ""

while true; do
    ((move_count++))
    
    echo "Ход № $move_count"
    echo ""
    display_stacks
    echo ""
    
    echo -n "Ход № $move_count (откуда, куда): "
    read user_input
    
    user_input_upper=$(echo "$user_input" | tr '[:lower:]' '[:upper:]')
    if [ "$user_input_upper" = "Q" ]; then
        echo "Выход из игры."
        exit 1
    fi
    
    parsed_input=$(echo "$user_input" | tr -d ' ,;:')
    
    if [ ${#parsed_input} -ne 2 ]; then
        echo "Такое перемещение запрещено!"
        echo ""
        ((move_count--))
        continue
    fi
    
    from_stack="${parsed_input:0:1}"
    to_stack="${parsed_input:1:1}"
    
    from_stack=$(echo "$from_stack" | tr '[:lower:]' '[:upper:]')
    to_stack=$(echo "$to_stack" | tr '[:lower:]' '[:upper:]')
    
    if ! validate_stack_name "$from_stack" > /dev/null 2>&1; then
        echo "Такое перемещение запрещено!"
        echo ""
        ((move_count--))
        continue
    fi
    
    if ! validate_stack_name "$to_stack" > /dev/null 2>&1; then
        echo "Такое перемещение запрещено!"
        echo ""
        ((move_count--))
        continue
    fi
    
    if [ "$from_stack" = "$to_stack" ]; then
        echo "Такое перемещение запрещено!"
        echo ""
        ((move_count--))
        continue
    fi
    
    from_top=$(peek_stack "$from_stack")
    to_top=$(peek_stack "$to_stack")
    
    if [ $from_top -eq -1 ]; then
        echo "Такое перемещение запрещено!"
        echo ""
        ((move_count--))
        continue
    fi
    
    if [ $to_top -ne -1 ] && [ $from_top -gt $to_top ]; then
        echo "Такое перемещение запрещено!"
        echo ""
        ((move_count--))
        continue
    fi
    
    value=$(pop_stack "$from_stack")
    push_stack "$to_stack" "$value"
    
    echo ""
    
    if check_win; then
        echo "Поздравляем! Вы решили головоломку за $move_count ходов!"
        echo ""
        display_stacks
        exit 0
    fi
done
