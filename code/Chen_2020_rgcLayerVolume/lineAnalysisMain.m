function lineAnalysisMain(varargin)
% Conducts analyses and creates figures for:
%
%   Chen 2020, Title here
%
% The routine assumes that pre-processing of the horizontal line-scans has
% been conducted using preProcessLineScans.m
%
% The default locations of files should work if the LocalHook for this repo
% has been properly configured.
%
% Examples:
%{
    % Run for the horizontal line data
    dropboxBaseDir=fullfile(getpref('retinaTOMEAnalysis','dropboxBaseDir'));
    orientation = 'horiz';
    GCIPthicknessFile = fullfile(dropboxBaseDir,'AOSO_analysis','OCTExplorerExtendedHorizontalData','GCIP_thicknessesByDeg');
    saveDir = fullfile(dropboxBaseDir,'AOSO_analysis','GCPaperFigures_horiz');
    lineAnalysisMain('orientation',orientation,'GCIPthicknessFile',GCIPthicknessFile,'saveDir',saveDir);
%}
%{
    % Run for the vertical line data
    dropboxBaseDir=fullfile(getpref('retinaTOMEAnalysis','dropboxBaseDir'));
    orientation = 'vert';
    GCIPthicknessFile = fullfile(dropboxBaseDir,'AOSO_analysis','OCTSingleVerticalData','GCIP_thicknessesByDeg');
    saveDir = fullfile(dropboxBaseDir,'AOSO_analysis','GCPaperFigures_vert');
    lineAnalysisMain('orientation',orientation,'GCIPthicknessFile',GCIPthicknessFile,'saveDir',saveDir);
%}

%% Set the dropboxBaseDir
% We need this for the default loations of some the directories
dropboxBaseDir=fullfile(getpref('retinaTOMEAnalysis','dropboxBaseDir'));
%dropboxBaseDir ='C:\Users\dontm\Dropbox (Aguirre-Brainard Lab)';


%% Parse vargin
p = inputParser;

% Optional analysis params
p.addParameter('showPlots',true,@islogical);
p.addParameter('GCIPthicknessFile',fullfile(dropboxBaseDir, 'AOSO_analysis','OCTExplorerExtendedHorizontalData','GCIP_thicknessesByDeg'),@ischar);
p.addParameter('eyeModelsFileName',fullfile(dropboxBaseDir,'AOSO_analysis','eyeModels','eyeModels.mat'),@ischar);
p.addParameter('subjectTableFileName',fullfile(dropboxBaseDir,'TOME_subject','TOME-AOSO_SubjectInfo.xlsx'),@ischar);
p.addParameter('anatMeasuresFileName',fullfile(getpref('retinaTOMEAnalysis','projectBaseDir'),'data','visualPathwayAnatMeasures.xlsx'),@ischar);
p.addParameter('saveDir',fullfile(dropboxBaseDir,'AOSO_analysis','GCPaperFigures_horiz'),@ischar);
p.addParameter('smoothPCAFactor',0.5,@isscalar);
p.addParameter('orientation','horiz',@ischar); % or vert

% Check the parameters
p.parse(varargin{:});


%% Create Save Directory
saveDir = p.Results.saveDir;
nFigs = 10;
mkdir(saveDir);
for ii = 1:nFigs
    mkdir(fullfile(saveDir,['fig' num2str(ii)]));
end


% Loads the GC profiles, mean gc profile, bad indexes, subject list, and X
% positions
[gcVec,meanGCVecProfile,badIdx,subList,XPos_Degs,subjectTable,thicknessTable] =  loadAndMergeData(p);

% Converts GC thickness into GC volume and provide mmSqPerDegSq conversion
% for each subject
[mmSqPerDegSq,gcVolumePerDegSq,meanGCVolumePerDegSqProfile,volumeTable] = convertThicknessToVolume(p,gcVec,badIdx,subList,XPos_Degs,subjectTable,p.Results.orientation);

% Join the thickness and volume data table with the subject biometry and
% demographics table, using the AOSO_ID as the key variable
gcTable = join(thicknessTable,volumeTable,'Keys','AOSO_ID');
comboTable = join(gcTable,subjectTable,'Keys','AOSO_ID');

% Save these variables
saveName = fullfile(saveDir,'gcVolumeData.mat');
save(saveName,'gcVolumePerDegSq','badIdx','XPos_Degs','comboTable','subList');

nDimsToUse = 6; % number of PCA components to use.


%% Conduct PCA upon the tissue volume data
% Perform the PCA and smooth components
[GCVolPCAScoreExpanded, GCVolPCAScoreExpandedSmoothed, GCVolPCACoeff, GCVolPCAVarExplained] = createVolumePCA(gcVolumePerDegSq,badIdx,XPos_Degs,nDimsToUse,p.Results.smoothPCAFactor,p.Results.orientation);

% Adjust each coeff with the axial length contribution, also create some
% synthetic ones
[adjustedGCVolPCACoeff,synGCVolPCACoeff] = adjustAndSynthPCAWithAxialLength(nDimsToUse,GCVolPCACoeff,comboTable.Axial_Length_average);


%% Create and save plots if so instructed
if p.Results.showPlots
    close all;
    
    % Pull up an example montage and individual pieces
    fig1_ShowMontage(dropboxBaseDir, saveDir)
    
    % Plots Relating GC thickness and volume to axial length
    fig2_ThickAndVolRelationships(XPos_Degs, gcVec, meanGCVecProfile, mmSqPerDegSq, gcVolumePerDegSq, meanGCVolumePerDegSqProfile,comboTable,saveDir)
    
    % Panel d of figure 2 is a couple of extreme model eyes
    fig2d_ExtremeEyes(saveDir)
    
    % Show the effect of smoothing on each of the PCA scores
    fig3_EffectOfSmoothingOnPCA(GCVolPCAVarExplained,GCVolPCAScoreExpanded,GCVolPCAScoreExpandedSmoothed,nDimsToUse,saveDir)
    
    % Reconstruct original profiles using smoothed and first 'nDimsToUse'
    % components to show they still looks correct
    fig4_smoothedPCAReconstruction(gcVolumePerDegSq,GCVolPCAScoreExpandedSmoothed,GCVolPCACoeff,nDimsToUse,saveDir)
    
    % Look at how each PCA component regresses with axial length
    fig5_PCACompRegressionAxialLength(comboTable.Axial_Length_average,GCVolPCACoeff,nDimsToUse,saveDir)
    
    % Plot the reconstructions of each of the profiles after adjusting the PCs
    % to remove the influence of axial length (subjects sorted by axial length)
    fig6_AxialLengthAdjustedReconstruction(comboTable.Axial_Length_average,gcVolumePerDegSq,GCVolPCAScoreExpandedSmoothed,adjustedGCVolPCACoeff,nDimsToUse,saveDir)
    
    % Using PCA, show how axial length will effect the average emmetropic profile
    fig7_SynthesizeALImpactOnEmmEye(GCVolPCAScoreExpandedSmoothed,synGCVolPCACoeff,XPos_Degs,saveDir)
    
    % Show AL adjusted profiles stacked, and their mean/median relationship with axial length before/after adjustment
    fig8_VolRelationshipAfterAdjustment(XPos_Degs,comboTable,GCVolPCAScoreExpandedSmoothed,adjustedGCVolPCACoeff,GCVolPCACoeff,gcVolumePerDegSq,nDimsToUse,saveDir)
    
    % Synthetic profiles that demonstrate the appearance of eyes of
    % different sizes, cast in different coordinate systems
    fig9_SynthProfileAndALRelationship(GCVolPCACoeff,comboTable.Axial_Length_average,XPos_Degs,comboTable,GCVolPCAScoreExpandedSmoothed,nDimsToUse,saveDir,p.Results.orientation)
    
    % Relationship between retinal thickness, volume, and optic chiasm size
    fig10_postRetinalAnatomy(p,GCVolPCACoeff,gcVolumePerDegSq,adjustedGCVolPCACoeff,comboTable,GCVolPCAScoreExpandedSmoothed,nDimsToUse,subList,saveDir)
    
end

end

