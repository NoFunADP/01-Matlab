clear
clc
close all

%%Notizen und Ideen zum Skript
% Vorhandensein der Roten, Farblosen und Jet- Anteile in einer Kontrollmatrix einpflegen. Manuelle Änderung des Skriptes recht aufwendig.
% Aktuelles Verständnis Skript Wertet nur einzelne Bilder aus. Daher bietet sich eventuell eine Schleife an ?
% Auswertungsgrößen festlegen
% >Zeitpunkt zwischen Auftreffen des Tropfens, Kronenbildung und Ausbildung der Sekundärtropfen bestimmen
% >Können wir Sekundärtropfen in irgendeiner Art und Weise tracken
% >Geschwindigkeit der Tropfenausbreitung, Maß der Streuung, Größe der Tropfen
% >Farbe der Tropfen durch Schwarz weis Auswerten ?



%% %% <- Für Teilschritte in denen der Anwendung etwas überprüfen oder eingeben muss.
%%% <- Stellen für eine Eingabe
%%%Red
%%%Blank
%%%Jet
%% %% 1 Input
% Bildordner
    BO='C:\Users\POS\Desktop\Si10FuH2o250' %%%
% Hintergrund Bild
    BG=imread('K0.8x22_Si10FuH2o_5_250um_001.png'); %%%
%Primärtropfen Bild 1
    Pic1=imread('K0.8x22_Si10FuH2o_5_250um_020.png'); %%%
% Primärtropfen Bild 2
    Pic2=imread('K0.8x22_Si10FuH2o_5_250um_039.png'); %%%
% Aktionsbild (Bild auf dem der die Sekundärtropfen, Jet oder beides abgebildet sind)
    Im=imread('K0.8x22_Si10FuH2o_5_250um_198.png');%%%
% Speichernamen für das Übersichtsbild
    OView='Overview'%%%
%%% ferner das Spiegelbild abzuschneiden
    cut1=720;  %%%
    cut2=774; %%%
    cut3=745; %%%
% Ordner zum Speichern der Ergebnisse
    RO='C:\Users\POS\Desktop\Si10FuH2o250\Results'%%%
% Speichernamen für Ergebnisse
    R='Results_Si10_FuH2o_250_5'%%%
% Anzahl der Bilder pro Zeit (sekunde)
    FPS=12500; %%%
% Abstand der Bilder (Anzahl der Bilder welche zwischen den beiden Aufnahmen liegen)
    dpic=20; %%%
% Pixel pro mm, um von pixel zu mm umrechnen zu können
    pixmm=329/10; %%%
    mmpix = 1 / pixmm;
% Abspeichern von Input
    Input(1).mmpix=mmpix; %% Müsste doch pixmm sein
    Input(1).Pic1=Pic1;
    Input(1).Pic2=Pic2;
    Input(1).Pic3=Im;
    Input(1).cut=cut2;
    Input(1).FPS=FPS;
%% %%  2 Geschwindigkeit und mittleren Radius des Primärtropfens bestimmen

% Zeit (sekunde) für ein Bild
    SPF=1/FPS; 
% Zeit zwischen beiden Aufnahmen (sekunde)
    t=dpic*SPF; 
% mm pro Pixel
    mmpix=1/pixmm;
% m pro Pixel
    mpix=mmpix/1000;
%%% Ordner auswählen    
    cd(BO);%%%1
% Transformation von RGB zu Grau des Hintergrundbilds
    BGgray=rgb2gray(BG);
    
% Bestimmen der Bild Matrixgröße
    S=size(BG);
    sxbg=S(2);
    sybg=S(1);

% Transformation von RGB zu Binär der Primärtropfen Bilder, und Abschneiden
% des unteren Abschnitts
    Picgray1=rgb2gray(Pic1);
    Picbw1=imbinarize(Picgray1,'adaptive','ForegroundPolarity','dark');
    Picbw1=imcomplement(Picbw1);
    Picbw1(cut1:end,:)=0;

    Picgray2=rgb2gray(Pic2);
    Picbw2=imbinarize(Picgray2,'adaptive','ForegroundPolarity','dark');
    Picbw2=imcomplement(Picbw2);
    Picbw2(cut1:end,:)=0;

    % Zusammenführen beider Bilder
    Picbw12=Picbw1+Picbw2;
    Picbw12=imbinarize(Picbw12,'adaptive','ForegroundPolarity','bright');
    Picbw12=imfill(Picbw12,4,'holes');

    %Darstellung des Primärtropfensausschnitts
    Picbw128=uint8(Picbw12);  %%Warum hier 2mal genau der gleiche Code ?
    ic(:,:,1)=Pic1(:,:,1).*Picbw128;
    ic(:,:,2)=Pic1(:,:,2).*Picbw128;
    ic(:,:,3)=Pic1(:,:,3).*Picbw128;

    Picbw128=uint8(Picbw12);
    ic2(:,:,1)=Pic2(:,:,1).*Picbw128;
    ic2(:,:,2)=Pic2(:,:,2).*Picbw128;
    ic2(:,:,3)=Pic2(:,:,3).*Picbw128;
    imshowpair(ic,ic2,'montage')

%% 2.1 Filtern von Flächen kleiner als 50, -> Filtert Rauschen
    Prim=regionprops(Picbw12,'Centroid','Area','MajorAxisLength','MinorAxisLength','Image');
    z=0;
    clear Primary

    for i=1:length(Prim)
        if Prim(i).Area>200 %%% Schranke für den Tiefpass, nach Flächengröße
           z=z+1;
           Primary(z)=Prim(i);
        end
    end
% Darstellung des Primärtropfens

    for i=1:length(Primary)
        diameters = mean([Primary(i).MajorAxisLength Primary.MinorAxisLength],2);
        Primary(i).radiimm = (diameters/2)*mmpix;
    end
    Centroid1=Primary(1).Centroid;
    Centroid2=Primary(2).Centroid;
    distance=abs(Centroid1(2)-Centroid2(2))*mpix;
    Primary(1).Velocity=(distance)/t;

%% 3 Aktionsbild Auswerten 
    clear filtered Prim2 % Um Fehlermeldung "Subscripted assignment between dissimilar structures." bei wiederholtem Aktivieren des Abschnitts zu vermeiden.

% Transformation von RGB zu Binär
    Imgd1=rgb2gray(Im);
    Imbw1=imbinarize(Imgd1(1:cut1,:),'adaptive','ForegroundPolarity','dark');
    Imbw1=imcomplement(Imbw1);
% Hintergrundbild von Aktionsbild abziehen
    Imgd=rgb2gray(BG-Im);
% Bilden der binären Matrix
    Imbw=zeros(sxbg);
    Imbw(1:cut1,:)=Imbw1;
    Imbw(cut1+1:cut3,:)=imbinarize(Imgd(cut1+1:cut3,:),0.04); %%% Schranke falls nötig anpassen
    Imbw(cut3+1:end,:)=imbinarize(Imgd1(cut3+1:end,:),'adaptive','ForegroundPolarity','dark');
    Imbw(cut3+1:end,:)=imcomplement(Imbw(cut3+1:end,:));
    % Imbw=imcomplement(Imbw);
% Darstellung des binärean Aktionsbilds
    imshow(Imbw)
    
% Filtern von Rauschen anhand der Flächengröße
    clear filtered boundary
    Prim2=regionprops(Imbw,'Centroid','Area','BoundingBox','Image');
    z=0;
    for i=1:length(Prim2)
        if Prim2(i).Area>100 %%% Schranke für den Tiefpass, nach Flächengröße, um rauschen herauszufiltern
           z=z+1;
           filtered(z)=Prim2(i);

        end
    end
% Darstellung der gefilterten Bilds
    S=size(Im);
    sx=S(2);
    Imfltrd=zeros(sx);
    for i=1:length(filtered)
        boundary=filtered(i).BoundingBox;
        x1=ceil(boundary(1));
        x2=ceil(boundary(1)+boundary(3))-1;
        y1=ceil(boundary(2));
        y2=ceil(boundary(2)+boundary(4))-1;
        Imfltrd(y1:y2,x1:x2)=Imfltrd(y1:y2,x1:x2)+filtered(i).Image;
    end
%% %% 3.1  Manuelles Vervollständigen der binären Bildmatrix
% Zuerst das Eingabefeld leeren und dann das zu bearbeitende Bild Anschauen
% Darstellung des zu bearbeitenden Bilds
Imfltrd=imfill(Imfltrd,'holes');
Imfltrd(cut2:end,:)=0;
Imfltrd2=Imfltrd;
Imfltrdf=imfill(Imfltrd2,'holes');
Imfltrdf(cut2:end,:)=0;

clear Imcut
Imfltrdf8=uint8(Imfltrdf);
Imcut(:,:,1)=Im(:,:,1).*Imfltrdf8;
Imcut(:,:,2)=Im(:,:,2).*Imfltrdf8;
Imcut(:,:,3)=Im(:,:,3).*Imfltrdf8;
BW=imbinarize(Imfltrd);

OV=regionprops(BW,'Centroid','Area','BoundingBox');

imshow(Imcut); hold on;

for k=1:length(OV)
  boundary = OV(k).BoundingBox;
  rectangle('Position',[boundary(1),boundary(2),boundary(3),boundary(4)],...
       'EdgeColor','g','LineWidth',1)
  h = text(boundary(1)+boundary(3)*0.5, boundary(2), num2str(k));
  set(h,'Color','w','FontSize',8)%,'FontWeight','bold');
end


% Tools zum löschen oder Vervollständigen von Objekten
% Allgemein werden Pixel hinzugefügt wenn Hinterm = Zeichen eine Einz steht
% und gelöscht wenn eine Null steht

% einzel Punkt oder linie
%     Imfltrd2(,)=0;

% fallend von links nach rechts
%     n=; %%% n= Elemente der Diagonale +1(falls 4 Punkte-> n=3) (geht für 45°)
%     x1=; %%% Startpunkt
%     y1=; %%%
%     for i=0:n
%     Imfltrd2(y1+i:y1+i+1,x1+i)=1;
%     end

% steigend von links nach rechts
%     n=4; %%% n= Elemente der Diagonale +1(falls 4 Punkte-> n=3) (geht für 45°)
%     x1=178; %%%Startpunkt
%     y1=543; %%%
%     for i=0:n
%     Imfltrd2(y1-i-1:y1-i,x1+i)=0;
%     end

% Kreis 
% x=Matrixbreite Horizontal;
% y=Matrixbreite Vertikal;
% xm=707; Spalte Koordinate des Kreismittelpunkts
% ym=729; Zeile Koordinate des Kreismittelpunkts
% r1=11; Radius
% for r=1:r1+1 % von 1 bis r1, falls nur ein Ring bearbeitet werden soll
%              % die 1 mit entsprechenden Wert ersetzen
%     for i=1:y        
%         for k=1:x
%             if (i-ym)^2+(k-xm)^2>=r^2-r &&(i-ym)^2+(k-xm)^2<=r^2+r
%             Imfltrd2(i,k)=1; % Wert 1 schreiben, 0 löschen
%             end
%         end
%     end
% end

% Eingabefeld für die Manipulation der Matrix
%%%

% Darstellung des Vervollständigten Bilds
    Imfltrdf=imfill(Imfltrd2,'holes');
    Imfltrdf(cut2:end,:)=0;
    clear Imcut
    Imfltrdf8=uint8(Imfltrdf);
    Imcut(:,:,1)=Im(:,:,1).*Imfltrdf8;
    Imcut(:,:,2)=Im(:,:,2).*Imfltrdf8;
    Imcut(:,:,3)=Im(:,:,3).*Imfltrdf8;
    BW=imbinarize(Imfltrd);

    OV=regionprops(BW,'Centroid','Area','BoundingBox');

    imshow(Imcut); hold on;

    for k=1:length(OV)
      boundary = OV(k).BoundingBox;
      rectangle('Position',[boundary(1),boundary(2),boundary(3),boundary(4)],...
           'EdgeColor','g','LineWidth',1)
      h = text(boundary(1)+boundary(3)*0.5, boundary(2), num2str(k));
      set(h,'Color','w','FontSize',8)%,'FontWeight','bold');
    end
%% %% 3.2 Auslesen der Elementeigenschaften, Fläche, Achsenlänge, Schablonen etc...
clear stat
BW=imbinarize(Imfltrdf);
stat = regionprops(BW,'Centroid','Area','Minoraxis','Majoraxis','Image','BoundingBox');
clear stat2

S2=size(stat);
sx2=S2(2);
sy2=S2(1);
z=0;
for i=1:sy2
    if stat(i).Area>100 %%% Schranke für den Tiefpass, nach Flächengröße
       z=z+1;
       stat2(z)=stat(i);
    end
end
centroids = cat(1, stat2.Centroid);
BoundingBox=cat(1, stat2.BoundingBox);
imshow(Imcut)
hold on
plot(centroids(:,1),centroids(:,2), 'b*')
hold off
%% 3.3 Elemente ausschneiden, Elementschablone auf Originalbild-> Target
b=size(BoundingBox);
bx=b(2);
by=b(1);

for k=1:by
    clear Target mask
    y1=ceil(BoundingBox(k,1));
    y2=ceil(BoundingBox(k,1)+BoundingBox(k,3)-1);
    x1=ceil(BoundingBox(k,2));
    x2=ceil(BoundingBox(k,2)+BoundingBox(k,4)-1);
    mask=stat2(k).Image;
    mask=uint8(mask);
 
    Target(:,:,1)=Im(x1:x2,y1:y2,1).*mask;
    Target(:,:,2)=Im(x1:x2,y1:y2,2).*mask;
    Target(:,:,3)=Im(x1:x2,y1:y2,3).*mask;
    
    stat2(k).Target=Target(:,:,:);
end
%% 3.4 Boundaries, Umgebung des Tropfen entfernen

for i=1:length(stat2)
    Target2=stat2(i).Target;
    Target3=stat2(i).Image;
    [B,L] = bwboundaries(stat2(i).Image);
    for k = 1 : length(B)
        c = B{k};
        for n=1:length(c)
            Target2(c(n,1),c(n,2),:)=0;
            Target3(c(n,1),c(n,2),:)=0;
        end
    end
    Region=regionprops(Target3,'Area','MajorAxisLength','MinorAxisLength','Image');
    stat2(i).Area=Region.Area;
    stat2(i).MajorAxisLength=Region.MajorAxisLength;
    stat2(i).MinorAxisLength=Region.MinorAxisLength;
    stat2(i).Target2=Target2;
end
    
    
% imshowpair(Target2,stat2(i).Target,'montage')
%%  %% 3.5 Tropfen Übersicht für die Nachbearbeitung einzelner Tropfen
figure
for i=1:length(stat2)
    k=ceil(sqrt(length(stat2)));
    subplot(k,k,i)
    imshow(stat2(i).Target2)
    title(num2str(i))
end
%% %% 3.6 Nachbearbeitung einzelner Tropfen, Umriss noch schärfer ausschneiden
nr= []; %%% Tropfen nummer eingeben, in aufsteigender Reihenfolge
rep=[]; %%% Wie oft der Rand entfernt werden soll
for a=1:length(nr)
    Target2=stat2(nr(a)).Target;
    Target3=stat2(nr(a)).Image;
    for i=1:rep(a)
        [D,L] = bwboundaries(Target3);
        for k = 1 : length(D)
            d = D{k};
            for n=1:length(d)
                Target2(d(n,1),d(n,2),:)=0;
                Target3(d(n,1),d(n,2),:)=0;
            end
        end
    end
    stat2(nr(a)).Target2=Target2;
    Region=regionprops(Target3,'Area','MajorAxisLength','MinorAxisLength','Image');
    stat2(nr(a)).Area=Region.Area;
    stat2(nr(a)).MajorAxisLength=Region.MajorAxisLength;
    stat2(nr(a)).MinorAxisLength=Region.MinorAxisLength;
    stat2(nr(a)).Target2=Target2;
end


figure
for a=1:length(nr)
    k=ceil(sqrt(length(nr)));
    subplot(k,k,a)
    imshowpair(stat2(nr(a)).Target2,stat2(nr(a)).Target,'montage')
    title(num2str(nr(a)))
end
%% %% 4 Kategorisierung (Tropfen und Jet)
clear stat2.Jet stat2.Secondarydrop stat2.other
for i=1:length(stat2)
    if stat2(i).Area>5000 %%% Schranke für den Hochpass, bei stat2 auf die Jetfläche schauen und festlegen
           stat2(i).Jet=stat2(i).Target2;
    else
        stat2(i).Secondarydrop=stat2(i).Target2;
    end
end   
%% 4.1 Bilden der Hue Matrizen für alle, Umgebung wird mit NaN beschrieben. 
for i=1:length(stat2)
                Size=size(stat2(i).Target2);
                sx=Size(2);
                sy=Size(1);
                A=stat2(i).Target2;
                AHSV=zeros(sy,sx,3);
                for m=1:sy
                    for n=1:sx
                        if A(m,n,1)~=0||A(m,n,2)~=0||A(m,n,2)~=0
                        AHSV(m,n,:)=rgb2hsv(A(m,n,:));
                        else
                        AHSV(m,n,:)=NaN;
                        end
                    end
                end
                H=AHSV(:,:,1);
                stat2(i).Hue=H;
end
%% 5 Volume all 
% Volumen Berechnung der Tropfen unter der Annahme das der Tropfen eines Ellipsoiden 
% ähnelt (Eiförmig, 2 kurze Hauptradien und eine lange)

% Volumen Berechnung des Jets, das Jet Volumen wird als ein Stapel von kreisförmigen
% Scheiben berechnet. Folgende Schritte wurden hierzu unternommen:
% Summe der zeilen Eintrage, dividiert durch zwei, multipliziert mit mmpix ergibt den Radius der Scheibe
% quadrieren ergibt das r^2
% einsetzen in die Kreisflächenformel
% kreisfläche mit der höhe von einem Pixel in mm multiplizieren, ergibt Scheibenvolumen
% Alle Scheiben addieren ergibt Volumen des Jets


for i=1:length(stat2)
    
   
    if isempty(stat2(i).Secondarydrop)==0
        rl=stat2(i).MajorAxisLength/2*mmpix;
        stat2(i).Rlong=rl;
        rs=stat2(i).MinorAxisLength/2*mmpix;
        stat2(i).Rshort=rs;
        Vol=(4/3)*pi*rl*(rs^2);
        stat2(i).Volume=Vol;

    else 
        J=stat2(i).Image;
        r=sum(J,2)./2.*mmpix;
        rquadr=r.^2;
        VolJ=pi*mmpix*sum(rquadr);
        stat2(i).Volume=VolJ;
    end
end
%% 6 Einordnen von Red und Blank Tropfen in Structs
% sinnige Tropfen
% secondary drop struct 
% Hue Intervall für Rot entspricht (0:0.1665) und (0.8335:1). Für einen
% anderen Farbstoff muss diese ggf. geändert werden.
clear dropred dropblank
k=0;
m=0;

for i=1:length(stat2)
     if isempty(stat2(i).Secondarydrop)==0       
        H=stat2(i).Hue;
        if isempty(H(H>=0 & H<0.1665))==0 || isempty(H(H>0.8335))==0
                k=k+1;
                
                dropred(k)=stat2(i);
        else
                m=m+1;
                
                dropblank(m)=stat2(i);
        end
     end
end
%%% nur aktivieren wenn Jet vorhanden
%%% deaktivieren wenn kein Jet vorhanden
%%%Red

% if exist ('dropred','var')==1
%     dropred=rmfield(dropred,'Jet');
% end
%
%%%Blank
% if exist ('dropblank','var')==1
%     dropblank=rmfield(dropblank,'Jet');
% end
%% %% 6.1 Einordnung von Jet Red/ Blank in Structs
% nur aktivieren wenn ein Jet vorhanden
% deaktivieren wenn kein Jet vorhanden

clear jetred jetblank H
p=0;
q=0;
for i=1:length(stat2)
     if isempty(stat2(i).Jet)==0       
        H=stat2(i).Hue;
            if isempty(H(H>=0 & H<0.1665))==0 || isempty(H(H>0.8335))==0
                    p=p+1;
                    jetred(p)=stat2(i);
            else
                    q=q+1;
                    jetblank(q)=stat2(i);
            end
     end
end

% nur aktivieren wenn Jet vorhanden
% deaktivieren wenn kein Jet vorhanden
% clear i H p q
%%%Jet
% if exist ('jetred','var')==1
%     jetred=rmfield(jetred,'Secondarydrop');
% end

%%%Jet
% if exist('jetblank','var')==1
%     jetblank=rmfield(jetblank,'Secondarydrop');
% end
%% %% 7 Dropred Tropfen überprüfen, welche sind richtig, welche falsch
figure
for i=1:length(dropred)
    k=ceil(sqrt(length(dropred)));
    subplot(k,k,i)
    imshow(dropred(i).Target2)
    title(num2str(i))
end
%% %% 7.1 Verschieben von falschen roten Tropfen zu blank
%%%Red
% in aufsteigender Reihenfolge die Zahlen eingeben
move=[]; %%% zu verschiebende Tropfen
remove=[]; %%% löschen der verschobenen Tropfen aus der Rotliste und falsche Objekte
%%%Blank
% m=length(dropblank);
% for i=1:length(move)
%     k=move(i);
%     m=m+1;
%     dropblank(m)=dropred(k);
% end
% löschen der verschobenen und unsinnigen Elemente
m=0;
for i=1:length(remove)
    k=remove(i)-m;
    dropred(k)=[];
    m=m+1;
end
%% %% %% 7.2 Löschen von Volumenergebnissen von  roten Tropfen, die keinem Ellipsoiden entsprechen
%%%Red
figure
for i=1:length(dropred)
    k=ceil(sqrt(length(dropred)));
    subplot(k,k,i)
    imshow(dropred(i).Target2)
    title(num2str(i))
end
%% 7.3 zu löschende Volumeneintrage eines Tropfens in den Vektor einfügen
remove=[]; %%% Idnr des nicht ellipsoiden Objektes

m=0;
for i=1:length(remove)
    k=remove(i)-m;
    dropred(k).Volume=[];
    dropred(k).Rlong=[];
    dropred(k).Rshort=[];
    m=m+1;
end
%% 8 Dropblank Tropfen überprüfen, welche sind richtig, welche falsch
%%%Blank
figure
for i=1:length(dropblank)
    k=ceil(sqrt(length(dropblank)));
    subplot(k,k,i)
    imshow(dropblank(i).Target2)
    title(num2str(i))
end
%% 8.1 Löschen von falschen blank Tropfen 
remove=[]; %%% löschen der verschobenen Tropfen aus der Blankliste und falsche Objekte
% löschen unsinnigen Elemente
m=0;
%%%Blank
for i=1:length(remove)
    k=remove(i)-m;
    dropblank(k)=[];
    m=m+1;
end
%% %% 8.2 Überprüfen
%%%Blank
figure
for i=1:length(dropblank)
    k=ceil(sqrt(length(dropblank)));
    subplot(k,k,i)
    imshow(dropblank(i).Target2)
    title(num2str(i))
end
%% %% 8.3 Löschen von Volumenergebnissen von  blank Tropfen, die keinem Ellipsoiden entsprechen
%%%Blank
figure
for i=1:length(dropblank)
    k=ceil(sqrt(length(dropblank)));
    subplot(k,k,i)
    imshow(dropblank(i).Target2)
    title(num2str(i))
end
%% %% 8.4 zu löschende Volumeneintrage eines Tropfens in den Vektor einfügen
remove=[]; %%% Idnr des nicht ellipsoiden Objektes
%%%Blank
m=0;
for i=1:length(remove)
    k=remove(i)-m;
    dropblank(k).Volume=[];
    dropblank(k).Rlong=[];
    dropblank(k).Rshort=[];
    m=m+1;
end
%% 9 Volumen und Flächenbestimmung für Sekundärtropfen
%%%%Red
% Für Tropfen ROT: Bilden einer Binär Matrix für rote Huewert=1, 
% Restliche Huewerte=0 Hue Matrix (Rot Bereich bei Hue(0.8335 bis 1 und 0 bis 0.1665) 
% -> Separieren von Red und Blank in einem Tropfen
for a=1:length(dropred)
    H=dropred(a).Hue(:,:,1);
    S=size(H);
    sx=S(2);
    sy=S(1);
    redmask=zeros(sy,sx);
    for i=1:sy
        for k=1:sx
            if H(i,k)>=0 && H(i,k)<0.1665
                redmask(i,k)=1;
            elseif H(i,k)>0.8335
                redmask(i,k)=1;  
            else
                redmask(i,k)=0;
            end
        end
    end
    dropred(a).redmask=redmask;
    red=regionprops(redmask,'Area','MajorAxisLength','MinorAxisLength');
    % Bestimmung der Achsenlängen des Ellipsoids und der Fläche des roten
    % Gebiets
    dropred(a).redArea=red.Area;
    dropred(a).redMajorAxisLength=red.MajorAxisLength;
    dropred(a).redMinorAxisLength=red.MinorAxisLength;
    % Verhältnis von Fläche rot zu transparent(Blank)
    dropred(a).RatioArea= dropred(a).redArea/dropred(a).Area;
    % Volumenbestimmung des roten Bereichs
    rl=red.MajorAxisLength/2*mmpix;
    rs=red.MinorAxisLength/2*mmpix;
    Vol=(4/3)*pi*rl*(rs^2); % es wird angenommen das der rote Bereich im Tropfen
                            % einem eiförmigen Ellipsoiden ähnelt-> 2
                            % kurze Hauptachsen und eine lange.
    dropred(a).redVolume=Vol;
    % Verhältnis von Volumen rot zu Gesamtvolumen
    if isempty(dropred(a).Volume)==0
        dropred(a).RatioVolume=dropred(a).redVolume/dropred(a).Volume;
    else
        dropred(a).RatioVolume=NaN;
    end
end
%% 10 Volumen und Flächenbestimmung für Jet
%%%Jet
% Für Tropfen ROT: Bilden einer Binär Matrix für rote Huewert=1, 
% Restliche Huewerte=0 Hue Matrix (Rot Bereich bei Hue(0.8335 bis 1 und 0 bis 0.1665) 
% -> Separieren von Red und Blank in einem Tropfen

% nur aktivieren wenn Jet vorhanden 
% deaktivieren wenn kein Jet vorhanden

for a=1:length(jetred)
    H=jetred(a).Hue(:,:,1);
    S=size(H);
    sx=S(2);
    sy=S(1);
    redmask=zeros(sy,sx);
    for i=1:sy
        for k=1:sx
            if H(i,k)>=0 && H(i,k)<0.1665
                redmask(i,k)=1;
            elseif H(i,k)>0.8335
                redmask(i,k)=1;  
            else
                redmask(i,k)=0;
            end
        end
    end
    % Maske für das rote Gebiet im Jet-> redmask
    jetred(a).redmask=redmask;
    % Volumenbestimmung des roten Gebiets analog wie beim gesamten Jet
    J=jetred(a).redmask;
    r=sum(J,2)./2.*mmpix;
    rquadr=r.^2;
    VolJ=pi*mmpix*sum(rquadr);
    jetred(a).redVolume=VolJ;
    % Auslesen der Fläche (Anzahl der Pixel) im roten Gebiet
    red=regionprops(redmask,'Area');
    jetred(a).redArea=red.Area;
    % Verhältnis von Fläche rot zu transparent(Blank)
    jetred(a).RatioArea= jetred(a).redArea/jetred(a).Area;
    % Verhältnis von Volumen rot zu Volumen gesamt
    jetred(a).RatioVolume=jetred(a).redVolume/jetred(a).Volume;

end
%% 11 Overview, Boundaries, figures of Elements
figure
imshow(Im); hold on;
%für rote oder gemischte Tropfen
for k=1:length(dropred)
  boundary = dropred(k).BoundingBox;
  rectangle('Position',[boundary(1),boundary(2),boundary(3),boundary(4)],...
       'EdgeColor','b','LineWidth',1)
  h = text(boundary(1)+boundary(3)*0.5, boundary(2)-20, num2str(k));
  set(h,'Color','g','FontSize',8)%,'FontWeight','bold');
end
% 
%%%Blank
% % Für Transparente Tropfen
% for k=1:length(dropblank)
%   boundary = dropblank(k).BoundingBox;
%   rectangle('Position',[boundary(1),boundary(2),boundary(3),boundary(4)],...
%        'EdgeColor','y','LineWidth',1)
%   h = text(boundary(1)+boundary(3)*0.5, boundary(2)-20, num2str(k));
%   set(h,'Color','m','FontSize',8)%,'FontWeight','bold');
% end
%%%Jet
% % Für den Jet
% for k=1:length(jetred)
%   boundary = jetred(k).BoundingBox;
%   rectangle('Position',[boundary(1),boundary(2),boundary(3),boundary(4)],...
%        'EdgeColor','r','LineWidth',1)
%   h = text(boundary(1)+boundary(3)*0.5, boundary(2)-20, num2str(k));
%   set(h,'Color','r','FontSize',8)%,'FontWeight','bold');
% end

% Abspeichern des Übersichtsbild
cd(RO);%%%7 Eingeben des Zielordners
saveas(gcf,OView);


%% %% 12 Save primary stat dropred jetred dropblank jetblank Matlabskript
clearvars -except Input Primary stat2 dropred dropblank jetred jetblank
save(R) %%%8

