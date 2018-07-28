//Bulk processing of images for QuantiFly analysis by Scott Wolf
//Based off macro written by Dominic Waithe to extract circular regions from Drosopholia egg grid for QuantiFly
//Number of images per row in current version is 4
//Input and output directories
input = "/Users/Wolf/Desktop/Input/";
output = "/Users/Wolf/Desktop/Output/";

function bulkAction(input, output, filename) {
    open(input + filename);
    name = getTitle();

    //Sets the Imagej preferences so that they are consistent between versions.
    run("Colors...", "foreground=white background=black selection=yellow");
    run("Set Measurements...", "area min centroid center bounding redirect=None decimal=3");

    //Creates a duplicate of the original which we then resize.
    run("Duplicate...", "title=downscale");
    //Resizing for processing speed
    run("Size...", "width=" + round(getWidth() / 2) + " height=" + round(getHeight() / 2) + " constrain average interploation=Bilinear");
    //Makes a duplicate which we threshold
    run("Duplicate...", "title=thr");
    //Necessary for thresholding
    run("Invert");
    run("8-bit");

    //Using MinError from AutoThresholds - others may have better results
    setAutoThreshold("MinError dark");
    run("Convert to Mask");


    //Clear the ROImanager to remove any regions.
    roiManager("Reset");
    //We then find the image regions on threshold image
    //This line requires the most changing to make it work for a given image set.
    run("Analyze Particles...", "size=1500-Infinity circularity=0.40-1.00 display add"); // Sizes reflects area to consider and the same applies to circularity
    roiCount = roiManager('Count');
    selectWindow("downscale");

    //Next we run through each region, calculate the average size and then calculate
    //the best order so it runs from top-left to bottom right, one row at a time.

    final_rank = newArray(roiCount);
    wid = 0;
    hei = 0;
	//Change 4's to appropriate number to fit data set
    for (rc = 0; rc < roiCount; rc = rc + 4) {
        selectWindow("downscale");
        left = 10000;
        grX = newArray(4);

        for (id1 = 0; id1 < 4; id1++) {

            roiManager("select", rc + id1);
            run('Measure');
            grX[id1] = getResult('X', nResults - 1);
            wid += getResult("Width", nResults - 1);
            hei += getResult("Height", nResults - 1);


        }
        ranks = Array.rankPositions(grX);
        for (rk = 0; rk < 4; rk++) {
            final_rank[rc + rk] = rc + ranks[rk];
        }
    }

    //Calculate the average size of an image.
    ave_wid = wid / roiCount;
    ave_hei = hei / roiCount;

    //Add the image regions in order.
    for (rc = 0; rc < roiCount; rc++) {
        selectWindow("downscale");
        roiManager("select", final_rank[rc]);

        run('Measure');
        grX = getResult('X', nResults - 1);
        grY = getResult('Y', nResults - 1);
        //Training data sets require same width for each, so setting ave_hei and ave_wid to constants
        run("Specify...", "width=" + ave_wid + " height" + ave_hei + " x=" + grX + " y=" + grY + " oval centered scaled");
        roiManager("Add");

    }
    //Clear the outside region to simplify subsequent analysis
    selectWindow("downscale");
    roiManager('Select All');
    roiManager('OR'); //Combine them
    run('Clear Outside'); //
    //We then extract the regions in the correct order.
    for (rc = roiCount; rc < roiCount * 2; rc++) {
        selectWindow("downscale");
        roiManager("select", rc);
        run("Duplicate...", "title=region_" + rc);
    }

    //This is the image stack of individual well images
    run("Images to Stack", "method=[Copy (center)] name=" + name + " title=region use");
    saveAs("tif", output + filename);
    close();
}

//Main loop 
list = getFileList(input);
setBatchMode(true);
for (i = 0; i < list.length; i++) {
    bulkAction(input, output, list[i]);
}
setBatchMode(false);
close("*");
selectWindow("Results");
run("Close");