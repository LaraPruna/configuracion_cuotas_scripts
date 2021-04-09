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
echo 'Lista de volúmenes:'
lsblk -l

echo 'Introduce el nombre de un dispositivo de bloque sin montar:'
read volumen
if [[ $(f_está_montado $volumen) = 1 ]]; then
	if [[ $(f_existe_directorio /QUOTA; echo $?) = 1 ]]; then
		echo 'Creando directorio /QUOTA...'
		mkdir /QUOTA
	fi
	echo 'Montando dispositivo en el directorio /QUOTA.'
	f_montar $volumen /QUOTA
	echo 'Dispositivo montado.'

else
	if [[ $(df | egrep $volumen | awk '{print $6}') = '/QUOTA' ]]; then
		echo 'El dispositivo está montado en /QUOTA.'
	else
		echo 'El dispositivo está montado en otro directorio. ¿Desea desmontarlo? (s/n)'
		read resp4
		if [[ $resp4 = 's' ]]; then
			echo 'Desmontando dispositivo...'
			umount $volumen
			if [[ $(f_existe_directorio /QUOTA; echo $?) = 1 ]]; then
				echo 'Creando directorio /QUOTA...'
				mkdir /QUOTA
			fi
			echo 'Montando dispositivo en el directorio /QUOTA.'
			f_montar $volumen /QUOTA
			echo 'Dispositivo montado.'
		else
			echo 'Fin del programa.'
			exit
		fi
	fi
fi
