function [dff_interp, denoisesig, deconvsig, options]=deconvsig_cb_mod(dff)
nanx=isnan(dff(1,:));
t=1:numel(dff(1,:));
dff_interp=dff;
for i=1:size(dff,1)
    dff_interp(i,nanx)=interp1(t(~nanx),dff(i,~nanx),t(nanx));
end
if isnan(dff_interp(1,1))==1
    for i=1:length(dff)
        if isnan(dff(1,i))==0
            break
        end
    end
    for n=1:i-1
        dff_interp(:,n)=dff(:,i);
    end
end

m=max(find(~isnan(dff_interp(1,:))));
for i=m+1:length(dff_interp)
        dff_interp(:,i)=dff_interp(:,m);
end
for i=1:size(dff,1)
       [denoisesig(i,:) deconvsig(i,:),options{i}]=deconvolveCa(dff_interp(i,:)','ar1','optimize_pars','optimize_b'); 
end
thenans=find(isnan(dff(1,:)));
denoisesig(:,thenans)=nan;
deconvsig(:,thenans)=nan;
dff_interp(:,thenans)=nan;
end
%deconv_smooth = deconvsig_smooth;
%deconv_smooth[find(deconv_smooth<0.05)=0;