function H = compute_H_aff(ls,ms, debug)
%GETH_FROM_AFFINE Computes H through least square approximation starting from an
%   affinity
% H is the reconstruction matrix that brings the affinity to an euclidean
% reconstruction
% The affine hypothesis is important since the last row is made of 0s.
%   ls is a matrix containing l lines
%   ms is a matrix containig m lines
%   ms and ls are orthogonal to the line in the same position
% if we know the angles in the real scene, the real lines obey this law:
% cos(theta) =              l1_t C_star_inf l2
%               -----------------------------------------------
%               sqrt(l1_t C_star_inf l1)  sqrt(l2_t C_star_inf l2)
%
% if the angles are ortogonal it's a linear equation
% Transforming using image elements:
% 0 = l1'_t C_star_inf_prime l2'
% C_star_inf_prime = [a b 0
%                     b 1 0
%                     0 0 0]
% 2 constraints are enough to determine C_star_inf
% here we use a least square approximation using all lines provided.


% pagg 54 of the book eq 2.21 and 2.22

X = []; 
Y = []; 
for ii = 1:size(ls,2)
    li = ls(:,ii);
    mi = ms(:,ii);
    l1 = li(1,1);
    l2 = li(2,1);
    m1 = mi(1,1);
    m2 = mi(2,1);
 
    X(ii,:) = [l1*m1, l1*m2+l2*m1];
    Y(ii,1) = -l2*m2;
end

W = (X.'*X)\(X.'*Y);
C_star_prime = [W(1,1) W(2,1) 0; W(2,1) 1 0; 0 0 0];
[U, S, V] = svd(C_star_prime);
H = (U * diag([sqrt(S(1, 1)), sqrt(S(2, 2)), 1]));
H = inv(H);
    
if debug
    disp(S);
    disp(U);
    disp(V);
end 

