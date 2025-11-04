#!/bin/bash

generate_puzzle() {
    local tiles=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 0)
    
    local i tmp size max rand
    size=${#tiles[@]}
    
    for ((i=size-1; i>0; i--)); do
        max=$(( 32768 / (i+1) * (i+1) ))
        while (( (rand=RANDOM) >= max )); do :; done
        rand=$(( rand % (i+1) ))
        tmp=${tiles[i]}
        tiles[i]=${tiles[rand]}
        tiles[rand]=$tmp
    done
    
    local inversions=0
    local blank_row=0
    
    for ((i=0; i<16; i++)); do
        if [ ${tiles[i]} -eq 0 ]; then
            blank_row=$((3 - i / 4))
            continue
        fi
        for ((j=i+1; j<16; j++)); do
            if [ ${tiles[j]} -ne 0 ] && [ ${tiles[i]} -gt ${tiles[j]} ]; then
                ((inversions++))
            fi
        done
    done

    if [ $(( (inversions % 2) == (blank_row % 2) )) -eq 1 ]; then
        echo "${tiles[@]}"
    else
        # Если не решаемо, меняем две первые не нулевые плитки
        for ((i=0; i<16; i++)); do
            if [ ${tiles[i]} -ne 0 ]; then
                for ((j=i+1; j<16; j++)); do
                    if [ ${tiles[j]} -ne 0 ]; then
                        tmp=${tiles[i]}
                        tiles[i]=${tiles[j]}
                        tiles[j]=$tmp
                        echo "${tiles[@]}"
                        return
                    fi
                done
            fi
        done
    fi
}

draw_board() {
    local board=("$@")
    
    echo "+-------------------+"
    for row in 0 1 2 3; do
        echo -n "|"
        for col in 0 1 2 3; do
            local idx=$((row * 4 + col))
            local val=${board[idx]}
            if [ $val -eq 0 ]; then
                printf " %4s |" ""
            else
                printf " %2d |" $val
            fi
        done
        echo ""
        if [ $row -lt 3 ]; then
            echo "|-------------------|"
        fi
    done
    echo "+-------------------+"
}

find_empty() {
    local board=("$@")
    for ((i=0; i<16; i++)); do
        if [ ${board[i]} -eq 0 ]; then
            echo $i
            return
        fi
    done
}

find_number() {
    local num=$1
    shift
    local board=("$@")
    for ((i=0; i<16; i++)); do
        if [ ${board[i]} -eq $num ]; then
            echo $i
            return
        fi
    done
    echo -1
}

can_move() {
    local num_pos=$1
    local empty_pos=$2
    
    local num_row=$((num_pos / 4))
    local num_col=$((num_pos % 4))
    local empty_row=$((empty_pos / 4))
    local empty_col=$((empty_pos % 4))
    
    if [ $num_row -eq $empty_row ] && [ $((num_col - empty_col)) -eq 1 -o $((num_col - empty_col)) -eq -1 ]; then
        return 0
    fi
    if [ $num_col -eq $empty_col ] && [ $((num_row - empty_row)) -eq 1 -o $((num_row - empty_row)) -eq -1 ]; then
        return 0
    fi
    return 1
}

get_available_moves() {
    local board=("$@")
    local empty_pos=$(find_empty "${board[@]}")
    local empty_row=$((empty_pos / 4))
    local empty_col=$((empty_pos % 4))
    local moves=()
    
    for dr in -1 0 1; do
        for dc in -1 0 1; do
            if [ $((dr * dr + dc * dc)) -ne 1 ]; then
                continue
            fi
            
            local new_row=$((empty_row + dr))
            local new_col=$((empty_col + dc))
            
            if [ $new_row -ge 0 ] && [ $new_row -lt 4 ] && [ $new_col -ge 0 ] && [ $new_col -lt 4 ]; then
                local pos=$((new_row * 4 + new_col))
                moves+=(${board[pos]})
            fi
        done
    done
    
    echo "${moves[@]}"
}

check_win() {
    local board=("$@")
    for ((i=0; i<15; i++)); do
        if [ ${board[i]} -ne $((i + 1)) ]; then
            return 1
        fi
    done
    return 0
}

board=($(generate_puzzle))
moves=0

echo "=== Пятнашки (15 Puzzle) ==="
echo ""

while true; do
    ((moves++))
    
    echo "Ход № $moves"
    echo ""
    draw_board "${board[@]}"
    echo ""
    
    available=($(get_available_moves "${board[@]}"))
    echo -n "Ваш ход (q - выход): "
    read user_input
    
    if [ "$user_input" = "q" ]; then
        echo "Выход из игры."
        exit 0
    fi
    
    if ! [[ "$user_input" =~ ^[0-9]+$ ]]; then
        echo "Неверный ход!"
        echo "Невозможно костяшку $user_input передвинуть на пустую ячейку."
        echo -n "Можно выбрать:"
        for move in "${available[@]}"; do
            echo -n " $move,"
        done
        echo ""
        echo ""
        ((moves--))
        continue
    fi
    
    if [ $user_input -lt 1 ] || [ $user_input -gt 15 ]; then
        echo "Неверный ход!"
        echo "Невозможно костяшку $user_input передвинуть на пустую ячейку."
        echo -n "Можно выбрать:"
        for move in "${available[@]}"; do
            echo -n " $move,"
        done
        echo ""
        echo ""
        ((moves--))
        continue
    fi
    
    num_pos=$(find_number $user_input "${board[@]}")
    empty_pos=$(find_empty "${board[@]}")
    
    if can_move $num_pos $empty_pos; then
        board[$empty_pos]=${board[$num_pos]}
        board[$num_pos]=0
        echo ""
        
        if check_win "${board[@]}"; then
            echo "Вы собрали головоломку за $moves ходов."
            echo ""
            draw_board "${board[@]}"
            exit 0
        fi
    else
        echo "Неверный ход!"
        echo "Невозможно костяшку $user_input передвинуть на пустую ячейку."
        echo -n "Можно выбрать:"
        for move in "${available[@]}"; do
            echo -n " $move,"
        done
        echo ""
        echo ""
        ((moves--))
    fi
done
