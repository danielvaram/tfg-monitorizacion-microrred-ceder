%% barrido_S3.m
%  Barrido del escenario S3 (captura de calidad de onda) sobre el modelo
%  monitor_ceder_S3.slx. Quince analizadores emiten forma de onda en flujo
%  continuo (tramas de 1500 bytes) a una tasa ratePQ por analizador; una cola
%  finita delante del núcleo permite observar la saturacion y las perdidas.
%
%  El núcleo deja de ser despreciable: su tiempo de servicio depende del tamaño
%  de cada entidad (dt = entity.Lbytes*8/Cenlace), de modo que las tramas grandes
%  de calidad de onda lo saturan. Las perdidas se calculan por diferencia entre
%  entidades generadas y entidades llegadas al Terminator.
%
%  Requiere: monitor_ceder_S3.slx con un segundo Entity Generator (GenPQ), el
%  atributo Lbytes en ambos generadores, una Entity Queue de capacidad 100 y la
%  estadística 'a' (number arrived) del Terminator exportada como n_terminadas.
%
%  Trabajo Fin de Grado - Daniel Varela Ramírez - ETSIT-UPM - 2026
% -------------------------------------------------------------------------

clear; clc;

mdl = 'monitor_ceder_S3';
load_system(mdl);

% --- Parametros fijos ---
Cenlace = 100e6;     % capacidad del enlace [bit/s]
Lpq     = 1500;      % tamaño de trama de calidad de onda [bytes]
tResp   = 0.0287;    % tiempo de servicio de Node-RED [s]
c       = 8;         % concurrencia (holgada para aislar el efecto del núcleo)
lambda0 = 134.7;     % tasa de sondeo base [trans/s]
stopTime = 100;

% --- Barrido por analizador ---
rates = [50 100 200 500];     % tramas/s por cada uno de los 15 analizadores

filas = {};
for ratePQ = rates
    in = Simulink.SimulationInput(mdl);
    in = in.setVariable('ratePQ', ratePQ);
    in = in.setVariable('Lpq', Lpq);
    in = in.setVariable('c', c);
    in = in.setVariable('tResp', tResp);
    in = in.setVariable('Cenlace', Cenlace);
    in = in.setVariable('lambda0', lambda0);
    in = in.setModelParameter('StopTime', num2str(stopTime));

    out = sim(in);

    utilNu = out.util_nucleo.Data(end);
    generadas = ratePQ*15*stopTime + lambda0*stopTime;
    terminadas = out.n_terminadas.Data(end);
    perdidas = max(generadas - terminadas, 0);
    pct = 100*perdidas/generadas;

    filas(end+1,:) = {ratePQ, utilNu, perdidas, pct};
end

R3 = cell2table(filas, 'VariableNames', {'ratePQ','util_nucleo','perdidas','pct_perdidas'});
disp(R3);
writetable(R3, 'resultados_S3.xlsx');
fprintf('\nResultados guardados en resultados_S3.xlsx\n');
fprintf('Saturacion teorica del enlace: ratePQ ~ %.0f tramas/s\n', Cenlace/(15*Lpq*8));
