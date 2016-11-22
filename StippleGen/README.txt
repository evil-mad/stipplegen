
 StippleGen_2_40
 
 SVG Stipple Generator, v. 2.4.0
 Copyright (C) 2016 by Windell H. Oskay, www.evilmadscientist.com
 
 Full Documentation: http://wiki.evilmadscientist.com/StippleGen
 Blog post about the release: http://www.evilmadscientist.com/go/stipple2
 
 
 An implementation of Weighted Voronoi Stippling:
 http://mrl.nyu.edu/~ajsecord/stipples.html
 
 *******************************************************************************
 
 Change Log:
 
 v 2.4
 * Processing 3.0.1
 
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
 