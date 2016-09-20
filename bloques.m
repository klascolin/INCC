%bloque 1
%el sujeto  solamente ve imagen
img = 1
snd = 0
delay = 0
target = 1
Imagenes(delay, img, snd,target,5)
%bloque 2
%el sujeto  solamente ve sondio
img = 0
snd = 1
delay = 0
target = 0
Imagenes(delay, img, snd,target,5)
%bloque 3
%el sujeto ve imagen y sonido sincronizado
img = 1
snd = 1
delay = 0
target = 1 % no importa
Imagenes(delay, img, snd,target,5)
%bloque 4
%el sujeto ve imagen y sonido + 0.25, sigue a la imagen
img = 1
snd = 1
delay = 0.25
target = 1 
Imagenes(delay, img, snd,target,5)
%bloque 5
%el sujeto ve imagen y sonido + 0.5, sigue a la imagen
img = 1
snd = 1
delay = 0.5
target = 1 
Imagenes(delay, img, snd,target,5)
%bloque 6
%el sujeto ve imagen y sonido + 0.75, sigue a la imagen
img = 1
snd = 1
delay = 0.75
target = 1 
Imagenes(delay, img, snd,target,5)
%bloque 7
%el sujeto ve imagen y sonido -0.25 , sigue al sonido
img = 1
snd = 1
delay = 0.25
target = 0 
Imagenes(delay, img, snd,target,5)
%bloque 8
%el sujeto ve imagen y sonido -0.5 , sigue al sonido
img = 1
snd = 1
delay = 0.5
target = 0 
Imagenes(delay, img, snd,target,5)
%bloque 9
%el sujeto ve imagen y sonido -0.75 , sigue al sonido
img = 1
snd = 1
delay = 0.75
target = 0 
Imagenes(delay, img, snd,target,5)

