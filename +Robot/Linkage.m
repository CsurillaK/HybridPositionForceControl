classdef Linkage < handle
    properties(Access = protected)
        Name_
        Vertices_ = []
        Normals_ = []
        ScalingFactor_

        RelativeTransform_
        RelativeTransformListener_
        AbsoluteTransformationMatrix_ = eye(4)
    end
    properties(SetAccess = protected)
        Faces = []
        Parent = []
    end

    properties(Hidden)
        HasBeenMoved_ = true
        ChildByName_
    end

    properties(Dependent, SetAccess = protected)
        VertexCount
        Children
    end

    properties(Dependent)
        Name
        ScalingFactor
        RelativeTransform
    end
    
    methods
        function this = Linkage(options)
            arguments
                options.Name (1, 1) {mustBeTextScalar} = ""
                options.StlFilePath (1, 1) {mustBeTextScalar} = ""
                options.ScalingFactor (1, 1) double {mustBeReal, mustBePositive} = 1
                options.Parent {mustBeClassOrEmpty_(options.Parent, "Robot.Linkage")} = []
                options.RelativeTransform Robot.Transform = Robot.Transform()
            end
            
            this.ScalingFactor_ = options.ScalingFactor;
            if strlength(options.StlFilePath) > 0
                this.LoadGeometry(options.StlFilePath);
            end
            if ~isempty(options.Name)
                this.Name_ = options.Name;
            end

            this.RelativeTransform_ = options.RelativeTransform;
            this.RelativeTransformListener_ = addlistener(this.RelativeTransform_, "eMatrixChanged", @(~, ~) this.SetHasBeenMovedRecursive_);

            this.ChildByName_ = containers.Map();
            if ~isempty(options.Parent) 
                this.ConnectTo(options.Parent);
            else
                this.Parent = options.Parent;
            end
        end

        function this = LoadGeometry(this, stlFilePath)
            arguments
                this
                stlFilePath (1, 1) {mustBeTextScalar}
            end
            [this.Vertices_, this.Faces, this.Normals_, this.Name_] = stlTools.stlRead(stlFilePath);
            this.Vertices_ = horzcat(this.Vertices_ * this.ScalingFactor_, ones(this.VertexCount, 1));
        end

        function value = get.VertexCount(this)
            value = size(this.Vertices_, 1);
        end

        function name = get.Name(this)
            name = this.Name_;
        end
        function set.Name(this, name)
            arguments
                this
                name (1, 1) {mustBeTextScalar}
            end

            if ~isempty(this.Parent)
                if this.Parent.IsChild(name)
                    error("Linkage '%s' already has a child with name '%s'.", this.Parent.Name, name);
                end

                this.Parent.ChildByName_(name) = this;
                this.Parent.ChildByName_.remove(this.Name_);
            end
            this.Name_ = name;
        end

        function scalingFactor = get.ScalingFactor(this)
            scalingFactor = this.ScalingFactor_;
        end
        function set.ScalingFactor(this, scalingFactor)
            arguments
                this
                scalingFactor (1, 1) double {mustBeReal, mustBePositive}
            end

            if ~isempty(this.Vertices_)
                this.Vertices_(:, 1:3) = this.Vertices_(:, 1:3) * (scalingFactor / this.ScalingFactor_);
            end
            this.ScalingFactor_ = scalingFactor;
        end
        
        function relativeTransform = get.RelativeTransform(this)
            relativeTransform = this.RelativeTransform_;
        end
        function set.RelativeTransform(this, relativeTransform)
            arguments
                this
                relativeTransform Robot.Transform
            end
            delete(this.RelativeTransformListener_);
            this.RelativeTransformListener_ = addlistener(relativeTransform, "eMatrixChanged", @(~, ~) this.SetHasBeenMovedRecursive_);
            this.RelativeTransform_ = relativeTransform;
            this.SetHasBeenMovedRecursive_();
        end
        function absoluteTransformationMatrix = GetAbsoluteTransformationMatrix(this)
            if isempty(this.Parent)
                absoluteTransformationMatrix = this.RelativeTransform.Matrix;
            elseif this.HasBeenMoved_
                this.HasBeenMoved_ = false;
                absoluteTransformationMatrix = this.Parent.GetAbsoluteTransformationMatrix() * this.RelativeTransform.Matrix;
                this.AbsoluteTransformationMatrix_ = absoluteTransformationMatrix;
            else
                absoluteTransformationMatrix = this.AbsoluteTransformationMatrix_;
            end
        end
        function transformedVertices = GetTransformedVertices(this)
            transformedVertices = this.Vertices_ * this.GetAbsoluteTransformationMatrix()';
            transformedVertices = transformedVertices(:, 1:3);
        end

        % function set.Parent(this, parent)
        %     arguments
        %         this
        %         parent {mustBeClassOrEmpty_(parent, "Robot.Linkage")}
        %     end
        % 
        %     if ~isempty(parent) && parent.IsChild(this.Name_)
        %         error("Linkage '%s' already has a child with name '%s'.", parent.Name, this.Name_);
        %     end
        %     if ~isempty(this.Parent_)
        %         this.Parent_.RemoveChild(this.Name);
        %     end
        %     this.Parent_ = parent;
        %     this.SetHasBeenMovedRecursive_();
        % end
        % function parent = get.Parent(this)
        %     parent = this.Parent;
        % end
        function children = get.Children(this)
            children = this.ChildByName_.values;
        end
        function isChild = IsChild(this, name)
            arguments
                this
                name (1, 1) {mustBeTextScalar}
            end
            isChild = this.ChildByName_.isKey(name);
        end
        function this = ConnectTo(this, parentLinkage)
            arguments
                this
                parentLinkage (1, 1) Robot.Linkage
            end
            
            if parentLinkage.IsChild(this.Name)
                error("Linkage '%s' already has a child named '%s'.", parentLinkage.Name, this.Name);
            end
            if ~isempty(this.Parent)
                this.Disconnect();
            end
            this.Parent = parentLinkage;
            this.Parent.ChildByName_(this.Name_) = this;
            this.SetHasBeenMovedRecursive_();
        end
        function this = Disconnect(this)
            if isempty(this.Parent)
                return
            end

            this.Parent.ChildByName_.remove(this.Name_);
            this.Parent = [];
            this.SetHasBeenMovedRecursive_();
        end

        function delete(this)
            try
                this.Disconnect();
            
                children = this.ChildByName_.values;
                for i = 1 : this.ChildByName_.Count
                    children{i}.Disconnect();
                end
            end
        end
    end

    methods(Access = protected)
        function this = SetHasBeenMovedRecursive_(this)
            this.HasBeenMoved_ = true;
            children = this.ChildByName_.values;
            for i = 1 : this.ChildByName_.Count
                children{i}.SetHasBeenMovedRecursive_();
            end
        end
    end
end

function mustBeClassOrEmpty_(input, classString)
    eidType = 'mustBeClassOrEmpty:notClassOrEmpty';
    
    if isempty(input) || isa(input, classString)
        return
    end

    error(eidType, "Input must be empty or of class %s", classString);
end
