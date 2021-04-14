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
#Devuelve 1 si no eres root, 2 si el dispositivo no está montado, y 0 si no hay ningún error.
function f_UUID {
	if [[ $(f_eres_root;echo $?) = 0 ]]
		then
			if [[ $(f_esta_montado $1;echo $?) = 0 ]]
				then
					var='[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}'
					blkid $1 | awk '{print $2}' | egrep -o $var
					return 0
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
	if [[ $(dpkg-query -l | awk '{print $2}' | egrep ^$1$) = $1 ]]
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
					apt-get install -y $1 > /dev/null
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
	if [[ $(df | egrep $1) ]]
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

#Esta función crea un sistema de ficheros en un dispositivo de bloque.
#Acepta como primer argumento el nombre del volumen, y como segundo argumento, el tipo de sistema de ficheros
#(ext2, ext3, ext4 o vfat).
#Devuelve 0 al crear el sistema de ficheros, 1 si no eres root, 2 si no existe ese volumen,
#3 si no está instalado el paquete e2fsprogs o dosfstools (necesarios para crear el sistema de ficheros),
#y 4 si no se ha introducido un tipo de sistema de ficheros de entre los especificados en este comentario.
function f_crea_fs {
	if [[ $(f_eres_root;echo $?) = 0 ]]; then
		if [[ $(blkid $1) ]]; then
			if [[ $2 = 'ext2' || $2 = 'ext3' || $2 = 'ext4' ]]; then
				if [[ $(f_esta_instalado e2fsprogs; echo $?) = 0 ]]; then
					mkfs.$2 $1 > /dev/null
					return 0
				else
					echo 'El paquete e2fsprogs no está instalado.'
					return 3
					exit
				fi
			elif [[ $2 = 'vfat' ]]; then
				if [[ $(f_esta_instalado dosfstools;echo $?) = 0 ]]; then
					mkfs.$2 $1
					return 0
				else
					echo 'El paquete dosfstools no está instalado.'
					return 3
					exit
				fi
			else
				echo 'Tipo de sistema de ficheros incorrecto.'
				return 4
				exit
			fi
		else
			echo 'Nombre de dispositivo incorrecto.'
			return 2
			exit
		fi
	else
		echo 'No eres root'
		return 1
	fi
}

#Esta función permite añadir una nueva línea al fichero /etc/fstab con los datos del dispositivo de bloque.
#Recibe como argumentos los valores correspondientes a los campos del fichero fstab y en ese mismo orden
#(UUID, punto de montaje, tipo de sistema de ficheros, opciones de montaje, dump y chequeo).
#Devuelve 0 al añadir la línea al fichero y 1 si ya existe esa línea.
function f_nueva_linea_fstab {
	if [[ $(egrep $1 /etc/fstab;echo $?) = 1 ]]
		then
			echo $1	$2	$3	$4	$5	$6 >> /etc/fstab
			return 0
		else
			return 1
	fi
}

#Esta función permite añadir opciones de cuotas para usuarios y grupos en el fichero /etc/fstab.
#Acepta como argumento la UUID del volumen al que se quiere aplicar cuotas.
#Devuelve 0 al añadir las opciones y 1 si la UUID es incorrecta.
function f_cuotas_fstab {
	if [[ $(egrep $1 /etc/fstab) ]]
		then
			opciones=$(egrep $1 /etc/fstab | awk '{print $4}')
			sed -i 's/'$opciones'/&,usrquota,grpquota/' /etc/fstab
			return 0
		else
			echo 'La UUID es incorrecta.'
			return 1
	fi
}

#Esta función crea los ficheros aquota.user y aquota.group.
#Acepta como argumento el punto de montaje del volumen.
#Devuelve 0 al generar los ficheros y 1 si el punto de montaje es incorrecto.
function f_habilita_quota {
	if [[ $(lsblk -f | egrep $1) ]]; then
		quotacheck -ug $1 > /dev/null
		quotaon $1
		return 0
	else
		echo 'El punto de montaje es incorrecto.'
		return 1
	fi
}

#Esta función comprueba si existe un determinado fichero.
#Acepta como primer argumento el fichero que se quiere buscar, y como segundo argumento, la ruta absoluta
#del directorio donde se quiere buscar el fichero, que por defecto será donde se encuentre el usuario.
#Devuelve 0 si el fichero existe, 1 si no existe y 2 si no existe el directorio introducido.
function f_existe_fichero {
	if [[ $2 = $null ]]; then
		if [[ -e ./$1 ]]; then
			return 0
		else
			return 1
		fi
	else
		if [[ $(f_existe_directorio $2;echo $?) = 0 ]]; then
			if [[ -e $2/$1 ]]; then
				return 0
			else
				return 1
			fi
		else
			return 2
		fi
	fi
}

#Esta función crea una plantilla de cuotas a gusto del usuario mediante un simple cuestionario,
#para después emplearla en otros usuarios o grupos.
#Acepta como primer argumentola ruta del directorio en la que se quiere crear la plantilla.
function f_plantilla_quota {
	echo '¿Desea aplicar cuotas a un usuario o a un grupo? (usuario/grupo)'
	read resp1
	while [[ $resp1 != 'usuario' && $resp1 != 'grupo' ]];
	do
		echo 'Respuesta incorrecta. Introduzca una de las opciones.';
		read resp1;
	done
	if [[ $resp1 = 'usuario' ]]; then
		var1='-u'
                echo 'Nombre o UID del usuario (por defecto, se creará el usuario "plantilla"):'
                read nombre
		if [[ $nombre = $null ]]; then
			useradd plantilla 2> /dev/null
			nombre=plantilla
		fi
        else
                var1='-g'
                echo 'Nombre o GUID del grupo (por defecto, se creará el grupo "plantilla"):'
                read nombre
		if [[ $nombre = $null ]]; then
			groupadd plantilla 2> /dev/null
			nombre=plantilla
		fi
	fi
	echo '¿Desea aplicar una cuota de bloques o de inodos? (bloques/inodos)'
	read resp2
	while [[ $resp2 != 'bloques' && $resp2 != 'inodos' ]];
	do
		echo 'Respuesta incorrecta. Introduzca una de las opciones.'
		read resp2
	done
	if [[ $resp2 = 'bloques' ]]; then
		var2='-b'
	else
		var2='-i'
	fi
	echo '¿Desea aplicar cuotas blandas? (s/n)'
	read resp3
	if [[ $resp3 = 's' ]]; then
		var3='-q'
		echo '¿Qué tamaño desea asignarle a la cuota?'
		read qsize
		echo '¿Desea aplicar cuotas duras? (s/n)'
		read resp4
		if [[ $resp4 = 's' ]]; then
			var4='-l'
			echo '¿Qué tamaño desea asignarle a la cuota?'
			read lsize
			quotatool $var1 $nombre $var2 $var3 $qsize $var4 $lsize $1
			quotaon $1 &> /dev/null
			return 0
		else
			quotatool $var1 $nombre $var2 $var3 $qsize $1
			quotaon $1 &> /dev/null
			return 0
		fi
	else
		echo '¿Desea aplicar cuotas duras? (s/n)'
		read resp4
		if [[ $resp4 = 's' ]]; then
			var3='-l'
			echo '¿Qué tamaño desea asignarle a la cuota?'
			read lsize
			quotatool $var1 $nombre $var2 $var3 $lsize $1
			quotaon $1 &> /dev/null
			return 0
		fi
	fi
}

#Esta función copia las cuotas de un usuario a un número de usuarios dado.
#Acepta como argumento el número de usuarios a los que se quiere copiar las cuotas.
function f_copia_cuotas {
	echo 'Introduce el nombre del usuario cuyas cuotas quiere copiar:'
	read nombre
	for num in $(seq 1 $1)
	do
		echo "Nombre de usuario al que quiere aplicar las cuotas:"
		read usuario
		if [[ $(awk -F: '{print $1}' /etc/passwd | egrep $usuario) ]]; then
			edquota -p $nombre $usuario
		else
			echo 'Ese usuario no existe.'
			continue
		fi;
	done
}
