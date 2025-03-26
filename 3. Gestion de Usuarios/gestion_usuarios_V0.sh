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
    
    test "$require_uppercase" = true && ! [[ "$contrasena" =~ [A-Z] ]] && {
        echo "la contrasena debe contener al menos una letra mayuscula."
        valida=false
    }
    
    test "$require_lowercase" = true && ! [[ "$contrasena" =~ [a-z] ]] && {
        echo "la contrasena debe contener al menos una letra minuscula."
        valida=false
    }
    
    test "$require_numbers" = true && ! [[ "$contrasena" =~ [0-9] ]] && {
        echo "la contrasena debe contener al menos un numero."
        valida=false
    }
    
    test "$require_special_chars" = true && ! [[ "$contrasena" =~ [$special_chars] ]] && {
        echo "la contrasena debe contener al menos un caracter especial"
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
    
    if validar_contrasena "$contrasena"; then
        echo "contrasena valida."
        break
    else
        echo "corrija los errores e intente nuevamente."
    fi
done

args=()

test -n "$nombre_completo" && args+=(-c "$nombre_completo")
test -n "$directorio_home" && args+=(-d "$directorio_home") || args+=(-m)
test -n "$grupo_principal" && args+=(-g "$grupo_principal")

args+=("$usuario")

useradd "${args[@]}"

echo "$usuario:$contrasena" | chpasswd

echo -e "\nusuario creado exitosamente:"
echo "nombre de usuario: $usuario"
test -n "$nombre_completo" && echo "nombre completo: $nombre_completo"
echo "directorio home: $(eval echo ~$usuario)"
echo "grupo principal: $(id -gn $usuario)"
echo "uid: $(id -u $usuario)"
echo "gid: $(id -g $usuario)"

exit 0
