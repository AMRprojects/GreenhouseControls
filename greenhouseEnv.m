classdef greenhouseEnv < rl.env.MATLABEnvironment
    %GREENHOUSEENV: Template for defining custom environment in MATLAB.    
    
    %% Properties (set properties' attributes accordingly)
    properties
        % Specify and initialize environment's necessary properties
        V = 4000;       %Volume of air in greenhouse, m^3
        U = 4;         %heat transfer coefficient W/(Km^2)
        A = 1000;       %Surface area of greenhouse, m^2
        rho = 1.2;      %Density of air, kg/m^3
        Cp = 1006;      %specific heat of air, J/kgK
        gamma = 2257;   %latent heat of vaporization, J/g
        alpha = 0.125;  %leaf cover coefficient

        Ts = 1;         %step time, sample every second
        Tf = 3600;      %total simulation time, runs for one hour simulated
        stepTime = 0;

        T_set = 25;     %Temperature Setpoint degCelcius
        W_set = 16;     %Humidity Setpoint g/m^3
     
    end
    
    properties
        % Initialize system state [T_in, W_in, T_out, W_out, Sr]'
        State = zeros(3,1)
    end
    
    properties(Access = protected)
        % Initialize internal flag to indicate episode termination
        IsDone = false        
    end

    %% Necessary Methods
    methods              
        % Contructor method creates an instance of the environment
        % Change class name and constructor name accordingly
        function this = greenhouseEnv()
            % Initialize Observation settings
            ObservationInfo = rlNumericSpec([3 1],...
                LowerLimit = -inf*ones(3,1),...
                UpperLimit = inf*ones(3,1));
            ObservationInfo.Name = 'Greenhouse States';
            ObservationInfo.Description = 'T_in, T_out, Sr';
            
            % Initialize Action settings   
            ActionInfo = rlNumericSpec([3 1],...
                LowerLimit=[0;0;0],...
                UpperLimit=[1;1;1]);
            ActionInfo.Name = "Heater;Fogger;Ventilation";
            
            % The following line implements built-in functions of RL env
            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
            
            % Initialize property values and pre-compute necessary values
            %updateActionInfo(this);
        end
        
        % Apply system dynamics and simulates the environment with the 
        % given action for one step.
        function [Observation,Reward,IsDone,LoggedSignals] = step(this,Action)
            LoggedSignals = [];
            
            % Get action
            Control = getControl(this,Action);
            HeaterAct = Control(1);
            FoggerAct = Control(2);
            VentAct = Control(3);
            
            %Scaled Control Actions
            SHeaterAct = 100000*HeaterAct;
            SFoggerAct = 100*FoggerAct;
            SVentAct = 100*VentAct;
            
            % Unpack state vector
            T_in = this.State(1);
            %W_in = this.State(2);
            T_out = this.State(2);
            %W_out = this.State(4);
            Sr = this.State(3);
            
            % Cache to avoid recomputation
            Mass = this.rho * this.V;
            ThermalMass = Mass * this.Cp;
            Si = Sr * this.A;
            E = (this.alpha/this.gamma)*Si;

            % Apply differential equations            
            T_in_dot = ((SHeaterAct+Si-(this.gamma*SFoggerAct))/ThermalMass)-(T_in-T_out)*((SVentAct/this.V)+((this.U*this.A)/ThermalMass));
            %W_in_dot  = (SFoggerAct+E-SVentAct*(W_in-W_out))/Mass;
            
            % Euler integration
            Observation = this.State + this.Ts.*[T_in_dot;0;0];

            % Update system states
            this.State = Observation;
            this.stepTime = this.stepTime + 1;
            
            
            % Check terminal condition
            T_in = Observation(1);
            %W_in = Observation(2);
            IsDone = (abs(T_in - this.T_set) > 5) && (this.stepTime == this.Tf);
            this.IsDone = IsDone;
            
            % Get reward
            Reward = getReward(this,Control);
            
        end
        
        % Reset environment to initial state and output initial observation
        function InitialObservation = reset(this)
            % T_out 
            T_out0 = normrnd(16.5,7.56);        %Degrees Celcius 
            % W_out
            %Wrelative = max(min(normrnd(0.5,0.139),1),0);       %Percentage
            %Ps = 610.94 * exp((17.625*T_out0)/(T_out0+243.04)); %Saturation vapor pressure of water, Pa
            %W_out0 = (Wrelative * Ps * 1000)/(461.5 * (T_out0+273.15)); %Absolute humidity, g/m^3
            % Solar Radiation
            SolarEnergy = max(normrnd(4.13,1.31),0);    %kWh/m^2
            Sr0 = SolarEnergy*(1000/24);

            %T_in
            T_in0 = normrnd(16.5,7.56);
            %W_in
            %W_inR0 = max(min(normrnd(0.5,0.139),1),0);
            %PsI = 610.94 * exp((17.625*T_in0)/(T_in0+243.04));
            %W_in0 = (W_inR0 * PsI * 1000)/(461.5 * (T_in0+273.15));

            this.stepTime = 0;

            InitialObservation = [T_in0;T_out0;Sr0];
            this.State = InitialObservation;

            
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
            %notifyEnvUpdated(this);
        end
    end
    %% Optional Methods (set methods' attributes accordingly)
    methods               
        % Helper methods to create the environment
        % Continuous Control Signals
        function Control = getControl(this,action)
            if (action(1) > this.ActionInfo.UpperLimit(1))||(action(1) < this.ActionInfo.LowerLimit(1))
                error('Heater Action Outside of Range');
            end
            if (action(2) > this.ActionInfo.UpperLimit(2))||(action(2) < this.ActionInfo.LowerLimit(2))
                error('Fogger Action Outside of Range');
            end
            if (action(3) > this.ActionInfo.UpperLimit(3))||(action(3) < this.ActionInfo.LowerLimit(3))
                error('Ventilation Action Outside of Range');
            end
            Control = action;           
        end
        
        % Reward function
        function Reward = getReward(this,Action)
           Temperature_error = abs(this.State(1)-this.T_set);
           %Humidity_error = abs(this.State(2)-this.W_set);
           speedBonus = (Temperature_error <= 0.01) && (this.stepTime <= 1000);

           Temp_penalty1 = (Temperature_error > 5) && (this.stepTime > 1000);
           Temp_penalty2 = (Temperature_error > 5) && (this.stepTime > 500);
           Temp_penalty3 = (Temperature_error > 5) && (this.stepTime > 240);
           Temp_bonus1 = (Temperature_error <= 2.5) && (this.stepTime < 500);
           Temp_bonus2 = (Temperature_error <= 2) && (this.stepTime < 1500);
           ConstTempBonus = (Temperature_error < 1);
           ConstTempPenalty = (Temperature_error > 3);

           %Hum_penalty1 = (Humidity_error > 20) && (this.stepTime > 1000);

           Reward = -(2500*Temp_penalty1 + 2500*Temp_penalty2 + 2500*Temp_penalty3) ...
               +(7500*Temp_bonus1 + 15000*Temp_bonus2)...
               -(1000000*this.IsDone)+(100000*speedBonus)...
               -(2500*ConstTempPenalty) + (2500*ConstTempBonus*(this.stepTime/this.Tf));
        end
    end
    
    methods (Access = protected)
        % (optional) update visualization everytime the environment is updated 
        % (notifyEnvUpdated is called)
        %function envUpdatedCallback(this)
        end
    end

