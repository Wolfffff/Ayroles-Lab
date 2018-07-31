import numpy as np
import argparse
import imutils
import cv2
import os
import warnings
import csv

# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-d", "--dir", required=True, help="Path to the image")
args = vars(ap.parse_args())
#args = ["/Users/Wolf/Desktop/Area_Weight_correlation/tiff_images"]

count = 0
rows = []

def calculateHoughCircles(fileName):
    # load the image, clone it for output
    image = cv2.imread(fileName)
    if (image.shape[0] > image.shape[1]):
        image = imutils.rotate_bound(image, 270)
    output = image.copy()
    global rows
    global count
    height, width, depth = image.shape

    # Grayscale
    imgray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # Median
    #*** Blurring can require modification for the script to work ***
    blur = cv2.medianBlur(imgray, 23)
    # Thresh
    ret1, thresh1 = cv2.threshold(blur, 0, 255, cv2.THRESH_TOZERO + cv2.THRESH_OTSU)
    
    #*** (ret1 - 12) is the threshold as a factor of the one determined by cv2.THRESH_TOZERO + cv2.THRESH_OTSU above. Its modification can fix the script. ***
    ret2, thresh = cv2.threshold(blur, (ret1 - 12), 255, cv2.THRESH_TOZERO)
    edged = cv2.Canny(thresh, 0, 255)

    # Crop image
    cropped = np.zeros((height, width), np.uint8)
    # NOTE: This cropping can be very problematic. It can cut too much or not enough depending on the image. Make sure to adjust this when implementing the algorithm.
    cropped[250:(height - 250), 450:(width - 450)] = -1

    masked = cv2.bitwise_and(edged, edged, mask=cropped)

    #In the line below, the parameters are very relevant for the alg. Radius, sensitivity, minDist, etc. can affect the algorithm. Change them before looking further.
    circles = cv2.HoughCircles(masked, cv2.HOUGH_GRADIENT, 5, 320, minRadius=120, maxRadius=160)

    # detect circles in the image
    # https://docs.opencv.org/3.1.0/da/d53/tutorial_py_houghcircles.html
    # VERY parameter specific. This requires tweaking at the photo level and is non generalizable.
    # Standardized pictures should fix this problem. We have a ~95% success rate

    # First check for 96 wells
    warn = False
    kill = False
    #print(circles.shape)
    if circles.shape[1] > 96:
        warnings.warn("96 wells were not detected! Skipping image")
        print("Filename: ", os.path.basename(fileName))
        print("Greater than 96 wells were detected. Skipping image.")
        kill = True
              
    if circles.shape[1] < 96:
        warnings.warn("96 wells were not detected! Skipping image.")
        print("Filename: ", os.path.basename(fileName))
        print("Less than than 96 wells were detected. Skipping image.")
        kill = True

    if circles is not None and kill == False:
        count = count + 1
        # convert the (x, y) coordinates and radius of the circles to integers
        circles = np.round(circles[0, :]).astype("int")
        circ = circles.tolist()
        circ.sort(key=lambda x: x[1])
        # Hardcode list structure - rows on horizontals
        Lists = [[] for _ in range(8)]
        Lists[0] = circ[0:12]
        Lists[1] = circ[12:24]
        Lists[2] = circ[24:36]
        Lists[3] = circ[36:48]
        Lists[4] = circ[48:60]
        Lists[5] = circ[60:72]
        Lists[6] = circ[72:84]
        Lists[7] = circ[84:96]

        for l in Lists:
            if (len(l) != 12):
                warnings.warn("Wrong count of wells in a row")
            l.sort(key=lambda x: x[0])
        for i in range(8):
            for n in range(12):
                (x, y, r) = Lists[i][n]
                xo = np.round(x).astype("int")
                yo = np.round(y).astype("int")
                ro = np.round(r).astype("int")

                crop = output[(y - r):(y + r), (x - r):(x + r)]
                crop_gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
                ret, threshCrop1 = cv2.threshold(crop_gray, 0, 255, cv2.THRESH_TOZERO + cv2.THRESH_OTSU)
                
                #*** (ret1 - 15) is the threshold as a factor of the one determined by cv2.THRESH_TOZERO + cv2.THRESH_OTSU above. Its modification can fix the script. ***
                ret, threshCrop = cv2.threshold(crop_gray, (ret - 15), 255, cv2.THRESH_TOZERO)
                ret2, tc2 = cv2.threshold(threshCrop, 1, 255, cv2.THRESH_BINARY_INV)

                height, width = 2 * r, 2 * r
                mask = np.zeros((height, width), np.uint8)
                
                #Cut circle with radius = 25 from section of image. This keeps edges of well from interferring with flies. 
                cv2.circle(mask, (r, r), (r - 25), (255, 255, 255), thickness=-1)
                masked_data = cv2.bitwise_and(tc2, tc2, mask=mask)
                
                image, contours, hierarchy = cv2.findContours(masked_data, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
                contour_list = []
                area = 0
                for contour in contours:
                    approx = cv2.approxPolyDP(contour, 0.01 * cv2.arcLength(contour, True), True)
                    tempArea = cv2.contourArea(contour)
                    (x, y), radius = cv2.minEnclosingCircle(contour)
                    #Ad hoc morphology check
                    if (len(approx) > 5) & (tempArea < 5000) & (tempArea > 1000) & (3.1415 * (radius ** 2) / 7 < tempArea):
                        contour_list.append(contour)
                        area = tempArea
                cv2.drawContours(masked_data, contour_list, -1, (50, 50, 50), 3)
                cv2.circle(output, (xo, yo), ro, (0, 255, 0), 4)
                rows.append({'NumericalLocation(Row)': str(i + 1), 'NumericalLocation(Col)': str(n + 1), 'Area': area,'FileName': os.path.basename(fileName)})
        if warn:
            cv2.imshow("output", output)
            cv2.waitKey(0)




total = 0
for file in os.listdir(args[0]):
    if file.endswith(".tiff"):
        total = total + 1
        print(os.path.join(args[0], file))
        calculateHoughCircles(os.path.join(args[0], file))

with open('Output.csv', 'w') as csvfile:
    fieldnames = ['NumericalLocation(Row)', 'NumericalLocation(Col)', 'Area', "FileName"]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)
    
print("Used ", count, " out of ", total, " images.")

if count/total < 0.75:
    warnings.warn("Less than 75% of images used.")
if count < 10:
    warnings.warn("Used less than 10 images for size estimates.")
