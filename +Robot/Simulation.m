classdef Simulation < handle
    properties(Access = protected)
        Assembly
        ModelInterface
        GUI

        Timer
    end

    methods
        function this = Simulation()
            this.Assembly = Robot.Assembly();
            
            this.ModelInterface = Robot.ModelInterface();

            this.GUI = Robot.GUI();
            this.GUI.Slider.Force.Callback = @(~, ~) this.onForceSliderValueChanged_;
            this.GUI.Figure.DeleteFcn = @(~, ~) this.onFigureDeleted_;
            this.GUI.Axes.Target.ButtonDownFcn = @(~, ~) this.onTargetFigureButtonDown_;
            set(this.GUI.Scene.Simulation3D.Linkages{1}, ...
                "Vertices", this.Assembly.Linkages{1}.GetTransformedVertices(), ...
                "Faces", this.Assembly.Linkages{1}.Faces);

            this.Timer = timer("ExecutionMode", "fixedRate", ...
                               "StartDelay", 1, ...
                               "Period", 0.05, ...
                               "TimerFcn", @(~, ~) this.onTimerTick_(), ...
                               "ErrorFcn", @(~, ~) this.onTimerError_());

            this.ModelInterface.Start();
            start(this.Timer);
        end

        function delete(this)
            this.Stop_();
            if isvalid(this.Timer)
                delete(this.Timer)
            end
            delete@handle(this);
        end
    end

    methods(Access = protected)
        function Stop_(this)
            if isvalid(this.Timer)
                stop(this.Timer);
            end
            try
                this.ModelInterface.Stop();
            catch exception
                disp(exception.message);
            end
        end

        function onTimerTick_(this)
            % Target
            this.GUI.Scene.Target.InterpolatedLine.addpoints( ...
                this.ModelInterface.Y_ref, ...
                this.ModelInterface.Z_ref);
            yz = this.ModelInterface.YZ;
            set(this.GUI.Scene.Target.PositionMarker, ...
                "XData", yz(1), ...
                "YData", yz(2));

            % Force
            simulationTime = this.ModelInterface.SimulationTime;
            this.GUI.Scene.Force.Measurement.addpoints( ...
                simulationTime, ...
                this.ModelInterface.Fx);
            this.GUI.Scene.Force.Reference.addpoints( ...
                simulationTime, ...
                this.ModelInterface.Fx_ref);
            xlim(this.GUI.Axes.Force, getAnimatedLineXLimits_(this.GUI.Scene.Force.Reference));

            % Simulation3D
            endeffectorPosition = this.ModelInterface.XYZ;
            if endeffectorPosition(1) >= 0.4
                this.GUI.Scene.Simulation3D.ContactPoint.addpoints( ...
                    endeffectorPosition(1), ...
                    endeffectorPosition(2), ...
                    endeffectorPosition(3));
            else
                this.GUI.Scene.Simulation3D.ContactPoint.addpoints( ...
                    NaN, ...
                    NaN, ...
                    NaN);
            end
            jointPositions = this.ModelInterface.Q;
            for i = 2 : 4
                this.Assembly.Linkages{i}.RelativeTransform.JointOffset = jointPositions(i-1);
                set(this.GUI.Scene.Simulation3D.Linkages{i}, ...
                    "Vertices", this.Assembly.Linkages{i}.GetTransformedVertices(), ...
                    "Faces", this.Assembly.Linkages{i}.Faces);
            end

        end

        function onTimerError_(this)
            this.Stop_();
        end

        function onForceSliderValueChanged_(this)
            sliderValue = this.GUI.Slider.Force.Value;
            this.GUI.Text.Force.String = [num2str(sliderValue, 3) ' N'];
            this.ModelInterface.Fx_ref = sliderValue;
        end
    
        function onTargetFigureButtonDown_(this)
            currentPoint = this.GUI.Axes.Target.CurrentPoint(1, 1:2);
            this.ModelInterface.Y_ref = currentPoint(1);
            this.ModelInterface.Z_ref = currentPoint(2);
            this.GUI.Scene.Target.InteractionLine.addpoints( ...
                currentPoint(1), ...
                currentPoint(2));
        end

        function onFigureDeleted_(this)
            delete(this);
        end
    end
end

function limits = getAnimatedLineXLimits_(animatedLine)
    [xData, ~] = getpoints(animatedLine);
    limits = minmax(xData);
    if limits(1) >= limits(2)
        limits = [ceil(limits(1) - 1) floor(limits(1) + 1)];
    end
end
