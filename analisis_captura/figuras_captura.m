%% figuras_captura.m
%  Genera las Figuras 4.2 (CDF del tiempo de respuesta) y 4.3 (concurrencia
%  en vuelo) directamente desde la captura de trafico del CEDER.
%
%  REQUISITO: tener el fichero .pcap (o .pcapng) accesible y Wireshark/tshark
%  instalado. Estas figuras salen NATIVAS de MATLAB; haz capturas.
% -------------------------------------------------------------------------

clear; clc;

%% --- FIGURA 4.2: CDF del tiempo de respuesta ---
%  Exporta primero las transacciones Modbus con tshark a un CSV con tres
%  campos: tiempo (epoch), IP destino y Transaction ID, separando peticion
%  (puerto destino 502) de respuesta (puerto origen 502).
%
%  Ejecuta UNA VEZ en una terminal ajustando la ruta:
%
%    tshark -r ceder.pcap -Y "modbus" -T fields -e frame.time_epoch -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e mbtcp.trans_id -E separator=, -E quote=n > modbus.csv
%

csv = 'modbus.csv';
T = readtable(csv, 'ReadVariableNames', false);
T.Properties.VariableNames = {'t','ipsrc','ipdst','sport','dport','tid'};

% Separar peticiones (dport==502) y respuestas (sport==502)
isReq  = T.dport == 502;
isResp = T.sport == 502;

% Emparejar por (esclavo, trans_id): el esclavo es ipdst en la peticion y ipsrc en la respuesta
reqKey  = T.ipdst(isReq);   reqTid = T.tid(isReq);   reqT = T.t(isReq);
respKey = T.ipsrc(isResp);  respTid = T.tid(isResp); respT = T.t(isResp);

% Empareja cada respuesta con su peticion mas reciente del mismo esclavo+tid
key_r = string(reqKey)  + "_" + string(reqTid);
key_s = string(respKey) + "_" + string(respTid);

tReq = []; rt = []; tStart = [];
map = containers.Map('KeyType','char','ValueType','double');
[allT, ord] = sort(T.t);
for i = 1:height(T)
    j = ord(i);
    if T.dport(j) == 502
        k = char(string(T.ipdst(j)) + "_" + string(T.tid(j)));
        map(k) = T.t(j);
    elseif T.sport(j) == 502
        k = char(string(T.ipsrc(j)) + "_" + string(T.tid(j)));
        if isKey(map, k)
            tReq(end+1,1)   = map(k);
            rt(end+1,1)     = T.t(j) - map(k);
            remove(map, k);
        end
    end
end

t0 = min(tReq);
tReq = tReq - t0; % tiempo relativo al inicio (s)


%% --- FIGURA 4.3: concurrencia en vuelo ---
%  Reconstruye cuantas transacciones hay simultaneamente "en vuelo":
%  cada peticion suma +1 al empezar y -1 cuando llega su respuesta.
tIni = tReq;            % inicio de cada transaccion
tFin = tReq + rt;       % fin de cada transaccion
ev_t = [tIni; tFin];
ev_d = [ones(n,1); -ones(n,1)];
[ev_t, idx] = sort(ev_t);
ev_d = ev_d(idx);
enVuelo = cumsum(ev_d);

% media temporal (ponderada por el tiempo en cada nivel) = ley de Little
dur = max(tFin) - min(tIni);
mediaTemporal = sum(enVuelo(1:end-1) .* diff(ev_t)) / dur;

% ventana de 10 s
win = (ev_t >= 60) & (ev_t <= 70);

figure('Color','w','Position',[100 100 720 480]);
stairs(ev_t(win), enVuelo(win), 'LineWidth', 1.1, 'Color', [0 0.447 0.741]);
hold on; grid on;
yline(mediaTemporal, '--', sprintf('media temporal = %.1f', mediaTemporal), 'Color',[0.85 0.325 0.098], 'LineWidth',1.6, 'LabelHorizontalAlignment','left');
xlabel('Tiempo de captura (s)');
ylabel('Transacciones Modbus en vuelo');
xlim([60 70]); ylim([0 max(enVuelo(win))+2]);
set(gca,'FontSize',11,'Box','on');
exportgraphics(gcf, 'fig4_3_concurrencia.png', 'Resolution', 300);

%% --- Resumen por pantalla ---
fprintf('\nTransacciones emparejadas: %d\n', n);
fprintf('Tiempo de respuesta: mediana %.1f ms, media %.1f ms, p95 %.0f ms\n', med, mu, p95);
fprintf('Concurrencia media temporal (ley de Little): %.2f\n', mediaTemporal);
fprintf('lambda*E[t] = %.2f (debe coincidir con la media temporal)\n', (n/dur)*mean(rt));
