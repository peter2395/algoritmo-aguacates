clc;
clear all;
agCarT=table();
contador=1;
figure(1)
while contador<=231
    
    %% Adquisicion de imagen del aguacate   
    load('imagenesAguacates.mat');                  % Matriz con los nombres de las imagenes
    load('calidad.mat');                            % Matriz para ordenar las imagenes por
                                                    % calidad
    archivo=calidad(contador,1);

    aguacate=char(aguacatesArchivos(archivo,1));    % Lectura de la imagen
    ag1=imread(aguacate);                            

    datosAguacate=strsplit(aguacate,'-');           % Toma de datos del nombre del archivo 
                                                    % de la imagen
    
    tamano=strsplit(char(datosAguacate(1,2)),'g');
    numAg=strsplit(char(datosAguacate(1,4)),'.');

    agCar=table();                                  % Tabla de datos
    agCar.Aguacate=numAg(1,1);
    agCar.Masa=tamano(1,1);
    agCar.Tamano=tamano(1,2);
    agCar.Calidad=datosAguacate(1,3);

    %% Preprocesamiento de imagen

    ag=ag1-20;                                      % Operaciones algebraicas en histogramas
    ag=ag*2;
    ag=ag+10;

    %% Analisis de tama?o en pixeles

    agB=ag(:,:,3);                                  % Segmentacion mediante umbralizacion 
    T = graythresh(agB);                            % en el componente azul de la imagen
    agBin=imbinarize(agB,T);

    agBin=imfill(~agBin,'holes');                   % Invierte la imagen y rellena agujeros

    ES=strel('disk',20);                            % Suaviza bordes irregulares con 
    agBin=imdilate(agBin,ES);                       % dilatacion y erosion con elementro 
    agBin=imerode(agBin,ES);                        % estructural tipo disco radio 20

    [etag,numag] = bwlabel(agBin,4);                % Etiquetado
    agCar2 = regionprops('table',etag,'Area');      % Calculo del ?rea en pixeles del aguacate

    agPix=agCar2{1,1};
    agCar.AreaPixeles=agPix;

    %% Analisis de color

    contag=bwboundaries(agBin);                     % Obtencion de la matriz de pixeles 
                                                    % limitrofes
    cont=contag{1};                                 
    contmin=min(cont);                              % Valor minimo y maximo de la matriz 
    contmax=max(cont);                              % de pixeles limitrofes

    ag=imcrop(ag,[contmin(1,2)                      % Recorta la imagen con las coordenadas 
                  contmin(1,1)                      % minima y maxima
                  contmax(1,2)-contmin(1,2) 
                  contmax(1,1)-contmin(1,1)]);

    agBin=imcrop(agBin,[contmin(1,2)                % Recorta la imagen binaria con las 
                        contmin(1,1)                % coordenadas minima y maxima
                        contmax(1,2)-contmin(1,2) 
                        contmax(1,1)-contmin(1,1)]);

    ag=ag.*uint8(agBin);                            % Elimina el fondo de la imagen con el  
                                                    % producto de la imagen RGB con la imagen 
                                                    % binaria recortada

    agNew=ag;                                       % Realza caracteristicas de la corteza en 
    agR=ag(:,:,1);                                  % los componentes rojo, azul y verde con 
    agRnew = medfilt2(agR,[5 5]);                   % un filtro de mediana con una region de 
    ES=strel('disk',7);                             % 5x5 junto a una erosion con elemento 
    agEr=imerode(agRnew,ES);                        % estructural tipo disco radio 7 y a una 
    ES=strel('disk',5);                             % dilatacion con elemento estructural tipo 
    agRnew=imdilate(agEr,ES);                       % disco radio 5 
    agRnew=agRnew*1.7;
    agNew(:,:,1)=agRnew;

    agG=ag(:,:,2);
    agGnew = medfilt2(agG,[5 5]);
    ES=strel('disk',7);
    agEr=imerode(agGnew,ES);
    ES=strel('disk',5);
    agGnew=imdilate(agEr,ES);
    agGnew=agGnew*1.7;
    agNew(:,:,2)=agGnew;                                    

    agB=ag(:,:,3);
    agBnew = medfilt2(agB,[5 5]);
    ES=strel('disk',7);
    agEr=imerode(agBnew,ES);
    ES=strel('disk',5);
    agBnew=imdilate(agEr,ES);
    agBnew=agBnew*1.7;
    agNew(:,:,3)=agBnew;

    ES=strel('disk',7);                             % Aplica una erosion en la imagen 
    agBin=imerode(agBin,ES);                        % binarizada con un elemento estructural 
                                                    % tipo disco de radio 7


    %% Analisis de color RGB

    agGnewBin=double(agGnew);                       % Segmentacion de los defectos del 
    [mG,nG]=size(agGnew);                           % aguacate en el componente verde
    for(i=1:nG)
        for(j=1:mG)
            pixel=agGnew(j,i);
            if(pixel<=90)
                agGnewBin(j,i)=1;
            else
                agGnewBin(j,i)=0;
            end
        end
    end

    agGnewBin=agGnewBin&(agBin);
   
    agGPix=sum(agGnewBin(:));                       % Calculo del area de los defectos del 
                                                    % aguacate en el componente verde
    
    agRnewBin=double(agRnew);                       % Segmentacion de los defectos del 
    [mR,nR]=size(agRnew);                           % aguacate en el componente rojo
    for(i=1:nR)
        for(j=1:mR)
            pixel=agRnew(j,i);
            if(pixel>=180)
                agRnewBin(j,i)=1;
            else
                agRnewBin(j,i)=0;
            end
        end
    end
    
    agRPix=sum(agRnewBin(:));                       % Calculo del area de los defectos del 
                                                    % aguacate en el componente rojo
                                                    
    %% Analisis de color L*a*b

    agLab=rgb2lab(agNew);                           % Convierte la imagen RGB en el modelo de 
                                                    % color L*a*b
                                                    
    agA=agLab(:,:,2);                               % Canal a*
    agB2=agLab(:,:,3);                              % Canal b*

    agB2newBin=double(agB2);                        % Segmentacion de los defectos del 
    [mB,nB]=size(agB2);                             % aguacate en el canal b*
    for(i=1:nB)
        for(j=1:mB)
            pixel=agB2(j,i);
            if(pixel<=25)
                agB2newBin(j,i)=1;
            else
                agB2newBin(j,i)=0;
            end
        end
    end
    agB2newBin=agB2newBin&(agBin);
    
    agB2Pix=sum(agB2newBin(:));                     % Calculo del area de los defectos del 
                                                    % aguacate en el canal b*
    
    agAnewBin=double(agA);                          % Segmentacion de los defectos del 
    [mA,nA]=size(agA);                              % aguacate en el canal a*
    for(i=1:nA)
        for(j=1:mA)
            pixel=agA(j,i);
            if(pixel<=-15)
                agAnewBin(j,i)=0;
            else
                agAnewBin(j,i)=1;
            end
        end
    end
    
    agAnewBin=agAnewBin&(agBin);

    agAPix=sum(agAnewBin(:));                       % Calculo del area de los defectos del
                                                    % aguacate en el canal a*

    %% Analisis de color en defectos

    agDef=agRnewBin|agGnewBin;                      % Suma de los componentes rojo y verde

    if agAPix<=(agPix*0.15)                         % Operaciones entre los canales a* y b*
        agDef2=agB2newBin&agAnewBin;
    else
        agDef2=agB2newBin|agAnewBin;
    end

    agDef3=agDef&agDef2;                            % Producto entre los defectos RG y a*b*
    agDef4=agDef3;

    if agAPix<=(agPix*0.1)                          % Elimina problemas de iluminacion  
        agDef4=agDef3&~agRnewBin;
    end

    if agRPix>=(agPix*0.3)                          % Anade defectos por decoloracion
        agDef4=agDef3|agRnewBin;
    end


        
    agDefPix=sum(agDef4(:));                        % Calculo del area de los defectos del 
                                                    % aguacate
                                                    
    Defecto=agDefPix/agPix;                         % Porcentaje de los defectos presentes 
                                                    % en el aguacate
                                                    
    agCar.AreaCanalA=agAPix;
    agCar.AreaComponenteRojo=agRPix;
    agCar.PorcentajeA=agAPix/agPix;
    agCar.PorcentajeRojo=agRPix/agPix;

    agCar.PixelesDefecto=agDefPix;
    agCar.PorcentajeDefecto=Defecto;

    %% Clasificacion

    if(agPix<135000)                                % Clasificacion por Tamano
        Tamano='Pequeno';
    else
        if(agPix>180000)
            Tamano='Grande ';
        else
            Tamano='Mediano';
        end 
    end

    if(Defecto<0.02)                                % Clasificacion por Calidad
        Calidad='Alta ';
    else
        if(Defecto>0.1)
            Calidad='Baja ';
        else
            Calidad='Media';
        end 
    end

    agCar.TamanoAlgoritmo=Tamano;
    agCar.CalidadAlgoritmo=Calidad;


    %% Graficas

    ag2=ag;                                         % Defectos del aguacate resaltados con 
    [mAgDef4,nAgDef4]=size(agDef4);                 % color amarillo
    for i=1:nAgDef4
        for j=1:mAgDef4
            pixel=agDef4(j,i);
            if(pixel==1)
                ag2(j,i,1)=255;
                ag2(j,i,2)=255;
                ag2(j,i,3)=0;
            end
        end
    end

    figure(1)
    subplot(1,3,1),imshow(ag),title(strcat('Aguacate-',numAg(1,1)));
    subplot(1,3,2),imshow(agDef4),title('Defectos detectados por el algoritmo');
    subplot(1,3,3),imshow(ag2),title(strcat('Defectos del aguacate resaltados'));


    figure(2)
    subplot(3,5,1),imshow(ag),title(strcat('Aguacate-',numAg(1,1)));
    subplot(3,5,3),imshow(agRnew),title('Componente rojo');
    subplot(3,5,7),imshow(agRnewBin),title('Segmentacion rojo');
    subplot(3,5,5),imshow(agA,[-75 75]),title('Componente a*');
    subplot(3,5,9),imshow(agAnewBin),title('Segmentacion a*');
    subplot(3,5,11),imshow(agDef),title('Defectos (rojo || verde)');
    subplot(3,5,13),imshow(agDef3),title('Defectos RG & a*b*');
    subplot(3,5,2),imshow(agNew),title(strcat('Aguacate-',numAg(1,1)));
    subplot(3,5,4),imshow(agGnew),title('Componente verde');
    subplot(3,5,8),imshow(agGnewBin),title('Segmentacion verde');
    subplot(3,5,6),imshow(agB2,[-75 75]),title('Componente b*');
    subplot(3,5,10),imshow(agB2newBin),title('Segmentacion b*');
    subplot(3,5,12),imshow(agDef2),title('Defectos entre a* y b*');
    subplot(3,5,14),imshow(agDef4),title('Defectos detectados');
    subplot(3,5,15),imshow(ag2),title(strcat('Defectos resaltados'));

   pause;
    contador=contador+1;
    agCarT=[agCarT;agCar];
end
