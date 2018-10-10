function R2starPNC_analysis
% Run basic age analyses on the PNC 2416 group for R2*

%% Setup variables
% Demographics
% this wasn't reading the dateformat correctly
% demographics = readtable('/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv');
% now we use this
importDemographics;
demographics.age = years(demographics.DOSCAN-demographics.dob);

% Clinical data
clin = readtable('/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/pnc_diagnosis_categorical_20170526.csv');
demographics = outerjoin(demographics,clin(:,{'bblid','pncGrpPsych','pncGrpPsychosis','pncGrpPsychCl','pncGrpPsychosisCl'}),'Key','bblid','MergeKeys',true);

% merge with R2* data
t2 = readtable('../../results/t2star_ROIs.csv');
% convert T2* (msec) to R2* (1/sec)
fx = @(x) 1000./x; %function to convert
r2_vals = varfun(fx,t2,'InputVariables',4:width(t2)); %apply the fx
r2 = t2;
r2{:,4:end} = r2_vals{:,:}; %Replace T2* with R2*

dataTable = outerjoin(demographics,r2,'keys',{'scanid','bblid'},'MergeKeys',true);
dataTable.bblid = categorical(dataTable.bblid);
dataTable.scanid = categorical(dataTable.scanid);
dataTable.ethnicity = categorical(dataTable.ethnicity);
dataTable.sex = categorical(dataTable.sex);
dataTable.race = categorical(dataTable.race);
dataTable.invAge = 1./dataTable.age;

%% Visualize data
% figure;histogram(r2.Right_Accumbens_Area,20); %Figure out why some extreme values and some negatives

%%  Models
rois = {'Right_Accumbens_Area','Left_Accumbens_Area','Right_Caudate','Left_Caudate','Right_Putamen','Left_Putamen','Right_Pallidum','Left_Pallidum','Left_Hippocampus','Right_Hippocampus'};
numRois = numel(rois);

for r = 1:numRois
    fprintf('\n%s',rois{r});
    thisExc = dataTable{:,rois{r}}>50|dataTable{:,rois{r}}<0;
    lme = fitlme(dataTable,sprintf('%s ~ age + sex + (1|bblid)',rois{r}),'exclude',thisExc) % exclusions are somewhat arbitrary at this point
    figure;plotAdjustedLME(lme,'age')
    lme = fitlme(dataTable,sprintf('%s ~ invAge + sex + (1|bblid)',rois{r}),'exclude',thisExc) % exclusions are somewhat arbitrary at this point
    figure;plotAdjustedLME(lme,'invAge')
%     lme = fitlme(dataTable,sprintf('%s ~ age*pncGrpPsych + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ age*sex*pncGrpPsych + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ invAge*pncGrpPsych + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ age*pncGrpPsychosis + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ invAge*pncGrpPsychosis + (1|bblid)',rois{r}),'exclude',thisExc);
end

function plotAdjustedLME(mdl,adVar)
figure;
dsnew = mdl.Variables(mdl.ObservationInfo.Subset,mdl.VariableInfo.InModel|strcmp(mdl.VariableNames,mdl.ResponseName));
dsold = mdl.Variables(mdl.ObservationInfo.Subset,mdl.VariableInfo.InModel|strcmp(mdl.VariableNames,mdl.ResponseName));
dsold.learners=mdl.Variables(mdl.ObservationInfo.Subset,strcmp(mdl.VariableNames,'learners'));
if ~exist('dsold.sex','var')
    dsold.sex = mdl.Variables.sex(mdl.ObservationInfo.Subset);
end
for v = 1:numel(mdl.PredictorNames)
    switch mdl.PredictorNames{v}
        case 'bblid'
            continue
        case adVar
            eval(sprintf('dsnew.%s = [min(dsnew.%s):(max(dsnew.%s)-min(dsnew.%s))/length(dsnew.%s):max(dsnew.%s)-(max(dsnew.%s)-min(dsnew.%s))/length(dsnew.%s)]'';',...
                mdl.PredictorNames{v},mdl.PredictorNames{v},mdl.PredictorNames{v},mdl.PredictorNames{v},mdl.PredictorNames{v},mdl.PredictorNames{v},...
                mdl.PredictorNames{v},mdl.PredictorNames{v},mdl.PredictorNames{v}));
        otherwise 
            if class(
            eval(sprintf('dsnew.%s(:) = mean(double(dsnew.%s));',mdl.PredictorNames{v},mdl.PredictorNames{v}));
    end
end

yhatM = predict(mdl,dsnew,'conditional',false);
% eval(sprintf('plot(dsold.%s,dsnew.%s,''o'')',adVar,mdl.ResponseName))
hold on
uId = unique(dsold.bblid);
for id = 1:length(uId)
    x = eval(sprintf('dsold.%s(dsold.bblid==uId(id))',adVar));
    y = eval(sprintf('dsold.%s(dsold.bblid==uId(id))',mdl.ResponseName));
    c = eval(sprintf('dsold.%s(dsold.bblid==uId(id),1)','learners'));
    if strcmp(adVar,'invAge')
        if dsold.sex(dsold.bblid==uId(id))==1
            plot(1./x,y,'-o','color','b','LineWidth',2,'MarkerFaceColor','b')
        elseif dsold.sex(dsold.bblid==uId(id))==0
            plot(1./x,y,'-o','color','r','LineWidth',2,'MarkerFaceColor','r')
        end
        eval(sprintf('h=plot(1./dsnew.%s,yhatM);',adVar));
    else
        if dsold.learners{dsold.bblid==uId(id),1}==0
            plot(x,y,'-o','color','b','LineWidth',2,'MarkerFaceColor','b')
        elseif dsold.learners{dsold.bblid==uId(id),1}==1
            plot(x,y,'-o','color','k','LineWidth',1,'MarkerFaceColor','k')
        end
        eval(sprintf('h=plot(dsnew.%s,yhatM,''k'');',adVar));
%         text(x(1),y(1),char(uId(id)))
    end
%     else
%         if dsold.sex(dsold.bblid==uId(id))==1
%             plot(x,y,'-o','color','b','LineWidth',2,'MarkerFaceColor','b')
%         elseif dsold.sex(dsold.bblid==uId(id))==0
%             plot(x,y,'-o','color','r','LineWidth',2,'MarkerFaceColor','r')
%         end
%         eval(sprintf('h=plot(dsnew.%s,yhatM,''k'');',adVar));
%     end
%     text(x(1),y(1),char(uId(id)))
end