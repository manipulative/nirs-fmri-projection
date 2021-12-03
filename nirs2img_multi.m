function nirs2img_multi(imgFileName, mni, value, set, doInterp)
% a modified function of Cui Xu's nirs2img. It could now construct brain
% plots one set by one set, avoiding the separate channel sets interpolate
% to one another. And optimized for single-channel plot.
% Input : imgFileName: the name of saved brain plot
%         mni: mni coordinates of each channel
%         value: plotted value of each channel
%         set: set ID of each channel, as [1 1 1 2 2 2 3 3 3]
%         doInterp: whether interpolate 1 or 0
% Output : a hdr/img file
% By Siyuan Zhou, 2021/11

%% main
% initial
voxel_total = zeros(41,48,35);
Vt.fname = imgFileName;
Vt.mat = [
    -4     0     0    84
    0     4     0  -116
    0     0     4   -56
    0     0     0     1];
Vt.dim = [41 48 35];
Vt.dt = [16 0];
Vt.n = [1  1];
Vt.descrip = 'SPM contrast - 2: +1';
Vt.private = [];

set = set - min(set) + 1;

% seperate sets
for setID = 1:max(set)
    
    mask = set==setID;
    submni = mni(mask,:);
    subvalue = value(mask);
    
    voxel_set = nirs2img_sub(submni,subvalue,doInterp);
    voxel_total = voxel_total + voxel_set;
end

Mt = voxel_total;
spm_write_vol(Vt, Mt);



%% helper function
% basic nirs2img function, modifed from Cui's
    function voxel_sub = nirs2img_sub(mni, value, doInterp)
        
        M = zeros(41,48,35);
        
        V.mat = [
            -4     0     0    84
            0     4     0  -116
            0     0     4   -56
            0     0     0     1];
        
        % At first design I want extented all channels, but thid procedure
        % would result in a new kind of artifacts.
        %         mni_new = [];value_new = [];
        %         for jj = 1:size(mni,1)
        %             [mni_temp value_temp] = extendCH(mni(jj,:),value(jj));
        %             mni_new = [mni_new; mni_temp];
        %             value_new = [value_new; value_temp];
        %         end
        %         mni = mni_new;value = value_new;
        
        cor = mni2cor(mni, V.mat);
        
        
        
        distanceToOriginal = sum((repmat([21 29 14], size(cor,1),1) - cor).^2, 2);
        distanceToOriginal = min(distanceToOriginal);
        
        if(doInterp)
            
            [xi,yi,zi] = meshgrid([min(cor(:,1)):max(cor(:,1))], [min(cor(:,2)):max(cor(:,2))], [min(cor(:,3)):max(cor(:,3))]);
            vi = griddata(cor(:,1), cor(:,2), cor(:,3), value, xi, yi, zi);
            
            cor2 = [xi(:), yi(:), zi(:)];
            value2 = vi(:);
            
            if isempty(value2)
                cor2 = cor;
                value2 = value;
                
                mni_new = [];value_new = [];
                for jj = 1:size(cor2,1)
                    [mni_temp value_temp] = extendCH(cor2(jj,:),value2(jj));
                    mni_new = [mni_new; mni_temp];
                    value_new = [value_new; value_temp];
                end
                cor2 = mni_new;value2 = value_new;
            end
            
        else
            cor2 = cor;
            value2 = value;
            
            mni_new = [];value_new = [];
                for jj = 1:size(cor2,1)
                    [mni_temp value_temp] = extendCH(cor2(jj,:),value2(jj));
                    mni_new = [mni_new; mni_temp];
                    value_new = [value_new; value_temp];
                end
                cor2 = mni_new;value2 = value_new;
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
        
        voxel_sub = M;
        
    end

% convert mni to coordinates
    function coordinate = mni2cor(mni, T)
        
        if isempty(mni)
            coordinate = [];
            return;
        end
        
        if nargin == 1
            T = ...
                [-4     0     0    84;...
                0     4     0  -116;...
                0     0     4   -56;...
                0     0     0     1];
        end
        
        coordinate = [mni(:,1) mni(:,2) mni(:,3) ones(size(mni,1),1)]*(inv(T))';
        coordinate(:,4) = [];
        coordinate = round(coordinate);
        return;
    end

% extend single-channel area
    function [corT valueT] = extendCH(cor,value)
        % Note: only one cor and value shall be input
        extendMat1 = [1 0 0; 0 1 0; 0 0 1;...
            1 1 0; 1 0 1; 0 1 1;
            1 1 1;...
            1 -1 0; 1 0 -1; 0 1 -1;...
            1 -1 1;1 -1 -1;1 1 -1];
        extendMat2 = -extendMat1;
        extendMat = [extendMat1; extendMat2];
        
        cor_ext = cor + extendMat;
        cor_ext = [cor_ext; cor];
        value_ext = repmat(value,size(cor_ext,1),1);
        
        corT = cor_ext;
        valueT = value_ext;
        
    end


end
