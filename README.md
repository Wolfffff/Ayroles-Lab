# Asorted Files

This static repo contains a few of the files associated with things I worked on over the summer of 2018. There are more in other repos as well as locally, but I have put a few of the files here just as a bookkeeping measure. Note that very few files are in this repo and many of the more complete repos are linked in this README. Furthermore, many of the files are annotated but not perfectly so some probing may be required to utilize them. They should provide a solid starting point for a variety of projects.

## RATrak

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system. Note that Simon knows this system extremely well and if anyone else would like to use it, he will be a great resource.

[Repo](https://github.com/Wolfffff/RATrak)

[Website](https://wolfffff.github.io/RATrak/)

## Capillary Feeding Assay

##### Design Files
Designed in AutoCAD - Only final design files are in this repo under FeedingAssay folder but the following folder contains many more intermittent designs that could prove useful.

[Feeding Assay Design](https://github.com/Wolfffff/Ayroles-Lab/tree/master/FeedingAssay/DesignFiles)

[AutoCAD Repository](https://github.com/Wolfffff/AC_DM)

##### Associated Code
Written in MATLAB to segregate capillaries and track fluid movement. It relies on the assumption that a specific hue only exists on capillaries. The code is pretty easy to read and modify. I'd recommend looking through it and modifying thresholds as necessary before implementation. Of course, adjusting hue is necessary for any implementation and currently conversion from pixel to true length is not in this script; however, that should be trivial.

[Feeding Assay Code](https://github.com/Wolfffff/Ayroles-Lab/tree/master/FeedingAssay/Code)

## Assorted Scripts
[Assorted Scripts](https://github.com/Wolfffff/Ayroles-Lab/tree/master/AssortedScripts)
##### Index
* QuantiFly_PreProcessing
  * Bulk grid cutting script, not a particularly useful script
* BulkPreProcessing
  * [Fiji](https://fiji.sc/) script for locating food on plates, cropping, sorting, and creating a tiff stack
  * Currently setup for 4x6 plates but can be easily modified to support different setups
* FlySizer
  * Python script for analyzing fly size. The script relies on a thresholding, hough circles, and a variety of other vision structures to provide an estimation fly size. Using the data given by Sudarshan, it has around r = ~.8 for area to weight correlation.
  * Be very careful when implementing this. Very finicky when it comes to parameters
* BulkBarCodeProcessing
  * Sorts images by the barcode found in them. Super simple script and easily modifiable for other uses.
  * Uses zbar for barcode reading
   

## Assorted Design Files
[Assorted Design Files](https://github.com/Wolfffff/Ayroles-Lab/tree/master/AssortedDesignFiles)
##### Index
* Various laser cutting files
* Intermediate designs that are not necessarily in [AutoCAD](https://github.com/Wolfffff/AC_DM) repository.

## Everything Else
[Other](https://github.com/Wolfffff/Ayroles-Lab/tree/master/Other)
##### Index
* [STLs](https://github.com/Wolfffff/Ayroles-Lab/tree/master/Other/STLs)
  * STLs from first industrial print on 30/07/2018
* Sample speed file and associated annotation file
* Bibliography exported from Zotero


## Related Images
[Images](https://github.com/Wolfffff/Ayroles-Lab/tree/master/Images)
##### Index
* A few images of related things. Specifically of designs, tracking, and intermediate steps in the development process. This will be updated later as I take more images.


