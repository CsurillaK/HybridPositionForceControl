function [v, f, n, name] = stlRead(fileName)
%STLREAD reads any STL file not depending on its format
%V are the vertices
%F are the faces
%N are the normals
%NAME is the name of the STL object (NOT the name of the STL file)

format = stlTools.stlGetFormat(fileName);
if strcmp(format,'ascii')
  [v,f,n,name] = stlTools.stlReadAscii(fileName);
elseif strcmp(format,'binary')
  [v,f,n,name] = stlTools.stlReadBinary(fileName);
end