#! /usr/bin/env bash

min_length=8
require_uppercase=true
require_lowercase=true
require_numbers=true
require_special_chars=true
special_chars="!@#$%^&*"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
nc='\033[0m'

mostrar_reglas_contrasena() {
    echo -e "${yellow}\nreglas para la contrasena:${nc}"
    echo "- longitud minima: $min_length caracteres"
    [[ "$require_uppercase" = true ]] && echo "- debe contener al menos una letra mayuscula"
    [[ "$require_lowercase" = true ]] && echo "- debe contener al menos una letra minuscula"
    [[ "$require_numbers" = true ]] && echo "- debe contener al menos un numero"
    [[ "$require_special_chars" = true ]] && echo "- debe contener al menos un caracter especial: $special_chars"
    echo ""
}

validar_contrasena() {
    local contrasena=$1
    local valida=true
    
    if [ ${#contrasena} -lt $min_length ]; then
        echo -e "${red}la contrasena es demasiado corta. minimo $min_length caracteres.${nc}"
        valida=false
    fi
    
    if [[ "$require_uppercase" = true && ! "$contrasena" =~ [A-Z] ]]; then
        echo -e "${red}la contrasena debe contener al menos una letra mayuscula.${nc}"
        valida=false
    fi
    
    if [[ "$require_lowercase" = true && ! "$contrasena" =~ [a-z] ]]; then
        echo -e "${red}la contrasena debe contener al menos una letra minuscula.${nc}"
        valida=false
    fi
    
    if [[ "$require_numbers" = true && ! "$contrasena" =~ [0-9] ]]; then
        echo -e "${red}la contrasena debe contener al menos un numero.${nc}"
        valida=false
    fi
    
    if [[ "$require_special_chars" = true ]]; then
        if ! [[ "$contrasena" =~ [$special_chars] ]]; then
            echo -e "${red}la contrasena debe contener al menos un caracter especial: $special_chars${nc}"
            valida=false
        fi
    fi
    
    $valida
}

echo -e "${green}creacion de nuevo usuario${nc}"
read -p "nombre de usuario: " usuario

if id "$usuario" &>/dev/null; then
    echo -e "${red}el usuario $usuario ya existe.${nc}"
    exit 1
fi

read -p "nombre completo (opcional): " nombre_completo
read -p "directorio home (opcional, dejar en blanco para default): " directorio_home
read -p "grupo principal (opcional, dejar en blanco para default): " grupo_principal

while true; do
    mostrar_reglas_contrasena
    read -s -p "contrasena: " contrasena
    echo
    read -s -p "confirmar contrasena: " confirmar_contrasena
    echo
    
    if [ "$contrasena" != "$confirmar_contrasena" ]; then
        echo -e "${red}las contrasenas no coinciden. intente nuevamente.${nc}"
    elif validar_contrasena "$contrasena"; then
        echo -e "${green}contrasena valida.${nc}"
        break
    else
        echo -e "${red}por favor, corrija los errores e intente nuevamente.${nc}"
    fi
done

comando_useradd="useradd"

[[ -n "$nombre_completo" ]] && comando_useradd+=" -c \"$nombre_completo\""
[[ -n "$directorio_home" ]] && comando_useradd+=" -d \"$directorio_home\"" || comando_useradd+=" -m"
[[ -n "$grupo_principal" ]] && comando_useradd+=" -g \"$grupo_principal\""

comando_useradd+=" \"$usuario\""

eval $comando_useradd

echo "$usuario:$contrasena" | chpasswd

echo -e "${green}\nusuario creado exitosamente:${nc}"
echo -e "nombre de usuario: $usuario"
[[ -n "$nombre_completo" ]] && echo "nombre completo: $nombre_completo"
echo "directorio home: $(eval echo ~$usuario)"
echo "grupo principal: $(id -gn $usuario)"
echo "uid: $(id -u $usuario)"
echo "gid: $(id -g $usuario)"
