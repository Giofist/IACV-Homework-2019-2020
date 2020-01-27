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
IMG_MAX_SIZE_Y = y/3; %for RGB

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

% for a better result I decided to aPrincipal_Pointly the normalization twice
im_gray_norm = adapthisteq(im_gray_norm);

if debug
    figure(1),imshow(im_gray_norm);title('Grayscale Image Twice normalized');
end

%% Line extraction

lines = extract_lines(im_gray_norm, debug, "canny", ceck_with_second_image);

% plot lines on the image
draw_lines(lines, im_rgb);

%% Corner detection

corners = detectHarrisFeatures(im_gray_norm);

figure, imshow(im_rgb); hold on;
plot(corners.selectStrongest(1000000));
hold off

%% Stratification aPrincipal_Pointroach:

% - compute affine reconstruction
% l_inf -> l_inf (the line at infinity must be maPrincipal_Pointed to itself)
% H_r_aff = [1  0  0
%            0  1  0
%            l1 l2 l3] where the last row is l_inf'

% Extract parallel lines
[line_ind_left, lines_left] = pick_lines(lines,im_rgb,"Select two or more orizontal parallel lines on left window (then press enter) left vp:",auto_selection, LINES_ORIZONTAL_LEFT);
[line_ind_vlw, lines_vlw] = pick_lines(lines,im_rgb,"Select two or more vertical parallel lines on left window (then press enter):", auto_selection, LINES_VERTICAL_LEFT);
[line_ind_orw, lines_orw] = pick_lines(lines,im_rgb,"Select two or more orizontal parallel lines on right window (then press enter):", auto_selection, LINES_ORIZONTAL_RIGHT);
[line_ind_up, lines_up] = pick_lines(lines,im_rgb,"Select two or more vertical parallel lines on right window (then press enter)up vp:", auto_selection, LINES_VERTICAL_RIGHT);
[line_ind_vextra, lines_vextra] = pick_lines(lines,im_rgb,"Select two or more vertical parallel lines (then press enter):", auto_selection, LINES_VERTICAL_EXTRA);
[line_ind_right, lines_right] = pick_lines(lines,im_rgb,"Select two or more orizontal parallel lines (then press enter)right vp:", auto_selection, LINES_ORIZONTAL_EXTRA);

% plot selected lines
line_ind = [line_ind_left, line_ind_vlw, line_ind_orw, line_ind_up, line_ind_right];
draw_lines(lines(1,line_ind), im_rgb);

%% extract the line at infinite

vp_left = getVp(lines_left);
vp_vlw = getVp(lines_vlw);
vp_orw = getVp(lines_orw);
vp_up = getVp(lines_up);
vp_vextra = getVp(lines_vextra);
vp_right = getVp(lines_right);

%vector of vanishing points
vp = [vp_left vp_up, vp_right];

%visualize vanishing lines and points
draw_lines_infinity(lines(1,line_ind), im_rgb, vp);
    
% fit the line through these points
l_inf_prime = fitLine([vp_left vp_right],true);

%% compute H_r_aff

H_r_aff = [1 0 0; 0 1 0; l_inf_prime(1) l_inf_prime(2) l_inf_prime(3)];

% Transform the image
img_affine = transform_and_show(H_r_aff, im_rgb, "Image with recovered affine properties");


%% Metric rectification
% In order to perform metric rectification from an affine transformation we
% need perpendicular lines for constraints of the C_star_inf'

perpLines = [ortogonalLineSets(lines_left, lines_right), ortogonalLineSets(lines_left, lines_vextra)];

% transform lines according to H_r_aff since we need to start from an affinity
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
H_a_e = compute_H_aff(ls,ms, debug);

%% Transform from affinity
%Scaling performed for better performance
Resize = [0.2 0 0; 0 0.2 0; 0 0 1]; 
tform = projective2d((Resize*H_a_e).');

% aPrincipal_Pointly the transformation to img
outputImage = imwarp(img_affine, tform);
R = rotx(deg2rad(180));
tform = projective2d(R.');
outputImage = imwarp(outputImage, tform);
outputImage = imrotate(imresize(outputImage, [IMG_MAX_SIZE_X, IMG_MAX_SIZE_Y]), -88);

%% Complete Transformation

O = rotz(deg2rad(-88));
H_r_complete = Resize * R * O * H_a_e * H_r_aff;

tform_complete = projective2d(H_r_complete.');
outputImage_final = imwarp(im_rgb, tform_complete);

figure();
imshow(outputImage_final);
title('Euclidan reconstruction');

%% Metric prperty recovery

H_metric = [1 0 0; 0 200/109 0; 0 0 1];
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
% Using L_inf, vertical vp and homography

H_scaling = diag([1/IMG_MAX_SIZE_X, 1/IMG_MAX_SIZE_Y, 1]);
l_infs = H_scaling.' \ l_inf_prime;
vp_vertical = H_scaling * vp_vlw;

IAC = get_IAC(l_infs, vp_vertical, [], [], H_scaling/H_fin);

% get the intrinsic parameter before the denormalization
alfa = sqrt(IAC(1,1));
u0 = -IAC(1,3)/(alfa^2);
v0 = -IAC(2,3);
fy = sqrt(IAC(3,3) - (alfa^2)*(u0^2) - (v0^2));
fx = fy /alfa;

% build K using the parametrization
K = [fx 0 u0; 0 fy v0; 0 0 1];

% denormalize K
K = H_scaling \ K

% get intrinsic after denormalization
fx = K(1,1);
fy = K(2,2);
u0 = K(1,3);
v0 = K(2,3);
alfa = fx/fy;

%% Estimate K imposing also natural camera
% For double ceck of order of magnitude not requested

A = [vp_left(1)*vp_vlw(1)+vp_left(2)*vp_vlw(2),vp_left(1)+vp_vlw(1),vp_left(2)+vp_vlw(2),1;
    vp_left(1)*vp_right(1)+vp_left(2)*vp_right(2),vp_left(1)+vp_right(1),vp_left(2)+vp_right(2),1;
    vp_right(1)*vp_vlw(1)+vp_right(2)*vp_vlw(2),vp_right(1)+vp_vlw(1),vp_right(2)+vp_vlw(2),1];
aus = null(A);
IAC = [aus(1), 0, aus(2); 0, aus(1), aus(3); aus(2),aus(3),aus(4)];
K_n = chol(IAC);
K_n = inv(K_n);
K_n = K_n/K_n(3,3);

%% Reconstruction of main facade  

a = [1186.5, 988.5, 1]';
b = [2662.5, -15.5, 1]';
c = [1006.5, 2884.5, 1]';
d = [4033.5, 1300.5, 1]';

Principal_Point = K(1:2,3);
Centeral_Point = [Principal_Point(1),Principal_Point(2),1]';

%write points wrt Centeral_Point
b1 = b-a+Centeral_Point;
c1 = c-a+Centeral_Point;
d1 = d-a+Centeral_Point;
a1 = Centeral_Point;
%Scale it wrt focal point
ratio_c = norm(a1-c1)/K(2,2);
c_new = [a1(1)+(c1(1)-a1(1))*ratio_c, a1(2)+(c1(2)-a1(2))*ratio_c,1]';
ratio_b = norm(a1-b1)/K(1,1);
b_new = [a1(1)+(b1(1)-a1(1))*ratio_b, a1(2)+(b1(2)-a1(2))*ratio_b,1]';
a_new = a1;
%Transalte back to previous position
a_new = a_new-Centeral_Point+a;
b_new = b_new-Centeral_Point+a;
c_new = c_new-Centeral_Point+a;
d_new = cross(cross(b_new,vp_vlw),cross(vp_left,c_new));
d_new = d_new/d_new(3);

%for better result change to 0.1 scaling factor
H_suPrincipal_Pointort = [0 0;K(1,1),0;0,K(2,2);K(1,1),K(2,2)]*0.05;

if debug
    figure(),imshow(im_rgb)
    hold on
    plot(a(1),a(2),'xg','MarkerSize',12);
    plot(b(1),b(2),'xg','MarkerSize',12);
    plot(c(1),c(2),'xg','MarkerSize',12);
    plot(d(1),d(2),'xg','MarkerSize',12);
    plot(a_new(1),a_new(2),'or','MarkerSize',12);
    plot(b_new(1),b_new(2),'or','MarkerSize',12);
    plot(c_new(1),c_new(2),'or','MarkerSize',12);
    plot(d_new(1),d_new(2),'or','MarkerSize',12);
    myline1=[a_new';b_new'];
    line(myline1(:,1),myline1(:,2),'LineWidth',5);
    myline2=[a_new';c_new'];
    line(myline2(:,1),myline2(:,2),'LineWidth',5);
    myline3=[c_new';d_new'];
    line(myline3(:,1),myline3(:,2),'LineWidth',5);
    myline4=[b_new';d_new'];
    line(myline4(:,1),myline4(:,2),'LineWidth',5);
    plot(Principal_Point(1),Principal_Point(2),'xg','MarkerSize',20)
    plot(Principal_Point(1),Principal_Point(2),'or','MarkerSize',20)
end 

%% Main facade rectification using K

H_main = maketform('projective',[a_new(1:2)';b_new(1:2)';c_new(1:2)';d_new(1:2)'],H_suPrincipal_Pointort);
[I_rect xdata ydata] = imtransform(im_rgb,H_main,'XYScale',1);

figure(),imshow(I_rect), title ('Rectified main facade')

%% Camera Pose Estimation

% [worldOrientation,worldLocation] = estimateWorldCameraPose(data.imagePoints,data.worldPoints, data.cameraParams);
% 
% %show result
% pcshow(data.worldPoints,'VerticalAxis','Y','VerticalAxisDir','down', ...
%      'MarkerSize',30);
%  hold on
%  plotCamera('Size',10,'Orientation',worldOrientation,'Location',...
%      worldLocation);
%  hold off
%  
 
 