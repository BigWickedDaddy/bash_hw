#!/bin/bash

generate_secret() {
    local digits=()
    while [ ${#digits[@]} -lt 4 ]; do
        digit=$((RANDOM % 10))
        if [ ${#digits[@]} -eq 0 ] && [ $digit -eq 0 ]; then
            continue
        fi
        if [[ ! " ${digits[@]} " =~ " ${digit} " ]]; then
            digits+=($digit)
        fi
    done
    echo "${digits[@]}" | tr -d ' '
}

check_unique_digits() {
    local num=$1
    local len=${#num}
    for ((i=0; i<len; i++)); do
        digit=${num:i:1}
        for ((j=i+1; j<len; j++)); do
            if [ "${num:j:1}" = "$digit" ]; then
                return 1
            fi
        done
    done
    return 0
}

count_bulls_and_cows() {
    local secret=$1
    local guess=$2
    local bulls=0
    local cows=0
    
    for ((i=0; i<4; i++)); do
        guess_digit=${guess:i:1}
        secret_digit=${secret:i:1}
        
        # Проверка на быка
        if [ "$guess_digit" = "$secret_digit" ]; then
            ((bulls++))
        else
            # Проверка на корову
            for ((j=0; j<4; j++)); do
                if [ "$guess_digit" = "${secret:j:1}" ]; then
                    ((cows++))
                    break
                fi
            done
        fi
    done
    
    echo "$bulls $cows"
}

sigint_handler() {
    echo ""
    echo "Для завершения игры введите 'q' или 'Q'"
}

trap sigint_handler SIGINT

secret=$(generate_secret)

history=()
step=0

echo "=== Игра: Быки и Коровы ==="
echo "Угадайте 4-х значное число с неповторяющимися цифрами"
echo "Введите 'q' или 'Q' для выхода"
echo ""

while true; do
    if [ ${#history[@]} -gt 0 ]; then
        echo "--- История ходов ---"
        for entry in "${history[@]}"; do
            echo "$entry"
        done
        echo "---------------------"
        echo ""
    fi
    
    echo -n "Шаг $((step + 1)). Введите 4-х значное число (q/Q - выход): "
    read user_input
    
    if [ "$user_input" = "q" ] || [ "$user_input" = "Q" ]; then
        echo "Выход из игры."
        exit 1
    fi
    
    if ! [[ "$user_input" =~ ^[0-9]{4}$ ]]; then
        echo "Ошибка: введите 4-х значное число с неповторяющимися цифрами"
        echo ""
        continue
    fi
    
    if [ "${user_input:0:1}" = "0" ]; then
        echo "Ошибка: первая цифра не может быть 0"
        echo ""
        continue
    fi
    
    if ! check_unique_digits "$user_input"; then
        echo "Ошибка: цифры должны быть неповторяющимися"
        echo ""
        continue
    fi
    
    ((step++))
    
    result=$(count_bulls_and_cows "$secret" "$user_input")
    bulls=$(echo $result | cut -d' ' -f1)
    cows=$(echo $result | cut -d' ' -f2)
    
    history+=("Шаг $step: $user_input - Быки: $bulls, Коровы: $cows")
    
    echo "Быки: $bulls, Коровы: $cows"
    echo ""
    
    if [ $bulls -eq 4 ]; then
        echo "========================================="
        echo "Поздравляем! Вы угадали число: $secret"
        echo "Количество попыток: $step"
        echo "========================================="
        exit 0
    fi
done
