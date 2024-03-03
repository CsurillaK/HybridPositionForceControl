classdef GUI < handle
    properties(Constant)
        Color = struct("Background", [84 84 219]/255, ...
                        "Foreground", [171 171 216]/255)
        
        Default = struct("Padding", 5, ...
                         "Spacing", 5);

        ForceRange = {5, 10, 20}
    end

    properties(SetAccess = protected)
        Figure
        Axes = struct()
        Slider = struct()
        Text = struct()
        Scene = struct()
    end

    methods
        function this = GUI()
            this.Build_();
            this.HandleAxes_();
        end
    end

    methods(Access = protected)
        function Build_(this)
            layoutStack = Stack();
                        
            this.Figure = figure( ...
                "Name", "Robot", ...
                "NumberTitle", "Off", ...
                "Toolbar", "none",...
                "MenuBar", "default" ,...
                "Units", "pixels", ...
                "OuterPosition", [221 337 1090 600], ...
                "Color", this.Color.Background);
            layoutStack.Push(this.Figure);
            LimitFigSize(this.Figure, "min", [1090 600]);
            
            layoutStack.Push(uix.HBox( ...
                "Parent", layoutStack.Top(), ...
                "Padding", this.Default.Padding, ...
                "Spacing", this.Default.Spacing, ...
                "BackgroundColor", this.Color.Background));

            layoutStack.Push(uix.VBox( ...
                "Parent", layoutStack.Top(), ...
                "Padding", 0, ...
                "Spacing", this.Default.Spacing, ...
                "BackgroundColor", this.Color.Background));
            layoutStack.Push(uix.Panel( ...
                "Parent", layoutStack.Top(), ...
                "Title", "Target", ...
                "FontSize", 14, ...
                "BackgroundColor", this.Color.Foreground));
            layoutStack.Push(uix.HBox( ...
                "Parent", layoutStack.Top(), ...
                "Padding", this.Default.Padding, ...
                "Spacing", this.Default.Spacing*2, ...
                "BackgroundColor", this.Color.Foreground));
            layoutStack.Push(uix.VBox( ...
                "Parent", layoutStack.Top(), ...
                "Padding", 0, ...
                "Spacing", this.Default.Spacing, ...
                "BackgroundColor", this.Color.Foreground));
            this.Text.Force = uicontrol( ...
                "Parent", layoutStack.Top(), ...
                "Style", "text", ...
                "String", [num2str(this.ForceRange{2}, 3) ' N'], ...
                "FontAngle", "italic", ...
                "FontWeight", "bold", ...
                "FontSize", 12, ...
                "Units", "normalized", ...
                "PositioN", [0 0 1 1], ...
                "BackgroundColor", this.Color.Foreground, ...
                "HorizontalAlignment", "center");
            this.Slider.Force = uicontrol( ...
                "Parent", layoutStack.Top(), ...
                "Style", "Slider", ...
                "Value", this.ForceRange{2}, ...
                "Min", this.ForceRange{1}, ...
                "Max", this.ForceRange{3});
            set(layoutStack.Pop(), "Heights", [20 -1]);
            this.Axes.Target = axes( ...
                "Parent", layoutStack.Top(), ...
                "Units", "normalized", ...
                "Position", [0 0 1 1], ...
                "XLim", [0 1], "YLim", [0 1], ...
                "XTick", [], "XTickLabel", [], ...
                "YTick", [], "YTickLabel", [], ...
                "Box", "on", ...
                "Color", [0.9 0.9 0.9], ...
                "NextPlot", "add");
            set(layoutStack.Pop(), "Widths", [40, -1]);
            layoutStack.Pop();
            layoutStack.Push(uix.Panel( ...
                "Parent", layoutStack.Top(), ...
                "Title", "Force", ...
                "FontSize", 14, ...
                "BackgroundColor", this.Color.Foreground));
            this.Axes.Force = axes( ...
                "Parent", uicontainer("Parent", layoutStack.Top()), ...
                "Units", "normalized", ...
                "ActivePositionProperty", "outerposition", ...
                ... % "OuterPosition", [0 0 1 1], ...
                "Box", "on", ...
                "Color", "white", ...
                "NextPlot", "add");
            layoutStack.Pop();
            set(layoutStack.Pop(), "Heights", [300 -1]);

            layoutStack.Push(uix.Panel( ...
                "Parent", layoutStack.Top(), ...
                "Title", "3D simulation", ...
                "FontSize", 14, ...
                "Padding", this.Default.Padding, ...
                "BackgroundColor", this.Color.Foreground));
            this.Axes.Simulation3D = axes( ...
                "Parent", layoutStack.Top(), ...
                "Units", "normalized", ...
                "Position", [0 0 1 1], ...
                "XLim", [-0.4 0.6], "YLim", [-0.2 0.8], "ZLim", [-0.2 1.4], ...
                "XTick", [], "XTickLabel", [], ...
                "YTick", [], "YTickLabel", [], ...
                "ZTick", [], "ZTickLabel", [], ...            
                "Box", "on", ...
                "Color", "white", ...
                "NextPlot", "add", ...
                "DataAspectRatio", [1 1 1]);
            view(this.Axes.Simulation3D, 33, 20);
            camlight("headlight");
            material("shiny");
            layoutStack.Pop();

            set(layoutStack.Pop(), "Widths", [500 -1]);
        end

        function HandleAxes_(this)
            % Target
            this.Scene.Target = struct();
            this.Scene.Target.InteractionLine = animatedline( ...
                "Parent", this.Axes.Target, ...
                "LineStyle", ":", ...
                "Color", "g", ...
                "Marker", "o", ...
                "LineWidth", 2, ...
                "MarkerEdgeColor", "k", ...
                "MarkerFaceColor", [.49 1 .63], ...
                "MarkerSize", 10, ...
                "MaximumNumPoints", 4);
            this.Scene.Target.InterpolatedLine = animatedline( ...
                "Parent", this.Axes.Target, ...
                "LineStyle", "--", ...
                "Color", "b", ...
                "LineWidth", 2, ...
                "MaximumNumPoints", 100);
            this.Scene.Target.PositionMarker = line( ...
                "Parent", this.Axes.Target, ...
                "Marker", "s", ...
                "LineWidth", 2, ...
                "MarkerEdgeColor", "red", ...
                "MarkerFaceColor", [0.5 0.5 0.5], ...
                "MarkerSize", 10, ...
                "XData", [], ...
                "YData", []);

            % Force
            xlabel(this.Axes.Force, "Time [s]", "FontSize", 12);
            ylabel(this.Axes.Force, "Force [N]", "FontSize", 12);
            grid(this.Axes.Force, "on");
            this.Scene.Force = struct();
            this.Scene.Force.Measurement = animatedline( ...
                "Parent", this.Axes.Force, ...
                "LineStyle", "-", ...
                "Color", "b", ...
                "LineWidth", 1, ...
                "MaximumNumPoints", 100);
            this.Scene.Force.Reference = animatedline( ...
                "Parent", this.Axes.Force, ...
                "LineStyle", "--", ...
                "Color", "r", ...
                "LineWidth", 2, ...
                "MaximumNumPoints", 100);

            % Simulation3D
            plot3(this.Axes.Simulation3D, ...
                [0.4, 0.4, 0.4, 0.4, 0.4],...
                [0.2, 0.6, 0.6, 0.2, 0.2],...
                [0, 0, 0.4, 0.4, 0], ...
                "b", "LineWidth",3);
            this.Scene.Simulation3D.ContactPoint = animatedline( ...
                "Parent", this.Axes.Simulation3D, ...
                "LineStyle", "-", ...
                "Color", "r", ...
                "LineWidth", 2, ...
                "MaximumNumPoints", 100);
            this.Scene.Simulation3D.Linkages = cell(1, 4);
            this.Scene.Simulation3D.Linkages{1} = patch( ...
                "Parent", this.Axes.Simulation3D, ...
                "Vertices", [], ...
                "Faces", [], ...
                "FaceColor", [0.8 0.8 1.0], ...
                "EdgeColor", "none", ...
                "FaceLighting", "gouraud", ...
                "AmbientStrength", 0.15);
            this.Scene.Simulation3D.Linkages{2} = patch( ...
                "Parent", this.Axes.Simulation3D, ...
                "Vertices", [], ...
                "Faces", [], ...
                "FaceColor", [0.8 0.8 1.0], ...
                "EdgeColor", "none", ...
                "FaceLighting", "gouraud", ...
                "AmbientStrength", 0.15);
            this.Scene.Simulation3D.Linkages{3} = patch( ...
                "Parent", this.Axes.Simulation3D, ...
                "Vertices", [], ...
                "Faces", [], ...
                "FaceColor", [0.8 0.8 1.0], ...
                "EdgeColor", "none", ...
                "FaceLighting", "gouraud", ...
                "AmbientStrength", 0.15);
            this.Scene.Simulation3D.Linkages{4} = patch( ...
                "Parent", this.Axes.Simulation3D, ...
                "Vertices", [], ...
                "Faces", [], ...
                "FaceColor", [0.8 0.8 1.0], ...
                "EdgeColor", "none", ...
                "FaceLighting", "gouraud", ...
                "AmbientStrength", 0.15);
        end
    end
end
