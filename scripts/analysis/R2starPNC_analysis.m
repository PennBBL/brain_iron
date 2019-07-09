
function R2starPNC_analysis
% Run basic age analyses on the PNC 2416 group for R2*

%% Setup variables
%%% Demographics
% this wasn't reading the dateformat correctly: 
% demographics = readtable('/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv');
% now we use this
importDemographics;
demographics.age = years(demographics.DOSCAN-demographics.dob);

%%% Clinical data
% Not doing longitudinal for now
%clin = readtable('/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/pnc_diagnosis_categorical_20170526.csv');
%demographics = outerjoin(demographics,clin(:,{'bblid','pncGrpPsych','pncGrpPsychosis','pncGrpPsychCl','pncGrpPsychosisCl'}),'Key','bblid','MergeKeys',true);
% T1
clin = readtable('/Users/larsenb/temp_from_chead/clinical/n1601_diagnosis_dxpmr_20170509.csv'); %temp while chead down
demographics = outerjoin(demographics,clin,'Keys',{'bblid','scanid'},'MergeKeys',true);
clin2 = readtable('/Users/larsenb/temp_from_chead/clinical/n1601_goassess_itemwise_psychosis_JCPP_factor_scores_20170331.csv');
demographics = outerjoin(demographics,clin2,'Keys',{'bblid','scanid'},'MergeKeys',true);

%%% Cognitive data
cog = readtable('/Users/larsenb/temp_from_chead/cnb/n1601_cnb_factor_scores_tymoore_20151006.csv');
demographics = outerjoin(demographics,cog,'Keys',{'bblid','scanid'},'MergeKeys',true);

%%% merge with R2* data
% t2 = readtable('../../results/t2star_ROIs.csv');
t2 = readtable('/Users/larsenb/temp_from_chead/results/t2star_ROIs.csv');
% convert T2* (msec) to R2* (1/sec)
fx = @(x) 1000./x; %function to convert
r2_vals = varfun(fx,t2,'InputVariables',4:width(t2)); %apply the fx
temp = r2_vals{:,:};
temp(isinf(r2_vals{:,:}))=nan; % Replace the infs
r2_vals{:,:} = temp;
r2 = t2;
r2{:,4:end} = r2_vals{:,:}; %Replace T2* with R2*

dataTable = outerjoin(demographics,r2,'keys',{'scanid','bblid'},'MergeKeys',true);
dataTable.bblid = categorical(dataTable.bblid);
dataTable.scanid = categorical(dataTable.scanid);
dataTable.ethnicity = categorical(dataTable.ethnicity);
% dataTable.sex = categorical(dataTable.sex);
dataTable.race = categorical(dataTable.race);
dataTable.invAge = 1./dataTable.age;

%% Visualize data

% figure;histogram(r2.Right_Accumbens_Area,20); 

%%  Models
rois = {'Right_Accumbens_Area','Left_Accumbens_Area','Right_Caudate','Left_Caudate','Right_Putamen','Left_Putamen','Right_Pallidum','Left_Pallidum'};%,'Left_Hippocampus','Right_Hippocampus'};
numRois = numel(rois);

for r = 1:numRois
    %% ROI
    fprintf(rois{r});
    fprintf('\n%s',rois{r});
    thisExc = dataTable{:,rois{r}}>25|dataTable{:,rois{r}}<10; % exclusions are arbitrary at this point
    %%% Age
%     lme = fitlme(dataTable,sprintf('%s ~ age + sex + (1|bblid)',rois{r}),'exclude',thisExc);
%     plotAdjustedLME(lme,'age'); snapnow
%     lme = fitlme(dataTable,sprintf('%s ~ invAge + sex + (1|bblid)',rois{r}),'exclude',thisExc)
%     plotAdjustedLME(lme,'invAge'); snapnow
    %%% Clinical scores
%     lm = fitlm(dataTable,sprintf('%s ~ Overall_Psychosis * age + sex',rois{r}),'exclude',thisExc)
%     lm = fitlm(dataTable,sprintf('%s ~ F1_Positive_2Fac * age + sex',rois{r}),'exclude',thisExc)
%     lm = fitlm(dataTable,sprintf('%s ~ F2_Negative_2Fac * age + sex',rois{r}),'exclude',thisExc)
%     lme = fitlme(dataTable,sprintf('%s ~ age*pncGrpPsych + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ invAge*pncGrpPsych + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ age*pncGrpPsychosis + (1|bblid)',rois{r}),'exclude',thisExc);
%     lme = fitlme(dataTable,sprintf('%s ~ invAge*pncGrpPsychosis + (1|bblid)',rois{r}),'exclude',thisExc);
    %%% Cog measures
    %overall
    ovs = {'Efficiency','Accuracy','Speed'};
    for v = 1:numel(ovs)
        lm = fitlm(dataTable,sprintf('%s ~ Overall_%s * age + sex',rois{r},ovs{v}),'exclude',thisExc);
        if lm.Coefficients.pValue(~cellfun(@isempty,regexp(lm.CoefficientNames,sprintf(':'))))<.05
            disp(lm);
            figure;
            plotInteraction(lm,sprintf('Overall_%s',ovs{v}),'age','predictions');
            t=get(gca,'title');
            t.Interpreter = 'none';
            set(gca,'title',t)
            
            dataTable.hi = dataTable{:,sprintf('Overall_%s',ovs{v})}>nanmean(dataTable{:,sprintf('Overall_%s',ovs{v})});
            dataTable.lo = dataTable{:,sprintf('Overall_%s',ovs{v})}<nanmean(dataTable{:,sprintf('Overall_%s',ovs{v})});
            lmh = fitlm(dataTable,sprintf('%s ~ age + sex',rois{r}),'exclude',dataTable.lo|thisExc);
            figure
            plotAdjustedResponse(lmh,'age');title('high performers');
            figure
            lml = fitlm(dataTable,sprintf('%s ~ age + sex',rois{r}),'exclude',dataTable.hi|thisExc);
            plotAdjustedResponse(lml,'age');title('low performers');
        end
        
%         lm = fitlm(dataTable,sprintf('Overall_%s ~ %s + age + sex',ovs{v},rois{r}),'exclude',thisExc);
%         if lm.Coefficients.pValue(strcmp(lm.CoefficientNames,sprintf('%s',rois{r})))<.05
%             disp(lm);
%             figure;
%             plotAdjustedResponse(lm,sprintf('%s',rois{r}));
%             t=get(gca,'title');
%             t.Interpreter = 'none';
%             set(gca,'title',t)
%         end
    end
    
%     %Exec
%     lm = fitlm(dataTable,sprintf('F1_Exec_Comp_Res_Accuracy ~ %s * age + sex',rois{r}),'exclude',thisExc)
%     lm = fitlm(dataTable,sprintf('F3_Executive_Efficiency ~ %s * age + sex',rois{r}),'exclude',thisExc)
%     lm = fitlm(dataTable,sprintf('F3_Memory_Accuracy ~ %s * age + sex',rois{r}),'exclude',thisExc)
%     lm = fitlm(dataTable,sprintf('F2_Memory_Efficiency ~ %s * age + sex',rois{r}),'exclude',thisExc)
%     
%     %Social
%     lm = fitlm(dataTable,sprintf('F2_Social_Cog_Accuracy ~ %s * age + sex',rois{r}),'exclude',thisExc)
%     lm = fitlm(dataTable,sprintf('F4_Social_Cognition_Efficiency ~ %s * age + sex',rois{r}),'exclude',thisExc)
    
    
end

function plotAdjustedLME(mdl,adVar)
figure;
dsnew = mdl.Variables(mdl.ObservationInfo.Subset,mdl.VariableInfo.InModel|strcmp(mdl.VariableNames,mdl.ResponseName));
dsold = mdl.Variables(mdl.ObservationInfo.Subset,mdl.VariableInfo.InModel|strcmp(mdl.VariableNames,mdl.ResponseName));
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
    if strcmp(adVar,'invAge')
        if dsold.sex(dsold.bblid==uId(id))==1
            plot(1./x,y,'-o','color','b','LineWidth',1,'MarkerFaceColor','b')
        elseif dsold.sex(dsold.bblid==uId(id))==2
            plot(1./x,y,'-o','color','r','LineWidth',1,'MarkerFaceColor','r')
        end
        eval(sprintf('h=plot(1./dsnew.%s,yhatM,''k'');',adVar));
    else
        if dsold.sex(dsold.bblid==uId(id))==1
            plot(x,y,'-o','color','b','LineWidth',1,'MarkerFaceColor','b')
        elseif dsold.sex(dsold.bblid==uId(id))==2
            plot(x,y,'-o','color','r','LineWidth',1,'MarkerFaceColor','r')
        end
        eval(sprintf('h=plot(dsnew.%s,yhatM,''k'');',adVar));
    end
%     text(x(1),y(1),char(uId(id)))
end
xlabel(adVar,'Interpreter','none');
ylabel(mdl.ResponseName,'Interpreter','none');