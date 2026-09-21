function savePublication(fig,folder,name)
% Consistent light-background PNG, vector PDF, SVG and editable MATLAB figure.
if ~isfolder(folder),mkdir(folder);end
set(fig,'Color','w','InvertHardcopy','off');
ax=findall(fig,'Type','axes');
for i=1:numel(ax)
 set(ax(i),'Color','w','XColor',[.15 .2 .25],'YColor',[.15 .2 .25], ...
    'FontName','Arial','FontSize',15,'LineWidth',1,'Box','off', ...
    'GridColor',[.7 .75 .8],'GridAlpha',.35);
end
tx=findall(fig,'Type','text');set(tx,'Color',[.06 .14 .22],'FontName','Arial');
lg=findall(fig,'Type','legend');set(lg,'Color','w','TextColor',[.06 .14 .22], ...
    'FontName','Arial','Box','off','FontSize',13);
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',220,'BackgroundColor','white');
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
savefig(fig,fullfile(folder,[name '.fig']));
try,print(fig,fullfile(folder,[name '.svg']),'-dsvg');catch,end
close(fig);
end
