function [adjustedGCVolPCACoeff,synGCVolPCACoeff,synthALRange] = adjustAndSynthPCAWithAxialLength(nDimsToUse,GCVolPCACoeff,axialLengths)

corrCoeffAxialLength = nan(1,nDimsToUse);
corrCoeffAxialLength_pVal = nan(1,nDimsToUse);
fprintf('Correlation axial length with PCA coefficients:\n');
for ii = 1:nDimsToUse
    [corrCoeffAxialLength(ii), corrCoeffAxialLength_pVal(ii)] = corr(axialLengths,real(GCVolPCACoeff(:,ii)),'rows','complete');
    txt = sprintf('\tPC%d: %2.2f with p=%2.4f\n',ii,corrCoeffAxialLength(ii),corrCoeffAxialLength_pVal(ii));
    fprintf(txt);
end

% Regress the axial length upon the coefficients
X = [GCVolPCACoeff(:,1:nDimsToUse)'; ones(1,50)]';
b = X\axialLengths;

% % Show regression fit of PCA and axial length
figure
plot(axialLengths,X*b,'*r');
axis square
refline(1,0);


adjustedGCVolPCACoeff = zeros(size(GCVolPCACoeff));
ALmax= max(axialLengths);
ALmin= min(axialLengths);
synthALRange = linspace(ALmin,ALmax,50);%synth range for AL
synGCVolPCACoeff = zeros(50,nDimsToUse);
for d=1:nDimsToUse
    
    currCoeff = GCVolPCACoeff(:,d);
    %find regression line between PC coeff and  axial length
    pp = polyfit(axialLengths,currCoeff,1);
    
    %find PC coeff value for emmetrope
    %Adjust each score by fraction: coeff_emm / coeff_regress
    AL_emmetrope_mm=23.58;
    adjustProportion_allSub = polyval(pp,AL_emmetrope_mm) - polyval(pp,axialLengths);
    adjustedGCVolPCACoeff(:,d) = currCoeff + adjustProportion_allSub;
    
    %Save synthesized representation of AL
    synGCVolPCACoeff(:,d) = polyval(pp,synthALRange);
end