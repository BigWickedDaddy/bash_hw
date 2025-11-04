#!/bin/bash

GREEN='\033[32m'
RED='\033[31m'
RESET='\033[0m'

total_games=0
guessed=0
history=()

while true; do
    secret=$((RANDOM % 10))
    
    ((total_games++))
    
    while true; do
        echo -n "Step: $total_games"
        echo ""
        echo -n "Please enter number from 0 to 9 (q - quit): "
        read user_input
        
        if [ "$user_input" = "q" ]; then
            exit 0
        fi
        
        if ! [[ "$user_input" =~ ^[0-9]$ ]]; then
            echo "Error: please enter single digit from 0 to 9 (or q to quit)"
            continue
        fi
        
        break
    done
    
    if [ "$user_input" -eq "$secret" ]; then
        echo "Hit! My number: $secret"
        ((guessed++))
        history+=("$secret|1")
    else
        echo "Miss! My number: $secret"
        history+=("$secret|0")
    fi
    
    not_guessed=$((total_games - guessed))
    guessed_percent=$((guessed * 100 / total_games))
    not_guessed_percent=$((not_guessed * 100 / total_games))
    
    echo "Hit: ${guessed_percent}% Miss: ${not_guessed_percent}%"
    
    echo -n "Numbers: "
    start=$((${#history[@]} > 10 ? ${#history[@]} - 10 : 0))
    for ((i=$start; i<${#history[@]}; i++)); do
        IFS='|' read -r num status <<< "${history[$i]}"
        if [ "$status" = "1" ]; then
            echo -ne "${GREEN}${num}${RESET} "
        else
            echo -ne "${RED}${num}${RESET} "
        fi
    done
    echo ""
    echo ""
done
