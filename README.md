# GreenhouseControls
Objective of project was to recreate a simulation from a published article and use the recreated simulation to obtain additional insights.   
Showcases proficiency in MATLAB and Simulink.  

This repository consists of two separate analyses of the same system.   
The first analysis uses classical control techniques to analyze a MIMO system with 2 Inputs - 2 Outputs - 3 Disturbances  
The second analysis uses Reinforcement Learning (Machine Learning) to attempt to design a comprable control law for the system  

***Classical Control Analysis***  
Utilizes the files:  
1. ProjectSim.m  
2. greenhouse_model.slx  
3. RosenbergPresentation.pptx  

ProjectSim.m defines parameters based on the article  
Equilibrium values for outputs and linearized matrices are defined using classical control techniques, good reference here: https://apmonitor.com/pdc/index.php/Main/ModelLinearization  
Models were linearized by hand, program calculates values based on parameters. "RosenbergPresentation.pptx" lists governing equations and shows how linearization performed.  

ProjectSim.m defines transfer functions and calls greenhouse_model.slx simulink model to simulate both non-linear and linearized responses to changes in any combination of input varibles and disturbance variables  
Program goes on to calculate system insights such as Infinity norms, Step responses for each output, comparison of coupled vs decoupled controllers  

RosenbergPresentation.pptx summarizes setup and results  

***Reinforcement Learning Analysis***  
Utilizes the files:  
4. Simulation.m
5. ControlSIM.m
6. greenhouseEnv.m
7. StepSimulation.m
8. Rosenberg_Aaron_FinalPresentation.pptx  
9. Rosenberg_Aaron_FinalReport.pdf  

RL model uses reinforcement learning approach to attempt to create an equivalent control law as the optimal classical approach for the same system. Benefits of obtaining an equivalent control law using RL would be the ability to control systems without known physical models. For more information on Reinforcement Learning in general and how it was used for this project, reference file number 8. and 9.  
greenhouseEnv.m sets up greenhouse class for use in the main simulation "Simulation.m". Main simulation uses MATLAB built-in functions from Reinforcement Learning Toolbox to train simulation. "StepSimulation.m" generates the step response from the trained RL simulation. "ControlSIM.m" generates classical control step responses for identical parameters, to compare classical control to RL.  

***Project is complete, future work should involve improved documentation within each file  
***RL model had difficulties generating control law for such a complex system, future work should include lowering complexity to see if it yields better results -- also should include an attempt to increase speed of training using GPU

