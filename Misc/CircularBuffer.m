classdef CircularBuffer < handle
    
    properties (SetAccess = private)
        Dimension
        Length
        Data
    end
    properties (Access = private)
        Pointer = 0;
        Amount = 0;
    end
    properties (Dependent)
        IndexedData
        LastData
    end
    
    methods
        
        function obj = CircularBuffer(input_matrix)
            
            if ~isnumeric(input_matrix)
                error('CircularBuffer constructor parameter must be numeric array.');
            end
            
            obj.Dimension = size(input_matrix,1);
            obj.Length = size(input_matrix,2);
            obj.Data = input_matrix;
            obj.Pointer = obj.Length;
            
        end
        
        function obj = Push(obj,newdata)
            
            P = obj.Pointer;
            L = obj.Length;
            A = obj.Amount;
            obj.Pointer = Increment(P,L);
            obj.Amount = min(A+1,L);
            
            obj.Data(:,obj.Pointer) = newdata;
            
        end
        
        function output_mx = get.IndexedData(obj)
            
            P = obj.Pointer;
            L = obj.Length;
            A = obj.Amount;
            
            output_mx = obj.Data(:,CircularIndex(P-A+1:P,L));
            
        end
        
        function output_vec = get.LastData(obj)
            output_vec = obj.Data(:,obj.Pointer);
        end
        
        function Reset(this)
            
            this.Amount = 0;
            %this.Push(zeros(this.Dimension, 1));
            
        end
    end
end

function output_val = Increment(x,length)

if x >= length
    x = 0;
end

output_val = x + 1;

end

function output_vec = CircularIndex(index,length)
output_vec = index - length*floor((index-1)/length);
end