'''
Wolf - 2018

Usage:

1. Install required packages(as seen below) using pip, brew, etc
2. Place this file into the parent folder of your images(e.g. images are in /home/images/, place this script in /home/)
3. Place your images(and strictly your images) in a folder named "images" under the directory the script is in.
Alternatively, you can edit the "subdir" variable to change location relative to the current working directory.
4. Execute the script.
5. Resolve issues(files that were not sorted, did not have bar/qr code will be left in the original folder)

numpy, opencv-python, pyzbar, zbar
install homebrew
brew install zbar
https://github.com/zplab/zbar-py
https://github.com/ZBar/ZBar/tree/master/python zbar shared
'''
#TODO: Rename if file exists already(or consider time stamping each)

import pyzbar.pyzbar as pyzbar
import numpy as np
import cv2
import os

subdir = "/images"
wd = os.getcwd()
imageNames = []

def load_images_from_folder(folder):
    for filename in os.listdir(folder):
        #img = cv2.imread(os.path.join(folder,filename))
        if filename is not None:
            imageNames.append(filename)
    return imageNames

#def move_renameIfNecessary(title)

def rotate_image(mat, angle):
    """
    Rotates an image (angle in degrees) and expands image to avoid cropping
    """

    height, width = mat.shape
    image_center = (width/2, height/2) # getRotationMatrix2D needs coordinates in reverse order (width, height) compared to shape

    rotation_mat = cv2.getRotationMatrix2D(image_center, angle, 1.)

    # rotation calculates the cos and sin, taking absolutes of those.
    abs_cos = abs(rotation_mat[0,0]) 
    abs_sin = abs(rotation_mat[0,1])

    # find the new width and height bounds
    bound_w = int(height * abs_sin + width * abs_cos)
    bound_h = int(height * abs_cos + width * abs_sin)

    # subtract old image center (bringing image back to origo) and adding the new image center coordinates
    rotation_mat[0, 2] += bound_w/2 - image_center[0]
    rotation_mat[1, 2] += bound_h/2 - image_center[1]

    # rotate image with the new bounds and translated rotation matrix
    rotated_mat = cv2.warpAffine(mat, rotation_mat, (bound_w, bound_h))
    return rotated_mat

#decodedObjects represents the identifiers found in an image
decodedObjects = []
#tracker represents the unique ids found
tracker = []
#Tuples of ids for grouping at the "per run" level
identifiers = []

def process(im):
    #Rotate to get more coverage
    angle = 0
    while (angle < 180):
        test = rotate_image(im, angle)
        decoded = pyzbar.decode(test)
        for x in decoded:
            if (x.type, x.data) not in tracker:
                decodedObjects.append(x)
                tracker.append((x.type,x.data))
        angle = angle + 40
        
#Groups on pass - note that it only holds onto groupings for a single run.
def placeInFolder(title, decodedObjects):
    if decodedObjects != []:
        for d in decodedObjects:
            for i in identifiers:
                if d[0] in i:
                     os.rename(wd + subdir + "/"+ title, wd + "/" +str(i[0]) + "/" + title)
                     break
            continue
                
        if not os.path.exists(str(wd) + "/" + str(d[0])):
            holder = []
            os.makedirs(str(wd) + "/" + str(d[0]))
            os.rename(wd + subdir + "/" +title, wd + "/" + str(d[0]) + "/" + title)
            for x in d:
                holder.append(x[0])
            identifiers.append(holder)
        else:
            holder = []
            os.rename(wd + subdir + "/" +title, wd + "/" + str(d[0]) + "/" + title)
            for x in d:
                holder.append(x[0])
            identifiers.append(holder)

    else:
        print("Did not find bar code in " str(title) + "." + " ")
            
    
# Main 
if __name__ == '__main__':

  images = load_images_from_folder(os.getcwd() + subdir)
  for name in imageNames:
      image = cv2.imread(os.path.join(os.getcwd() + subdir, name))
      temp = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
      process(temp)
      placeInFolder(name, decodedObjects)
      decodedObjects = []
      tracker = []

