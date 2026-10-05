🚀 BlastersGameGD
Proyecto de práctica de un juego de naves (shooter) desarrollado en Godot Engine.

Este es un proyecto personal de aprendizaje con el que estoy practicando el desarrollo de videojuegos en Godot: manejo de escenas, scripts en GDScript, sistema de guardado, menús, música, efectos de sonido y dificultad progresiva.

🎮 Descripción
BlastersGameGD es un juego de naves estilo arcade donde controlas una nave, disparas a enemigos y esquivas obstáculos. El objetivo es sobrevivir el mayor tiempo posible y conseguir la mayor puntuación.

A medida que avanzas, la dificultad va aumentando, apareciendo más enemigos y de forma más agresiva.

✨ Características
🕹️ Jugabilidad arcade: controla tu nave, dispara y esquiva.

👾 Sistema de enemigos con aparición dinámica.

📈 Dificultad progresiva: cuantos más enemigos, más difícil se vuelve la partida.

🎵 Música y efectos de sonido.

💾 Sistema de guardado simple (puntuaciones).

📋 Menús interactivos con contador de puntuación.

📱 Soporte para joystick virtual (addon virtual_joystick_DX), pensado para poder jugar en dispositivos táctiles.

🖥️ Ejecutable para PC ya compilado (ver sección de descarga).

🛠️ Tecnologías y requisitos
Motor: Godot Engine (versión 4.x, según la configuración del proyecto)

Lenguaje: GDScript

Plataforma objetivo: PC (Windows/Linux) y potencialmente móvil gracias al joystick virtual.

Si quieres abrir el proyecto en el editor necesitas tener instalado Godot 4 o superior.

⬇️ Descargar y probar el juego
El ejecutable ya compilado está disponible en la carpeta ExePc del repositorio.

🔗 Enlace a la carpeta del ejecutable:


⚠️ Importante: Para que el juego funcione correctamente debes descargar los dos archivos que se encuentran en esa carpeta (el .exe y el archivo de datos .pck, o los archivos correspondientes según el export). Si solo descargas uno, el juego no arrancará.

Pasos para probarlo:
Entra en el enlace de arriba: /BlastersGameGD/tree/main/ExePc

Descarga los dos archivos que hay en esa carpeta.

Colócalos en la misma carpeta en tu PC.

Ejecuta el archivo .exe (o el binario correspondiente).

¡A jugar! 🎮

📂 Estructura del proyecto
text
BlastersGameGD/
├── Escenas/              # Escenas del juego (.tscn)
├── ExePc/                # Ejecutable compilado para PC
├── accets/               # Recursos gráficos y de audio (assets)
├── addons/
│   └── virtual_joystick_DX/   # Addon para joystick virtual
├── resourse/             # Recursos varios
├── saves/                # Sistema de guardado
├── scripts/              # Scripts en GDScript
├── MainMenu.tscn         # Escena del menú principal
├── main.tscn             # Escena principal del juego
├── main.gd               # Script principal
├── main_menu.gd          # Script del menú
├── project.godot         # Configuración del proyecto Godot
└── icon.svg              # Icono del proyecto
🕹️ Controles
Acción	Tecla / Entrada
Moverse	Flechas / WASD / Joystick virtual
Disparar	Espacio / Botón de disparo
Pausa	Esc 


🎯 Objetivo del proyecto
Este proyecto nace como práctica personal para aprender y afianzar conceptos de desarrollo en Godot:

Creación y gestión de escenas.

Programación en GDScript.

Sistema de guardado y carga de datos.

Menús y navegación entre escenas.

Integración de audio (música y SFX).

Exportación de builds para PC.

Uso de addons externos (joystick virtual).

No es un proyecto comercial, sino un laboratorio de aprendizaje donde iré añadiendo mejoras poco a poco.