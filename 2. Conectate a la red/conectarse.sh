#!/bin/bash

echo "interfaces disponibles:"
ip -br a
echo "selecciona a continuacion la interfaz para cambiar su estado:"
read interfaz

estado=$(ip -br link show "$interfaz" | awk '{print $2}')
if [[ "$estado" == "UP" ]]; then
    sudo ip link set "$interfaz" down
    echo "$interfaz...DOWN"
elif [[ "$estado" == "DOWN" ]]; then
    sudo ip link set "$interfaz" up
    echo "$interfaz...UP"
else
    echo "no se determino"
    exit 1
fi

echo "conectarse de manera inalambrica (w) o cableada (c)?"
read eleccion
if [[ "$eleccion" == "w" ]]; then
    echo "redes wifi disponibles:"
    sudo iwlist "$interfaz" scan | grep 'ESSID'
    echo "pon el nombre de la red:"
    read nombre
    echo "pon la contraseña de la red:"
    read contrasena
    wpa_passphrase "$nombre" "$contrasena" | sudo tee /etc/wpa_supplicant.conf
    sudo wpa_supplicant -B -i "$interfaz" -c /etc/wpa_supplicant.conf
    echo "conectado a $nombre"
else
    sudo ip link set "$interfaz" up
    echo "conexion cableada hecha"
fi

echo "configurar con dhcp (d) o ip fija (f)?"
read eleccion2
if [[ "$eleccion2" == "d" ]]; then
    sudo dhclient "$interfaz"
    echo "configuracion DHCP realizada"
else
    echo "pon la ip:"
    read direccion
    echo "pon la mascara:"
    read mascara
    echo "pon la puerta de enlace:"
    read puerta
    sudo ip addr add "$direccion/$mascara" dev "$interfaz"
    sudo ip route add default via "$puerta"
    echo "configuracion IP fija aplicada"
fi
    
