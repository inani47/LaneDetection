% Author: Pranav Inani
%% Extract Frames From Video
a=VideoReader('../input/project_video.mp4');
for img = 1:a.NumberOfFrames;
    filename=strcat('../input/frame',num2str(img),'.jpg');
    b = read(a, img);
    imwrite(b,filename);
end
%% Load Frames, find lanes and predict direction

% Initialize Circular Buffer
buffSize = 25;
vanBuffer = ones(1,buffSize)*480;

% Load Frames
for i = 1:1260
    frame = sprintf('../input/frame%d.jpg', i);
    road = imread(frame);
    filtRoad = imgaussfilt3(road);  % Apply Gaussian Filter
    grayRoad=rgb2gray(filtRoad);    % Convert RGB image to Grayscale
    grayRoad = grayRoad > 180;      % Apply Thresholding
    [edges,thresh] = edge(grayRoad,'Sobel', 0.025, 'vertical'); % Find edges
    xPoly = [165; 580; 737; 1132;165];  % X cordinates of ROI polygon
    yPoly = [684 ;455; 447; 668; 684];  % Y corrinated of ROI polygon
    mask = poly2mask(xPoly,yPoly,720,1280);  % Create a mask using ROI poly
    edges(~mask)= 0;  % Apply the mask
    % Apply Hough Transform & Find Hough peaks
    [H,T,R] = hough(edges);  
    P  = houghpeaks(H,10,'threshold',ceil(0.1*max(H(:)))); 
    x = T(P(:,2)); y = R(P(:,1));
    lines = houghlines(edges,T,R,P,'FillGap',20,'MinLength',5);
    %Find Best candidate for Left Lane
    maxLeftLineNo = 0;
    maxRightLineNo = 0;
    max_len = 0;
    for l = 1:length(lines)
        if lines(l).theta > 0
            len = norm(lines(l).point1 - lines(l).point2);
            if ( len > max_len)
               maxLeftLineNo = l; 
               max_len = len;
            end
        end
    end
    %Find Best candidate for Left Lane
    max_len = 0; 
    for l = 1:length(lines)
        if lines(l).theta < 0      
            len = norm(lines(l).point1 - lines(l).point2);
            if ( len > max_len)
               maxRightLineNo = l; 
               max_len = len;
            end
        end
    end
    maxLeftLineNo;
    maxRightLineNo;
    % If either left lane or right lane is not found: Skip Image
    if maxLeftLineNo == 0 || maxRightLineNo == 0
        continue
    end
    figure, imshow(frame), hold on
    xy = [lines(maxLeftLineNo).point1; lines(maxLeftLineNo).point2];
    % Find Slope of Left Line
	x1 = xy(1,1);
	y1 = xy(1,2);
	x2 = xy(2,1);
	y2 = xy(2,2);
	slope = (y2-y1)/(x2-x1);
    % Find Desired Start and End points and Plot Them
	yStart = 680;
    xStart = (yStart -y1)/slope + x1;
	yEnd = 475; 
	xEnd = (yEnd-y1)/slope + x1;
	plot([xStart, xEnd], [yStart, yEnd], 'LineWidth',2,'Color','black');	
    XY = [lines(maxRightLineNo).point1; lines(maxRightLineNo).point2];
    % Find Slope of Right Line
    X1 = XY(1,1);
	Y1 = XY(1,2);
	X2 = XY(2,1);
	Y2 = XY(2,2);
	Slope = (Y2-Y1)/(X2-X1);
    % Find Desired Start and End points and Plot Them
	YStart = 680;
    XStart = (YStart -Y1)/Slope + X1;
	YEnd = 475; 
	XEnd = (YEnd-Y1)/Slope + X1;
	plot([XStart, XEnd], [YStart, YEnd], 'LineWidth',2,'Color','black');
    % Plot Area Between Lanes 
    xTrep = [xStart xEnd XEnd XStart];
    yTrep = [yStart yEnd YEnd YStart];
    patch(xTrep,yTrep,'r', 'FaceAlpha', 0.1);
    % Calculate Vanishing Point as the intersection of two Lanes
    van_pt = ((slope*xStart - Slope*XStart) + XEnd-xEnd)/(slope-Slope);
    vanBuffer = [vanBuffer(2:end), van_pt];  % Add Vanishing point to Buffer
    avgVan = mean(vanBuffer);  % Calculate Mean Vanishing Point
    % Predict Lane direction using the average vanishing points
    if avgVan > 530 
        lanePrediction = "Right Curve Ahead" + newline + "Avg Vanishing Point: " + num2str(ceil(avgVan));
    elseif avgVan < 515
        lanePrediction = "Left Curve Ahead" + newline + "Avg Vanishing Point: " + num2str(ceil(avgVan)) ;
    else
        lanePrediction = "Straight Ahead"+ newline + "Avg Vanishing Point: " + num2str(ceil(avgVan));
    end
    text(640, 70, lanePrediction,'horizontalAlignment', 'center', 'Color','red','FontSize',15,'FontWeight','bold');
    % Export output File
    filename = sprintf('output%d.jpg',i);
    output_folder = ('../output');
    hgexport(gcf, fullfile(output_folder, filename), hgexport('factorystyle'), 'Format', 'jpeg');
    hold off
    close all
    
end
%% Make Video From Frame

video = VideoWriter('../output/finalOutput1.mp4','MPEG-4'); %create the video object
video.FrameRate = 15;
video.Quality = 100;
open(video); %open the file for writing
for ii=1:400 
  frame = sprintf('../output/output%d.jpg', ii);
  I = imread(frame); %read the next image
  writeVideo(video,I); %write the image to file
end
close(video);