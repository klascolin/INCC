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

%% arreglar los taps que cayeron en el bloque siguiente por error
for t = 1 : (num_trials - 1)

  a = t;
  b = t+1;

  if Trials(a).NumBloqueOriginal ~= Trials(b).NumBloqueOriginal
    continue
  end
  
  if Trials(a).PrimerTap ~= -1
    continue
  end
  
  if (Trials(b).Asincronia >= -1)
    continue
  end
  
  %% a y b son del mismo bloque, a no tiene ningun tap y b esta apuradisimo
  %% muevo el primer tap de b como primer tap de a, y el ultimo de b como primero de b
  
  nuevo_a = Trials(b).PrimerTap;
  
  b_unico_tap = (Trials(b).PrimerTap == Trials(b).UltimoTap);
  
  if b_unico_tap
    nuevo_b = -1;
  else
    nuevo_b = Trials(b).UltimoTap;
  end
  
  Trials(a).PrimerTap = nuevo_a;
  Trials(a).UltimoTap = nuevo_a;
  
  Trials(b).PrimerTap = nuevo_b;
  Trials(b).UltimoTap = nuevo_b;
  
  %% recalculo asincronias
  Trials(a).Asincronia = Trials(a).PrimerTap - Trials(a).TiempoObjetivo;
  Trials(b).Asincronia = Trials(b).PrimerTap - Trials(b).TiempoObjetivo;
end


%% calcular muestras (promedio de cada bloque)
Muestras = [];
t = 1;
m = 1;
k = 0;
asincs_bloque = [];

asinc = 0;
unbo = Trials(1).NumBloqueOriginal;
while t <= (num_trials + 1)

    if t == (num_trials + 1) || unbo ~= Trials(t).NumBloqueOriginal

        if k ~=0 
            
            Muestras(m).StdBloque = std(asincs_bloque);
            Muestras(m).AsinMedia = asinc / k;
            Muestras(m).Sujeto = Trials(t-1).Sujeto;
            Muestras(m).EsDePractica = Trials(t-1).EsDePractica;
            Muestras(m).Delay = Trials(t-1).Delay;
            Muestras(m).HayImagen = Trials(t-1).HayImagen;
            Muestras(m).HaySonido = Trials(t-1).HaySonido;
            Muestras(m).SeguirImagen = Trials(t-1).SeguirImagen;
            Muestras(m).Accuracy = 1 - (ignorados/(k+ignorados));
            Muestras(m).t = tiempos;
            
            Muestras(m).Tiempo = Trials(t-1).Tiempo;
            Muestras(m).TiempoObjetivo = Trials(t-1).TiempoObjetivo;
            Muestras(m).NumBloqueOriginal = Trials(t-1).NumBloqueOriginal;
            m = m + 1;
        end
        
        asincs_bloque = [];
        k = 0;
        asinc = 0;
        if (t == (num_trials + 1))
        	break
        end
    end
    
    ignorados = 0;
    % ignorar cuando no apreto nada
    if Trials(t).PrimerTap == -1
        ignorados = ignorados + 1;
    end
    
    % ignorar casos donde pega la vuelta (igual estan re afuera de la ventana)
    if abs(Trials(t).Asincronia) > 0.5
        ignorados = ignorados + 1;
    end
    
    
    if ignorados == 0
        asinc = asinc + Trials(t).Asincronia;
        asincs_bloque = [asincs_bloque, Trials(t).Asincronia];
        k = k + 1;
        tiempos(k) = Trials(t).Asincronia;
    end
        
    unbo = Trials(t).NumBloqueOriginal;
    t = t + 1;
end
%% RECONSTRUYENDO LOS SIGNOS DEL DELAY

ds = [0.1, 0.3, 0.4];

corte = [];
es_negativo = [];
es_positivo = [];
es_practica = [];

for segu = 1:2
    for iid = 1:3
        eee = [Muestras( ...
                [Muestras.EsDePractica] == 0 & ...
                [Muestras.Delay] == ds(iid) & ...
                [Muestras.SeguirImagen] == (segu-1) & ...
                [Muestras.HayImagen] == 1 & ...
                [Muestras.HaySonido] == 1)];
            
        jose = [];
        for e = 1: numel(eee)
            jose(e) = [0.5 - (eee(e).Tiempo - eee(e).TiempoObjetivo)];
        end

        m = mean(jose);
        d = ds(iid);
        s = (segu-1);
        %disp([m, d, s]);
        corte(iid, segu) = m;
        
        for i = 1:numel(Muestras)
            es_practica(Muestras(i).NumBloqueOriginal) = Muestras(i).EsDePractica;
            
            if Muestras(i).Delay == ds(iid) && Muestras(i).SeguirImagen == (segu-1)
                delay_es_negativo = ( ...
                    (Muestras(i).EsDePractica == 0) & ...
                    (Muestras(i).Delay == ds(iid)) & ...
                    (Muestras(i).SeguirImagen == (segu-1)) & ...
                    (Muestras(i).HayImagen == 1) & ...
                    (Muestras(i).HaySonido == 1) & ...
                    ((0.5 - (Muestras(i).Tiempo - Muestras(i).TiempoObjetivo) > corte(iid, segu)) ~= Muestras(i).SeguirImagen) ...
                );

                delay_es_positivo = ( ...
                    (Muestras(i).EsDePractica == 0) & ...
                    (Muestras(i).Delay == ds(iid)) & ...
                    (Muestras(i).SeguirImagen == (segu-1)) & ...
                    (Muestras(i).HayImagen == 1) & ...
                    (Muestras(i).HaySonido == 1) & ...
                    ((0.5 - (Muestras(i).Tiempo - Muestras(i).TiempoObjetivo) > corte(iid, segu)) == Muestras(i).SeguirImagen) ...
                );

                es_negativo(Muestras(i).NumBloqueOriginal) = delay_es_negativo;
                es_positivo(Muestras(i).NumBloqueOriginal) = delay_es_positivo;
            end
        end
    end
end


% arreglar
for i = 1:numel(Muestras)
    b = Muestras(i).NumBloqueOriginal;
    
    if es_negativo(b)
        Muestras(i).Delay = -1 * abs(Muestras(i).Delay);
    end
end



%% cuentitas cuentitas
mi=1;
ms=1;
mc0=1;
mc1=1;
mc2=1;
mc3=1;
mc4=1;
mc5=1;
mc6=1;
mc7=1;
mc8=1;
mc9=1;
mc10=1;
mc11=1;
mc12=1;
mc13=1;
deltas = cell(1,1);
deltas_img = [];
deltas_snd = [];
deltas_combinados_0 = [];
m_accuracy = cell(1,1);
tiempos = []


sujs = unique([Muestras.Sujeto]);
for s = 1:numel(sujs)
    suj = sujs(s);
    
    %bloques de sonido y su accuracy
    delta_snd = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 0 & ...
        [Muestras.HaySonido] == 1 ...
    ).AsinMedia];
    
   
    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 0 & ...
        [Muestras.HaySonido] == 1 ...
    ).Accuracy];
    
    if numel(delta_snd) > 0
        deltas{1}(ms) = delta_snd(1);
        m_accuracy{1}(ms) = accuracy;
        ms = ms + 1;
    end
    
    %bloques de imagen y su accuracy
    delta_img = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 0 ...
    ).Accuracy];


    if numel(delta_img) > 0
        deltas{2}(mi) = delta_img(1);
        m_accuracy{2}(mi) = accuracy;
        mi = mi + 1;
    end
    
    %bloques combinados +0 y su accuracy
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0 & ...
        [Muestras.SeguirImagen] == 0 ... 
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0 & ...
        [Muestras.SeguirImagen] == 0 ... 
    ).Accuracy];

    if numel(delta_c0) > 0
        deltas{3}(mc0) = delta_c0(1);
        m_accuracy{3}(mc0) = accuracy(1);
        mc0 = mc0 + 1;
    end
    
     %bloques combinados +0.1 y su accuracy(seguir Imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{4}(mc1) = delta_c0(1);
        m_accuracy{4}(mc1) = accuracy(1);
        mc1 = mc1 + 1;
    end
    
     %bloques combinados +0.3 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ... 
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{5}(mc2) = delta_c0(1);
        m_accuracy{5}(mc2) = accuracy(1);
        mc2 = mc2 + 1;
    end
    
     %bloques combinados +0.4 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{6}(mc3) = delta_c0(1);
        m_accuracy{6}(mc3) = accuracy(1);
        mc3 = mc3 + 1
    end
    
    
     %bloques combinados +0.4 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{7}(mc4) = delta_c0(1);
        m_accuracy{7}(mc4) = accuracy(1);
        mc4 = mc4 + 1;
    end
    
    
    
     %bloques combinados +0.3 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{8}(mc5) = delta_c0(1);
        m_accuracy{8}(mc5) = accuracy(1);
        mc5 = mc5 + 1;
    end
    
    
    
     %bloques combinados +0.1 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{9}(mc6) = delta_c0(1);
        m_accuracy{9}(mc6) = accuracy(1);
        mc6 = mc6 + 1;
    end
    
      %bloques combinados +0 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{10}(mc7) = delta_c0(1);
        m_accuracy{10}(mc7) = accuracy(1);
        mc7 = mc7 + 1;
    end
    
    
%     CAMBIAR INDICES!    
    %bloques combinados -0.4 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 1 & ...
        [Muestras.Delay] == -0.4   ...
       ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 1 & ...
        [Muestras.Delay] == -0.4 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        
        deltas{11}(mc8) = delta_c0(1);
        m_accuracy{11}(mc8) = accuracy(1);
        mc8 = mc8 + 1;
    end
    
    %bloques combinados -0.4 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 0 & ...
        [Muestras.Delay] == -0.4   ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 0 & ...
        [Muestras.Delay] == -0.4 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{12}(mc9) = delta_c0(1);
        m_accuracy{12}(mc9) = accuracy(1);
        mc9 = mc9 + 1;
    end
    
    %bloques combinados -0.3 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 1 & ...
        [Muestras.Delay] == -0.3   ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 1 & ...
        [Muestras.Delay] == -0.3 ...
    ).Accuracy];


    if numel(delta_c0) > 0
       
        deltas{13}(mc10) = delta_c0(1);
        m_accuracy{13}(mc10) = accuracy(1);
        mc10 = mc10 + 1;
    end
    
     %bloques combinados -0.3 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 0 & ...
        [Muestras.Delay] == -0.3   ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 0 & ...
        [Muestras.Delay] == -0.3 ...
    ).Accuracy];


    if numel(delta_c0) > 0
      
        deltas{14}(mc11) = delta_c0(1);
        m_accuracy{14}(mc11) = accuracy(1);
        mc11 = mc11 + 1;
    end
    
     %bloques combinados -0.1 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 1 & ...
        [Muestras.Delay] == -0.1  ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 1 & ...
        [Muestras.Delay] == -0.1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
      
        deltas{15}(mc12) = delta_c0(1);
        m_accuracy{15}(mc12) = accuracy(1);
        mc12 = mc12 + 1;
    end
    
     %bloques combinados -0.1 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 0 & ...
        [Muestras.Delay] == -0.1  ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == 0 & ...
        [Muestras.Delay] == -0.1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
       
        deltas{16}(mc13) = delta_c0(1);
        m_accuracy{16}(mc13) = accuracy(1);
        mc13 = mc13 + 1;
    end
    
    if ~isempty(deltas) 
        % figure;
        % plot(deltas,'r*');
        % plot(deltas);
        % title(['Sujeto ', num2str(suj)]);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Analisis de datos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tit = cell(1,1);
tit{1} = 'Sound';
tit{2} = 'Image';
tit{3} = 'AV(target sound)';
tit{4} = 'AV(target image) +0.1';
tit{5} = 'AV(target image) +0.3';
tit{6} = 'AV(target image) +0.4';
tit{7} = 'AV(target sound) -0.4';
tit{8} = 'AV(target sound) -0.3';
tit{9} = 'AV(target sound) -0.1';
tit{10} = 'AV(target image)';
tit{11} = 'AV(target image) -0.4';
tit{12} = 'AV(target sound) +0.4';
tit{13} = 'AV(target image) -0.3';
tit{14} = 'AV(target sound) +0.3';
tit{15} = 'AV(target image) -0.1';  
tit{16} = 'AV(target sound) +0.1';


for i=1:16
    disp(tit{i})
    %Distribucion de las muestras(histograma normalizado)

    [f,x] = hist(deltas{i},7);
    figure;
    bar(x,f/sum(f))
    hold on;
    line([mean(deltas{i}) mean(deltas{i})], [0  max(x)])
    hold off
    title(tit{i})
    
    %One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
    disp('Kolmogorov normality test')
    t = kstest(deltas{i})

    %Boxplot
    figure;
    boxplot(deltas{i})
    title('Boxplot tiempos de respuesta Delay +0 target image')

    %Medidas de centralidad
    disp('prom')
    mean(deltas{i})
    disp('mediana')
    median(deltas{i})

    %Medidas de dispersion, estabilidad de la sincronia
    disp('varianza')
    var(deltas{i})

    %Medidas de precision en la tarea
    disp('accuracy')
    mean(m_accuracy{i})

end


%Inspeccion de la evolucion de los sujetos
% tiempos = cell(1,1);
% for s = 1:numel(sujs)
%     suj = sujs(s);
%     i = 1;
%     t =  [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == 0 & ...
%         [Muestras.SeguirImagen] == 0 ... 
%     ).t];
% figure;
%     h=plot(t,'bo-');
%     title('Trials target sound delay +0');
%     set(h,'linewidth',2);
%    
% end
% 
% tiempos = cell(1,1);
% for s = 1:numel(sujs)
%     suj = sujs(s);
%     i = 1;
%     t =  [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == 0 & ...
%         [Muestras.SeguirImagen] == 1 ... 
%     ).t];
% figure;
%     h=plot(t,'go-');
%     title('Trials target image delay +0');
%     set(h,'linewidth',2);
%    
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Comparacion de los resultados:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('imagen vs sonido')
[p,h] = ranksum(deltas{1},deltas{2})

delta_h0 =  abs(mean(deltas{1}) - mean(deltas{2}))
y = Permutation_Test(10000,deltas{1},deltas{2},delta_h0)


disp('imagen vs delay+0 target sound')
[p,h] = ranksum(deltas{3},deltas{2})

delta_h0 = abs(mean(deltas{3}) - mean(deltas{2}))
y = Permutation_Test(10000,deltas{3},deltas{2},delta_h0)

disp('delay+0 target sound vs sonido')
[p,h] = ranksum(deltas{3},deltas{1})

delta_h0 = abs(mean(deltas{3}) - mean(deltas{1}))
y = Permutation_Test(10000,deltas{3},deltas{1},delta_h0)

disp('delay0 target img vs sonido')
[p,h] = ranksum(deltas{10},deltas{1})

delta_h0 = abs(mean(deltas{10}) - mean(deltas{1}))
y = Permutation_Test(10000,deltas{10},deltas{1},delta_h0)

disp('delay0 target img  vs sonido')
[p,h] = ranksum(deltas{10},deltas{2})

delta_h0 = abs(mean(deltas{10}) - mean(deltas{2}))
y = Permutation_Test(10000,deltas{10},deltas{2},delta_h0)

disp('delay0(img) vs delay0(snd)')
[p,h] = ranksum(deltas{10},deltas{3})

delta_h0 = abs(mean(deltas{10}) - mean(deltas{3}))
y = Permutation_Test(10000,deltas{10},deltas{3},delta_h0)

disp('+0.1 +0.3 +0.4 target image')
x = [deltas{4};deltas{5};deltas{6}]
p = kruskalwallis(transpose(x))

disp('-0.1 -0.3 -0.4 target image')
x = [deltas{15};deltas{13};deltas{11}]
p = kruskalwallis(transpose(x))

disp('-0.1 -0.3 -0.4 target sound')
x = [deltas{9};deltas{8};deltas{7}]
p = kruskalwallis(transpose(x))


disp('+0.1 +0.3 +0.4 target sound')
x = [deltas{16};deltas{14};deltas{12}]
p = kruskalwallis(transpose(x))


disp('+0.1 target image vs +0.1 target sound')
[p,h] = ranksum(deltas{4},deltas{16})

delta_h0 = abs(mean(deltas{4}) - mean(deltas{16}))
y = Permutation_Test(10000,deltas{4},deltas{16},delta_h0)


disp('+0.3 target image vs +0.3 target sound')
[p,h] = ranksum(deltas{5},deltas{16})

delta_h0 = abs(mean(deltas{5}) - mean(deltas{14}))
y = Permutation_Test(10000,deltas{5},deltas{14},delta_h0)


disp('+0.4 target image vs +0.4 target sound')
[p,h] = ranksum(deltas{6},deltas{12})

delta_h0 = abs(mean(deltas{6}) - mean(deltas{12}))
y = Permutation_Test(10000,deltas{6},deltas{12},delta_h0)


%Comparacion de las medias de solo sonido, solo imagen, y sincronia
figure;
y = [mean(deltas{1});mean(deltas{2});mean(deltas{3});mean(deltas{10})];
labels = {'A';'V';'AV(snd)';'AV(img)'}
bar_h=bar(y,0.5)
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',y);
title('Comparacion de las medias de solo sonido, solo imagen, y sincronia')


figure;
v =  [std(deltas{1});std(deltas{2});std(deltas{3});std(deltas{10})]
labels = {'A';'V';'AV(snd)';'AV(img)'}
bar_h = bar(v,0.5)
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',v);
title('Comparacion de los std de solo sonido, solo imagen, y sincronia')




%Comparacion de las medias de target image
figure;
y = [mean(deltas{4});mean(deltas{5});mean(deltas{6});mean(deltas{15});mean(deltas{13});mean(deltas{11});mean(deltas{1});mean(deltas{2})];
labels = {'+0.1';'+0.3';'+0.4';'-0.1';'-0.3';'-0.4';'SND';'IMG'}
bar_h=bar(y,0.5)
title('Comparacion medias asincronia target image')
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',y);

figure;
v =  [std(deltas{4});std(deltas{5});std(deltas{6});std(deltas{15});std(deltas{13});std(deltas{11})]
labels = {'+0.1';'+0.3';'+0.4';'-0.1';'-0.3';'-0.4'}
bar_h = bar(v,0.5)
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',v);
title('Comparacion de std de asincronia target image')


%Comparacion de las medias de target sound
figure;
y = [mean(deltas{9});mean(deltas{8});mean(deltas{7});mean(deltas{16});mean(deltas{14});mean(deltas{12});mean(deltas{1});mean(deltas{2})];
labels = {'-0.1';'-0.3';'-0.4';'+0.1';'+0.3';'+0.4';'SND';'IMG'}
bar_h=bar(y,0.5)
title('Comparacion medias asincronia target sound')
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',y);

figure;
v =  [std(deltas{9});std(deltas{8});std(deltas{7});std(deltas{16});std(deltas{14});std(deltas{12})]
labels = {'-0.1';'-0.3';'-0.4';'+0.1';'+0.3';'+0.4'}
bar_h = bar(v,0.5)
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',v);
title('Comparacion de std de asincronia target sound')

[p,h] = ranksum(deltas{15},deltas{13})
[p,h] = ranksum(deltas{13},deltas{11})





%%%% graficos 2.0 (?) con StdBloque

vsolo = [];
vsolo(1) = mean([Muestras( ...
    [Muestras.EsDePractica] == 0 & ...
    [Muestras.HayImagen] == 0 & ...
    [Muestras.HaySonido] == 1 ...
).StdBloque]);
vsolo(2) = mean([Muestras( ...
    [Muestras.EsDePractica] == 0 & ...
    [Muestras.HayImagen] == 1 & ...
    [Muestras.HaySonido] == 0 ...
).StdBloque]);


queTarget={'sound', 'image'};
queTargetMini={'SND', 'IMG'};
delays = [-0.1, -0.3, -0.4, 0.1, 0.3, 0.4];
for sigueImg = 0:1
  v = [];
  for i = 1 : 6
    v(i) = mean([Muestras( ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.SeguirImagen] == sigueImg & ...
        [Muestras.Delay] == delays(i) ...
    ).StdBloque]);
  end
  v(7) = vsolo(sigueImg+1);
  figure;
  labels = {'-0.1';'-0.3';'-0.4';'+0.1';'+0.3';'+0.4';queTargetMini(sigueImg+1)};
  bar_h = bar(v,0.5)
  set(gca,'xticklabel',labels)
  bar_child=get(bar_h,'Children');
  set(bar_child,'CData',v);
  title(['Comparacion de std de asincronia, target', queTarget(sigueImg+1) ]);

end

v = [];
v(1) = vsolo(1);
v(2) = vsolo(2);
v(3) = mean([Muestras( ...
    [Muestras.EsDePractica] == 0 & ...
    [Muestras.HayImagen] == 1 & ...
    [Muestras.HaySonido] == 1 & ...
    [Muestras.Delay] == 0.0 & ...
    [Muestras.SeguirImagen] == 0 ...
).StdBloque]);
v(4) = mean([Muestras( ...
    [Muestras.EsDePractica] == 0 & ...
    [Muestras.HayImagen] == 1 & ...
    [Muestras.HaySonido] == 1 & ...
    [Muestras.Delay] == 0.0 & ...
    [Muestras.SeguirImagen] == 1 ...
).StdBloque]);

figure;
labels = {'A'; 'V'; 'AV(snd)';'AV(img)'}
bar_h = bar(v,0.5)
set(gca,'xticklabel',labels)
bar_child=get(bar_h,'Children');
set(bar_child,'CData',v);
title(['Comparacion v2 de los std de solo sonido, solo imagen y sincronia'])
