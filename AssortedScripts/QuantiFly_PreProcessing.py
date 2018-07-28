#You must batch group your input images beforehand in a way that direct gridding segregates wells

import glob
import os
import warnings
from PIL import Image

def crop(im,height,width):
    imgwidth, imgheight = im.size
    for i in range(imgheight//height):
        for j in range(imgwidth//width):
            box = (j*width, i*height, (j+1)*width, (i+1)*height)
            yield im.crop(box)

if __name__=='__main__':
    if not os.path.exists('Input'):
        os.makedirs('Input')
        raise Exception('No input directory found, please place PNG images in newly created folder')
    if not os.path.exists('Output'):
        os.makedirs('Output')

    imgdir = 'Input'
    basename = '*.png'
    filelist = glob.glob(os.path.join(imgdir,basename))
    print filelist
    
    for infile in enumerate(filelist):
        
        pieceHeight, pieceWidth = 450,450 #Likely will require changes
        cutColumns, cutRows = 4,6
        
        im = Image.open(infile)
        imgwidth, imgheight = im.size
        height = imgheight/cutColumns
        width =  imgwidth/cutRows
        
        if(abs(height/pieceHeight - 1) > 0.2 or abs(width/pieceWidth - 1) > 0.2):
            warnings.warn("Conversion to uniform size may result in deformation")
        start_num = 0
        for k,piece in enumerate(crop(im,height,width),start_num):
            img=Image.new('L', (pieceHeight,pieceWidth), 255) #'L' converts to greyscale
            img.paste(piece.resize((pieceHeight,pieceWidth), resample=0),(0,0))
            path = os.path.join("./Output/%s_%d.png" % (os.path.basename(infile),int(k+1)))
            img.save(path)

