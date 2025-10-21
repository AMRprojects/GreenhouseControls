%Aaron Rosenberg
%ECE 607
%Final Project 
%DDPG Simulation

clc;clear;close all;
%% Initialize Environment
rng(0)
greenhouse = greenhouseEnv;
ObservationInfo = getObservationInfo(greenhouse);
ActionInfo = getActionInfo(greenhouse);

%% Initialize Critic
% Number of neurons
L = 100;

% Main path
mainPath = [
    featureInputLayer(prod(ObservationInfo.Dimension),Name="obsInLyr")
    fullyConnectedLayer(L)
    reluLayer
    fullyConnectedLayer(L)
    additionLayer(2,Name="add")
    reluLayer
    fullyConnectedLayer(L)
    reluLayer
    fullyConnectedLayer(1,Name="QValLyr")
    ];

% Action path
actionPath = [
    featureInputLayer(prod(ActionInfo.Dimension),Name="actInLyr")
    fullyConnectedLayer(L,Name="actOutLyr")
    ];

% Assemble layergraph object
criticNet = layerGraph(mainPath);
criticNet = addLayers(criticNet,actionPath);    
criticNet = connectLayers(criticNet,"actOutLyr","add/in2");

criticNet = dlnetwork(criticNet);
summary(criticNet)

%figure
%plot(criticNet)

critic = rlQValueFunction(criticNet,ObservationInfo,ActionInfo,...
ObservationInputNames="obsInLyr",ActionInputNames="actInLyr");

%% Initialize Actor

actorNet = [
    featureInputLayer(prod(ObservationInfo.Dimension))
    fullyConnectedLayer(L)
    reluLayer
    fullyConnectedLayer(L)
    reluLayer
    fullyConnectedLayer(L)
    reluLayer
    fullyConnectedLayer(3)
    sigmoidLayer
    ];

actorNet = dlnetwork(actorNet);
summary(actorNet)

actor = rlContinuousDeterministicActor(actorNet,ObservationInfo,ActionInfo);

%% Agent and Agent Options
criticOptions = rlOptimizerOptions( ...
    LearnRate=1e-3, ...
    GradientThreshold=1, ...
    L2RegularizationFactor=1e-4);
actorOptions = rlOptimizerOptions( ...
    LearnRate=1e-4, ...
    GradientThreshold=1, ...
    L2RegularizationFactor=1e-4);

agentOptions = rlDDPGAgentOptions(...
    SampleTime=greenhouse.Ts,...
    ActorOptimizerOptions=actorOptions,...
    CriticOptimizerOptions=criticOptions,...
    ExperienceBufferLength=1e6);
agentOptions.NoiseOptions.Variance = [0.3;0.3;0.3];
agentOptions.NoiseOptions.VarianceDecayRate = 1e-5;

ControlSystem = rlDDPGAgent(actor,critic,agentOptions);

%% Training

trainOpts = rlTrainingOptions;
trainOpts.MaxEpisodes = 500;
trainOpts.MaxStepsPerEpisode = 3600;
trainOpts.ScoreAveragingWindowLength = 25;
trainOpts.StopTrainingCriteria = "EpisodeCount";
trainOpts.StopTrainingValue = 150;
trainOpts.SaveAgentCriteria = "EpisodeCount";
trainOpts.SaveAgentValue = 150;

trainingInfo = train(ControlSystem,greenhouse,trainOpts)
simOpts = rlSimulationOptions;
simOpts.MaxSteps = 3600;