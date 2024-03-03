classdef ModelInterface < handle
    properties(SetAccess = protected)
        Model
        % Workspace

        Handles = struct()
    end
    
    properties(Dependent)
        Y_ref
        Z_ref
        Fx_ref
    end
    properties(Dependent, GetAccess = protected)
    end
    properties(Dependent, SetAccess = protected)
        Q
        YZ
        XYZ
        Fx

        SimulationTime
    end

    methods
        function this = ModelInterface()
            this.Model = load_system("./+Robot/Model/robot_3DoF_model.slx");
            % this.Workspace = get_param(this.Model, "ModelWorkspace");

            this.Handles.Y_ref = get_param("robot_3DoF_model/Reference Y", "Handle");
            this.Handles.Z_ref = get_param("robot_3DoF_model/Reference Z", "Handle");
            this.Handles.Fx_ref = get_param("robot_3DoF_model/Reference Force X", "Handle");

            this.Reset();
        end

        function Reset(this)
            this.Y_ref = 0.5;
            this.Z_ref = 0.5;
            this.Fx_ref = 10;
        end

        function Start(this)
            if get_param(this.Model, "SimulationStatus") ~= "stopped"
                return
            end

            set_param(this.Model, "SimulationCommand", "start");
            pause(1);

            this.Handles.YZ_ref = get_param("robot_3DoF_model/Trajectory generation/Reference signal transform", "RunTimeObject");
            this.Handles.Q = get_param("robot_3DoF_model/Rate Transition", "RunTimeObject");
            this.Handles.YZ = get_param("robot_3DoF_model/Industrial robot/Force calculation", "RunTimeObject");
            this.Handles.XYZ = get_param("robot_3DoF_model/Forward kinematics/Direct kinematics", "RunTimeObject");
            this.Handles.Fx = get_param('robot_3DoF_model/Industrial robot/Force calculation', "RunTimeObject");
        end
        function Stop(this)
            set_param(this.Model, "SimulationCommand", "stop");
        end

        function set.Y_ref(this, value)
            set_param(this.Handles.Y_ref, "Value", num2str(value, 10));
        end
        function value = get.Y_ref(this)
            value = this.Handles.YZ_ref.InputPort(1).Data(1);
        end
        function set.Z_ref(this, value)
            set_param(this.Handles.Z_ref, "Value", num2str(value, 10));
        end
        function value = get.Z_ref(this)
            value = this.Handles.YZ_ref.InputPort(2).Data(1);
        end
        function set.Fx_ref(this, value)
            set_param(this.Handles.Fx_ref, "Value", num2str(value, 10));
        end
        function value = get.Fx_ref(this)
            value = str2double(get_param(this.Handles.Fx_ref, "Value"));
        end

        function value = get.Q(this)
            value = this.Handles.Q.OutputPort(1).Data(1:3);
        end
        function value = get.YZ(this)
            value = this.Handles.YZ.OutputPort(2).Data;
        end
        function value = get.XYZ(this)
            value = this.Handles.XYZ.OutputPort(1).Data;
        end
        function value = get.Fx(this)
            value = - this.Handles.Fx.OutputPort(1).Data(1);
        end

        function value = get.SimulationTime(this)
            value = get(this.Model, "SimulationTime");
        end

        function delete(this)
            try
                this.Stop();
            catch exception
                disp(exception.message);
            end
        end
    end

    methods(Access = protected)
    end
end
