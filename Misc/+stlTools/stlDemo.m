%% STLDEMO shows how to use the functions included in the toolbox STLTOOLS

%% EXAMPLE 1.- How to cut a sphere and close the base to get a semisphere

% load an ascii STL sample file (STLGETFORMAT and STLREADASCII)
[vertices,faces,normals,name] = stlTools.stlRead('./+stlTools/sphere_ascii.stl');
stlTools.stlPlot(vertices,faces,name);

% the sphere is centered in the origin
% now we get a list of vertices to be deleted if (x,y,z<0)
minZ = 0;
[rows, ~] = find(vertices(:,3) < minZ);
list = vertices(rows,:);

% if we delete the list of vertices with z<0, we get an opened semisphere 
% (as the base is not closed)
[newv,newf] = stlTools.stlDelVerts(vertices,faces,list);
stlTools.stlPlot(newv,newf,name);

% the next step is to identify a new list with the faces that are opened
% (that means all the sides that belong only to a unique triangle)
list = stlTools.stlGetVerts(newv,newf,'opened');

% finally we generate all the new faces that are needed just to close the 
% base of the semisphere
[vsemi,fsemi] = stlTools.stlAddVerts(newv,newf,list);
stlTools.stlPlot(vsemi,fsemi,'closed semisphere');

%% EXAMPLE 2.- How to get a section of a femur

[vertices,faces,normals,name] = stlTools.stlRead('./+stlTools/femur_binary.stl');
stlTools.stlPlot(vertices,faces,name);

minX = 1.2;
[rows, ~] = find(vertices(:,1) < minX);
list = vertices(rows,:);

[newv,newf] = stlTools.stlDelVerts(vertices,faces,list);
stlTools.stlPlot(newv,newf,'section of the femur');
