function String=GenRandomString()

N=ceil(10*rand(40,1));

for j=1:numel(N)
    if N(j)==10
        N(j)=0;
    end
end

L={'A','a','B','b','C','c','D','d','E','e',...
    'F','f','G','g','H','h','I','i','J','j',...
    'K','k','L','l','M','m','N','n','O','o',...
    'P','p','Q','q','R','r','S','s','T','t',...
    'U','u','V','v','W','w','X','x','Y','y',...
    'Z','z'};

if rand>0.5
    L=L(randperm(numel(L)));
end

Lidcs=round(randi([1 numel(L)-1],2,1)+rand);

letter_pair=[L{Lidcs(1)} L{Lidcs(2)}];

number_pair1=num2str(N(1)*10+N(2));
number_pair2=num2str(N(12)*10+N(13));


if numel(number_pair1)==1
    number_pair1=['0' number_pair1];
end

if numel(number_pair2)==1
    number_pair2=['0' number_pair2];
end

String=[letter_pair '-' number_pair1 '-' number_pair2];