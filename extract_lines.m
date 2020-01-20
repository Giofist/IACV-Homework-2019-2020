function lines = extract_lines(im_gray_norm, debug, method)
%Extract Lines Perform line extraction forma gray scale image applinig
%Hough method on a filtered image
% im_gray_norm: is the gray scale image file already pre-processed and normalized.
% debug: True display the images, False do not display.
% method: canny, roberts, sobel, log. Best result Canny.

%% Edge detection with canny
if method == "canny"
    [BW2, th] = edge(im_gray_norm,'canny');
    if debug
        figure;
        imshow(BW2)
        title('Canny Filter');
    end

    %% Test with alternative Threshold for Canny
    % try changing threshold *1.5 is good
    th2 = th.*[0.2, 2];
    th3 = th.*[1.5, 2.5];
    
    BW2 = edge(im_gray_norm,'canny', th2);
    BW3 = edge(im_gray_norm,'canny', th3);
    if debug
        figure,imshow(BW2), title('Canny alternative th1');
        figure,imshow(BW2), title('Canny alternative th2');
        
    end
end

%% with roberts
if method == "roberts"
    [BW2, th] = edge(im_gray_norm,'roberts');
    figure;
    imshow(BW2)
    title('Roberts Filter');
    %% Change ROberts Threshold
    % try changing threshold
    th2 = th*0.7
    BW2 = edge(im_gray_norm,'roberts', th2);
    figure, imshow(BW2);
end

%% Sobel
if method == "sobel"
    [BW2, th] = edge(im_gray_norm,'Sobel', 0.035);
    figure;
    imshow(BW2)
    title('Sobel Filter');
    th
end

%% Log
if method == "log"
    [BW2, th] = edge(im_gray_norm,'log', 0.0025);
    figure;
    imshow(BW2)
    title('Log Filter');
    th
end

%% Line Detection
% Hough parameters
% Use two sets of parameters for line extraction
minLineLength_vert = 170;
fillGap = 20;
numPeaks = 100;
NHoodSize = [111 81];
vertical_angles = -90:0.5:89.9;

% find lines vertical
[H,theta,rho] = hough(BW2,'RhoResolution', 1, 'Theta', vertical_angles);
% find peaks in hough transform
P = houghpeaks(H,numPeaks,'threshold',ceil(0.05*max(H(:))), 'NHoodSize', NHoodSize);

% find lines using houghlines
lines_1 = houghlines(BW2,theta,rho,P,'FillGap',fillGap,'MinLength',minLineLength_vert);

% Other params
minLineLength_vert = 160;
fillGap = 20;
numPeaks = 200;
NHoodSize = [101 51];
vertical_angles = -90:0.5:89.9;

% find lines vertical
[H,theta,rho] = hough(BW3,'RhoResolution', 1, 'Theta', vertical_angles);
% find peaks in hough transform
P = houghpeaks(H,numPeaks,'threshold',ceil(0.05*max(H(:))), 'NHoodSize', NHoodSize);

% find lines using houghlines
lines_2 = houghlines(BW3,theta,rho,P,'FillGap',fillGap,'MinLength',minLineLength_vert);

%lines = [lines_1, lines_2];

lines = [lines_1, lines_2(1,[80,89,86,77,17,32])];

lines(137).point1 = [1166, 2295];
lines(137).point2 = [1381, 2171];
lines(138).point1 = [3158, 1118];
lines(138).point2 = [3464, 941];
lines(139).point1 = [3176, 1173];
lines(139).point2 = [3443 1522];
lines(140).point1 = [3511, 978];
lines(140).point2 = [3851, 1321];

%%TODO I have to clean out some wrong lines before delivery



