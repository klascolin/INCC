format long g;

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
time_delta = cell(1,1);
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

num_bloques = i;

n_invalidos = 0;
for i = 1 : num_bloques
   
   invalidos = find(time_firstPress{i} == -1);
   n_invalidos = n_invalidos + length(invalidos);
  
   target_time{i}(invalidos) = [];
   time_firstPress{i}(invalidos) = [];
   time_lastPress{i}(invalidos) = [];
   time_delta{i} = time_firstPress{i} - target_time{i};
   
   disp(mean(time_delta{i}))
end
disp(n_invalidos)
