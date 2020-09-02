clear Ig
clear Isat
clear A
clear Rs
clear Rp

% Silva method

%%%%METODO SILVA
metodo="Silva Method";
%%datosIV contiene las muestras de datos reales
clear datosSinCeros
indiceSinCeros=1;
for indice=[1:1:length(datosIV)]
  if (~((datosIV(1,indice) == 0)&(datosIV(2,indice) == 0)))
     datosSinCeros(1,indiceSinCeros)=datosIV(1,indice);
     datosSinCeros(2,indiceSinCeros)=datosIV(2,indice);
     indiceSinCeros=indiceSinCeros+1;
  end
end
clear ordenadosIV
ordenadosIV=fOrdenarVI(datosSinCeros);
%% Parametros de la placa
Isc = max(ordenadosIV(1,:));
Voc = max(ordenadosIV(2,:));

potenciaMuestra=ordenadosIV(1,:).*ordenadosIV(2,:);
pMaxMuestra=max(potenciaMuestra);
indiceMaxPotMuestra=find(potenciaMuestra==pMaxMuestra);
Imp = ordenadosIV(1,indiceMaxPotMuestra);
Vmp = ordenadosIV(2,indiceMaxPotMuestra);
%%Recibe los parametros de la placa.
%%Si no estan definidos tomamos valores de prueba
%Este metodo debe recibir la matriz de datos experimentales
if(~exist("Isc"))
   Isc=0.32;
end
if(~exist("Voc"))
  Voc=22.0;
end
if(~exist("Imp"))
  Imp=0.29;
end
if(~exist("Vmp"))
  Vmp=17.5;
end
if(~exist("pMaxMuestra"))
  pMaxMuestra=5;
end 

if(~exist("potenciaMuestra"))
 printf("debe existir potenciaMuestra: matriz de potencia de las muestrras\n");
end

%%Constantes
T=302; %Temperatura
K=1.38065*10^(-23); % Constante de Bolzan
Ns=36; %%NUmero de celdas en serie
q=1.6022*10^(-19);

clear Vgrafica 
clear Igrafica
%eq 7
Ig=Isc;
Voc=Voc;

columnaMaep=1;
clear matrizMAEP
for A=[1:0.5:2] %en articulo en pasos de 0.01
  for Rs=[0.5:0.5:15]
    ResistenciaSerie=Rs;
    %Solve eq 2,7,11, and 13
    %eq 2
    Vt=Ns*A*K*T/q;  %A sera obtenido de forma numerica
    
    %eq 29
    RpTerminoExp=(exp((Vmp+Imp*Rs)/Vt)-1)/(exp(Voc/Vt)-1);
    RpNumerador=Voc*RpTerminoExp-Vmp-Imp*Rs;
    RpDenominador=Imp+Ig*(RpTerminoExp-1);
    Rp=RpNumerador/RpDenominador;
    if(Rp<0)
     %printf("Error, Rp menor que cero \n");
     Rp=Rp;
     continue;
    end
    
    %eq 9
    Isat=Ig-(Voc/Rp);
    Isat=Isat/(exp(Voc/Vt)-1);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%555
%% Calculo Curva Teorica
Vt=Ns*A*K*T/q;
clear Vmetodo
clear Imetodo

%Vmetodo=[0:1:Voc];
%Como tensiones tomamos las mismas de las experimentales
Vmetodo=ordenadosIV(2,:);
index=1;
Imetodo(1)=Ig;
for V=Vmetodo
   %tension=V;
   index=index;
   if (index==1)
     Ip=Ig;
   else
     Ip=Imetodo(index-1);
   end   
   while((length(Imetodo)<index))
     Inew=Ig-Isat*(exp((V+Ip*Rs)/Vt)-1)-(V+Ip*Rs)/Rp;
     if (Inew>Ip)
        %printf("Ines mayor que IP\n");
        Ip=Ip;
        Inew=Inew;
        Imetodo(index)=0;
     else
       actualError=Ip-Inew;
       if(actualError < 0.0001)
         if (Inew  < 0)
           Imetodo(index)=0;
         else
           Imetodo(index)=Inew;
         end
       end
     end
     Ip=Ip-0.00001;
   end
   index=index+1;
end


%% Fin calculo curva Teorica
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %comparacion entre curva teorica y experimental
    % the best set of parameters is chosen based on the lowest value of MAEP 
    % calculated between the curve generated by the electrical model and the 
    % curve extracted from the datasheet (or from the experimental curve) 
    % potenciaMuestra Ya esta calculado
    clear Vgrafica;
    clear Igrafica;
    
    Vgrafica = Vmetodo;
    Igrafica = Imetodo;  
    
    potenciaMetodo=Vgrafica.*Igrafica;
    miError=potenciaMuestra-potenciaMetodo;
    miError=abs(miError);
    MAEP=sum(miError)/length(miError);
    
    %grabamos en la matrizMAEP los valores de A,Rs y MAEP obtenidos
    %para esta curva.
    matrizMAEP(1,columnaMaep)=MAEP;
    matrizMAEP(2,columnaMaep)=A;
    matrizMAEP(3,columnaMaep)=Rs;
    matrizMAEP(4,columnaMaep)=Rp;
    matrizMAEP(5,columnaMaep)=Ig;
    matrizMAEP(6,columnaMaep)=Isat;
    columnaMaep=columnaMaep+1;
    
  end %Valores de Rs
%Vgrafica;
%Igrafica;
%figure();
%plot(Vgrafica,Igrafica,"*");

end %A


%Consideramos como optimos los valores de A y Rs que nos proporcionan
%el menor indicee de error MAEP
minimoMAEP=min(matrizMAEP(1,:));
indiceMinimoMAEP=find(matrizMAEP(1,:)==minimoMAEP);
AOptimo   =matrizMAEP(2,indiceMinimoMAEP);
RsOptimo  =matrizMAEP(3,indiceMinimoMAEP);
RpOptimo  =matrizMAEP(4,indiceMinimoMAEP);
IgOptimo  =matrizMAEP(5,indiceMinimoMAEP);
IsatOptimo=matrizMAEP(6,indiceMinimoMAEP);

A=AOptimo;
Rs=RsOptimo;
Rp=RpOptimo;
Ig=IgOptimo;
Isat=IsatOptimo;

curvaTeorica;
Vmetodo_3=Vmetodo;
Imetodo_3=Imetodo;
figure(3);
plot(tension, corriente,'.r',Vmetodo_3, Imetodo_3)

xlabel('Tension(V)');
ylabel('Corriente(A)');
suptitle('Curva I-V MetodoSilva Vs Curva I-V Experimental');
title('Modelo de 5 Parametros');
grid
legend('Curva Experimental','Curva Modelada','Location','SouthWest');

ParametrosSilva=[Ig; A; Isat; Rs; Rp];
%ParametrosMetodoSilva=table(ParametrosSilva,'RowNames',{'Ig','A','Isat','Rs','Rp'})
VocMetodo3=max(Vmetodo_3);
IscMetodo3=max(Imetodo_3);
potenciaMetodo3=Vmetodo_3.*Imetodo_3;
PmMetodo3=max(potenciaMetodo3);
[fila3,columna3]=find(potenciaMetodo3==PmMetodo3);
ImpMetodo3=Imetodo_3(columna3);
VmpMetodo3=Vmetodo_3(columna3);

MetodoSilva=[IscMetodo3;VocMetodo3;PmMetodo3;ImpMetodo3;VmpMetodo3];

