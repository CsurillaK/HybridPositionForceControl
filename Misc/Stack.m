classdef Stack < handle
    properties(Access = protected)
        Stack_ = {}
    end

    methods
        function Push(this, element)
            this.Stack_{end+1} = element;
        end
        function element = Pop(this)
            this.CheckForEmptyStack_();
            element = this.Stack_{end};
            this.Stack_(end) = [];
        end
        function element = Top(this)
            this.CheckForEmptyStack_();
            element = this.Stack_{end};
        end
        end
    
    methods(Access = protected)
        function CheckForEmptyStack_(this)
            if isempty(this.Stack_)
                error("Stack is empty!");
            end
        end
    end
end