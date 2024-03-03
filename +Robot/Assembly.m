classdef Assembly < handle
    properties(Constant)
        DenavitHartenbergTable = [0         0     0.34287   0
                                  0.25      0     0.105     0
                                  0.35683   0    -0.0305   -0.6109]
        DenavitHartenbergIndex = [4
                                  4
                                  3]

        StlFilePaths = {"./+Robot/Geometry/0.STL"
                        "./+Robot/Geometry/1.STL"
                        "./+Robot/Geometry/2.STL"
                        "./+Robot/Geometry/3.STL"}

        ScalingFactor = 0.001
    end
    properties (SetAccess = private)
        Linkages = {}
    end
    
    methods
        function this = Assembly()
            this.Build_()
        end
        
        function Build_(this)
            this.Linkages = cell(1, 5);

            % Base
            this.Linkages{1} = Robot.Linkage("StlFilePath", this.StlFilePaths{1}, ...
                                              "ScalingFactor", this.ScalingFactor);

            % Serial linkage chain
            for i = 2 : 4
                this.Linkages{i} = Robot.Linkage("StlFilePath", this.StlFilePaths{i}, ...
                                                  "ScalingFactor", this.ScalingFactor, ...
                                                  "RelativeTransform", Robot.DenavitHartenbergTransform(this.DenavitHartenbergTable(i-1, :), ...
                                                                                                        this.DenavitHartenbergIndex(i-1)), ...
                                                  "Parent", this.Linkages{i-1});
            end

            % Tool center point
            this.Linkages{5} = Robot.Linkage("Name", "ToolCenterPoint", ...
                                             "ScalingFactor", this.ScalingFactor, ...
                                             "RelativeTransform", Robot.Transform(Robot.Transform.BuildTransformationMatrix(eye(3), ...
                                                                                                                            [0.2 0 0])), ...
                                             "Parent", this.Linkages{4});
        end

        function Plot(this)
            f = figure();
            a = axes("Parent", f, ...
                     "XTick", [], "XTickLabel", [], "YTick", [], "YTickLabel", [], "ZTick", [], "ZTickLabel", [], ...
                     "XLim", [-0.6 0.6], "YLim", [-0.6 0.6], "ZLim", [0 1.2], ...
                     "Box", "on", ...
                     "DataAspectRatio", [1 1 1], "PlotBoxAspectRatio", [1 1 1], ...
                     "Color", "white");
            patches = cell(1, 4);

            for i = 1 : length(this.Linkages) - 1
                patches{i} = patch("Vertices", this.Linkages{i}.GetTransformedVertices(), ...
                                   "Faces", this.Linkages{i}.Faces,...
                                   "FaceColor", [0.8 0.8 1.0], ...
                                   "EdgeColor", 'none', ...
                                   "FaceLighting", 'gouraud', ...
                                   "AmbientStrength", 0.15,...
                                   "Parent", a);
            end
            camlight("headlight");
            material("shiny");
            grid(a, "on");
            view(a, 33, 20);
            
            function Redraw_(linkages, patches, q)
                for j = 1 : 3
                    linkages{j}.RelativeTransform.JointOffset = q(j);
                    set(patches{j}, "Vertices", linkages{j}.GetTransformedVertices());
                end
            end
            manipulate(f, @(q1, q2, q3) Redraw_(this.Linkages(2:4), patches(2:4), [q1 q2 q3]), ...
                {"q1", -pi, pi, 2.00142}, ...
                {"q2", -pi, pi, -1.6713}, ...
                {"q3", -0.48369, 0, -0.21737});
        end
    end
end
