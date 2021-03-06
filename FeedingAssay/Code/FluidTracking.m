%Wolf 2018 -
%Uses color properties to get liquid amounts from images.
%Note: Configuration for hues will be necessary and the part of the image
%selected must not contain any non liquonid sections of same hue(HSV)

%Note: Post processing is neccessary, you need to remove any spontaneous
%drops. An easy way to do this is to remove any movements of great than
%some percent. E.g. don't count movements if they're greater than 5 of
%previous size. This, of course, should be dependent on setup.

%Note that this only supports 3 x _ grids right now. The sorting function below is manual and a quick expansion would make it work with more grid sizes.

function main()
    %Establish global vars for tracking in other functions
    global frameNumber;
    global output;
    global sortedRects;
    global masterRect;
    masterRect = {};
    frameNumber = 1;
    output = [,];

    % Rects to pass to later calls so we dont have a "section swap"
    v = VideoReader("Data/test2.mp4"); 
    %Start time here in this case we start at 5 minutes to avoid any
    %movement associated with starting the video.
    v.CurrentTime = 300;
    while v.CurrentTime < v.Duration
        vidFrame = readFrame(v);
        im = vidFrame;
        if v.CurrentTime < 301
        %Get's a set of rectangles to look for hue in later. We only search in original rectangles to avoid appearance of movement outside of original dye location
            masterRect = AnalyzeImageRects(im, 10, 3, 2);
        end
        im = imgaussfilt(im, 2);
        I = imcrop(im, masterRect);
        AnalyzeImage(I, 20, 3, 2, sortedRects);
        %Move 2 minutes between each analysis
        if v.CurrentTime < v.Duration - 120 %Time in S
            v.CurrentTime = v.CurrentTime + 120;
        else
            v.CurrentTime = v.Duration;
        end
    end
    %Output
    csvwrite('csvlist.csv',output)
end

function AnalyzeImage(I, distMin, rowCount, colCount, rectangles)
    global output;
    global frameNumber;
    count = 0;
    [BW,maskedRGBImage] = createMask(I);

    BW = imfill(BW,'holes');
    %TODO: Use circularity to check as well, possibly implementing regionprops.
    for i = 1:length(rectangles)
        %Crop to appropriate rectangle from masterRects
        tem = imcrop(BW, rectangles{i});
        tem = imfill(tem,'holes');
        imshow(tem);
        [temB,temL] = bwboundaries(tem,'noholes');
        %Image cleaning
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
        % compute the roundness metric - ad hoc solution
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
    %Needs to be generalized - this sorts in sets of 3's y so we support 3x2 only right now
    for i = 1:(length(rects)/rowCount)
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

    frameNumber = frameNumber + 1;
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

