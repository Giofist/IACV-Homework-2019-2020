function outputImage = transform_and_show(H,img, text)

% create the tform object from H
tform = projective2d(H.');

% apply the transformation to img
outputImage = imwarp(img, tform);

% show
figure();
imshow(outputImage);
title(text);
end

