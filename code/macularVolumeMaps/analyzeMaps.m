function analyzeMaps(thicknessMapDir, volumeMapDir, saveDir, varargin)
% Do some analysis
%
% Description:
%   Foo
%


%% Parse vargin for options passed here
p = inputParser;

% Required
p.addRequired('thicknessMapDir',@ischar);
p.addRequired('volumeMapDir',@ischar);
p.addRequired('saveDir',@ischar);

% Optional analysis params
p.addParameter('subjectTableFileName',fullfile(getpref('retinaTOMEAnalysis','dropboxBaseDir'),'TOME_subject','TOME-AOSO_SubjectInfo.xlsx'),@ischar);
p.addParameter('layerSetLabels',{'RGCIPL','RNFL','OPL','TotalRetina'},@iscell);
p.addParameter('showPlots',false,@islogical);

%% Parse and check the parameters
p.parse(thicknessMapDir, volumeMapDir, saveDir, varargin{:});



% Load the subject data table
opts = detectImportOptions(p.Results.subjectTableFileName);
subjectTable = readtable(p.Results.subjectTableFileName, opts);
axialLength = subjectTable.Axial_Length_average;

% Load the overlapMaps
inFile = fullfile(thicknessMapDir,'overlapMaps.mat');
load(inFile,'overlapMaps');


subIDs = dir(fullfile(volumeMapDir,'1*'));

%We're going to look at some measurements, this describes
measurements = zeros(length(subIDs),9);%this will be out ouput matrix
%This describes each column in the measurements
header = {'subject ID', 'RGCIPL mean thickness', 'RGCIPL mean volume', ...
    'RNFL mean thickness', 'RNFL mean volume', ...
    'OPL mean thickness', 'OPL mean volume', ...
    'Total Retina mean thickness', 'Total Retina mean volume'};


for layer = 1:length(p.Results.layerSetLabels) %L controls which layer we're looking
    
    %now that we've got the overlap, we go back through and calculate the
    %mean for each subject across the overlap
    overlap = ~isnan(overlapMaps.(p.Results.layerSetLabels{layer}));
    
    
    for ss = 1:length(subIDs)
        LoadthicknessMap=load(fullfile(thicknessMapDir,subIDs(ss).name,[subIDs(ss).name '_averageMaps.mat']));
        
        thicknessMap = LoadthicknessMap.averageMaps.(p.Results.layerSetLabels{layer});
        loadname = fullfile(volumeMapDir, subIDs(ss).name, [subIDs(ss).name '_' p.Results.layerSetLabels{layer} '_volumeMap.mat']);
        load(loadname,'volumeMap_mmCubedDegSquared');
        
        measurements(ss,1) = str2double(subIDs(ss).name);
        measurements(ss,2*layer) = mean(thicknessMap(overlap));
        measurements(ss,2*layer+1) =  mean(volumeMap_mmCubedDegSquared(overlap));
    end
    
end

% Add axial length
measurements(:,10)=axialLength;


filename = fullfile(saveDir,'meanThicknessAndVolumes.xlsx');
xlswrite(filename,header,1,'A1');
xlswrite(filename,measurements,1,'A2');