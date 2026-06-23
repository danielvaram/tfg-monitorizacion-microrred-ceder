%% figuras_resultados.m
%  Genera las Figuras 6.1 y 6.2 del Capitulo 6 a partir de la tabla de
%  resultados del barrido (resultados.xlsx).
%
%  Trabajo Fin de Grado - Daniel Varela Ramírez - ETSIT-UPM - 2026
% -------------------------------------------------------------------------

R = readtable('../simulacion/resultados.xlsx');
cs = unique(R.c)';

% --- Figura 6.1: utilizacion de Node-RED frente a fFactor ---
figure('Color','w'); hold on; grid on;
for cc = cs
    M = sortrows(R(R.c==cc,:), 'fFactor');
    plot(M.fFactor, M.util_nodeRED, '-o', 'LineWidth',1.4, 'MarkerFaceColor','w', 'DisplayName', sprintf('c = %d', cc));
end
yline(1, '--', 'Saturación', 'Color',[.4 .4 .4]);
xlabel('Factor de escala de la tasa (fFactor; 1 = operación actual)');
ylabel('Utilización de Node-RED');
ylim([0 1.15]); legend('Location','southeast'); box on;
set(gca,'XColor',[0 0 0],'YColor',[0 0 0]);
exportgraphics(gcf, 'fig6_1_util_vs_fFactor.png', 'Resolution', 300);

% --- Figura 6.2: espera media en cola (solo régimen no saturado) ---
figure('Color','w'); hold on; grid on;
for cc = cs
    M = sortrows(R(R.c==cc,:), 'fFactor');
    ns = M(M.saturado==0, :);     % solo puntos no saturados
    if ~isempty(ns)
        plot(ns.fFactor, ns.espera_cola_s*1000, '-o', 'LineWidth',1.4, 'MarkerFaceColor','w', 'DisplayName', sprintf('c = %d', cc));
    end
end
xlabel('Factor de escala de la tasa (fFactor)');
ylabel('Espera media en cola, régimen no saturado (ms)');
legend('Location','northwest'); box on;
set(gca,'XColor',[0 0 0],'YColor',[0 0 0]);
exportgraphics(gcf, 'fig6_2_espera_vs_fFactor.png', 'Resolution', 300);

fprintf('Figuras 6.1 y 6.2 generadas.\n');
