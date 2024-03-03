classdef Transform < handle
    properties(Access = protected)
        Matrix_ = eye(4)
    end

    properties(Dependent)
        Matrix
    end
    
    events
        eMatrixChanged
    end

    methods
        function this = Transform(matrix)
            arguments
                matrix (4, 4) double {mustBeHomogenousTransform_} = eye(4)
            end
            this.Matrix_ = matrix;
        end

        function set.Matrix(this, matrix)
            arguments
                this
                matrix (4, 4) double {mustBeHomogenousTransform_}
            end
            this.Matrix_ = matrix;
            notify(this, "eMatrixChanged");
        end
        function matrix = get.Matrix(this)
            matrix = this.Matrix_;
        end
    end
    
    methods (Static)
        function rotationMatrix = EvaluateRodriguesFormula(unitVector, angle)
            ux = unitVector(1);
            uy = unitVector(2);
            uz = unitVector(3);
            cosAngle = cos(angle);
            sinAngle = sin(angle);
            
            rotationMatrix = cosAngle * eye(3) + ...
                (1 - cosAngle) * ([ux uy uz]' * [ux uy uz]) + ...
                sinAngle * [ 0  -uz  uy; ...
                             uz  0  -ux; ...
                            -uy  ux  0];
        end
        function transformationMatrix = BuildTransformationMatrix(rotationMatrix, translationVector)
            transformationMatrix = eye(4);
            transformationMatrix(1:3,1:3) = rotationMatrix;
            transformationMatrix(1:3,4) = translationVector(:);
        end
    end
end

function mustBeHomogenousTransform_(input)
    eidType = 'mustBeHomogenousTransform:notHomogenousTransform';

    if ~isreal(input) || ~all(size(input) == [4, 4])
        error(eidType, "Input must be real 4x4 matrix!");
    end

    rotationMatrix = input(1:3, 1:3);
    if abs(norm(eye(3) - rotationMatrix' * rotationMatrix)) > eps
        error(eidType, "Rotation matrix must be orthonormal!");
    end
    
    if ~all(input(4, 1:4) == [0 0 0 1])
        error(eidType, "Last row must be [0 0 0 1]!");
    end
end
