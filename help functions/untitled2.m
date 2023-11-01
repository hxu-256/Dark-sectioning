
m=3;n=3;
for k = 1 : m*n       
        i = mod(k,m)+1;
        j = floor(k/m)+1;
        [i,j]
end