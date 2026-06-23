%% parametros.m
%  Parámetros del modelo de eventos discretos de la red de monitorización
%  de la microrred del CEDER-CIEMAT, calibrados con la captura de trafico real.
%
%  Ejecutar este script ANTES de abrir o simular el modelo monitor_ceder_S0.slx:
%  define en el workspace de MATLAB todas las variables que referencian los
%  bloques de SimEvents. Cambiando estos valores se configuran los escenarios
%  sin necesidad de editar el modelo.
%
%  Trabajo Fin de Grado - Daniel Varela Ramírez - ETSIT-UPM - 2026
% -------------------------------------------------------------------------

% --- Parámetros medidos en la captura (escenario base S0) ---
lambda0  = 134.7;        % tasa de transacciones Modbus [transacciones/s]
tResp    = 0.0287;       % tiempo de servicio medio (respuesta + procesado) [s]
                         %   mediana 4,9 ms; media 28,7 ms; p95 146 ms (cola pesada)
L        = 86;           % tamano medio de trama en el medio [bytes]
                         %   66 B de trama Ethernet + 20 B de preambulo/separacion

% --- Parámetros de la red ---
Cenlace  = 100e6;        % capacidad del enlace [bit/s]
tNucleo  = L*8/Cenlace;  % tiempo de servicio del nucleo (transmision) [s] ~ 6,9 us

% --- Variables de diseno y de escenario ---
fFactor  = 1;            % factor de escala de la tasa
c        = 4;            % concurrencia de Node-RED
                         %   medida real: media 3,9 en vuelo, maximo 26

% --- Derivados ---
periodGen = 1/(lambda0*fFactor);   % periodo del generador de entidades [s]

% --- Referencia analitica (utilizacion teorica) ---
rho_teorica = fFactor*lambda0*tResp/c;
fprintf('Parametros cargados. rho_teorica = %.3f (c = %d, fFactor = %g)\n', rho_teorica, c, fFactor);
fprintf('periodGen = %.4f ms, tNucleo = %.2f us\n', periodGen*1e3, tNucleo*1e6);
