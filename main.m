%% clear all and instantiate variables
clc
clear all
debug = false; %if True display all the images (intermediate passages and choices) else displays only most relevant images
auto_selection = true; %if true automatic line selection, if false manual line selection
ceck_with_second_image = false;  %if true it passes the second image to the algorithm

% global variables used in other functions
global WINDOW_SIZE LINES_ORIZONTAL_LEFT LINES_VERTICAL_LEFT LINES_ORIZONTAL_RIGHT ...
        LINES_VERTICAL_RIGHT LINES_VERTICAL_EXTRA LINES_ORIZONTAL_EXTRA TOP_LINE_LW TOP_LINE_RW ...
        IMG_MAX_SIZE_X IMG_MAX_SIZE_Y IMG_MAX_SIZE
       
% constants for line selection

LINES_ORIZONTAL_LEFT = 1;
LINES_VERTICAL_LEFT = 2;
LINES_ORIZONTAL_RIGHT = 3;
LINES_VERTICAL_RIGHT = 4;
LINES_VERTICAL_EXTRA = 5;
LINES_ORIZONTAL_EXTRA = 6;
TOP_LINE_LW = 7;
TOP_LINE_RW = 8;
IMG_MAX_SIZE_X;
IMG_MAX_SIZE_Y;
IMG_MAX_SIZE;
% length of the longside of horizontal faces
WINDOW_SIZE = 1000;   %1 meter

%% Open the Image

if ceck_with_second_image
    image_input = 'Image2.jpg';
    auto_selection = false; 
else
    image_input = 'Image1.jpg';
end 

im_rgb = imread(image_input);
IMG_MAX_SIZE = max(size(im_rgb));
[x, y] =size(im_rgb);
IMG_MAX_SIZE_X = x;
IMG_MAX_SIZE_Y = y/3; %fro RGB

if debug
    figure(1), imshow(im_rgb); title('Original Image');
end
%% Image GrayScale Conversion
im_gray = rgb2gray(im_rgb);

if debug
    figure(1),imshow(im_gray);title('Grayscale Image');
end

%% Image shadow and light normalization
im_gray_norm = adapthisteq(im_gray);

if debug
    im_gray_imadjust = imadjust(im_gray);
    im_gray_histeq = histeq(im_gray);
    montage({im_gray, im_gray_imadjust, im_gray_histeq, im_gray_norm, adapthisteq(im_gray_norm)},'Size',[1 5])
    title("Original Image and Enhanced Images using imadjust, histeq, and adapthisteq")
end

% for a better result I decided to apply the normalization twice
im_gray_norm = adapthisteq(im_gray_norm);

if debug
    figure(1),imshow(im_gray_norm);title('Grayscale Image Twice normalized');
end

%% Line extraction
lines = extract_lines(im_gray_norm, debug, "canny", ceck_with_second_image);

% plot lines on the image
draw_lines(lines, im_rgb);

%% Stratification approach:
% - compute affine reconstruction
% l_inf -> l_inf (the line at infinity must be mapped to itself)
% H_r_aff = [1  0  0
%            0  1  0
%            l1 l2 l3] where the last row is l_inf'

% Extract parallel lines

[line_ind_olw, lines_olw] = pick_lines(lines,im_rgb,"Select two or more orizontal parallel lines on left window (then press enter):",auto_selection, LINES_ORIZONTAL_LEFT);
[line_ind_vlw, lines_vlw] = pick_lines(lines,im_rgb,"Select two or more vertical parallel lines on left window (then press enter):", auto_selection, LINES_VERTICAL_LEFT);
[line_ind_orw, lines_orw] = pick_lines(lines,im_rgb,"Select two or more orizontal parallel lines on right window (then press enter):", auto_selection, LINES_ORIZONTAL_RIGHT);
[line_ind_vrw, lines_vrw] = pick_lines(lines,im_rgb,"Select two or more vertical parallel lines on right window (then press enter):", auto_selection, LINES_VERTICAL_RIGHT);
[line_ind_vextra, lines_vextra] = pick_lines(lines,im_rgb,"Select two or more vertical parallel lines (then press enter):", auto_selection, LINES_VERTICAL_EXTRA);
[line_ind_oextra, lines_oextra] = pick_lines(lines,im_rgb,"Select two or more orizontal parallel lines (then press enter):", auto_selection, LINES_ORIZONTAL_EXTRA);
% plot selected lines
line_ind = [line_ind_olw, line_ind_vlw, line_ind_orw, line_ind_vrw, line_ind_oextra];
draw_lines(lines(1,line_ind), im_rgb);

%% extract the line at infinite

% get vanishing points
vp_olw = getVp(lines_olw);
vp_vlw = getVp(lines_vlw);
vp_orw = getVp(lines_orw);
vp_vrw = getVp(lines_vrw);
%vp_vextra = getVp(lines_vextra);
vp_oextra = getVp(lines_oextra);

%vp = [vp_olw vp_vlw vp_orw vp_vrw vp_vextra vp_oextra];
vp = [vp_olw vp_vlw vp_orw vp_vrw, vp_oextra];

%visualize vanishing lines and points
draw_lines_infinity(lines(1,line_ind), im_rgb, vp);
    
    
% fit the line through these points
%l_inf_prime = fitLine([vp_olw vp_vlw vp_orw vp_vrw],false);
l_inf_prime = fitLine([vp_olw vp_oextra],true);

%% compute H_r_aff

H_r_aff = [1 0 0; 0 1 0; l_inf_prime(1) l_inf_prime(2) l_inf_prime(3)];

% Transform the image
img_affine = transform_and_show(H_r_aff, im_rgb, "Affine rectification XZ");


%% Metric rectification
% In order to perform metric rectification from an affine transformation we
% need perpendicular lines for constraints of the C_star_inf'

perpLines = [createLinePairsFromTwoSets(lines_olw, lines_oextra), createLinePairsFromTwoSets(lines_olw, lines_vextra)];

% transform lines according to H_r_aff since we need to start from an affinity
perpLines = transformLines(H_r_aff, perpLines);

% Ceck if transformed lines are good (TODO)

%% compute H through linear reg starting from affine transformation

ls = [];
ms = [];
index = 1;
for ii = 1:2:size(perpLines,2)
    ls(:, index) = perpLines(:, ii);
    ms(:, index) = perpLines(:, ii+1);
    index = index + 1;
end

% fit the transformation from affinity to euclidean
H_a_e = compute_H_aff(ls,ms, debug);

%% Transform from affinity
img_affine_scaled = imresize(img_affine, 0.2);
tform = projective2d(H_a_e.');

% apply the transformation to img
outputImage = imwarp(img_affine_scaled, tform);
R = rotx(deg2rad(180));
tform = projective2d(R.');
outputImage = imwarp(outputImage, tform);
outputImage = imrotate(imresize(outputImage, [IMG_MAX_SIZE_X, IMG_MAX_SIZE_Y]), -88);

figure();
imshow(outputImage);
title('Affine transformation');

%% Complete Transformation

Resize = [0.2 0 0; 0 0.2 0; 0 0 1];
O = rotz(deg2rad(-88));
H_r_complete = Resize * R * O * H_a_e * H_r_aff;
 
tform_complete = projective2d(H_r_complete.');
outputImage_final = imwarp(im_rgb, tform_complete);
%outputImage_final = imresize(outputImage_final, [IMG_MAX_SIZE_X, IMG_MAX_SIZE_Y]);

figure();
imshow(outputImage_final);
title('Affine transformation');

%% metric
H_metric = [1 0 0; 0 164/109 0; 0 0 1];
tform_metric = projective2d(H_metric.');
outputImage_metric = imwarp(outputImage_final, tform_metric);

figure();
imshow(outputImage_metric);
title('Metric reconstruction');

H_fin = H_metric * H_r_complete;

%% Estimate calibtation matrix K
% We can use skew simmetry but not natural camera assumption!!!
% the matrix we're looking for is:
%               |w1  0   w3|
%           w=  |0   w2  w4|
%               |w3  w4  w5|
%We need 5 constraint 3 form vanishing points and 2 form H matrix

%calculation of K from IAC using constraints (p226)
A = [vp_olw(1)*vp_vlw(1), vp_olw(2)*vp_vlw(2),   vp_olw(1)+vp_vlw(1),  vp_olw(2)+vp_vlw(2),  1;
    vp_olw(1)*vp_oextra(1),   vp_olw(2)*vp_oextra(2),  vp_olw(1)+vp_oextra(1),   vp_olw(2)+vp_oextra(2),   1;
    vp_oextra(1)*vp_vlw(1),   vp_oextra(2)*vp_vlw(2),  vp_oextra(1)+vp_vlw(1),   vp_oextra(2)+vp_vlw(2),   1;
    H_fin(1,1)*H_fin(2,1),  H_fin(1,2)*H_fin(2,2),  H_fin(1,3)*H_fin(2,1)+H_fin(1,1)*H_fin(2,3), H_fin(1,3)*H_fin(2,2)+H_fin(1,2)*H_fin(2,3), H_fin(1,3)*H_fin(2,3)];
aus = null(A);
IAC = [aus(1), 0, aus(3); 0, aus(2), aus(4); aus(3),aus(4),aus(5)];
K_g = chol(IAC);
K_g = inv(K_g);
K_g = K_g/K_g(3,3);

% %% Estimate calibtation matrix K second attempt not working!!!
% % We can use skew simmetry but not natural camera assumption!!!
% % the matrix we're looking for is:
% 
% %calculation of K from IAC using constraints (p226)zz
% A = [vp_olw(1)*vp_vlw(1), vp_olw(2)*vp_vlw(2),   vp_olw(1)+vp_vlw(1),  vp_olw(2)+vp_vlw(2),  1;
%     vp_olw(1)*vp_oextra(1),   vp_olw(2)*vp_oextra(2),  vp_olw(1)+vp_oextra(1),   vp_olw(2)+vp_oextra(2),   1;
%     vp_oextra(1)*vp_vlw(1),   vp_oextra(2)*vp_vlw(2),  vp_oextra(1)+vp_vlw(1),   vp_oextra(2)+vp_vlw(2),   1;
%     H_fin(1,1)*H_fin(2,1), H_fin(1,2)*H_fin(2,2),  H_fin(1,3)*H_fin(2,1)+H_fin(1,1)*H_fin(2,3), H_fin(1,3)*H_fin(2,2)+H_fin(1,2)*H_fin(2,3), H_fin(1,3)*H_fin(2,3);
%     H_fin(1,1)^2-H_fin(2,1)^2, H_fin(1,2)^2-H_fin(2,2)^2,   2*(H_fin(1,3)*H_fin(1,1)-H_fin(2,3)*H_fin(2,1)),    2*(H_fin(1,3)*H_fin(1,2)-H_fin(2,3)*H_fin(2,2)),   H_fin(1,3)^2-H_fin(2,3)^2];
% aus = null(A);
% IAC = [aus(1), 0, aus(3); 0, aus(2), aus(4); aus(3),aus(4),aus(5)];
% K_g2 = chol(IAC);
% K_g2 = inv(K_g2);
% K_g2 = K_g2/K_g2(3,3);

%% Estimate K from normalized vp Second test
% for double ceck but assuming also natural camera!!!
A = [vp_olw(1)*vp_vlw(1)+vp_olw(2)*vp_vlw(2),vp_olw(1)+vp_vlw(1),vp_olw(2)+vp_vlw(2),1;
    vp_olw(1)*vp_oextra(1)+vp_olw(2)*vp_oextra(2),vp_olw(1)+vp_oextra(1),vp_olw(2)+vp_oextra(2),1;
    vp_oextra(1)*vp_vlw(1)+vp_oextra(2)*vp_vlw(2),vp_oextra(1)+vp_vlw(1),vp_oextra(2)+vp_vlw(2),1];
aus = null(A);
IAC = [aus(1), 0, aus(2); 0, aus(1), aus(3); aus(2),aus(3),aus(4)];
K = chol(IAC);
K = inv(K);
K = K/K(3,3);

%% Reconstruction of main facade  (TO BE FIXED
tform_k = projective2d(K_g.');
outputImage_k = imwarp(im_rgb, tform_k);

figure();
imshow(outputImage_k);
title('Affine transformation using K');
