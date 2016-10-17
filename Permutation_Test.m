

function y =  Permutation_Test(prms,sample1,sample2,h0)
  exitos = 0;
  p = [sample1,sample2];
  for j = 1:prms
    a = p(randperm(numel(sample1)+numel(sample2)));
    set1 = a(1:numel(sample1));
    set2 = a(numel(sample1)+1:numel(p));
    abs(mean(set2)-mean(set1));
    exitos = exitos + (h0 < abs(mean(set1)-mean(set2)));
  end
  y = exitos / prms;
end

