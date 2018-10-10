function relabel_02_2

t = readtable('/data/jux/BBL/projects/brain_iron/results/t2star_ROIs_noName.csv','TreatAsEmpty','NA');
l = readtable('/data/jux/BBL/projects/brain_iron/results/OASIS30Labels.csv');

l.Label_Name(strcmp(l.Label_Name,'3rd Ventricle'))={'Third_Ventricle'};
l.Label_Name(strcmp(l.Label_Name,'4th Ventricle'))={'Fourth_Ventricle'};
l.Label_Name(strcmp(l.Label_Name,'5th Ventricle'))={'Fifth_Ventricle'};
l.Label_Name = strrep(l.Label_Name,' ','_');
l.Label_Name = strrep(l.Label_Name,'-','');
t.Properties.VariableNames(l.Label_Number+4) = l.Label_Name;
t.Properties.VariableNames(1:4) = {'bblid','scanid','t2fname','subbrik'};
%t = removevars(t,'subbrik'); %this function does not exist in older matlab versions
t = t(:,~strcmp(t.Properties.VariableNames,'subbrik'));

writetable(t,'/data/jux/BBL/projects/brain_iron/results/t2star_ROIs.csv');