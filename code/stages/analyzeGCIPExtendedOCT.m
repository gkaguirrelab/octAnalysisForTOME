function analyzeGCIPExtendedOCT(GCIPthicknessFile)
%Purpose does some preliminary data analysis of the extended OCT
%segmentations and thickness values

load(GCIPthicknessFile);

validInd = find(sum(dataAvailable,2) > 1);
N = size(validInd);
%only load cases where data exists for both eyes
GCthick_Valid = GCthicknessValuesAtXPos(validInd,:,:);
IPthick_Valid = IPthicknessValuesAtXPos(validInd,:,:);

GCthick_Valid_OD = squeeze(GCthick_Valid(:,1,:));
GCthick_Valid_OS_flipped = squeeze(flip(GCthick_Valid(:,2,:),3));

IPthick_Valid_OD = squeeze(IPthick_Valid(:,1,:));
IPthick_Valid_OS_flipped = squeeze(flip(IPthick_Valid(:,2,:),3));

%flip OS and average
GCthick_ValidAvgEyes = (GCthick_Valid_OD+GCthick_Valid_OS_flipped)/2;
IPthick_ValidAvgEyes = (IPthick_Valid_OD+IPthick_Valid_OS_flipped)/2;

%plot(XPos_Degs,GCthicknessValuesAtXPos_ValidAvg)
figure(1)
plot(XPos_Degs,GCthick_ValidAvgEyes)
title('GC Thicknesses (N = 26)')
xlabel('Location (Degrees)')
ylabel('Thickness (Pixel)')

figure(2)
plot(XPos_Degs,IPthick_ValidAvgEyes);
title('IP Thicknesses (N = 26)')
xlabel('Location (Degrees)')
ylabel('Thickness (Pixel)')

figure(3)
plot(XPos_Degs,[mean(GCthick_ValidAvgEyes,1); mean(IPthick_ValidAvgEyes,1)]);
title('Mean GC/IP Thickness (N = 26)')
legend({'GC','IP'});
xlabel('Location (Degrees)')
ylabel('Thickness (Pixel)')

figure(4)
prcntGC = GCthick_ValidAvgEyes./(GCthick_ValidAvgEyes+IPthick_ValidAvgEyes);
plot(XPos_Degs,prcntGC)
title('Mean GC/(GC+IP) ratio (N = 26)')
xlabel('Location (Degrees)')
ylabel('Ratio')

figure(5)
prcentIP = IPthick_ValidAvgEyes./(GCthick_ValidAvgEyes+IPthick_ValidAvgEyes);
plot(XPos_Degs,prcentIP)
title('Mean IP/(GC+IP) ratio (N = 26)')
xlabel('Location (Degrees)')
ylabel('Ratio')

figure(6)
plot(XPos_Degs,[mean(prcntGC,1); mean(prcentIP,1)]);
title('Mean GC/(GC+IP) and IP/(GC+IP) ratio (N = 26)')
legend({'GC','IP'},'Location','best');
xlabel('Location (Degrees)')
ylabel('Ratio')


end
