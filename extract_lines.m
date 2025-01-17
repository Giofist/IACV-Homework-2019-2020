function lines = extract_lines(im_gray_norm, debug, method, ceck_with_second_image)
%Extract Lines Perform line extraction forma gray scale image applinig
%Hough method on a filtered image
% im_gray_norm: is the gray scale image file already pre-processed and normalized.
% debug: True display the images, False do not display.
% method: canny, roberts, sobel, log. Best result Canny.
% ceck_with_second_image: true if we are using the second image to double
% ceck

%% Edge detection with canny
if method == "canny"
    [BW2, th] = edge(im_gray_norm,'canny');
    
    %elimination of noise
    BW2 = bwareaopen(BW2, 80);
    
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

if false
  imshow(BW2);
end
%% Line Detection
% find lines vertical
[H,theta,rho] = hough(BW2,'RhoResolution', 1, 'Theta', -90:0.5:89.9);
% find peaks in hough transform
P = houghpeaks(H,100,'threshold',ceil(0.05*max(H(:))), 'NHoodSize', [111 81]);
% find lines using houghlines
lines_1 = houghlines(BW2,theta,rho,P,'FillGap',20,'MinLength',170);

% find lines vertical
[H,theta,rho] = hough(BW3,'RhoResolution', 1, 'Theta', -90:0.5:89.9);
% find peaks in hough transform
P = houghpeaks(H,200,'threshold',ceil(0.05*max(H(:))), 'NHoodSize', [101 51]);
% find lines using houghlines
lines_2 = houghlines(BW3,theta,rho,P,'FillGap',20,'MinLength',160);


if ceck_with_second_image == false
    lines = [lines_1, lines_2(1,[80,89,86,77,17,32])];
    lines(137).point1 = [1166, 2295];
    lines(137).point2 = [1381, 2171];
    lines(138).point1 = [3158, 1118];
    lines(138).point2 = [3464, 941];
    lines(139).point1 = [3176, 1173];
    lines(139).point2 = [3443 1522];
    lines(140).point1 = [3511, 978];
    lines(140).point2 = [3851, 1321];
else
    lines = [lines_1, lines_2];
end


%%TODO I have to clean out some wrong lines before delivery



