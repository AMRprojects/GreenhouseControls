
%for k = 1:4
    %% Set Initial Conditions
    T_out = [19.2763;20.5658;26.0196;3.76295];
    Sr = [143.6157;215.91;253.55;93.2419];
    T_in = [18.9343;8.2753;15.4281;26.5223];
    k=1;
    time = [1:3600];
    greenhouse.State = [T_in(k);T_out(k);Sr(k)];

    %% Simulate over 1 Hour (3600 time steps)

    InitialObservation = greenhouse.State;
    InitialAction = getAction(ControlSystem,InitialObservation);

    observation=zeros(3,3600);
    observation(:,1) = InitialObservation;

    actions = zeros(3,3600);
    actions(:,1) = InitialAction{1};

    for i = 2:3600
        observation(:,i) = greenhouse.step(actions(:,i-1));
        action = getAction(ControlSystem,observation(:,i));
        actions(:,i) = action{1};
    end
    figure(1)
    hold on;grid on;
    plot(time,observation(1,:))

    if k==1
        figure(2)
        hold on;grid on;
        plot(time,actions(1,:),time,actions(2,:),time,actions(3,:))
        legend('Heater','Fogger','Ventilation','location','best')
        xlabel('Time (seconds)');ylabel('Normalized Action')
        title('RL Agent Actions Test 1')

    end


    if k==2
        figure(3)
        hold on;grid on;
        plot(time,actions(1,:),time,actions(2,:),time,actions(3,:))
        legend('Heater','Fogger','Ventilation','location','best')
        xlabel('Time (seconds)');ylabel('Normalized Action')
        title('RL Agent Actions Test 2')

    end

    ise = trapz(25-observation(1,:))
%end

%figure(1)
%legend('Test1','Test2','Test3','Test4','location','best')
%xlabel('Time (seconds)');ylabel('Temperature (Celcius)')
%title('RL Agent Temperature Control')





