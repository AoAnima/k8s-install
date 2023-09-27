#/bin/bash

function лог(){
 echo -e "\033[36m $1 \033[0m"
}

function инфо(){
    echo -e "\033[32m $1 \033[0m"
}



function ошибка(){    
    echo -e " \e[0;37;41m  [> $( caller )] ОШИБКА: \033[0m \e[1;31m  $1 \033[0m"
    # echo "[$( caller )] $*" >&2
    # echo "BASH_SOURCE: ${BASH_SOURCE[*]}"
    # echo "BASH_LINENO: ${BASH_LINENO[*]}"
    # echo "FUNCNAME: ${FUNCNAME[*]}"
}

function палитра (){
    for x in {0..8}; do 
        for i in {30..37}; do 
            for a in {40..47}; do 
                echo -ne "\e[$x;$i;$a""m\\\e[$x;$i;$a""m\e[0;37;40m "
            done
            echo
        done
    done
    echo ""
}

function проверить() {
    лог "Проверка: $1"
    if ! app="$(type -p "$1")" || [[ -z $app ]]; then
        инфо "Не найден $1"
        return 1
    else
    инфо "Найден $1"
        return 0
    fi
}

# \033[30m - чёрный
# \033[31m - красный
# \033[32m - зелёный
# \033[33m - желтый
# \033[34m - синий
# \033[35m - фиолетовый
# \033[36m - голубой
# \033[37m - серый

# \033[40m - чёрный
# \033[41m - красный
# \033[42m - зелёный
# \033[43m - желтый
# \033[44m - синий
# \033[45m - фиолетовый
# \033[46m - голубой
# \033[47m - серый
# \033[0m - сбросить все до значений по умолчанию
# Regular Colors

# | Value    | Color  |
# | -------- | ------ |
# | \e[0;30m | Black  |
# | \e[0;31m | Red    |
# | \e[0;32m | Green  |
# | \e[0;33m | Yellow |
# | \e[0;34m | Blue   |
# | \e[0;35m | Purple |
# | \e[0;36m | Cyan   |
# | \e[0;37m | White  |

# # Bold

# | Value    | Color    |
# | -------- | -------- |
# | \e[1;30m | Black    |
# | \e[1;31m | Red      |
# | \e[1;32m | Green    |
# | \e[1;33m | Yellow   |
# | \e[1;34m | Blue     |
# | \e[1;35m | Purple   |
# | \e[1;36m | Cyan     |
# | \e[1;37m | White    |
# | \e[1m    | No Color |

# # Underline

# | Value    | Color    |
# | -------- | -------- |
# | \e[4;30m | Black    |
# | \e[4;31m | Red      |
# | \e[4;32m | Green    |
# | \e[4;33m | Yellow   |
# | \e[4;34m | Blue     |
# | \e[4;35m | Purple   |
# | \e[4;36m | Cyan     |
# | \e[4;37m | White    |
# | \e[4m    | No Color |

# # Background

# | Value  | Color  |
# | ------ | ------ |
# | \e[40m | Black  |
# | \e[41m | Red    |
# | \e[42m | Green  |
# | \e[43m | Yellow |
# | \e[44m | Blue   |
# | \e[45m | Purple |
# | \e[46m | Cyan   |
# | \e[47m | White  |

# # Expand Background Horizontally

# | Value |   Color  |
# | ----- | -------- |
# | \e[K  | No Color |

# # High Intensty

# | Value    | Color  |
# | -------- | ------ |
# | \e[0;90m | Black  |
# | \e[0;91m | Red    |
# | \e[0;92m | Green  |
# | \e[0;93m | Yellow |
# | \e[0;94m | Blue   |
# | \e[0;95m | Purple |
# | \e[0;96m | Cyan   |
# | \e[0;97m | White  |

# # Bold High Intensty

# | Value    | Color  |
# | -------- | ------ |
# | \e[1;90m | Black  |
# | \e[1;91m | Red    |
# | \e[1;92m | Green  |
# | \e[1;93m | Yellow |
# | \e[1;94m | Blue   |
# | \e[1;95m | Purple |
# | \e[1;96m | Cyan   |
# | \e[1;97m | White  |

# # High Intensty backgrounds

# | Value     | Color  |
# | --------- | ------ |
# | \e[0;100m | Black  |
# | \e[0;101m | Red    |
# | \e[0;102m | Green  |
# | \e[0;103m | Yellow |
# | \e[0;104m | Blue   |
# | \e[0;105m | Purple |
# | \e[0;106m | Cyan   |
# | \e[0;107m | White  |

# # Reset

# | Value | Color  |
# | ----- | ------ |
# | \e[0m | Reset  |
