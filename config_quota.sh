#!/bin/bash
. ./libreria.sh
if [[ $(f_eres_root;echo $?) = 0 ]]; then
	echo 'Inicio de configuración. Comprobando el estado del paquete quota.'
	if [[ $(f_esta_instalado quota;echo $?) = 0 ]]; then
		if [[ $(f_paquete_esta_actualizado quota;echo $?) = 0 ]]; then
			echo 'El paquete quota está instalado y actualizado.'
			echo 'Procediendo a la configuración de cuotas...'
		else
			echo 'El paquete quota está instalado en una versión anterior. ¿Desea actualizarlo? (s/n)'
			read resp2
			if [[ $resp2 = 's' ]]; then
				echo 'Actualizando quota...'
				f_actualizar_paquete quota
				echo 'Paquete quota actualizado.'
				echo 'Procediendo a la configuración de cuotas...'
			else
				echo '¿Desea continuar con la configuración de cuotas de todas formas? (s/n)'
				read resp3
				if [[ $resp3 = 's' ]]; then
					echo 'Procediendo a la configuración de cuotas...'
				else
					echo 'Fin del programa.'
					exit
				fi
			fi
		fi
	else
		echo 'El paquete quota no está instalado. ¿Desea instalarlo? (s/n)'
		read resp1
		if [[ $resp1 = 's' ]]; then
			f_instalar quota
			echo 'Paquete quota instalado.'
			echo 'Procediendo a la configuración de cuotas...'
		else
			echo 'Fin del programa.'
			exit
		fi
	fi
else
	echo 'Tienes que ser root.'
	exit
fi

echo 'Lista de volúmenes:'
lsblk -l

echo 'Introduce el nombre de un dispositivo de la lista que no esté montado:'
read volumen
if [[ $(lsblk -l | egrep $volumen | awk '{print $6}') = 'part' ]]; then
	if [[ $(lsblk -l | egrep $volumen) ]]; then
		if [[ $(f_esta_montado /dev/$volumen;echo $?) = 1 ]]; then
			if [[ $(f_existe_directorio /QUOTA; echo $?) = 1 ]]; then
				echo 'Creando directorio /QUOTA...'
				mkdir /QUOTA
			fi
			echo '¿Qué tipo de sistema de ficheros desea crear en el volumen? (ext2/ext3/ext4/vfat)'
			read fs
			echo 'Creando sistema de ficheros en el volumen.'
			f_crea_fs /dev/$volumen $fs
			echo 'Montando dispositivo en el directorio /QUOTA.'
			f_montar /dev/$volumen /QUOTA
			echo 'Dispositivo montado.'
		else
			if [[ $(df | egrep /dev/$volumen | awk '{print $6}') = '/QUOTA' ]]; then
				echo 'El dispositivo está montado en /QUOTA.'
				fs=$(lsblk -f | egrep $volumen | awk '{print $2}')
			else
				echo 'El dispositivo está montado en otro directorio. ¿Desea desmontarlo? (s/n)'
				read resp4
				if [[ $resp4 = 's' ]]; then
					echo 'Desmontando dispositivo...'
					umount /dev/$volumen
					if [[ $(f_existe_directorio /QUOTA; echo $?) = 1 ]]; then
						echo 'Creando directorio /QUOTA...'
						mkdir /QUOTA
					fi
					echo 'Montando dispositivo en el directorio /QUOTA.'
					f_montar /dev/$volumen /QUOTA
					echo 'Dispositivo montado.'
				else
					echo 'Fin del programa.'
					exit
				fi
			fi
		fi
	else
		echo 'Nombre de volumen incorrecto.'
		echo 'Fin del programa.'
		exit
	fi
else
	echo 'Ese dispositivo no tiene UUID. ¿Desea crear una nueva partición? (s/n)' 
	read part
	if [[ $part = 's' ]]; then
		sgdisk -n 0:0:0 /dev/$volumen > /dev/null
		echo 'Partición creada. Vuelva a iniciar el programa.'
		exit
	else
		echo 'Fin del programa.'
		exit
	fi
fi

echo 'Comprobando fichero /etc/fstab...'
UUID=$(f_UUID /dev/$volumen)
if [[ $(egrep $UUID /etc/fstab) ]]; then
	echo 'El fichero fstab ya contiene una línea para el volumen.'
	echo 'Añadiendo opciones de quota...'
	f_cuotas_fstab $UUID
	echo 'Opciones de cuotas añadidas a fstab.'
else
	echo 'El fichero fstab no contiene información sobre el volumen.'
	echo 'Introduzca la siguiente información sobre el volumen:'
	echo 'Opciones de montaje (por defecto, "defaults,usrquota,grpquota"):'
	read opciones
	echo 'Número de copias de respaldo (por defecto, 0):'
	read dump
	echo 'Orden de chequeo (por defecto, 2):'
	read fsck
	if [[ $opciones = $null ]]; then
		opciones='defaults,usrquota,grpquota'
	fi
	if [[ $dump = $null ]]; then
		dump=0
	fi
	if [[ $fsck = $null ]]; then
		fsck=2
	fi
	f_nueva_linea_fstab UUID=$UUID /QUOTA $fs $opciones $dump $fsck
fi
echo 'Comprobando ficheros de quota...'
mount -o remount /QUOTA
if [[ $(f_existe_fichero aquota.user /QUOTA;echo $?) = 0 ]]; then
	if [[ $(f_existe_fichero aquota.group /QUOTA;echo $?) = 0 ]]; then
		echo 'Los ficheros de quota ya están generados.'
	else
		echo 'Generando fichero aquota.group...'
		f_habilita_quota /QUOTA
		echo 'Ficheros generados.'
	fi
else
	echo 'Generando ficheros de quota...'
	f_habilita_quota /QUOTA
	echo 'Ficheros generados.'
fi
echo 'Comprobando estado del paquete quotatool...'
if [[ $(f_esta_instalado quotatool;echo $?) = 0 ]]; then
	if [[ $(f_paquete_esta_actualizado quotatool; echo $?) = 0 ]]; then
		echo 'El paquete quotatool está instalado y en su última versión.'
		echo 'Procediendo a crear una plantilla de cuotas...'
	else
		echo 'El paquete quotatool está instalado en una versión anterior. ¿Desea actualizarlo? (s/n)'
		read resp5
		if [[ $resp5 = 's' ]]; then
			echo 'Actualizando quotatool...'
			f_actualizar_paquete quotatool
			echo 'Quotatool actualizado.'
			echo 'Procediendo a crear la plantilla de cuotas...'
		else
			echo 'Procediendo a crear la plantilla de cuotas...'
		fi
	fi
else
	echo 'Instalando paquete quotatool...'
	f_instalar quotatool
	echo 'Paquete quotatool instalado.'
	echo 'Procediendo a crear una plantilla de cuotas...'
fi
f_plantilla_quota /QUOTA
echo 'Plantilla creada.'
echo '¿Desea aplicar la plantilla en algún usuario o grupo? (s/n)'
read resp6
if [[ $resp6 = 's' ]]; then
	echo '¿A cuántos usuarios quieres copiar la plantilla?'
	read num
	f_copia_cuotas $num
	echo 'Cuotas copiadas. Fin del programa.'
else
	echo 'Fin del programa.'
fi
