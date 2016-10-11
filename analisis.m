format long g;

%% Leer CSV
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


%% Meter cada trial en el struct Trials
num_bloques = i;
j = 1;
s = 0;
Trials = struct();
for b = 1 : num_bloques
   if s ~= sujeto(b)
       bloque_del_sujeto = 1;
       s = sujeto(b);
   else
       bloque_del_sujeto = bloque_del_sujeto + 1;
   end
   deltas = time_firstPress{b} - target_time{b};
   deltas(find(deltas < -100000)) = 0;
   delta_bloque(b) = mean(deltas);
   
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
       Trials(j).UltimoTap = time_lastPress{b}(k);

       j = j + 1;    
   end
end

clear sujeto tiempo practica delay img snd target bloque_del_sujeto total_trials target_time time_firstPress time_lastPress f b i j k s num_bloques suj

%% Plot de todos los deltas
k = 1;
m = 1;
deltas_img = [];
deltas_snd = [];
for s = 1000 : 1011
    j = 1;
    deltas = [];

    ultimo_nbo = 0;

	for i = 1 : size(Trials, 2)

	    if Trials(i).Sujeto ~= s % mirar solo un sujeto
	        continue
	    end
	    
	    if Trials(i).PrimerTap == -1 % no apreto nada
	        continue
	    end
	  
	    delta = Trials(i).PrimerTap - Trials(i).TiempoObjetivo;
	    %Si el bloque contiene al menos un trial con delta positivo, entonces lo pongo
	    if delta < -0.5  % sacar picos en -2
	        continue
	    end


	    nbo = Trials(i).NumBloqueOriginal;
        if nbo == ultimo_nbo
            continue
        end
        ultimo_nbo = nbo;

        if ~Trials(i).HayImagen && Trials(i).HaySonido  && ~Trials(i).EsDePractica 
        	deltas_snd(k) = delta_bloque(nbo)
        	k = k + 1
        end

        if Trials(i).HayImagen && ~Trials(i).HaySonido  && ~Trials(i).EsDePractica
        	deltas_img(m) = delta_bloque(nbo);
        	m = m + 1
        end

	    deltas(j) = delta_bloque(nbo);
	    
        if delta_bloque(nbo) < -0.5
            disp('pifie feo aca')
            disp(Trials(i).Delay)
            disp(Trials(i).SeguirImagen)
            disp(Trials(i).HayImagen)
            disp(Trials(i).HaySonido)
        end
        j = j + 1;
	end
    if ~isempty(deltas)
         figure;
         plot(deltas);
    end
end
%Mostrar el promedio de todos los sujetos con solo imagen y con solo sonido
mean(deltas_snd)
mean(deltas_img)
