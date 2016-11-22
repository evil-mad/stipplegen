/**

 StippleGen_2_40

 SVG Stipple Generator, v. 2.40
 Copyright (C) 2016 by Windell H. Oskay, www.evilmadscientist.com

 Full Documentation: http://wiki.evilmadscientist.com/StippleGen
 Blog post about the release: http://www.evilmadscientist.com/go/stipple2

 An implementation of Weighted Voronoi Stippling:
 http://mrl.nyu.edu/~ajsecord/stipples.html

 *******************************************************************************

 Change Log:

 v 2.4
 * Compiling in Processing 3.0.1
 * Add GUI option to fill circles with a spiral

 v 2.3
 * Forked from 2.1.1
 * Fixed saving bug

 v 2.20
 * [Cancelled development branch.]

 v 2.1.1
 * Faster now, with number of stipples calculated at a time.

 v 2.1.0
 * Now compiling in Processing 2.0b6
 * selectInput() and selectOutput() calls modified for Processing 2.

 v 2.02
 * Force files to end in .svg
 * Fix bug that gave wrong size to stipple files saved white stipples on black background

 v 2.01:
 * Improved handling of Save process, to prevent accidental "not saving" by users.

 v 2.0:
 * Add tone reversal option (white on black / black on white)
 * Reduce vertical extent of GUI, to reduce likelihood of cropping on small screens
 * Speling corections
 * Fixed a bug that caused unintended cropping of long, wide images
 * Reorganized GUI controls
 * Fail less disgracefully when a bad image type is selected.

 *******************************************************************************

 Program is based on the Toxic Libs Library ( http://toxiclibs.org/ )
 & example code:
 http://forum.processing.org/topic/toxiclib-voronoi-example-sketch

 Additional inspiration:
 Stipple Cam from Jim Bumgardner
 http://joyofprocessing.com/blog/2011/11/stipple-cam/

 and

 MeshLibDemo.pde - Demo of Lee Byron's Mesh library, by
 Marius Watz - http://workshop.evolutionzone.com/

 Requires ControlP5 library and Toxic Libs library:
 http://www.sojamo.de/libraries/controlP5/
 http://bitbucket.org/postspectacular/toxiclibs/downloads/

*/

/*
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * http://creativecommons.org/licenses/LGPL/2.1/
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

// You need the controlP5 library from http://www.sojamo.de/libraries/controlP5/
import controlP5.*;

//You need the Toxic Libs library: http://hg.postspectacular.com/toxiclibs/downloads
import toxi.geom.*;
import toxi.geom.mesh2d.*;
import toxi.util.datatypes.*;
import toxi.processing.*;

import javax.swing.UIManager;
import javax.swing.JFileChooser;

// helper class for rendering
ToxiclibsSupport gfx;

// Feel free to play with these three default settings
float cutoff = 0;
float minDotSize = 1.75;
float dotSizeFactor = 4;
// Max value is normally 10000. Press 'x' key to allow 50000 stipples. (SLOW)
int maxParticles = 2000;

//Scale each cell to fit in a cellBuffer-sized square window for computing the centroid.
int cellBuffer = 100;

// Display window and GUI area sizes:
int mainwidth;
int mainheight;
int borderWidth;
int ctrlheight;
int textColumnStart;

float lowBorderX;
float hiBorderX;
float lowBorderY;
float hiBorderY;

float maxDotSize;
boolean reInitiallizeArray;
boolean pausemode;
boolean fileLoaded;
boolean saveNow;
String savePath;
String[] fileOutput;

boolean fillingCircles;

String statusDisplay = "Initializing, please wait. :)";
float millisLastFrame = 0;
float frameTime = 0;

float errorTime;
String errorDisplay = "";
boolean errorDisp = false;

int generation;
int particleRouteLength;
int routeStep;

boolean invertImg;
boolean fileModeTSP;
boolean tempShowCells;
boolean showBG, showPath, showCells;

int vorPointsAdded;
boolean voronoiCalculated;

int cellsTotal, cellsCalculated, cellsCalculatedLast;

int[] particleRoute;
Vec2D[] particles;

ControlP5 cp5;
Voronoi voronoi;
Polygon2D regionList[];
PolygonClipper2D clip;
PImage img, imgload, imgblur;

void LoadImageAndScale() {
  int tempx = 0;
  int tempy = 0;

  img = createImage(mainwidth, mainheight, RGB);
  imgblur = createImage(mainwidth, mainheight, RGB);

  img.loadPixels();

  for (int i = 0; i < img.pixels.length; i++) {
    img.pixels[i] = color(invertImg ? 0 : 255);
  }

  img.updatePixels();

  if (!fileLoaded) {
    // Load a demo image, at least until we have a "real" image to work with.
    // Image from: http://commons.wikimedia.org/wiki/File:Kelly,_Grace_(Rear_Window).jpg
    imgload = loadImage("grace.jpg"); // Load demo image
  }

  if ((imgload.width > mainwidth) || (imgload.height > mainheight)) {
    if (((float)imgload.width / (float)imgload.height) > ((float)mainwidth / (float)mainheight))
    {
      imgload.resize(mainwidth, 0);
    } else {
      imgload.resize(0, mainheight);
    }
  }

  if (imgload.height < (mainheight - 2)) {
    tempy = (int)((mainheight - imgload.height) / 2) ;
  }
  if (imgload.width < (mainwidth - 2)) {
    tempx = (int)((mainwidth - imgload.width) / 2) ;
  }

  img.copy(imgload, 0, 0, imgload.width, imgload.height, tempx, tempy, imgload.width, imgload.height);
  // For background image!

  /*
   // Optional gamma correction for background image.
   img.loadPixels();

   float tempFloat;
   float GammaValue = 1.0;  // Normally in the range 0.25 - 4.0

   for (int i = 0; i < img.pixels.length; i++) {
   tempFloat = brightness(img.pixels[i])/255;
   img.pixels[i] = color(floor(255 * pow(tempFloat,GammaValue)));
   }
   img.updatePixels();
  */

  imgblur.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  // This is a duplicate of the background image, that we will apply a blur to,
  // to reduce "high frequency" noise artifacts.

  // Low-level blur filter to elminate pixel-to-pixel noise artifacts.
  imgblur.filter(BLUR, 1);
  imgblur.loadPixels();
}

void MainArraySetup() {
  // Main particle array initialization (to be called whenever necessary):
  LoadImageAndScale();

  // image(img, 0, 0); // SHOW BG IMG

  particles = new Vec2D[maxParticles];

  // Fill array by "rejection sampling"
  int  i = 0;
  while (i < maxParticles) {
    float fx = lowBorderX + random(hiBorderX - lowBorderX);
    float fy = lowBorderY + random(hiBorderY - lowBorderY);

    float p = brightness(imgblur.pixels[ floor(fy)*imgblur.width + floor(fx) ])/255; 
    // OK to use simple floor_ rounding here, because  this is a one-time operation,
    // creating the initial distribution that will be iterated.

    if (invertImg) {
      p =  1 - p;
    }

    if (random(1) >= p ) {
      Vec2D p1 = new Vec2D(fx, fy);
      particles[i] = p1;
      i++;
    }
  }

  particleRouteLength = 0;
  generation = 0;
  millisLastFrame = millis();
  routeStep = 0;
  voronoiCalculated = false;
  cellsCalculated = 0;
  vorPointsAdded = 0;
  voronoi = new Voronoi();  // Erase mesh
  tempShowCells = true;
  fileModeTSP = false;
}

void setup() {
  borderWidth = 6;
  mainwidth = 800;
  mainheight = 600;
  ctrlheight = 110;
  fillingCircles = true;

  size(800, 710);

  gfx = new ToxiclibsSupport(this);

  lowBorderX = borderWidth; //mainwidth*0.01;
  hiBorderX = mainwidth - borderWidth; //mainwidth*0.98;
  lowBorderY = borderWidth; // mainheight*0.01;
  hiBorderY = mainheight - borderWidth; //mainheight*0.98;

  int innerWidth = mainwidth - 2 * borderWidth;
  int innerHeight = mainheight - 2 * borderWidth;

  Rect rect = new Rect(lowBorderX, lowBorderY, innerWidth, innerHeight);
  clip = new SutherlandHodgemanClipper(rect);

  MainArraySetup();   // Main particle array setup

  frameRate(24);
  smooth();
  noStroke();
  fill(153); // Background fill color, for control section

  textFont(createFont("SansSerif", 10));

  cp5 = new ControlP5(this);

  int leftcolumwidth = 225;
  int guiTop = mainheight + 15;
  int gui2ndRow = 4;   // Spacing for firt row after group heading
  int guiRowSpacing = 14;  // Spacing for subsequent rows
  int buttonHeight = mainheight + 19 + int(round(2.25 * guiRowSpacing));

  ControlGroup l3 = cp5.addGroup("Primary controls (Changing will restart)", 10, guiTop, 225);

  cp5.addSlider("sliderStipples", 10, 10000, maxParticles, 10, gui2ndRow, 150, 10)
    .setGroup(l3);

  cp5.addButton("buttonInvertImg", 10, 10, gui2ndRow + guiRowSpacing, 190, 10)
     .setCaptionLabel("Black stipples, White Background")
     .setGroup(l3);

  cp5.addButton("buttonLoadFile", 10, 10, buttonHeight, 175, 10)
     .setCaptionLabel("LOAD IMAGE FILE (.PNG, .JPG, or .GIF)");

  cp5.addButton("buttonQuit", 10, 205, buttonHeight, 30, 10)
     .setCaptionLabel("Quit");

  cp5.addButton("buttonSaveStipples", 10, 25, buttonHeight + guiRowSpacing, 160, 10)
     .setCaptionLabel("Save Stipple File (.SVG format)");

  cp5.addButton("buttonSavePath", 10, 25, buttonHeight + 2 * guiRowSpacing, 160, 10)
     .setCaptionLabel("Save \"TSP\" Path (.SVG format)");

  cp5.addButton("buttonFillCircles", 10, 10, buttonHeight + 3 * guiRowSpacing, 190, 10)
     .setCaptionLabel("Generate Filled circles in output");

  ControlGroup l5 = cp5.addGroup("Display Options - Updated on next generation", leftcolumwidth+50, guiTop, 225);

  cp5.addSlider("sliderMinDotSize", .5, 8, 2, 10, 4, 140, 10)
     .setCaptionLabel("Min. Dot Size")
     .setValue(minDotSize)
     .setGroup(l5);

  cp5.addSlider("sliderDotSizeRange", 0, 20, 5, 10, 18, 140, 10)
     .setCaptionLabel("Dot Size Range")
     .setValue(dotSizeFactor)
     .setGroup(l5);

  cp5.addSlider("sliderWhiteCutoff", 0, 1, 0, 10, 32, 140, 10)
     .setCaptionLabel("White Cutoff")
     .setValue(cutoff)
     .setGroup(l5);

  cp5.addButton("buttonImgOnOff", 10, 10, 46, 90, 10)
     .setCaptionLabel("Image BG >> Hide")
     .setGroup(l5);

  cp5.addButton("buttonCellsOnOff", 10, 110, 46, 90, 10)
     .setCaptionLabel("Cells >> Hide")
     .setGroup(l5);

  cp5.addButton("buttonPause", 10, 10, 60, 190, 10)
     .setCaptionLabel("Pause (to calculate TSP path)")
     .setGroup(l5);

  cp5.addButton("buttonOrderOnOff", 10, 10, 74, 190, 10)
     .setCaptionLabel("Plotting path >> shown while paused")
     .setGroup(l5);

  textColumnStart = 2 * leftcolumwidth + 100;
  maxDotSize = getMaxDotSize(minDotSize);

  saveNow = false;
  showBG = false;
  showPath = true;
  showCells = false;
  pausemode = false;
  invertImg = false;
  fileLoaded = false;
  reInitiallizeArray = false;
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    //println("User selected " + selection.getAbsolutePath());

    String loadPath = selection.getAbsolutePath();

    // If a file was selected, print path to file
    println("Loaded file: " + loadPath);

    String[] p = splitTokens(loadPath, ".");
    String ext = p[p.length - 1].toLowerCase();

    boolean fileOK = false;
    fileOK = fileOK || ext.equals("gif");
    fileOK = fileOK || ext.equals("jpg");
    fileOK = fileOK || ext.equals("tga");
    fileOK = fileOK || ext.equals("png");

    println("File OK: " + fileOK);

    if (fileOK) {
      imgload = loadImage(loadPath);
      fileLoaded = true;
      reInitiallizeArray = true;
    } else {
      // Can't load file
      errorDisplay = "ERROR: BAD FILE TYPE";
      errorTime = millis();
      errorDisp = true;
    }
  }
}

void buttonLoadFile(float theValue) {
  println(":::LOAD JPG, GIF or PNG FILE:::");
  selectInput("Select a file to process:", "fileSelected");  // Opens file chooser
}

void buttonSavePath(float theValue) {
  fileModeTSP = true;
  saveSvg(0);
}

void buttonSaveStipples(float theValue) {
  fileModeTSP = false;
  saveSvg(0);
}

void SavefileSelected(File selection) {
  if (selection == null) {
    // If a file was not selected
    println("No output file was selected...");
    errorDisplay = "ERROR: NO FILE NAME CHOSEN.";
    errorTime = millis();
    errorDisp = true;
  } else {
    savePath = selection.getAbsolutePath();
    String[] p = splitTokens(savePath, ".");
    boolean fileOK = p[p.length - 1].toLowerCase().equals("svg");
    if (!fileOK) savePath = savePath + ".svg";

    // If a file was selected, print path to folder
    println("Save file: " + savePath);
    saveNow = true;
    showPath = true;

    errorDisplay = "SAVING FILE...";
    errorTime = millis();
    errorDisp = true;
  }
}

void saveSvg(float theValue) {
  if (!pausemode) {
    buttonPause(0.0);
    errorDisplay = "Error: PAUSE before saving.";
    errorTime = millis();
    errorDisp = true;
  } else {
    selectOutput("Output .svg file name:", "SavefileSelected");
  }
}

void buttonQuit(float theValue) {
  exit();
}

void buttonOrderOnOff(float theValue) {
  Button orderOnOff = (Button)cp5.getController("buttonOrderOnOff");
  if (showPath) {
    showPath = false;
    orderOnOff.setCaptionLabel("Plotting path >> Hide");
  } else {
    showPath = true;
    orderOnOff.setCaptionLabel("Plotting path >> Shown while paused");
  }
}

void buttonCellsOnOff(float theValue) {
  Button cellsOnOff = (Button)cp5.getController("buttonCellsOnOff");
  if (showCells) {
    showCells = false;
    cellsOnOff.setCaptionLabel("Cells >> Hide");
  } else {
    showCells = true;
    cellsOnOff.setCaptionLabel("Cells >> Show");
  }
}

void buttonImgOnOff(float theValue) {
  Button imgOnOffButton = (Button)cp5.getController("buttonImgOnOff");
  if (showBG) {
    showBG = false;
    imgOnOffButton.setCaptionLabel("Image BG >> Hide");
  } else {
    showBG = true;
    imgOnOffButton.setCaptionLabel("Image BG >> Show");
  }
}

void buttonInvertImg(float theValue) {
  Slider cutoffSlider = (Slider)cp5.getController("sliderWhiteCutoff");
  Button invertImgButton = (Button)cp5.getController("buttonInvertImg");
  if (invertImg) {
    invertImg = false;
    invertImgButton.setCaptionLabel("Black stipples, White background");
    cutoffSlider.setCaptionLabel("White Cutoff");
  } else {
    invertImg = true;
    invertImgButton.setCaptionLabel("White stipples, Black background");
    cutoffSlider.setCaptionLabel("Black Cutoff");
  }

  reInitiallizeArray = true;
  pausemode = false;
}

void buttonFillCircles(float theValue) {
  Button fillCircleButton = (Button)cp5.getController("buttonFillCircles");
  if (fillingCircles) {
    fillingCircles = false;
    fillCircleButton.setCaptionLabel("Generate Open circles in output");
  } else {
    fillingCircles = true;
    fillCircleButton.setCaptionLabel("Generate Filled circles in output");
  }
}

void buttonPause(float theValue) {
  // Main particle array setup (to be repeated if necessary):
  Button pauseButton = (Button)cp5.getController("buttonPause");
  if (pausemode) {
    pausemode = false;
    println("Resuming.");
    pauseButton.setCaptionLabel("Pause (to calculate TSP path)");
  } else {
    pausemode = true;
    println("Paused. Press PAUSE again to resume.");
    pauseButton.setCaptionLabel("Paused (calculating TSP path)");
  }
  routeStep = 0;
}

boolean overRect(int x, int y, int width, int height) {
  return mouseX >= x && mouseX <= x + width && mouseY >= y && mouseY <= y + height;
}

void sliderStipples(int inValue) {
  if (maxParticles != inValue) {
    println("Update:  Stipple Count -> " + inValue);
    reInitiallizeArray = true;
    pausemode = false;
  }
}

void sliderMinDotSize(float inValue) {
  if (minDotSize != inValue) {
    println("Update: sliderMinDotSize -> " + inValue);
    minDotSize = inValue;
    maxDotSize = getMaxDotSize(minDotSize);
  }
}

void sliderDotSizeRange(float inValue) {
  if (dotSizeFactor != inValue) {
    println("Update: Dot Size Range -> " + inValue);
    dotSizeFactor = inValue;
    maxDotSize = getMaxDotSize(minDotSize);
  }
}

void sliderWhiteCutoff(float inValue) {
  if (cutoff != inValue) {
    println("Update: White_Cutoff -> " + inValue);
    cutoff = inValue;
    routeStep = 0; // Reset TSP path
  }
}

float getMaxDotSize(float minDotSize) {
  return minDotSize * (1 + dotSizeFactor);
}

void  doBackgrounds() {
  if (showBG) {
    image(img, 0, 0); // Show original (cropped and scaled, but not blurred!) image in background
  } else {
    fill(invertImg ? 0 : 255);
    rect(0, 0, mainwidth, mainheight);
  }
}

void optimizePlotPath() {
  int temp;
  // Calculate and show "optimized" plotting path, beneath points.

  statusDisplay = "Optimizing plotting path";
  /*
  if (routeStep % 100 == 0) {
    println("RouteStep:" + routeStep);
    println("fps = " + frameRate );
  }
  */

  Vec2D p1;

  if (routeStep == 0) {
    float cutoffScaled = 1 - cutoff;
    // Begin process of optimizing plotting route, by flagging particles that will be shown.

    particleRouteLength = 0;

    boolean particleRouteTemp[] = new boolean[maxParticles];

    for (int i = 0; i < maxParticles; ++i) {
      particleRouteTemp[i] = false;

      int px = (int) particles[i].x;
      int py = (int) particles[i].y;

      if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0)) {
        continue;
      }

      float v = (brightness(imgblur.pixels[py * imgblur.width + px])) / 255;

      if (invertImg) {
        v = 1 - v;
      }

      if (v < cutoffScaled) {
        particleRouteTemp[i] = true;
        particleRouteLength++;
      }
    }

    particleRoute = new int[particleRouteLength];
    int tempCounter = 0;
    for (int i = 0; i < maxParticles; ++i) {
      if (particleRouteTemp[i]) {
        particleRoute[tempCounter] = i;
        tempCounter++;
      }
    }
    // These are the ONLY points to be drawn in the tour.
  }

  if (routeStep < (particleRouteLength - 2)) {
    // Nearest neighbor ("Simple, Greedy") algorithm path optimization:

    int StopPoint = routeStep + 1000; // 1000 steps per frame displayed; you can edit this number!

    if (StopPoint > (particleRouteLength - 1)) {
      StopPoint = particleRouteLength - 1;
    }

    for (int i = routeStep; i < StopPoint; ++i) {
      p1 = particles[particleRoute[routeStep]];
      int ClosestParticle = 0;
      float  distMin = Float.MAX_VALUE;

      for (int j = routeStep + 1; j < (particleRouteLength - 1); ++j) {
        Vec2D p2 = particles[particleRoute[j]];

        float  dx = p1.x - p2.x;
        float  dy = p1.y - p2.y;
        float  distance = (float) (dx*dx+dy*dy);  // Only looking for closest; do not need sqrt factor!

        if (distance < distMin) {
          ClosestParticle = j;
          distMin = distance;
        }
      }

      temp = particleRoute[routeStep + 1];
      // p1 = particles[particleRoute[routeStep + 1]];
      particleRoute[routeStep + 1] = particleRoute[ClosestParticle];
      particleRoute[ClosestParticle] = temp;

      if (routeStep < (particleRouteLength - 1)) {
        routeStep++;
      } else {
        println("Now optimizing plot path" );
      }
    }
  } else {     // Initial routing is complete
    // 2-opt heuristic optimization:
    // Identify a pair of edges that would become shorter by reversing part of the tour.

    for (int i = 0; i < 90000; ++i) {   // 1000 tests per frame; you can edit this number.
      int indexA = floor(random(particleRouteLength - 1));
      int indexB = floor(random(particleRouteLength - 1));

      if (Math.abs(indexA  - indexB) < 2) {
        continue;
      }

      if (indexB < indexA) { // swap A, B.
        temp = indexB;
        indexB = indexA;
        indexA = temp;
      }

      Vec2D a0 = particles[particleRoute[indexA]];
      Vec2D a1 = particles[particleRoute[indexA + 1]];
      Vec2D b0 = particles[particleRoute[indexB]];
      Vec2D b1 = particles[particleRoute[indexB + 1]];

      // Original distance:
      float  dx = a0.x - a1.x;
      float  dy = a0.y - a1.y;
      float  distance = (float)(dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor!
      dx = b0.x - b1.x;
      dy = b0.y - b1.y;
      distance += (float)(dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor!

      // Possible shorter distance?
      dx = a0.x - b0.x;
      dy = a0.y - b0.y;
      float distance2 = (float)(dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 
      dx = a1.x - b1.x;
      dy = a1.y - b1.y;
      distance2 += (float)(dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 

      if (distance2 < distance) {
        // Reverse tour between a1 and b0.

        int indexhigh = indexB;
        int indexlow = indexA + 1;

        // println("Shorten!" + frameRate );

        while (indexhigh > indexlow) {
          temp = particleRoute[indexlow];
          particleRoute[indexlow] = particleRoute[indexhigh];
          particleRoute[indexhigh] = temp;

          indexhigh--;
          indexlow++;
        }
      }
    }
  }

  frameTime = (millis() - millisLastFrame) / 1000;
  millisLastFrame = millis();
}

void doPhysics() {   // Iterative relaxation via weighted Lloyd's algorithm.
  int temp;
  int CountTemp;

  if (!voronoiCalculated) {
    // Part I: Calculate voronoi cell diagram of the points.

    statusDisplay = "Calculating Voronoi diagram ";

    // float millisBaseline = millis();  // Baseline for timing studies
    // println("Baseline.  Time = " + (millis() - millisBaseline) );

    if (vorPointsAdded == 0) {
      voronoi = new Voronoi();  // Erase mesh
    }

    temp = vorPointsAdded + 500;   // This line: VoronoiPointsPerPass  (Feel free to edit this number.)
    if (temp > maxParticles) {
      temp = maxParticles;
    }

    for (int i = vorPointsAdded; i < temp; i++) {
      // Optional, for diagnostics:::
      //  println("particles[i].x, particles[i].y " + particles[i].x + ", " + particles[i].y );

      voronoi.addPoint(new Vec2D(particles[i].x, particles[i].y ));
      vorPointsAdded++;
    }

    if (vorPointsAdded >= maxParticles) {
      // println("Points added.  Time = " + (millis() - millisBaseline) );

      cellsTotal = voronoi.getRegions().size();
      vorPointsAdded = 0;
      cellsCalculated = 0;
      cellsCalculatedLast = 0;

      regionList = new Polygon2D[cellsTotal];

      int i = 0;
      for (Polygon2D poly : voronoi.getRegions()) {
        regionList[i++] = poly;  // Build array of polygons
      }
      voronoiCalculated = true;
    }
  } else {    // Part II: Calculate weighted centroids of cells.
    //  float millisBaseline = millis();
    //  println("fps = " + frameRate );

    statusDisplay = "Calculating weighted centroids";

    temp = cellsCalculated + 500;   // This line: CentroidsPerPass  (Feel free to edit this number.)
    // Higher values give slightly faster computation, but a less responsive GUI.
    // Default value: 500

    // Time/frame @ 100: 2.07 @ 50 frames in
    // Time/frame @ 200: 1.575 @ 50
    // Time/frame @ 500: 1.44 @ 50

    if (temp > cellsTotal) {
      temp = cellsTotal;
    }

    for (int i=cellsCalculated; i< temp; i++) {
      float xMax = 0;
      float xMin = mainwidth;
      float yMax = 0;
      float yMin = mainheight;
      float xt, yt;

      Polygon2D region = clip.clipPolygon(regionList[i]);

      for (Vec2D v : region.vertices) {
        xt = v.x;
        yt = v.y;

        if (xt < xMin) xMin = xt;
        if (xt > xMax) xMax = xt;
        if (yt < yMin) yMin = yt;
        if (yt > yMax) yMax = yt;
      }

      float xDiff = xMax - xMin;
      float yDiff = yMax - yMin;
      float maxSize = max(xDiff, yDiff);
      float minSize = min(xDiff, yDiff);

      float scaleFactor = 1.0;

      // Maximum voronoi cell extent should be between
      // cellBuffer/2 and cellBuffer in size.

      while (maxSize > cellBuffer) {
        scaleFactor *= 0.5;
        maxSize *= 0.5;
      }

      while (maxSize < (cellBuffer / 2)) {
        scaleFactor *= 2;
        maxSize *= 2;
      }

      if ((minSize * scaleFactor) > (cellBuffer/2)) {
        // Special correction for objects of near-unity (square-like) aspect ratio,
        // which have larger area *and* where it is less essential to find the exact centroid:
        scaleFactor *= 0.5;
      }

      float StepSize = (1/scaleFactor);

      float xSum = 0;
      float ySum = 0;
      float dSum = 0;
      float PicDensity = 1.0;

      if (invertImg) {
        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {
            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) {
              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.
              PicDensity = 0.001 + (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));

              xSum += PicDensity * x;
              ySum += PicDensity * y;
              dSum += PicDensity;
            }
          }
        }
      } else {
        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {
            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) {
              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.
              PicDensity = 255.001 - (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));

              xSum += PicDensity * x;
              ySum += PicDensity * y;
              dSum += PicDensity;
            }
          }
        }
      }

      if (dSum > 0) {
        xSum /= dSum;
        ySum /= dSum;
      }

      Vec2D centr;

      float xTemp = xSum;
      float yTemp = ySum;

      if ((xTemp <= lowBorderX) || (xTemp >= hiBorderX) || (yTemp <= lowBorderY) || (yTemp >= hiBorderY)) {
        // If new centroid is computed to be outside the visible region, use the geometric centroid instead.
        // This will help to prevent runaway points due to numerical artifacts.
        centr = region.getCentroid();
        xTemp = centr.x;
        yTemp = centr.y;

        // Enforce sides, if absolutely necessary:  (Failure to do so *will* cause a crash, eventually.)

        if (xTemp <= lowBorderX) xTemp = lowBorderX + 1;
        if (xTemp >= hiBorderX)  xTemp = hiBorderX - 1;
        if (yTemp <= lowBorderY) yTemp = lowBorderY + 1;
        if (yTemp >= hiBorderY)  yTemp = hiBorderY - 1;
      }

      particles[i].x = xTemp;
      particles[i].y = yTemp;

      cellsCalculated++;
    }

    //  println("cellsCalculated = " + cellsCalculated );
    //  println("cellsTotal = " + cellsTotal );

    if (cellsCalculated >= cellsTotal) {
      voronoiCalculated = false;
      generation++;
      println("Generation = " + generation );

      frameTime = (millis() - millisLastFrame)/1000;
      millisLastFrame = millis();
    }
  }
}

String makeSpiral ( float xOrigin, float yOrigin, float turns, float radius)
{
  float resolution = 20.0;

  float AngleStep = TAU / resolution;
  float ScaledRadiusPerTurn = radius / (TAU * turns);

  String spiralSVG = "<path d=\"M " + xOrigin + "," + yOrigin + " "; // Mark center point of spiral

  float x, y;
  float angle = 0;

  int stopPoint = ceil (resolution * turns);
  int startPoint = floor(resolution / 4);  // Skip the first quarter turn in the spiral, since we have a center point already.

  if (turns > 1.0) { // For small enough circles, skip the fill, and just draw the circle.
    for (int i = startPoint; i <= stopPoint; i = i+1) {
      angle = i * AngleStep;
      x = xOrigin + ScaledRadiusPerTurn * angle * cos(angle);
      y = yOrigin + ScaledRadiusPerTurn * angle * sin(angle);
      spiralSVG += x + "," + y + " ";
    }
  }

  // Last turn is a circle:
  float CircleRad = ScaledRadiusPerTurn * angle;

  for (int i = 0; i <= resolution; i = i+1) {
    angle += AngleStep;
    x = xOrigin + radius * cos(angle);
    y = yOrigin + radius * sin(angle);

    spiralSVG += x + "," + y + " ";
  }

  spiralSVG += "\" />" ;
  return spiralSVG;
}

void draw() {
  int i = 0;
  int temp;
  float dotScale = (maxDotSize - minDotSize);
  float cutoffScaled = 1 - cutoff;

  if (reInitiallizeArray) {
    // Only change maxParticles here!
    maxParticles = (int)cp5.getController("sliderStipples").getValue();
    MainArraySetup();
    reInitiallizeArray = false;
  }

  if (pausemode && !voronoiCalculated)  {
    optimizePlotPath();
  } else {
    doPhysics();
  }

  if (pausemode) {
    doBackgrounds();

    // Draw paths:

    if (showPath) {
      stroke(128, 128, 255); // Stroke color (blue)
      strokeWeight (1);

      for (i = 0; i < particleRouteLength - 1; ++i) {
        Vec2D p1 = particles[particleRoute[i]];
        Vec2D p2 = particles[particleRoute[i + 1]];
        line(p1.x, p1.y, p2.x, p2.y);
      }
    }

    stroke(invertImg ? 255 : 0);
    fill (invertImg ? 0 : 255);
    strokeWeight(1);

    for ( i = 0; i < particleRouteLength; ++i) {
      // Only show "routed" particles-- those above the white cutoff.

      Vec2D p1 = particles[particleRoute[i]];
      int px = (int)p1.x;
      int py = (int)p1.y;

      float v = (brightness(imgblur.pixels[py * imgblur.width + px])) / 255;

      if (invertImg) v = 1 - v;

      if (fillingCircles) {
        strokeWeight(maxDotSize - v * dotScale);
        point(px, py);
      } else {
        float dotSize = maxDotSize - v * dotScale;
        ellipse(px, py, dotSize, dotSize);
      }
    }
  } else { // NOT in pause mode.  i.e., just displaying stipples.
    if (cellsCalculated == 0) {
      doBackgrounds();

      tempShowCells = generation == 0;

      if (showCells || tempShowCells) {  // Draw voronoi cells, over background.
        strokeWeight(1);
        noFill();

        stroke(invertImg && !showBG ? 100 : 200);

        i = 0;
        for (Polygon2D poly : voronoi.getRegions()) {
          //regionList[i++] = poly;
          gfx.polygon2D(clip.clipPolygon(poly));
        }
      }

      if (showCells) {
        // Show "before and after" centroids, when polygons are shown.

        strokeWeight(minDotSize);  // Normal w/ Min & Max dot size
        for ( i = 0; i < maxParticles; ++i) {

          int px = (int)particles[i].x;
          int py = (int)particles[i].y;

          if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0))
            continue;
          {
            //Uncomment the following four lines, if you wish to display the "before" dots at weighted sizes.
            //float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255;
            //if (invertImg)
            //v = 1 - v;
            //strokeWeight (maxDotSize - v * dotScale);
            point(px, py);
          }
        }
      }
    } else {
      // Stipple calculation is still underway

      if (tempShowCells) {
        doBackgrounds();
        tempShowCells = false;
      }

      stroke(invertImg ? 255 : 0);
      fill(invertImg ? 0 : 255);
      strokeWeight(1);

      for (i = cellsCalculatedLast; i < cellsCalculated; ++i) {
        int px = (int)particles[i].x;
        int py = (int)particles[i].y;

        if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0))
          continue;
        {
          float v = (brightness(imgblur.pixels[py * imgblur.width + px])) / 255;

          if (invertImg) v = 1 - v;

          if (v < cutoffScaled) {
            if (fillingCircles) {
              strokeWeight(maxDotSize - v * dotScale);
              point(px, py);
            } else {
              float dotSize = maxDotSize - v * dotScale;
              ellipse(px, py, dotSize, dotSize);
            }
          }
        }
      }

      cellsCalculatedLast = cellsCalculated;
    }
  }

  noStroke();
  fill(100); // Background fill color
  rect(0, mainheight, mainwidth, height); // Control area fill

  // Underlay for hyperlink:
  if (overRect(textColumnStart - 10, mainheight + 35, 205, 20) ) {
    fill(150);
    rect(textColumnStart - 10, mainheight + 35, 205, 20);
  }

  fill(255); // Text color

  text("StippleGen 2      (v. 2.4.0)", textColumnStart, mainheight + 15);
  text("by Evil Mad Scientist Laboratories", textColumnStart, mainheight + 30);
  text("www.evilmadscientist.com/go/stipple2", textColumnStart, mainheight + 50);

  text("Generations completed: " + generation, textColumnStart, mainheight + 85);
  text("Time/Frame: " + frameTime + " s", textColumnStart, mainheight + 100);

  if (errorDisp) {
    fill(255, 0, 0); // Text color
    text(errorDisplay, textColumnStart, mainheight + 70);
    errorDisp = !(millis() - errorTime > 8000);
  } else {
    text("Status: " + statusDisplay, textColumnStart, mainheight + 70);
  }

  if (saveNow) {
    statusDisplay = "Saving SVG File";
    saveNow = false;

    fileOutput = loadStrings("header.txt");

    String rowTemp;

    float SVGscale = (800.0 / (float) mainheight);
    int xOffset = (int)(1600 - (SVGscale * mainwidth / 2));
    int yOffset = (int)(400 - (SVGscale * mainheight / 2));

    if (fileModeTSP) { // Plot the PATH between the points only.
      println("Save TSP File (SVG)");

      // Path header::
      rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:2px;stroke-linejoin:round;stroke-linecap:round;\" d=\"M ";
      fileOutput = append(fileOutput, rowTemp);

      for (i = 0; i < particleRouteLength; ++i) {
        Vec2D p1 = particles[particleRoute[i]];

        float xTemp = SVGscale * p1.x + xOffset;
        float yTemp = SVGscale * p1.y + yOffset;

        rowTemp = xTemp + " " + yTemp + "\r";
        fileOutput = append(fileOutput, rowTemp);
      }
      fileOutput = append(fileOutput, "\" />"); // End path description
    } else {
      println("Save Stipple File (SVG)");

      for (i = 0; i < particleRouteLength; ++i) {
        Vec2D p1 = particles[particleRoute[i]];

        int px = floor(p1.x);
        int py = floor(p1.y);

        float v = (brightness(imgblur.pixels[py * imgblur.width + px])) / 255;

        if (invertImg) v = 1 - v;

        float dotrad = (maxDotSize - v * dotScale) / 2;

        float xTemp = SVGscale * p1.x + xOffset;
        float yTemp = SVGscale * p1.y + yOffset;

        if (fillingCircles) {
          rowTemp = makeSpiral(xTemp, yTemp, dotrad / 2.0, dotrad);
        } else {
          rowTemp = "<circle cx=\"" + xTemp + "\" cy=\"" + yTemp + "\" r=\"" + dotrad +  "\"/> ";
        }
        //Typ:   <circle  cx="1600" cy="450" r="3" />

        fileOutput = append(fileOutput, rowTemp);
      }
    }

    // SVG footer:
    fileOutput = append(fileOutput, "</g></g></svg>");
    saveStrings(savePath, fileOutput);
    fileModeTSP = false; // reset for next time

    if (fileModeTSP) {
      errorDisplay = "TSP Path .SVG file Saved";
    } else {
      errorDisplay = "Stipple .SVG file saved ";
    }

    errorTime = millis();
    errorDisp = true;
  }
}

void mousePressed() {
  // rect(textColumnStart, mainheight, 200, 75);
  if (overRect(textColumnStart - 15, mainheight + 35, 205, 20) ) {
    link("http://www.evilmadscientist.com/go/stipple2");
  }
}

void keyPressed() {
  if (key == 'x') {   // If this program doesn't run slowly enough for you, 
    // simply press the 'x' key on your keyboard. :)
    cp5.getController("sliderStipples").setMax(50000.0);
  }
}
