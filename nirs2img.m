function nirs2img(imgFileName, mni, value, doInterp, doXjview, bilateral)
% function nirs2img(imgFileName, mni, value, doInterp, doXjview, bilateral)
%
% This function is to create an image file from the input data. Then the
% image file can be viewed by any fmri image viewing programs such as
% xjview. This function requires function mni2cor and spm
%
% imgFileName: the file name to be saved, e.g. 'testnirs.img'
% mni: Nx3 matrix, each row a coordinate in mni space
% value: Nx1 matrix, each row is the value corresponding to  mni
% doInterp: 1 or 0 , whether or not do linear interpolation to
% smooth data.
% doXjview: 1 or 0, whether or not to view the generated image by xjview
% now
% bilateral: 1 or 0, whether or not the input mni is bilateral or not. If
% bilateral, the first half points are considered as left side. There is no
% interpolation between left and right side.  (This argument is
% useless if doInterp is 0)
%
% output:
%   an image file whose name is specified by input
%
% If you have mni points of probes (instead of channels), you may need to
% convert first. Use function probe2channel
%
% This function will write to a image file which can be viewed by xjview. 
% In xjview, you need to check render view.
% 
% Example:
%     nirs2img('nirs_test.img', mni, value, 1, 1, 0);
%     
% Xu Cui
% 2009/06/11
% last update: 2009/07/06: have an option that left and right do not
% interpolate


%V = spm_vol('templateFile.img');
%M = spm_read_vols(V);
%M = M*0;
M = zeros(41,48,35);

V.mat = [
        -4     0     0    84
     0     4     0  -116
     0     0     4   -56
     0     0     0     1];
cor = mni2cor(mni, V.mat);

distanceToOriginal = sum((repmat([21 29 14], size(cor,1),1) - cor).^2, 2);
distanceToOriginal = min(distanceToOriginal);

if(doInterp)
    
    if(~bilateral)
        [xi,yi,zi] = meshgrid([min(cor(:,1)):max(cor(:,1))], [min(cor(:,2)):max(cor(:,2))], [min(cor(:,3)):max(cor(:,3))]);
        vi = griddata(cor(:,1), cor(:,2), cor(:,3), value, xi, yi, zi);

        cor2 = [xi(:), yi(:), zi(:)];
        value2 = vi(:);
    else
        n = size(cor,1); % # of points
        if mod(n, 2) ~= 0
            n = n-1;
        end
        ind1 = 1:n/2;
        ind2 = (n/2+1):n;
        [xi,yi,zi] = meshgrid([min(cor(ind1,1)):max(cor(ind1,1))], [min(cor(ind1,2)):max(cor(ind1,2))], [min(cor(ind1,3)):max(cor(ind1,3))]);
        vi = griddata(cor(ind1,1), cor(ind1,2), cor(ind1,3), value(ind1), xi, yi, zi);
        cor2 = [xi(:), yi(:), zi(:)];
        value2 = vi(:);
        
        [xi,yi,zi] = meshgrid([min(cor(ind2,1)):max(cor(ind2,1))], [min(cor(ind2,2)):max(cor(ind2,2))], [min(cor(ind2,3)):max(cor(ind2,3))]);
        vi = griddata(cor(ind2,1), cor(ind2,2), cor(ind2,3), value(ind2), xi, yi, zi);
        cor2 = [cor2; xi(:), yi(:), zi(:)];
        value2 = [value2; vi(:)];
    end
else
    cor2 = cor;
    value2 = value;
end

for ii=1:size(cor2,1)
    if sum((cor2(ii,:) - [21    29    14]).^2) > distanceToOriginal - 10  %we only include surface points. By surface we mean the distance to origin is larger than the min distance of original points        
        if(~isnan(value2(ii)))
            if cor2(ii,1)>0 && cor2(ii,2)>0 && cor2(ii,3)>0 & cor2(ii,1)<=41 && cor2(ii,2)<=48 && cor2(ii,3)<=35
                M(cor2(ii,1),cor2(ii,2),cor2(ii,3)) = value2(ii);
            end
        end
    end
end

V.fname = imgFileName;
V.mat = [
        -4     0     0    84
     0     4     0  -116
     0     0     4   -56
     0     0     0     1];
V.dim = [41 48 35];
V.dt = [16 0];
V.n = [1  1];
V.descrip = 'SPM contrast - 2: +1';
V.private = [];
spm_write_vol(V, M);

disp([imgFileName '.img/hdr are saved.'])

if doXjview==1
    xjview(imgFileName)
end
