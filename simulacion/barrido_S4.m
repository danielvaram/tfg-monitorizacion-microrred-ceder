%% barrido_S4.m
%  Barrido del escenario S4 (medidas sincronizadas / sincrofasores) sobre el
%  modelo monitor_ceder_S4.slx. Cinco equipos emiten 50 tramas/s (tipo C37.118),
%  lo que añade 250 transacciones/s al sondeo y compite con el en Node-RED.
%
%  El interés del escenario no es el volúmen en bytes (las tramas son pequeñas)
%  sino el efecto de esas transacciones adicionales sobre la concurrencia: por
%  eso se barre c. La precisión de la sincronización (NTP vs PTP) queda fuera del
%  alcance del modelo de carga y se discute cualitativamente en la memoria.
%
%  Requiere: monitor_ceder_S4.slx con un generador GenPMU (50 tramas/s por equipo,
%  nPMU equipos, Lbytes = 110) y el generador de calidad de onda desactivado.
%
%  Trabajo Fin de Grado - Daniel Varela Ramírez - ETSIT-UPM - 2026
% -------------------------------------------------------------------------

clear; clc;

mdl = 'monitor_ceder_S4';
load_system(mdl);

% --- Parametros fijos ---
nPMU    = 5;         % numero de equipos emitiendo sincrofasores
tResp   = 0.0287;    % tiempo de servicio de Node-RED [s]
lambda0 = 134.7;     % tasa de sondeo base [trans/s]
stopTime = 100;

% --- Barrido de la concurrencia ---
concurr = [4 8 16];

filas = {};
for c = concurr
    in = Simulink.SimulationInput(mdl);
    in = in.setVariable('nPMU', nPMU);
    in = in.setVariable('c', c);
    in = in.setVariable('tResp', tResp);
    in = in.setVariable('lambda0', lambda0);
    in = in.setModelParameter('StopTime', num2str(stopTime));

    out = sim(in);

    utilN = out.util_nodered.Data(end);
    espera = out.w_queue.Data(end);

    filas(end+1,:) = {c, utilN, espera};
end

R4 = cell2table(filas, 'VariableNames', {'c','util_nodeRED','espera_cola_s'});
disp(R4);
writetable(R4, 'resultados_S4.xlsx');
fprintf('\nResultados guardados en resultados_S4.xlsx\n');
fprintf('Carga anadida por sincrofasores: %d trans/s\n', nPMU*50);
