%% barrido_S0.m
%  Barrido automático de los escenarios S0-S2 sobre el modelo monitor_ceder_S0.slx.
%  Recorre la malla de factores de escala de la tasa (fFactor) y concurrencias (c),
%  ejecuta cada simulación, recoge las estadísticas de SimEvents y consolida los
%  resultados en una tabla que se exporta a Excel para elaborar el Capítulo 6.
%
%  Requiere: parametros.m (parametros base) y el modelo
%  monitor_ceder_S0.slx con los bloques To Workspace nombrados util_nucleo,
%  util_nodered, n_queue y w_queue (formato Timeseries).
%
%  Trabajo Fin de Grado - Daniel Varela Ramírez - ETSIT-UPM - 2026
% -------------------------------------------------------------------------

clear; clc;
run('../parametros/parametros.m');

mdl = 'monitor_ceder_S0';
load_system(mdl);

% ---- Barrido ----
fFactores = [0.5 1 2 4 8 16];     % escala de la tasa respecto a la actual
concurr   = [1 2 4 8 16];         % concurrencia de Node-RED
stopTime = 100;                   % duracion de cada simulacion [s]
descarte = 10;                    % transitorio de arranque a descartar [s]

filas = {};
for ff = fFactores
    for cc = concurr
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('lambda0', lambda0);
        in = in.setVariable('fFactor', ff);
        in = in.setVariable('c', cc);
        in = in.setVariable('tResp', tResp);
        in = in.setVariable('Cenlace', Cenlace);
        in = in.setVariable('L', L);
        in = in.setVariable('periodGen', 1/(lambda0*ff));
        in = in.setVariable('tNucleo', L*8/Cenlace);
        in = in.setModelParameter('StopTime', num2str(stopTime));

        out = sim(in);

        utilN = mediaTrasDescarte(out.util_nodered, descarte);
        utilC = mediaTrasDescarte(out.util_nucleo,  descarte);
        espera = mediaTrasDescarte(out.w_queue, descarte);
        colaMax = maxTrasDescarte(out.n_queue, descarte);

        rho = ff*lambda0*tResp/cc;
        saturado = (utilN >= 0.99) && (colaMax > 50);

        filas(end+1,:) = {ff, tResp, cc, rho, utilC, utilN, espera, colaMax, tResp + espera, double(saturado)};
    end
end

R = cell2table(filas, 'VariableNames', {'fFactor','tResp','c','rho_teorica','util_nucleo','util_nodeRED', 'espera_cola_s','cola_max','latencia_s','saturado'});

disp(R);
writetable(R, 'resultados.xlsx');
fprintf('\nResultados guardados en resultados.xlsx\n');

% ---- Concurrencia ----
fprintf('\nFrontera de saturación (primer fFactor que satura):\n');
for cc = concurr
    sub = R(R.c==cc, :);
    sat = sub.fFactor(sub.saturado==1);
    if isempty(sat)
        fprintf('  c = %2d: no satura en el rango ensayado\n', cc);
    else
        fprintf('  c = %2d: satura a partir de fFactor = %g\n', cc, min(sat));
    end
end

% --- Funciones auxiliares ---
function m = mediaTrasDescarte(ts, t0)
    idx = ts.Time >= t0;
    m = mean(ts.Data(idx));
end
function mx = maxTrasDescarte(ts, t0)
    idx = ts.Time >= t0;
    mx = max(ts.Data(idx));
end
