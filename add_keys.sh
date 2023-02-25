#!/bin/bash

# Настройки
conf_path="/opt/signer/conf"          # Часть пути до конфигов
conf_file="server_keystore.yml"       # Название файла конфигурации
backup_dir="backup"                   # Название директории для копий конфигов
cut_lenght="-60"                      # Количество символов значения сертификата, которое будет сохранено в лог-файле
log_path="./add_keys.log"             # Путь сохранения лог-файла
yes="y"                               # Вариант положительного ответа пользователя
no="n"                                # Вариант отрицательного ответа пользователя

parse_conf_list() {
        if [ $# -eq 2 ]; then
                build_range $1 $2 $3 $4 >/dev/null
                if [ -n "$no_such" ]; then
                        retry
                else
                        destination="$(build_range $1 $2 $3 $4)"
                fi
        elif [ $# -eq 4 ]; then
                build_range $1 $2 $3 $4 >/dev/null
                no_such_tmp=$no_such
                build_range2 $1 $2 $3 $4 >/dev/null
                no_such="$no_such_tmp$no_such"
                if [ -n "$no_such" ]; then
                        retry
                else
                        destination="$(build_range $1 $2 $3 $4) $(build_range2 $1 $2 $3 $4)"
                fi
        elif [ $# -eq 3 ]; then
                build_range $1 $2 $3 $4 >/dev/null
                no_such_tmp=$no_such
                build_range_other $1 $2 $3 $4 >/dev/null
                no_such="$no_such_tmp$no_such"
                if [ -n "$no_such" ]; then
                        retry
                else
                        destination="$(build_range $1 $2 $3 $4) $(build_range_other $1 $2 $3 $4)"
                fi
        elif [ $# -eq 1 ]; then
                build_single $1 >/dev/null
                if [ -n "$no_such" ]; then
                        retry
                else
                        destination="$(build_single $1)"
                fi
        else
                echo "Некорректно передан диапазон конфигов. Повторите попытку"
                continue
        fi
}

build_range() {
        no_such=""
        for ((i = $1; i <= $2; i++)); do
                file_exist $i
        done
}

build_range2() {
        no_such=""
        for ((i = $3; i <= $4; i++)); do
                file_exist $i
        done
}

build_range_other() {
        no_such=""
        local IFS=$' \t\n,'
        for i in $3; do
                file_exist $i
        done
}

build_single() {
        local IFS=$' \t\n,'
        no_such=""
        for i in $1; do
                file_exist $i
        done
}

file_exist() {
        if [ -f $conf_path/$i/$conf_file ]; then
                echo "$conf_path/$i/"
        else
                no_such="$no_such $(echo "$conf_path/$i/$conf_file")"
        fi
}

retry() {
        echo
        echo "Требуется повторить попытку, так как обнаружены несуществующие файлы:"
        echo "$(bad_paths)"
        echo
        continue
}

bad_paths() {
        for nsf in $no_such; do
                echo "  $nsf"
        done
}

check() {
        echo
        echo "WARNING! Новые значения будут добавлены в следующие файлы:"
        for path in $destination; do
                echo "  $path$conf_file"
        done
}

# Вывести примеры
echo
echo "Примеры:"
echo "  #1 Чтобы указать интервал от 1 до 5, введите: 1 5"
echo "  #2 Чтобы указать два интервала, введите: 1 5 7 9"
echo "  #3 Чтобы указать интервал от 1 до 5 + отдельно 7 и 9, введите: 1 5 7,9"
echo "  #4 Чтобы указать только отдельные номера 1, 3 и 7, введите: 1,3,7"
echo "  #5 Чтобы указать только один номер, введите: 1"

# Построить пути к конфигам
while true; do
        echo
        read -p "Укажите номера конфигов: " min max other other2
        parse_conf_list $min $max $other $other2
        check
        echo
        read -p "Продолжить (y/n)? " answer
        if [ $yes = $answer ]; then
                break
        elif [ $no = $answer ]; then
                continue
        else
                echo "Ошибка ввода. Пожалуйста, повторите попытку"
                continue
        fi
done

# Выполнить бэкап исходников
while true; do
        echo
        read -p "Выполнить бэкап исходных файлов (у/n)?: " backup
        if [ $yes = $backup ]; then
                for path in $destination; do
                        if [ ! -d $path/$backup_dir ]; then
                                mkdir -p $path/$backup_dir
                        fi
                        cp -v $path$conf_file $path$backup_dir/${conf_file}_copy_$(date "+%FT%H:%M:%S")
                done
                break
        elif [ $no = $backup ]; then
                break
        else
                echo "Ошибка ввода. Пожалуйста, повторите попытку"
                continue
        fi
done

# Определить новые значения
echo
echo
echo "Введите новые значения:"
echo "-------------------------------------------------------------------------------"

# comment for server_keystore.yml
read -p "Введите комментарий без #: " comment

# device_name
while true; do
        echo
        echo "Следующая строка имеет стандартное значение: - device_name: \"FileSystem\""
        read -p "Оставить без изменений (y/n)? " answer
        if [ $yes = $answer ]; then
                device_name="FileSystem"
                break
        elif [ $no = $answer ]; then
                read -p "Введите значение для device_name: " device_name
                break
        else
                echo "Ошибка ввода. Пожалуйста, повторите попытку"
                continue
        fi
done

# device_version
while true; do
        echo
        echo "Следующая строка имеет стандартное значение: device_version: \"v1\""
        read -p "Оставить без изменений (y/n)? " answer
        if [ $yes = $answer ]; then
                device_version="v1"
                break
        elif [ $no = $answer ]; then
                read -p "Введите значение для device_version: " device_version
                break
        else
                echo "Ошибка ввода. Пожалуйста, повторите попытку"
                continue
        fi
done

# instance_name
while true; do
        echo
        echo "Следующая строка имеет стандартное значение: instance_name: \"JCSP\""
        read -p "Оставить без изменений (y/n)? " answer
        if [ $yes = $answer ]; then
                instance_name="JCSP"
                break
        elif [ $no = $answer ]; then
                read -p "Введите значение для instance_name: " instance_name
                break
        else
                echo "Ошибка ввода. Пожалуйста, повторите попытку"
                continue
        fi
done

# key_id
echo
read -p "Введите значение для key_id: " key_id

# algorithm
while true; do
        echo
        echo "Следующая строка имеет стандартное значение: algorithm: \"GOST3410EL\""
        read -p "Оставить без изменений (y/n)? " answer
        if [ $yes = $answer ]; then
                algorithm="GOST3410EL"
                break
        elif [ $no = $answer ]; then
                read -p "Введите значение для algorithm: " algorithm
                break
        else
                echo "Ошибка ввода. Пожалуйста, повторите попытку"
                continue
        fi
done

# certificate
echo
read -p "Введите значение для certificate: " certificate

# Добавить полученные значения в файлы
for path in $destination; do
        echo "# $comment" >>$path$conf_file
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение # $comment добавлено"
        echo "- device_name: \"$device_name\"" >>$path$conf_file
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение device_name: \"$device_name\" добавлено"
        echo "  device_version: \"$device_version\"" >>$path$conf_file
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение device_version: \"$device_version\" добавлено"
        echo "  instance_name: \"$instance_name\"" >>$path$conf_file
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение instance_name: \"$instance_name\" добавлено"
        echo "  key_id: \"$key_id\"" >>$path$conf_file
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение key_id: \"$key_id\" добавлено"
        echo "  algorithm: \"$algorithm\"" >>$path$conf_file
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение algorithm: \"$algorithm\" добавлено"
        echo "  certificate: \"$certificate\"" >>$path$conf_file
        cut_cert=$(echo \"$certificate\" | cut -b $cut_lenght)
        echo "$(date "+%FT%H:%M:%S") $path$conf_file: значение certificate: $(echo $cut_cert)... добавлено"
done >>$log_path

echo
echo "-------------------------------------------------------------------------------"
echo "Результат выполнения сохранен в $log_path"
