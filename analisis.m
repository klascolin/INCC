format long g;

%% Leer CSV a variables aux
i = 0;
sujeto = [];
tiempo = [];
practica = [];
delay = [];
img = [];
snd = [];
target = [];
total_trials = [];
target_time = cell(1,1);
time_firstPress = cell(1,1);
time_lastPress = cell(1,1);
f = fopen('data/bloques.csv');

while 1    
    suj = fscanf(f, '%i,', [1 1]);
    if isempty(suj)
       break 
    end
    i = i + 1;
    
    sujeto(i) = suj;
    tiempo(i) = fscanf(f, '%f,', [1 1]);
    practica(i) = fscanf(f, '%i,', [1 1]);
    delay(i) = fscanf(f, '%f,', [1 1]);
    img(i) = fscanf(f, '%i,', [1 1]);
    snd(i) = fscanf(f, '%i,', [1 1]);
    target(i) = fscanf(f, '%i,', [1 1]);
    total_trials(i) = fscanf(f, '%i,', [1 1]);
    target_time{i} = fscanf(f, '%f:', [1 total_trials(i)]);
    fscanf(f, ',');
    time_firstPress{i} = fscanf(f, '%f:', [1 total_trials(i)]);
    fscanf(f, ',');
    time_lastPress{i} = fscanf(f, '%f:', [1 total_trials(i)]);
    fscanf(f, ',');
    fscanf(f, '\n');
end
fclose(f);


%% Meter cada trial en el struct Trials sin procesarlos
num_bloques = i;
j = 1;
s = 0;
Trials = [];
for b = 1 : num_bloques
   if s ~= sujeto(b)
       bloque_del_sujeto = 1;
       s = sujeto(b);
   else
       bloque_del_sujeto = bloque_del_sujeto + 1;
   end
   
   for k = 1 : total_trials(b)
       Trials(j).Sujeto = sujeto(b);
       Trials(j).Tiempo = tiempo(b);
       Trials(j).EsDePractica = practica(b);
       Trials(j).Delay = delay(b);
       Trials(j).HayImagen = img(b);
       Trials(j).HaySonido = snd(b);
       Trials(j).SeguirImagen = target(b);
       Trials(j).NumBloque = bloque_del_sujeto;
       Trials(j).NumBloqueOriginal = b;
       Trials(j).NumTrial = k;       
       Trials(j).TiempoObjetivo = target_time{b}(k);
       Trials(j).PrimerTap = time_firstPress{b}(k);
       Trials(j).Asincronia = Trials(j).PrimerTap - Trials(j).TiempoObjetivo;
       Trials(j).UltimoTap = time_lastPress{b}(k);
        
       j = j + 1;    
   end
end

num_trials = j-1;

clear sujeto tiempo practica delay img snd target bloque_del_sujeto total_trials target_time time_firstPress time_lastPress f b i j k s num_bloques suj


%% calcular muestras (promedio de cada bloque) ignorando datos fuera de la ventana y etc
Muestras = [];
t = 1;
m = 1;
k = 0;
asinc = 0;
unbo = Trials(1).NumBloqueOriginal;
while t <= (num_trials + 1)
    fin = 0;
    if (t == (num_trials + 1)) 
        fin = 1;
    else
        if (unbo ~= Trials(t).NumBloqueOriginal)
            fin = 1;
        end
    end 
    if fin
        if k == 0 % todos los trials del bloque fueron ignorados totalmente
            % viva peron
        else
            Muestras(m).AsinMedia = asinc / k;
            Muestras(m).Sujeto = Trials(t-1).Sujeto;
            Muestras(m).EsDePractica = Trials(t-1).EsDePractica;
            Muestras(m).Delay = Trials(t-1).Delay;
            Muestras(m).HayImagen = Trials(t-1).HayImagen;
            Muestras(m).HaySonido = Trials(t-1).HaySonido;
            Muestras(m).SeguirImagen = Trials(t-1).SeguirImagen;

            m = m + 1;
        end
        
        k = 0;
        asinc = 0;
        if (t == (num_trials + 1))
        	break
        end
    end
    
    ignorar = 0;
    % ignorar cuando no apreto nada
    if Trials(t).PrimerTap == -1
        ignorar = 1;
    end
    
    % ignorar casos donde pega la vuelta (igual estan re afuera de la ventana)
    if Trials(t).Asincronia < -1
        ignorar = 1;
    end
    
    
    if ~ignorar
        asinc = asinc + Trials(t).Asincronia;
        k = k + 1;
    end
        
    unbo = Trials(t).NumBloqueOriginal;
    t = t + 1;
end

%% cuentitas cuentitas
mi=1;
ms=1;
deltas_img = [];
deltas_snd = [];

sujs = unique([Muestras.Sujeto]);
for s = 1:numel(sujs)
    suj = sujs(s);
    
    deltas = [Muestras([Muestras.Sujeto]==suj).AsinMedia];
    
    delta_snd = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 0 & ...
        [Muestras.HaySonido] == 1 ...
    ).AsinMedia];

    if numel(delta_snd) > 0
        deltas_snd(ms) = delta_snd(1);
        ms = ms + 1;
    end
    
    delta_img = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 0 ...
    ).AsinMedia];

    if numel(delta_img) > 0
        deltas_img(mi) = delta_img(1);
        mi = mi + 1;
    end
    
    if ~isempty(deltas) 
        % figure;
        % plot(deltas,'r*');
        % plot(deltas);
        % title(['Sujeto ', num2str(suj)]);
    end
end

%Mostrar el promedio de todos los sujetos con solo imagen y con solo sonido
mean(deltas_snd)
mean(deltas_img)
var(deltas_snd)
var(deltas_img)

[p,h] = ranksum(deltas_snd,deltas_img)
