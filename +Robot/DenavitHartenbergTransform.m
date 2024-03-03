classdef DenavitHartenbergTransform < Robot.Transform
    properties(Access = protected)
        DenavitHartenbergParameters_
        DenavitHartenbergIndex_
    end
    % properties(Dependent)
        % DenavitHartenbergParameters
        % DenavitHartenbergIndex
    % end
    
    properties(Dependent, GetAccess = protected)
        JointOffset
    end

    methods
        function this = DenavitHartenbergTransform(denavitHartenbergParameters, denavitHartenbergIndex)
            % denavitHartenbergParameters: [Xdistance, Xangle, Zdistance, Zangle]
            % denavitHartenbergIndex: 1...4
            arguments
                denavitHartenbergParameters (1, 4) double {mustBeReal} = [0, 0, 0, 0]
                denavitHartenbergIndex (1, 1) double {mustBeMember(denavitHartenbergIndex, [1, 2, 3, 4])} = 1
            end

            this.DenavitHartenbergParameters_ = denavitHartenbergParameters;
            this.DenavitHartenbergIndex_ = denavitHartenbergIndex;
            this.JointOffset = 0;
        end

        function set.JointOffset(this, jointOffset)
            arguments
                this
                jointOffset (1, 1) double {mustBeReal}
            end
            this.Matrix = this.GetTransformation_(jointOffset);
        end

        % function set.DenavitHartenbergParameters(this, denavitHartenbergParameters)
        %     arguments
        %         this
        %         denavitHartenbergParameters (1, 4) double {mustBeReal}
        %     end
        %     this.DenavitHartenbergParameters_ = denavitHartenbergParameters;
        % end
        % function value = get.DenavitHartenbergParameters(this)
        %     value = this.DenavitHartenbergParameters_;
        % end
        % function set.DenavitHartenbergIndex(this, denavitHartenbergIndex)
        %     arguments
        %         this
        %         denavitHartenbergIndex (1, 1) double {mustBeMember(denavitHartenbergIndex, [1, 2, 3, 4])}
        %     end
        %     this.DenavitHartenbergIndex_ = denavitHartenbergIndex;
        % end
        % function value = get.DenavitHartenbergIndex(this)
        %     value = this.DenavitHartenbergIndex_;
        % end
    end

    methods(Access = protected)
        function transformationMatrix = GetTransformation_(this, jointOffset)            
            jointVector = this.DenavitHartenbergParameters_;
            jointVector(this.DenavitHartenbergIndex_) = jointVector(this.DenavitHartenbergIndex_) + jointOffset;
            transformationMatrix = ...
                this.BuildTransformationMatrix(this.EvaluateRodriguesFormula([1 0 0], jointVector(2)), ...
                                               [jointVector(1) 0 0]) * ...
                this.BuildTransformationMatrix(this.EvaluateRodriguesFormula([0 0 1], jointVector(4)), ...
                                               [0 0 jointVector(3)]);
        end
    end
end
