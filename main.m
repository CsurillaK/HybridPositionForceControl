if isempty(which("uix.Panel"))
    error("Please install ""GUI Layout Toolbox""!");
end

addpath("./Misc");
Robot.Simulation();