#! /usr/bin/env bash

set -e

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

    test "$require_special_chars" = true && {
        pattern="[$(printf '%q' "$special_chars")]"
        if ! [[ "$contrasena" =~ $pattern ]]; then
            echo "la contrasena debe contener al menos un caracter especial: $special_chars"
            valida=false
        fi
    }

    $valida
}

validar_cuota() {
    local valor=$1
    [[ "$valor" =~ ^[0-9]+$ ]] && [ "$valor" -gt 0 ]
}

establecer_cuota() {
    local usuario=$1
    local soft=$2
    local hard=$3
    local filesystem=$(df -P "$(eval echo ~$usuario)" | awk 'NR==2 {print $1}')
    
    if ! setquota -u "$usuario" "$soft" "$hard" 0 0 "$filesystem"; then
        echo "advertencia: no se pudo establecer la cuota para el usuario $usuario."
        echo "asegurese de que:"
        echo "1. El sistema de archivos soporta cuotas"
        echo "2. El paquete quota esta instalado"
        echo "3. Tienes permisos de administrador"
        return 1
    fi
    
    # Activar quotas si no están activadas
    if ! quotaon -u "$usuario"; then
        echo "advertencia: no se pudieron activar las quotas para el usuario."
    fi
    
    return 0
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

if [ -n "$grupo_principal" ]; then
    if ! getent group "$grupo_principal" >/dev/null; then
        echo "el grupo $grupo_principal no existe."
        exit 1
    fi
fi

while true; do
    mostrar_reglas_contrasena
    read -s -p "contrasena: " contrasena
    echo
    read -s -p "confirmar contrasena: " confirmar_contrasena
    echo

    if [ "$contrasena" != "$confirmar_contrasena" ]; then
        echo "las contrasenas no coinciden. intente nuevamente."
        continue
    fi

    if validar_contrasena "$contrasena"; then
        echo "contrasena valida."
        break
    else
        echo "error, corrija."
    fi
done

# Preguntar por cuotas
cuota_soft=""
cuota_hard=""
read -p "establecer cuotas para el usaurio>?: " establecer_cuota_resp

if [[ "$establecer_cuota_resp" =~ ^[SsYy] ]]; then
    echo -e "\nlas cuotas se especifican en bloques (1 bloque = 1KB normalmente)"
    echo "ej: 100000 bloques ≈ 100MB"
    
    while true; do
        read -p "límite soft (bloques): " cuota_soft
        if validar_cuota "$cuota_soft"; then
            break
        else
            echo "valor inválido. debe ser un número entero positivo."
        fi
    done
    
    while true; do
        read -p "límite hard (bloques, debe ser >= soft): " cuota_hard
        if validar_cuota "$cuota_hard" && [ "$cuota_hard" -ge "$cuota_soft" ]; then
            break
        else
            echo "valor inválido. debe ser un número entero positivo mayor o igual al límite soft."
        fi
    done
fi

args=()

[ -n "$nombre_completo" ] && args+=(-c "$nombre_completo")
[ -n "$directorio_home" ] && args+=(-d "$directorio_home" -m) || args+=(-m)
[ -n "$grupo_principal" ] && args+=(-g "$grupo_principal")

args+=("$usuario")

if ! useradd "${args[@]}"; then
    echo "no se pudo crear el usuario."
    exit 1
fi

if ! echo "$usuario:$contrasena" | chpasswd; then
    echo "no se pudo establecer la contrasena."
    userdel "$usuario"
    exit 1
fi

if [ -n "$cuota_soft" ] && [ -n "$cuota_hard" ]; then
    if establecer_cuota "$usuario" "$cuota_soft" "$cuota_hard"; then
        echo "soft=$cuota_soft, hard=$cuota_hard bloques"
    fi
fi
#
# echo -e "\nusuario creado exitosamente:"
# echo "INFORMACION DEL USUARIO"
# echo "#################################"
# echo "nombre de usuario: $usuario"
# [ -n "$nombre_completo" ] && echo "nombre completo: $nombre_completo"
# echo "directorio home: $(eval echo ~$usuario)"
# echo "grupo principal: $(id -gn $usuario)"
# echo "uid: $(id -u $usuario)"
# echo "gid: $(id -g $usuario)"
# [ -n "$cuota_soft" ] && echo "cuota soft: $cuota_soft bloques"
# [ -n "$cuota_hard" ] && echo "cuota hard: $cuota_hard bloques"
