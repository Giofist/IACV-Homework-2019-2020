function H = compute_H_sim(perp_lines)

X = []; % should be nxm matrix (n is ls size 2, m is 2)
Y = []; % should be n matrix of -l2m2 elements
for ii = 1:size(ls,2)
    % first compute the element of x
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
end

