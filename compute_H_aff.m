function H = compute_H_aff(ls,ms, debug)
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

