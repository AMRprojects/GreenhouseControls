 % Specify and initialize environment's necessary properties
        V = 4000;       %Volume of air in greenhouse, m^3
        U = 4;         %heat transfer coefficient W/(Km^2)
        A = 1000;       %Surface area of greenhouse, m^2
        rho = 1.2;      %Density of air, kg/m^3
        Cp = 1006;      %specific heat of air, J/kgK
        gamma = 2257;   %latent heat of vaporization, J/g
        alpha = 0.125;  %leaf cover coefficient

  T_out_eq = 19.2763;
  Si_eq = 143.6157;
  u1_eq = 50000;
  u2_eq = 0;

  T_in_eq = T_out_eq + (Si_eq/U)+((u1_eq-gamma*u2_eq)/(U*A));

  dfdx1 = -((U*A)/(rho*V*Cp));
  
  dfdu1 = 1/(rho*V*Cp);
  dfdu2 = gamma/(rho*V*Cp);

  Amat = dfdx1;
  Bmat = [dfdu1];
  Cmat = [1];
  Dmat = [0];

  sys = ss(Amat,Bmat,Cmat,Dmat)

 