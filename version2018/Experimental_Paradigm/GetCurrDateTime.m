function datetimestr=GetCurrDateTime()
c=clock;
yyyy=num2str(c(1));
mm=num2str(c(2));
if numel(mm)==1
    mm=['0' mm];
end
dd=num2str(c(3));
if numel(dd)==1
    dd=['0' dd];
end
hh=num2str(c(4));
if numel(hh)==1
    hh=['0' hh];
end
min=num2str(c(5));
datetimestr=[yyyy '_' mm '_' dd '_' hh '-' min];
end