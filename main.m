%% clear all and instantiate variables
clc
clear all
debug = false; %if True display all the images (intermediate passages and choices) else displays only most relevant images
auto_selection = true; %if true automatic line selection, if false manual line selection

% global variables used in other functions
global WINDOW_SIZE LINES_ORIZONTAL_LEFT LINES_VERTICAL_LEFT LINES_ORIZONTAL_RIGHT LINES_VERTICAL_RIGHT
       
% constants for line selection

LINES_ORIZONTAL_LEFT = 1;
LINES_VERTICAL_LEFT = 2;
LINES_ORIZONTAL_RIGHT = 3;
LINES_VERTICAL_RIGHT = 4;

% length of the longside of horizontal faces
WINDOW_SIZE = 1000;   %1 meter

%% Open the Image
im_rgb = imread('Image1.jpg');
IMG_MAX_SIZE = max(size(im_rgb));

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
lines = extract_lines(im_gray_norm, debug, "canny");

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

% plot selected lines
line_ind = [line_ind_olw, line_ind_vlw, line_ind_orw, line_ind_vrw];
draw_lines(lines(1,line_ind), im_rgb);

%% extract the line at infinite

% get vanishing points
vp_olw = getVp(lines_olw);
vp_vlw = getVp(lines_vlw);
vp_orw = getVp(lines_orw);
vp_vrw = getVp(lines_vrw);

%visualize vanishing lines and points
draw_lines_infinity(lines(1,line_ind), im_rgb);

% fit the line through these points
l_inf_prime = fitLine([vp_olw vp_vlw vp_orw vp_vrw],false);

%% compute H_r_aff

H_r_aff = [1 0 0; 0 1 0; l_inf_prime(1) l_inf_prime(2) l_inf_prime(3)];

% Transform the image and shows it
img_affine = transform_and_show(H_r_aff, im_rgb, "Affine rectification");

%{

%% Metric rectification 
% In order to perform metric rectification from an affine transformation we
% need perpendicular lines for constraints of the C_star_inf'

%%%(TODO error here)
perpLines = [createLinePairsFromTwoSets(lines_o1, lines_o2), createLinePairsFromTwoSets(lines_v1, lines_o2)];

% transform lines according to H_r_aff since we need to start from an
% affinity
perpLines = transformLines(H_r_aff, perpLines);


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
H_a_e = getH_from_affine(ls,ms);

%% Transform from affinity

tform = projective2d(H_a_e.');
img_affine_scaled = imresize(img_affine,[774 1032]);
% apply the transformation to img  (TODO fix here)
outputImage = imwarp(img_affine_scaled, tform);

% show
figure();
imshow(outputImage);
title("Euclidean Reconstruction");

%transform_and_show(H_a_e, img_affine, "Euclidean Reconstruction");

%% from original
% apply rotation of 180 degree along the x axis since the image is rotated
% around the x axis.
angle = 180;
R = rotx(deg2rad(180));

% calculate the composite transformation
% img -> affine -> euclidean -> rotation
% H_r is the transformation from the original image to the euclidean
% reconstruction.
H_r = R * H_a_e * H_r_aff;

out_e = transform_and_show(H_r, im_rgb, "Euclidean Reconstruction");
%}