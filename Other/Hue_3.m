%Wolf 2018 -
%Uses color properties to get liquid amounts from images.
%Note: Configuration for hues will be necessary and the part of the image
%selected must not contain any non liquonid sections of same hue(HSV)

%Note: Post processing is neccessary, you need to remove any spontaneous
%drops. An easy way to do this is to remove any movements of great than
%some percent. E.g. don't count movements if they're greater than 5 of
%previous size. This, of course, should be dependent on 

function main()
    %Establish global vars for tracking in other functions
    global frameNumber;
    global output;
    global sortedRects;
    global masterRect;
    masterRect = {};
    frameNumber = 1;
    output = [,];

    % Rects to pass to later calls so we dont have a "section swap" - More explanation necessary
    v = VideoReader("Data/test2.mp4"); 
    %Start time here in this case we start at 5 minutes to avoid any
    %movement associated with starting the video.
    v.CurrentTime = 1800;
    while v.CurrentTime < v.Duration
        vidFrame = readFrame(v);
        im = vidFrame;
        if v.CurrentTime < 1802
            masterRect = AnalyzeImageRects(im, 10, 3, 2);
        end
        im = imgaussfilt(im, 2);
        I = imcrop(im, masterRect);
        AnalyzeImage(I, 200, 3, 2, sortedRects);
        if v.CurrentTime < v.Duration - 1800 %1800 sec = 30min
            v.CurrentTime = v.CurrentTime + 1800;
        else
            v.CurrentTime = v.Duration;
        end
    end
    csvwrite('csvlist.csv',output)
end

function AnalyzeImage(I, distMin, rowCount, colCount, rectangles)
    global output;
    global frameNumber;
    tes = {};
    count = 0;
    [BW,maskedRGBImage] = createMask(I);
    BW = imfill(BW,'holes');
    [B,L] = bwboundaries(BW,'noholes');
    stats = regionprops(L,'Area','Centroid','BoundingBox');
    %imshow(label2rgb(L, @jet, [.5 .5 .5]))

    for k = 1:length(B)
        boundary = B{k};
        maxCircularity = 1.5; %Circularity solution

        boxLength = max(stats(k).BoundingBox(3:4));

        %Consider using 'BoundingBox'
        delta_sq = diff(boundary).^2;
        perimeter = sum(sqrt(sum(delta_sq,2)));
        area = stats(k).Area;
        % compute the roundness metric
        metric = 4*pi*area/perimeter^2;

        shouldPlot = false;
        if boxLength > distMin && metric < maxCircularity
            shouldPlot = true;
        end
        
        if shouldPlot == true
            count = count + 1;
        end
    end
    imshow(labeloverlay(I,L));
    hold on
    %for k = 1:length(B)
    %    boundary = B{k};
    %    plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
    %end
    print(int2str(frameNumber),'-dpng');
    close;
    
    disp("HERE");
    %imshow(label2rgb(L, @jet, [.5 .5 .5]))
    
    %TODO: Use circularity to check as well, possibly implementing regionprops.
    for i = 1:length(rectangles)
        tem = imcrop(BW, rectangles{i});
        tem = imfill(tem,'holes');
        %imshow(tem);
        [temB,temL] = bwboundaries(tem,'noholes');
        stats = regionprops(temL,'Area','Centroid','BoundingBox');
        for k = 1:length(temB)
            boxLength = max(stats(k).BoundingBox(3:4));
            if boxLength > 10
                count = count + 1;
                output(frameNumber, count) = boxLength;
            end


        end
    end
    if count ~= rowCount*colCount
        fprintf("More or less than rowCount*colCount capillaries being tracked. Likely causing tracking to be out of order");
    end
    
    
    frameNumber = frameNumber + 1;
end

function masterRect = AnalyzeImageRects(I, distMin, rowCount, colCount)
    global frameNumber;
    global sortedRects;
    rects = {};
    count = 0;

    %Note that it may be worthwhile to implement imabsdiff here to adjust
    %things
    % read the original image and put a gaussian filter to smooth
    I = imgaussfilt(I, 2);
    % call createMask function to get the mask and the filtered image
    [BW,maskedRGBImage] = createMask(I);
    BW = imfill(BW,'holes');
    [C,masterRect] = imcrop(BW);
    close;

    %TODO: Use circularity to check as well, possibly implementing regionprops.
    [B,L] = bwboundaries(C,'noholes');
    stats = regionprops(L,'Area','Centroid','BoundingBox');
    %imshow(label2rgb(L, @jet, [.5 .5 .5]))

    for k = 1:length(B)
        boundary = B{k};
        maxCircularity = 1.5; %Circularity solution

        boxLength = max(stats(k).BoundingBox(3:4));

        %Consider using 'BoundingBox'
        delta_sq = diff(boundary).^2;
        perimeter = sum(sqrt(sum(delta_sq,2)));
        area = stats(k).Area;
        % compute the roundness metric
        metric = 4*pi*area/perimeter^2;

        shouldPlot = false;
        if boxLength > distMin && metric < maxCircularity
            shouldPlot = true;
        end
        
        if shouldPlot == true
            count = count + 1;
            rects{count} = stats(k).BoundingBox;
        end
    end

    sortedRects = {};
    for i = 1:(length(rects)/rowCount) %Needs to be generalized - this sorts in sets of 3's y
        indices = ((3*i) - 2):(3*i);
        temp = rects(indices);
        if temp{1}(2) > temp{2}(2)
            holder = temp{1};
            temp{1} = temp{2};
            temp{2} = holder;
        end
        if temp{2}(2) > temp{3}(2)
            holder = temp{2};
            temp{2} = temp{3};
            temp{3} = holder;
        end
        if temp{1}(2) > temp{2}(2)
            holder = temp{1};
            temp{1} = temp{2};
            temp{2} = holder;
        end
        sortedRects{(3*i) - 2} = temp{1};
        sortedRects{(3*i) - 1} = temp{2};
        sortedRects{(3*i)} = temp{3};

    end

    if count ~= rowCount*colCount
        fprintf("More or less than rowCount*colCount capillaries being tracked. Likely causing tracking to be out of order");
    end
    

    %frameNumber = frameNumber + 1;
end


function [BW,maskedRGBImage] = createMask(RGB)
    % Convert RGB image to HSV image
    I = rgb2hsv(RGB);
    % Define thresholds for 'Hue'. Modify these values to filter out different range of colors.
    channel1Min =198;
    channel1Max = 202;
    % Define thresholds for 'Saturation'
    channel2Min = .4;
    channel2Max = .9;
    % Define thresholds for 'Value'
    channel3Min = .3;
    channel3Max = .5;
    % Create mask based on chosen histogram thresholds
    BW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;
    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;
end

