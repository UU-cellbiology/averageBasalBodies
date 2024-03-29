%% parameters
% column numbers corresponding to the coordinates
colNX = 4;
colNY = 5;
colNZ = 6;
%if Z slice numbering starts from 0 or 1
bZSliceZero = 1;
%output ROI width (in pixels)
nOutThickness = 105;

dirname = uigetdir ();
%dirname = '/home/eugene/workspace/extractBasalBodies/20240219_new_data/aligned';
files = glob(strcat(dirname,'/*.csv'));
mkdir(dirname,'BT_rois');
file_out = fopen(strcat(dirname,'/BT_rois/Output_btrois.csv'), 'w');
fprintf(file_out,'BigTrace_groups,version,0.3.0\n');
fprintf(file_out,'GroupsNumber,1\nBT_Group,1\nName,*undefined*\n');
fprintf(file_out,'PointSize,4\nPointColor,0,255,0,255\n');
fprintf(file_out,'LineThickness,%d\nLineColor,0,0,255,255\n',nOutThickness);
fprintf(file_out,'RenderType,2\n');
fprintf(file_out,'End of BigTrace Groups\n');
fprintf(file_out,'BigTrace_ROIs,version,0.3.0\n');
fprintf(file_out,'ROIsNumber,%d\n',numel(files));

%i=1;
for i=1:numel(files)
  datain = importdata(files{i});
  data = datain.data;
  filename = substr(files{i},length(dirname)+2,length(files{i})-length(dirname)-5);
  xyz = horzcat(data(:,colNX),data(:,colNY),data(:,colNZ));
  totP = length(xyz(:,1));
  if bZSliceZero>0
    xyz(:,3)=xyz(:,3)-1;
  fprintf(file_out,'BT_Roi,%d\nType,LineTrace\n',i);
  fprintf(file_out,'Name,%s\n',filename);
  fprintf(file_out,'GroupInd,0\n');
  fprintf(file_out,'TimePoint,0\n');
  fprintf(file_out,'PointSize,4\nPointColor,0,255,0,255\n');
 fprintf(file_out,'LineThickness,%d\nLineColor,0,0,255,255\n',nOutThickness);
 fprintf(file_out,'RenderType,2\n');
  fprintf(file_out,'Vertices,2\n');
  fprintf(file_out,'%d,%d,%d\n',xyz(1,1),xyz(1,2),xyz(1,3));
  fprintf(file_out,'%d,%d,%d\n',xyz(end,1),xyz(end,2),xyz(end,3));
  fprintf(file_out,'SegmentsNumber,1\n');
  fprintf(file_out,'Segment,1,Points,%d\n',totP);
 for vert=1:totP
   fprintf(file_out,'%d,%d,%d\n',xyz(vert,1),xyz(vert,2),xyz(vert,3));
   endfor
  endif
 endfor
fprintf(file_out,' End of BigTrace ROIs');

fclose(file_out);
disp('Done');
