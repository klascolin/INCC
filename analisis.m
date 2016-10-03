format long g;

f = fopen('data/bloques.csv');
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

while 1    
    i = i + 1;
    suj = fscanf(f, '%i,', [1 1]);
    if isempty(suj)
       break 
    end
    
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