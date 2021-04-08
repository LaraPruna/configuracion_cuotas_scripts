#!/bin/bash
. ./libreria.sh

echo 'Inicio de configuración. Comprobando el estado del paquete quota.'
if [[ $(f_esta_instalado quota;echo $?) = 0 ]]
	then
		if [[ $(f_esta_actualizado quota;echo $?) = 0 ]]
			then
				echo 'El paquete quota está instalado y actualizado.'
			else
				echo 'El paquete quota está instalado en una versión anterior. ¿Desea actualizarlo? (s/n)'
				read resp2
				if [[ $resp2 = 's' ]]
					then
						echo 'Actualizando quota'
					else
						echo '¿Desea continuar con la configuración de cuotas de todas formas? (s/n)'
						read resp3
						if [[ $resp3 = 's' ]]
							then
								echo 'Procediendo a la configuración de cuotas.'
							else
								exit
						fi
				fi
		fi
	else
		echo 'El paquete quota no está instalado. ¿Desea instalarlo? (s/n)'
		read resp1
		if [[ $resp1 = 's' ]]
			then
				f_instalar quota
			else
				echo 'Fin del programa'
		fi
fi
