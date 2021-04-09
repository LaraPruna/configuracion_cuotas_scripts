#!/bin/bash

#Mediante esta función, comprobamos la existencia de un directorio.
#Devuelve un 0 si el directorio existe y 1 si no existe.
#Acepta un argumento, que es el directorio que se quiera comprobar.
function f_existe_directorio {
	if [[ -d $1 ]]
		then
			return 0
		else
			return 1
	fi
}

#Esta función comprueba si eres root.
#No acepta argumentos
#Devuelve 0 si eres root y 1 si no lo eres.
function f_eres_root {
	if [[ $(whoami) = 'root' ]]
		then
			return 0
		else
			return 1
	fi
}

#Mediante esta función, conseguimos el UUID de un dispositivo de bloque.
#Acepta como argumento el nombre del dispositivo y devuelve su UUID.
#Devuelve 1 si no eres root, 2 si el dispositivo no está montado y 0 si
#no hay ningún error.
function f_UUID {
	if [[ $(f_eres_root;echo $?) = 0 ]]
		then
			if [[ $(f_esta_montado $1;echo $?) = 0 ]]
				then
					blkid $1 | awk '{print $2}' | egrep -o '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}'
				else
					echo 'El dispositivo no está montado'
					return 2
			fi
		else
			echo 'No eres root'
			return 1
	fi
}

#Esta función comprueba si un paquete está instalado o no.
#Acepta como argumento el nombre del paquete.
#Devuelve 0 si está instalado y 1 si no lo está.
function f_esta_instalado {
	if [[ $(dpkg-query -l | egrep $1 | awk '{print $2}') = $1 ]]
		then
			return 0
		else
			return 1
	fi
}

#Esta función instala un paquete.
#Acepta como argumento el nombre del paquete.
#Devuelve 0 al instalar el paquete, 1 si no eres root y 2 si el paquete
#ya está instalado.
function f_instalar {
	if [[ $(f_esta_instalado $1;echo $?) = 1 ]]
		then
			if [[ $(f_eres_root;echo $?) = 0 ]]
				then
					apt-get install -y $1
					return 0
				else
					echo 'No eres root'
					return 1
			fi
		else
			echo 'El paquete ya está instalado'
			return 2
	fi
}

#Esta función comprueba si un dispositivo de bloque está montado o no.
#Acepta como argumento el nombre del dispositivo de bloque.
#Devuelve 0 si está montado y 1 si lo está.
function f_esta_montado {
	if [[ $(df -h $1) ]]
		then
			return 0
		else
			return 1
	fi
}

#Esta función monta el dispositivo introducido como argumento por el usuario.
#Devuelve 0 al montar el dispositivo, 1 si el directorio no existe y 2
#si no eres root.
#Acepta como primer argumento el dispositivo de bloque,
#y como segundo argumento, el directorio donde se quiere montar.
function f_montar {
	if [[ $(f_eres_root;echo $?) = 0 ]]
		then
			if [[ $(f_existe_directorio $2;echo $?) = 0 ]]
				then
					mount $1 $2
					return 0
				else
					echo 'Ese directorio no existe'
					return 1
			fi
		else
			echo 'No eres root'
			return 2
	fi
}

#Esta función comprueba si un paquete está en su última versión.
#Acepta como argumento el nombre del paquete.
#Devuelve 0 si el paquete está actualizado, 1 si es una versión anterior
#y 2 si no está instalado.
function f_paquete_esta_actualizado {
	if [[ $(f_esta_instalado $1;echo $?) = 0 ]]
		then
			inst=$(apt policy $1 2>/dev/null | egrep Instalados | awk '{print $2}')
			cand=$(apt policy $1 2>/dev/null | egrep Candidato | awk '{print $2}')
			inst2=$(apt policy $1 2>/dev/null | egrep Installed | awk '{print $2}')
			cand2=$(apt policy $1 2>/dev/null | egrep Candidate | awk '{print $2}')
			if [[ $inst = $cand || $inst2 = $cand2 ]]
				then
					return 0
				else
					return 1
			fi
		else
			return 2
	fi
}

#Esta función actualiza un paquete que ya esté instalado.
#Acepta como argumento el nombre del paquete.
#Devuelve 0 al actualizar el paquete, 1 si no eres root, 2 si el paquete
#ya está actualizado y 3 si no está instalado.
function f_actualizar_paquete {
	if [[ $(f_esta_instalado $1;echo $?) = 0 ]]
		then
			if [[ $(f_paquete_esta_actualizado $1;echo $?) = 1 ]]
				then
					if [[ $(f_eres_root;echo $?) = 0 ]]
						then
							apt-get install --only-upgrade $1
							return 0
						else
							echo 'No eres root'
							return 1
					fi
				else
					echo 'El paquete ya está en su última versión'
					return 2
			fi
		else
			echo 'El paquete no está instalado'
			return 3
	fi
}

