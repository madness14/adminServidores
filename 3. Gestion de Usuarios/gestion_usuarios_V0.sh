#!/bin/bash

min_length=8
require_uppercase=true
require_lowercase=true
require_numbers=true
require_special_chars=true
special_chars="!@#$%^&*"

mostrar_reglas_contrasena() {
    echo -e "\nreglas para la contrasena:"
    echo "- longitud minima: $min_length caracteres"
    test "$require_uppercase" = true && echo "- debe contener al menos una letra mayuscula"
    test "$require_lowercase" = true && echo "- debe contener al menos una letra minuscula"
    test "$require_numbers" = true && echo "- debe contener al menos un numero"
    test "$require_special_chars" = true && echo "- debe contener al menos un caracter especial: $special_chars"
    echo ""
}

validar_contrasena() {
    local contrasena=$1
    local valida=true
    
    test ${#contrasena} -lt $min_length && {
        echo "la contrasena es demasiado corta. minimo $min_length caracteres."
        valida=false
    }
    
    test "$require_uppercase" = true && ! echo "$contrasena" | grep -q [A-Z] && {
        echo "la contrasena debe contener al menos una letra mayuscula."
        valida=false
    }
    
    test "$require_lowercase" = true && ! echo "$contrasena" | grep -q [a-z] && {
        echo "la contrasena debe contener al menos una letra minuscula."
        valida=false
    }
    
    test "$require_numbers" = true && ! echo "$contrasena" | grep -q [0-9] && {
        echo "la contrasena debe contener al menos un numero."
        valida=false
    }
    
    test "$require_special_chars" = true && ! echo "$contrasena" | grep -q "[$special_chars]" && {
        echo "la contrasena debe contener al menos un caracter especial: $special_chars"
        valida=false
    }
    
    $valida
}

echo "creacion de nuevo usuario"
read -p "nombre de usuario: " usuario

if id "$usuario" >/dev/null 2>&1; then
    echo "el usuario $usuario ya existe."
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
    
    test "$contrasena" != "$confirmar_contrasena" && {
        echo "las contrasenas no coinciden. intente nuevamente."
        continue
    }
    
    validar_contrasena "$contrasena" && {
        echo "contrasena valida."
        break
    } || echo "por favor, corrija los errores e intente nuevamente."
done

comando_useradd="useradd"

test -n "$nombre_completo" && comando_useradd="$comando_useradd -c \"$nombre_completo\""
test -n "$directorio_home" && comando_useradd="$comando_useradd -d \"$directorio_home\"" || comando_useradd="$comando_useradd -m"
test -n "$grupo_principal" && comando_useradd="$comando_useradd -g \"$grupo_principal\""

comando_useradd="$comando_useradd \"$usuario\""

eval $comando_useradd

echo "$usuario:$contrasena" | chpasswd

echo -e "\nusuario creado exitosamente:"
echo "nombre de usuario: $usuario"
test -n "$nombre_completo" && echo "nombre completo: $nombre_completo"
echo "directorio home: $(eval echo ~$usuario)"
echo "grupo principal: $(id -gn $usuario)"
echo "uid: $(id -u $usuario)"
echo "gid: $(id -g $usuario)"

exit 0
