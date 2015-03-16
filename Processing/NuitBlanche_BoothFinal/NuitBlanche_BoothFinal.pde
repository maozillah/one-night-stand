// Sept 29, 2014:
// Rigged up new backend image server


// IMPORTS
// ======================================================
import processing.video.*; 
import processing.serial.*;
import processing.data.*;
import java.net.*;
import java.io.*;
import java.awt.image.BufferedImage;
import http.requests.*;
import ddf.minim.*;

// For FFMPEG
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.io.Writer;
import java.io.Reader;
import java.io.BufferedReader;
import java.io.InputStreamReader; 


// APP OPTIONS
// ======================================================

// Core Settings
// ---------------------------

String PATH_TO_SKETCH = "/Users/ken/Documents/Processing/NuitBlanche_BoothFinal/"; //absolute path to this Processing sketch
// String PATH_TO_SKETCH = "/Users/mmilan/Documents/Processing/NuitBlanche_Booth6/"; //absolute path to this Processing sketch
int CAMERA_ID = 0; // Laptop Camera (ISight)
//int CAMERA_ID = 15; // External Booth Camera
int SCREEN_WIDTH = 1024;
int SCREEN_HEIGHT = 768;
//int SCREEN_WIDTH = 640;
//int SCREEN_HEIGHT = 480;
String BOOTH_MINE = "2";  
String BOOTH_THEIRS = "1";
boolean SENSOR_INPUT = false; // Control app using Arduino button
boolean KEYBOARD_INPUT = true; // Control app using keyboard
boolean PRINT_STANDARD = true; // Toggle printing to the system printer
boolean TWEET = true; // Toggle tweeting on and off;
 String ARDUINO_ADDRESS = "/dev/tty.usbmodem26431";

// Capture Settings
// ---------------------------

int COUNTDOWN_MAX = 3; // length of countdown before photo capture
int PHOTOS_MAX = 4; // max number of photos captured per photo strip
int INTROVIDEO_MAX = 75; // max number of frames for intro video
int PHOTOANIMATION_MAX = 75; // max number of frames for each photo animation 

// SCREEN DURATIONS
// ---------------------------

int DURATION_PRINTSCREEN = 255;
int DURATION_SEARCHSCREEN = 60;

// Application Settings
// ---------------------------
boolean CONSOLE_DEBUG = true; // Displays console messages for debugging
boolean DEBUG_MODE = true; // Print debug messages
boolean PRINT_LITTLEPRINTER = false; // Toggle printing to Little Printer


// Server Settings
// ---------------------------
String SERVER_ADDRESS = "http://104.130.201.159:8080/api/entrys/"; // IP address of destination web server (the 'other booth')
String LOCAL_ADDRESS = "http://localhost:8080/api"; 


// Camera
// ---------------------------

int CAMERA_WIDTH = 640;
int CAMERA_HEIGHT = 480; 


// FFMPEG Settings
// ---------------------------

String ffmpegInstall = "/usr/local/bin/";  // you may need to specify the location that ffmpeg is installed**


// Audio Files
// ---------------------------

 String SOUNDFILE_SHUTTER = "shutterclick.mp3";
 String SOUNDFILE_HEARTBEAT = "heartbeat.wav";
 String SOUNDFILE_COUNTDOWN3 = "countdown_beep3.wav";
 String SOUNDFILE_COUNTDOWN2 = "countdown_beep2.wav";
 String SOUNDFILE_COUNTDOWN1 = "countdown_beep1.wav";
 

// APP VARIABLES
// ======================================================

// Firmata
// ---------------------------
int buttonPin = 2;
int lightPin = 4;

// Serial
// ---------------------------

int LF = 10;    // ASCII for linefeed character
String serial;   
Serial port;  
boolean buttonPressed = false;
int sensorDistance = 0;

// Minim
// ---------------------------
Minim minim;
AudioPlayer sound_shutterclick;
AudioPlayer sound_heartbeat;
AudioPlayer sound_countdown3;
AudioPlayer sound_countdown2;
AudioPlayer sound_countdown1;


// Cam 
// ---------------------------
Capture cam; 


// Photo Arrays
// ---------------------------
PImage [] photosMine = new PImage[PHOTOS_MAX];
PImage [] photosTheirs = new PImage[PHOTOS_MAX];
PImage [] photosBlended = new PImage[PHOTOS_MAX];

PImage [] introVideoMine = new PImage[300]; // larger array size than is needed, for padding - revisit later
Movie introVideoTheirs;

PImage [][] animationMine = new PImage [PHOTOS_MAX][150];
Movie [] sessionVideoTheirs = new Movie[4];

PImage tempFrameOther;
PImage tempFrameOtherResized;

PImage photoStrip;
PImage photoGrid;

// Videos

Movie [] videosTheirs = new Movie[PHOTOS_MAX];
Movie [] videosMine = new Movie[PHOTOS_MAX]; // probably notpre needed


// File Upload
// ---------------------------

String scriptURL = "http://localhost:8888/nuitblanche/receive_image.php";
String TMPFNAME = "tempfile_";
String postURL = "http://localhost:8080/api/photos"; // server url


// App Modes 
// ---------------------------

String mode;
String MODE_PRELOADWAIT = "MODE: Preloading Screen";
String MODE_PRELOAD = "MODE: Preloading Assets";
String MODE_BEGIN = "MODE: Default Start Mode"; // 1. Defaults to this step after full process is completed
String MODE_CONNECTION = "MODE: Connecting Screen Mode"; // 1. Defaults to this step after full process is completed

String MODE_BUTTONTITLE = "Showing Button Title";
String MODE_BUTTONDIRECTIVE = "Showing Button Instructions";

String MODE_INTRO = "MODE: Intro Video Mode"; // 2. Play user intro video
String MODE_WAIT = "MODE: Waiting for Button Press Mode";
String MODE_COUNTDOWN = "MODE: Countdown Mode";
String MODE_PHOTOCAPTURE = "MODE: Photo Capture Mode";
String MODE_PHOTOPROCESS = "MODE: Photo Processing Mode";
String MODE_FLASH = "MODE: Flash Mode";
String MODE_PRINTSTRIP = "MODE: Printing Photo Strip";
String MODE_DISPLAYSTRIP = "MODE: Display Photo Strip"; // only fired when DEBUG_MODE is on
String MODE_UPLOADWAIT = "MODE: Displaying Wait Screen Before Uploading Assets To Server";
String MODE_UPLOAD = "MODE: Uploading Assets To Server";


int time;
int captureElapsedTime;
int counterElapsedTime;
int countdownInterval = 1000;
int countdown;

int photoCaptureInterval = 11000;
int photoCount = 0;
float flashOpacity = 0;
float waitScreenColor = 0;
float waitScreenColorDir = 1;

int introVideoTheirsCounter = 0; // frame count for playing intro video
int connectionScreenCounter = 0;
int printScreenCounter = 0;
int animationTheirsCounter = 0;
int animationMineCounter = 0;
int introVideoMineCounter = 0;
int introScreenTimer = 0;

int lastGoodIntroImage = 0; // hack for now

PImage tempImage;
PImage tempFlippedImage;

int photoGridTrans = 25;

int tweetFlag = 0;


PFont fontMono;

  /* Button press Mode Variables */
PImage buttonMode_arrow;
int buttonMode_arrowposition = 0;
int buttonMode_positiondir = 1;
int buttonMode_arrowbounce = 15;
boolean buttonMode_showLine = true;
int buttonModeTitle_counter = 0;
int buttonModeDirective_counter = 0;
int buttonModeTitle_trans = 50;
int buttonModeTitle_transdir = 1;

/* Searching/ Pairing Mode Variables */
int ANIM_SEARCH_IMAGEDELAY = 8; //number of cycles to display each image
PImage [] searchImages = new PImage[10];
int [] searchImageAlpha = new int [4];
PImage bg_searchingMode;
int searchingMode_currentFrame = 0;
int searchingMode_currentAlpha = 0;
int searchingMode_imageCount = 0;
int searchingMode_direction = 1;
int searchingMode_flash = 1;
int searchingMode_counter = 0;

int countdown_trans = 50;
int countdown_transdir = 1;


PImage logo;


void setup() { 
     
  size(SCREEN_WIDTH, SCREEN_HEIGHT, JAVA2D);
  colorMode(RGB);
  frameRate(24);
  background(0);

  initializeCamera(CAMERA_ID); 

  // Initialize sound library
  minim = new Minim(this);
  sound_shutterclick = minim.loadFile(SOUNDFILE_SHUTTER);
  sound_heartbeat = minim.loadFile(SOUNDFILE_HEARTBEAT);
  sound_countdown3 = minim.loadFile(SOUNDFILE_COUNTDOWN3);
  sound_countdown2 = minim.loadFile(SOUNDFILE_COUNTDOWN2);
  sound_countdown1 = minim.loadFile(SOUNDFILE_COUNTDOWN1);


  // Initialize Serial (for Arduino button input)
  if(SENSOR_INPUT) {  
      port = new Serial(this, ARDUINO_ADDRESS, 115200); // baud rate must match that of Arduino app
      port.clear();  // throws out the first serial reading, in case we started reading in the middle of a string from Arduino
      serial = port.readStringUntil(LF); 
      serial = null;  
  }


  if(TWEET) {
    tweetFlag = 1;  
  }
  
  else if (!TWEET) {
    tweetFlag = 0;  
    
  }


  fontMono = loadFont("TheSansMono-W9Black-48.vlw");

  // for Pairing Screen - temp
  preloadSearchImages();

  // for Button Press screen
  buttonMode_arrow = loadImage("data/buttonMode_arrow.png");

  logo = loadImage("data/logo.png");  


  countdown = COUNTDOWN_MAX;

  mode = MODE_PRELOADWAIT;


} 



void draw() {
    
  serialListen();
  
   // Check if Arduino button has been pressed
  if(buttonPressed == true) {
      handleInput();
  }

  // println(sensorDistance);
//  if(sensorDistance>10 && sensorDistance<39 && mode.equals(MODE_BEGIN)) {
  if(sensorDistance>10 && sensorDistance<200 && mode.equals(MODE_BEGIN)) {
     handleInput(); 
  }
  

   if(mode.equals(MODE_PRELOADWAIT)) {
      drawLoadingScreen("Thinking ...");
      mode = MODE_PRELOAD;     
   }
   else if(mode.equals(MODE_PRELOAD)) {
       
      preloadAssets();
   } 

   else if(mode.equals(MODE_BEGIN)) {
      displayStartScreen();
   } 

   else if(mode.equals(MODE_CONNECTION)) {
      displayConnectionScreen();
   } 

   else if(mode.equals(MODE_INTRO)) {
      // playIntro();
   } 

  else if(mode.equals(MODE_BUTTONTITLE)) {
    drawButtonTitle(70);
  }
  
  else if (mode.equals(MODE_BUTTONDIRECTIVE)) {
    drawButtonDirective(100);
  }

   
   else if(mode.equals(MODE_COUNTDOWN)) {
      drawCountdown();
   } 
   
   else if (mode.equals(MODE_PHOTOCAPTURE)) {
      capturePhotos();
   }
   
   else if (mode.equals(MODE_FLASH)) {
      doFlash(); 
   }
   
   
   
   
   else if (mode.equals(MODE_PRINTSTRIP)) {
     
     printPhotos();
     mode = MODE_DISPLAYSTRIP;
      
   }

   else if (mode.equals(MODE_DISPLAYSTRIP)) {
   
//      background(0);   
      displayPrintScreen();
     
   }
 
   
   else if (mode.equals(MODE_PHOTOPROCESS)) {
     
      // image(photoGrid,0,0); 
      processPhotos();
      
   }   
   
   else if (mode.equals(MODE_WAIT)) {
   
      background(0);         
      displayWaitScreen();
     
   }

   else if(mode.equals(MODE_UPLOADWAIT)) {
      drawLoadingScreen("Thanks for playing!");
      mode = MODE_UPLOAD;     
   }

   else if (mode.equals(MODE_UPLOAD)) {
   
      uploadAssets();
     
   }
   
   else {

     
   }

} 


void drawLoadingScreen (String msg) {

      background(18,217,235);
      fill(255); 

      textAlign(CENTER);
      textFont(fontMono, 40);
      text(msg, width/2, height/2); 

/*
      textAlign(CENTER);
      textSize(40);
      text(msg, width/2, height/2);
*/
}


void displayStartScreen() {

  if (waitScreenColor > 250 || waitScreenColor < 0) {
      waitScreenColorDir = -waitScreenColorDir;
      sound_heartbeat.play();
      sound_heartbeat.rewind();
  }
  
  // Color fill

  background(247,waitScreenColor,206,255); 
//  background(247,50,206,255); 
//  rect(0,0,width, height);  
 
  waitScreenColor = waitScreenColor + (waitScreenColorDir*5);

// First variation -- pulsating linked to sensor distance
/*
  if(sensorDistance>0) {
      waitScreenColor = waitScreenColor + (1600/(sensorDistance+1) * waitScreenColorDir);
      fill(255,255,255,waitScreenColor); 
  }
  else if (sensorDistance == 0) {
      waitScreenColor = waitScreenColor + (1.5 * waitScreenColorDir);
      fill(255,255,255,waitScreenColor); 
      
  }
*/
    
  // Print text
  fill(255,255,255); 
  textAlign(CENTER);
  textFont(fontMono, 40);
  text("Cross the line to meet your match ... ", width/2, height/2);
  
}

/*
void displayConnectionScreen() {

  if(connectionScreenCounter<95) {
    
    if (waitScreenColor > 255 || waitScreenColor < 0) {
        waitScreenColorDir = -waitScreenColorDir;
    }
    
    fill(255);
    rect(0,0,width, height);  
    waitScreenColor = waitScreenColor + (20 * waitScreenColorDir);
  
    fill(247,waitScreenColor,206,255);     
    textAlign(CENTER);
    textSize(40);
    text("Pairing you with someone ...", width/2, height/2);
  
    connectionScreenCounter++;
  }
  
  else if (connectionScreenCounter>=75) {
    
    mode = MODE_INTRO;
   
  } 

}
*/

void displayConnectionScreen() {

  drawSearchScreen(DURATION_SEARCHSCREEN);
  
}



void drawSearchScreen(int duration) {

  
  if (searchingMode_currentAlpha>ANIM_SEARCH_IMAGEDELAY/2 || searchingMode_currentAlpha<0) {
      searchingMode_direction = -searchingMode_direction;    
  }
  
  // this is important so text doesn't turn out blocky
  background(255);  
  blendMode(MULTIPLY);
  
  float alphaValue = ((float)searchingMode_currentAlpha/ANIM_SEARCH_IMAGEDELAY) * 255 * 2;
  
  tint(alphaValue,255);
  image(bg_searchingMode, 0, 0, width, height);

  if(searchingMode_currentFrame>=ANIM_SEARCH_IMAGEDELAY) {
    searchingMode_imageCount = (int)random(0,10);
    searchingMode_currentFrame=0;
    searchingMode_currentAlpha = 0;
    searchingMode_direction = 1;
  }
  
  println("Search image: " + searchingMode_imageCount);  
  image(searchImages[searchingMode_imageCount],0,0,width,height);
  


  blendMode(NORMAL);
  noTint();

  if(searchingMode_flash == 1) {
    textAlign(CENTER, CENTER);
    textFont(fontMono, 50);
    text("Searching...", width/2, height/2); 
    searchingMode_flash = 0;
  } 
  else if (searchingMode_flash == 0) {
     searchingMode_flash = 1;
  }
  
  searchingMode_currentAlpha = searchingMode_currentAlpha + (searchingMode_direction * 1);
  searchingMode_currentFrame++;

  searchingMode_counter++;

  if(searchingMode_counter>DURATION_SEARCHSCREEN) {

//      mode = MODE_INTRO;
      mode = MODE_BUTTONTITLE;
    
  }  
  
}


void preloadSearchImages() {
  
  for(int searchImageCounter=0;searchImageCounter<10;searchImageCounter++) {
    
     searchImages[searchImageCounter] = loadImage("data/searchimages/booth" + (searchImageCounter+1) + ".jpg");  
     bg_searchingMode = loadImage("data/bg_searchingmode.jpg");
    
  }  
  
  
}


void drawButtonTitle(int duration) {
  
    if(buttonModeTitle_trans<50 || buttonModeTitle_trans>255) {
        buttonModeTitle_transdir = -buttonModeTitle_transdir;
    }
      
    background(247,50,206);  
    
    drawButtonTitleText();

    buttonModeTitle_counter++;
    
    if(buttonModeTitle_counter>duration) {
       mode = MODE_BUTTONDIRECTIVE; 
    }
    
    buttonModeTitle_trans = buttonModeTitle_trans + (25*buttonModeTitle_transdir);
    
}

/*
void drawSearchScreen(int duration) {

  
  if (searchingMode_currentAlpha>ANIM_SEARCH_IMAGEDELAY/2 || searchingMode_currentAlpha<0) {
      searchingMode_direction = -searchingMode_direction;    
  }
  
  // this is important so text doesn't turn out blocky
  background(255);  
  blendMode(MULTIPLY);
  
  float alphaValue = ((float)searchingMode_currentAlpha/ANIM_SEARCH_IMAGEDELAY) * 255 * 2;
  
  tint(alphaValue,255);
  image(bg_searchingMode, 0, 0, width, height);

  if(searchingMode_currentFrame>=ANIM_SEARCH_IMAGEDELAY) {
    searchingMode_imageCount = (int)random(0,4);
    searchingMode_currentFrame=0;
    searchingMode_currentAlpha = 0;
    searchingMode_direction = 1;
  }
  
  image(searchImages[searchingMode_imageCount],0,0,width,height);
  


  blendMode(NORMAL);
  noTint();

  if(searchingMode_flash == 1) {
    textAlign(CENTER, CENTER);
    textFont(fontMono, 50);
    text("Searching...", width/2, height/2); 
    searchingMode_flash = 0;
  } 
  else if (searchingMode_flash == 0) {
     searchingMode_flash = 1;
  }
  
  searchingMode_currentAlpha = searchingMode_currentAlpha + (searchingMode_direction * 1);
  searchingMode_currentFrame++;
}
*/




void drawButtonTitleText() {
    fill(255,255,255,buttonModeTitle_trans);
    stroke(255,255,255,buttonModeTitle_trans);
    textAlign(CENTER, CENTER);
    textFont(fontMono, 55);
    text("100% perfect match found!", width/2, height/2); 
    rect(width/2-(width/4.8),height/2+50,width/5.3,3);
  
}

void drawButtonDirective(int duration) {
  
    if(buttonMode_arrowposition<0 || buttonMode_arrowposition>buttonMode_arrowbounce) {
        buttonMode_positiondir = -buttonMode_positiondir;
    }

    background(247,50,206);  

    drawButtonTitleText();
    

    fill(255,255,255,buttonMode_arrowposition * 20);

    fill(255,255,255,255);
    stroke(255,255,255,255);
    textAlign(CENTER, CENTER);
    textFont(fontMono, 30);
    text("Press the button to make some memories together", width/2, height/2+250); 
    
    image(buttonMode_arrow, width/2, (height/2+290) + buttonMode_arrowposition);
    
    buttonMode_arrowposition = buttonMode_arrowposition + (1*buttonMode_positiondir);
    
    println(buttonMode_arrowposition);

    buttonModeDirective_counter++;


}




/*
void playIntro() {

  introScreenTimer++;
  
  if(introScreenTimer>480) {
      
      resetVariables();
      mode = MODE_BEGIN;
    
  }
  
  introVideoTheirs.play();
  tempFrameOther = introVideoTheirs;
  image (tempFrameOther,0,0, SCREEN_WIDTH, SCREEN_HEIGHT);       

      
      // Surreptitiously capture animation of current user
      
      printDebug("Recording Intro Frame: " + introVideoMineCounter);
      
      if(introVideoMineCounter<INTROVIDEO_MAX) {

        if(cam.available() == false) {
          cam.start();
        }
      
        if (cam.available()) { 
            cam.read();
        } 
            
        introVideoMine[introVideoMineCounter] = cam.get();
        introVideoMineCounter++;
              
      }

      textAlign(CENTER);
      textSize(40);
      fill(255);

      text("Press the button below to pose with me", width/2, height/2 + 300);    
    
}
*/

void displayWaitScreen() {
    
  if (waitScreenColor > 50 || waitScreenColor < 0) {
      waitScreenColorDir = -waitScreenColorDir;
  }
  
  // Color fill
  if (sensorDistance == 0) {
    fill(waitScreenColor); 
    rect(0,0,width, height);  
    waitScreenColor = waitScreenColor + (1.5 * waitScreenColorDir);
  }
  
  else if(sensorDistance > 0) {
    fill(247,waitScreenColor*2,206); 
    rect(0,0,width, height);  
    waitScreenColor = waitScreenColor + (1.5 * waitScreenColorDir);
    
  }

  // Print text
  fill(255); 
  textAlign(CENTER);
  textSize(40);
  text("Press the button to take a photo!", width/2, height/2);
    
}



void doFlash() {
  
  printDebug(mode);
  
  if (flashOpacity<255) {

    // Reset stuff
    animationTheirsCounter = 0;
    animationMineCounter = 0;  
    mode = MODE_FLASH;
    sound_shutterclick.rewind();

    sound_shutterclick.play();

    // Turn on physical light on    
    fill(color(255,255,255,flashOpacity));
    rect(0,0,width,height);
    flashOpacity = flashOpacity+50;
  }
  
  else {
    mode = MODE_PHOTOCAPTURE;
    sound_countdown3.rewind();      
    sound_countdown2.rewind();      
    sound_countdown1.rewind();          
    flashOpacity = 0;
  }
  
}



void capturePhotos() {
  
  countdown = COUNTDOWN_MAX;

  if(cam.available() == false) {
    cam.start();
  }

  if (cam.available()) { 
      cam.read();
  } 


  // Play ghost of other booth user
  if (photoCount < PHOTOS_MAX) {

    // new video code 
    sessionVideoTheirs[photoCount].play();
    tempFrameOther = sessionVideoTheirs[photoCount];
    image(tempFrameOther,0,0,SCREEN_WIDTH,SCREEN_HEIGHT);
    tempFrameOtherResized = get();
    background(tempFrameOtherResized);

    tempImage = cam.get();
    tempFlippedImage = getReversePImage(tempImage);
    
    if(animationMineCounter <= PHOTOANIMATION_MAX) {
  
      animationMine[photoCount][animationMineCounter] = tempImage;  
      animationMineCounter++;  

      printDebug("Recording Session Frame: " + photoCount + "-" + animationMineCounter);
  
    }
    
    blend(tempFlippedImage, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, MULTIPLY);

    if (animationMineCounter >(PHOTOANIMATION_MAX-40) && animationMineCounter < (PHOTOANIMATION_MAX-30)) {

      sound_countdown3.play();      
      println("3!!!!");
      fill(255); 
      textAlign(CENTER);
      textSize(50);
      text("3", width/2, height/2);
            
    }
    
    else if (animationMineCounter >(PHOTOANIMATION_MAX-30) && animationMineCounter < (PHOTOANIMATION_MAX-20)) {
  
      sound_countdown2.play();      
      println("2!!!!");
      fill(255); 
      textAlign(CENTER);
      textSize(50);
      text("2", width/2, height/2);
            
    }
  
    else if (animationMineCounter >(PHOTOANIMATION_MAX-20) && animationMineCounter < (PHOTOANIMATION_MAX-10)) {
  
      sound_countdown1.play();      
      println("1!!!!");
      fill(255); 
      textAlign(CENTER);
      textSize(50);
      text("1", width/2, height/2);
            
    }

  }

  captureElapsedTime = millis() - time;


  // Do Flash
  if (photoCount < PHOTOS_MAX) {
    
      if(animationMineCounter>=PHOTOANIMATION_MAX) {
      
      time = millis();
           
      photosBlended[photoCount] = get();     
      
      photoCount++;
      
      if (CONSOLE_DEBUG) {
        printDebug("Snapped photo " + photoCount);
      }

      mode = MODE_FLASH;
      
    }  
    
  } else {    
     
    photoCount = 0;

    generateStrip();
    generatePhotoGrid();

    mode = MODE_PRINTSTRIP;
    
  }
  
}


void processPhotos() {
  
  printDebug(mode);
  
  savePhotos();
  
  saveVideos();
  
  mode = MODE_UPLOADWAIT;

  
  if (CONSOLE_DEBUG) {
    printDebug("********** Finished Processing **********\n\n");
  }
  
}


void displayPrintAnimation() {
  
//  println("trans" + photoGridTrans);

  if (waitScreenColor > 200 || waitScreenColor < 0) {
      waitScreenColorDir = -waitScreenColorDir;
  }  
   background(0);
   tint(255, photoGridTrans);    
   image(photoGrid,0,0); 
   photoGridTrans = photoGridTrans + 2;

   noTint();
   fill(255);
   textAlign(CENTER);
   textSize(30);
   text("Printing evidence of your brief encounter ... ", width/2, height/2);

   waitScreenColor = waitScreenColor+30;
}


void displayPrintScreen() {
  
  println(mode);
  
//  if(printScreenCounter<DURATION_PRINTSCREEN) {
  if(photoGridTrans<DURATION_PRINTSCREEN) {
    
    displayPrintAnimation();

  }
  
//  else if (printScreenCounter>=DURATION_PRINTSCREEN) {
  else if (photoGridTrans>=DURATION_PRINTSCREEN) {
    
    // mode = MODE_UPLOADWAIT;
    mode = MODE_PHOTOPROCESS;
   
  } 


  
  
}; 



void generateStrip() {

  fill(255);
  background(255);
  
  float photosetWidth = width*0.9;
  float photosetHeight = height*0.9;

/*    
  fill(0); 
  textAlign(CENTER);
  textSize(30);
  text("Memories of my One Night Stand ~ 2014", 450, 47);  
  image (loadImage("nuitblanche_logo.png"), width-(width*0.05)-229,10,229,48);
  image(photosBlended[0], (width*0.05), (height*0.1), photosetWidth/2, photosetHeight/2);
  image(photosBlended[1], photosetWidth/2 + (width*0.05), (height*0.1), photosetWidth/2, photosetHeight/2);
  image(photosBlended[2], (width*0.05), (photosetHeight/2)+(height*0.1), photosetWidth/2, photosetHeight/2);
  image(photosBlended[3], photosetWidth/2 + (width*0.05), (photosetHeight/2)+(height*0.1), photosetWidth/2, photosetHeight/2);
  fill(0);
*/

  fill(255);
  background(255);

  image(photosBlended[0], 0, 0, width/2, height/2);
  image(photosBlended[1], width/2, 0, width/2, height/2);
  image(photosBlended[2], 0, height/2, width/2, height/2);
  image(photosBlended[3], width/2, height/2, width/2, height/2);

  image(logo,20,20,100,100);
  textSize(20);
//  text("@onenightstandTO",20,height-50);


  photoStrip = get();  

  printDebug("Saving Photo Strip ...");
  photoStrip.save("data/booth" + BOOTH_MINE + "_photostrip.jpg");

  background(0);
  
}

void generatePhotoGrid() {
  
  fill(255);
  background(255);

  image(photosBlended[0], 0, 0, width/2, height/2);
  image(photosBlended[1], width/2, 0, width/2, height/2);
  image(photosBlended[2], 0, height/2, width/2, height/2);
  image(photosBlended[3], width/2, height/2, width/2, height/2);

  photoGrid = get();  

  printDebug("Saving Photo Grid ...");
  photoGrid.save("data/booth" + BOOTH_MINE + "_photogrid.jpg");

  background(0);
  
}


void savePhotos() {

  
/*
  printDebug("Saving Intro Photos ...");

  for(int i=0;i<INTROVIDEO_MAX;i++) {
    
     print("*");
     
     if(introVideoMine[i]!=null) { 
       introVideoMine[i].save("data/tmp_images_mine/booth" + BOOTH_MINE + "_" + "intro" +"_" + i + ".jpg");
       lastGoodIntroImage = i; 
     }

     // total hack, find better way of recording enough intro frames
     else {
       introVideoMine[lastGoodIntroImage].save("data/tmp_images_mine/booth" + BOOTH_MINE + "_" + "intro" +"_" + i + ".jpg");
     }        
  } 

*/

  printDebug("Saving Session Photos ...");

  int lastGoodSessionImage;
  for(int sessionCounter=0; sessionCounter<PHOTOS_MAX; sessionCounter++) {
    
    lastGoodSessionImage = 0;
  
    for(int frameCounter=0;frameCounter<PHOTOANIMATION_MAX;frameCounter++) {
         
         if(animationMine [sessionCounter][frameCounter]!=null) {
             animationMine [sessionCounter][frameCounter].save("data/tmp_images_mine/booth" + BOOTH_MINE + "_" + "video" + "_" + "sess" + (sessionCounter+1) + "_" + frameCounter + ".jpg");
             lastGoodIntroImage = frameCounter; 
             
             // Save an archived image
             if(frameCounter == (PHOTOANIMATION_MAX-1) && sessionCounter == (PHOTOS_MAX-1)) {

                animationMine [sessionCounter][frameCounter].save("data/searchimages/booth" + (int)random(0,10) + ".jpg");                       
               
             }
             
         }
         
         else {
             animationMine [sessionCounter][lastGoodSessionImage].save("data/tmp_images_mine/booth" + BOOTH_MINE + "_" + "video" + "_" + "sess" + (sessionCounter+1) + "_" + frameCounter + ".jpg");
           
         }

         print (".");
           
    }
  }  
  
  println("");
  
}


// Convert images to video via FFMPEG
void saveVideos() {

  String command;
  
  // Encode intro video
  // /usr/local/bin/ffmpeg -i data/tmp_images_mine/booth2_intro_%01d.jpg -c:v libx264 -r 30 -pix_fmt yuv420p booth1_video_sess1.mp4
  // /usr/local/bin/ffmpeg -i booth1_video_sess3_%01d.jpg -c:v libx264 -r 24 -pix_fmt yuv420p booth1_video_sess1.mp4

  printDebug("Encoding intro video ...");  
  command = ffmpegInstall + "ffmpeg -i " + "data/tmp_images_mine/booth" + BOOTH_MINE + "_" + "intro" +"_" + "%01d.jpg" + " -c:v libx264 -r 24 -pix_fmt yuv420p -y" + " data/tmp_videos_mine/booth" + BOOTH_MINE + "_video_intro" + ".mp4";
  printDebug(command);
  UnixCommand(command);  


  // Encode session videos
  printDebug("Encoding session videos ...");  
  for(int sessionCounter=0; sessionCounter<PHOTOS_MAX; sessionCounter++) {
      command = ffmpegInstall + "ffmpeg -i " + "data/tmp_images_mine/booth" + BOOTH_MINE + "_" + "video" +"_" + "sess" + (sessionCounter+1) + "_" + "%01d.jpg" + " -c:v libx264 -r 30 -pix_fmt yuv420p -y" + " data/tmp_videos_mine/booth" + BOOTH_MINE + "_video_sess" + (sessionCounter+1) + ".mp4";  
      printDebug(command);
      UnixCommand(command);  
  }
  
}


void printPhotos() {

  String[] params_standard = { "lp", "-o", "media='Postcard(4x6in)_Type2.FullBleed'", PATH_TO_SKETCH + "data/booth" + BOOTH_MINE + "_photostrip.jpg" };
  String[] params_littleprinter = {PATH_TO_SKETCH + "nuitblanche_littleprint_" + "booth" + BOOTH_MINE +".sh"};

  
  if(PRINT_STANDARD) {
    exec(params_standard);
    if (CONSOLE_DEBUG) {
      printDebug("Sending to printer...");
      printDebug(params_standard);
    }
  }
    
}


void drawCountdown() {

  background(0);
  if(countdown_trans<50 || countdown_trans>255) {
      countdown_transdir = -countdown_transdir;
  }

  fill(255,255,255,countdown_trans);
  stroke(255,255,255,countdown_trans);
  textAlign(CENTER, CENTER);
  textFont(fontMono, 40);
  text("Get ready to strike a pose", width/2, height/2); 

  
  counterElapsedTime = millis() - time;
  String countdownMsg = "";
  
  if (counterElapsedTime > countdownInterval) {
    
    time = millis();
    
    if (countdown >= 1 && countdown <= COUNTDOWN_MAX) {
      
        
      /*
      background(0);
      textAlign(CENTER);
      textSize(40);
      
      if(countdown == 3) {
          countdownMsg = "Ready";
      } 
      
      else if (countdown == 2) {
          countdownMsg = "Set"; 
      }

      else if (countdown == 1) {
          countdownMsg = "Pose for the camera!"; 
      }


      text(countdownMsg, width/2, height/2);
   */
   
      fill(255);
    } else {
      mode = MODE_PHOTOCAPTURE;
    }  
     
    countdown--;
  }

  countdown_trans = countdown_trans + (25*countdown_transdir);

      
}


void initializeCamera(int cameraId) {
  
  String[] cameras = Capture.list();
  
  cam = new Capture(this, cameras[cameraId]);    
  cam.start();
  
  if (CONSOLE_DEBUG) {
    printDebug(cameras);
  }

} 


// Download assets for other booth
void preloadAssets() {

  resetVariables();

  String introVideoURL = "";
  String [] sessionVideoURLs = new String[4];
  
  String jsonGetURL = SERVER_ADDRESS + "?booth=" + BOOTH_MINE;
    
  GetRequest get = new GetRequest(jsonGetURL);
  get.send();
 
  
  if(get.getContent()!=null) {

    printDebug("Loading JSON settings from: " + jsonGetURL);
    
    JSONObject response = parseJSONObject(get.getContent()); 

//    introVideoURL = response.getString("intro");
    
    println("");
    printDebug("My booth is Booth #" + BOOTH_MINE);
    printDebug("Their booth is Booth #" + BOOTH_THEIRS);

    println("");
    printDebug("Downloading from Booth #" + response.getInt("booth"));
    println("");
    println("");

    
    for(int sessionCounter=0; sessionCounter<PHOTOS_MAX; sessionCounter++) {
      
       sessionVideoURLs[sessionCounter] = response.getString("sess" + (sessionCounter+1)) ;          
  
    }
    
  }

  else {

    // failsafe here 

  }

/*
  printDebug("Downloading intro video ..." + introVideoURL);
  saveBytes( "data/tmp_videos_theirs/"+ "booth" + BOOTH_THEIRS + "_video_intro.mp4", loadBytes(introVideoURL));  
  printDebug("Loading intro video into memory ...");
  introVideoTheirs = new Movie(this, "tmp_videos_theirs/"+ "booth" + BOOTH_THEIRS + "_video_intro.mp4");
*/

  for(int sessionCounter=0; sessionCounter<PHOTOS_MAX; sessionCounter++) {
    printDebug("Downloading session video" + (sessionCounter + 1) + " from " + sessionVideoURLs[sessionCounter]);
    saveBytes( "data/tmp_videos_theirs/"+ "booth" + BOOTH_THEIRS + "_video_sess" + (sessionCounter+1) + ".mp4", loadBytes(sessionVideoURLs[sessionCounter]));  
    printDebug("Loading session " + (sessionCounter + 1) + " video into memory ...");
    sessionVideoTheirs[sessionCounter] = new Movie(this, "tmp_videos_theirs/"+ "booth" + BOOTH_THEIRS + "_video_sess" + (sessionCounter+1) + ".mp4");
  }

  mode = MODE_BEGIN;      
  
}


// Upload assets for this booth
void uploadAssets() {
  
  PostRequest post = new PostRequest(SERVER_ADDRESS);  

  post.addData("tweet", tweetFlag + ""); 
  post.addData("booth", BOOTH_MINE + ""); 
  post.addFile("strip", PATH_TO_SKETCH + "data/booth" + BOOTH_MINE + "_" + "photogrid" + ".jpg"); 
  println("Adding: " + PATH_TO_SKETCH + "data/booth" + BOOTH_MINE + "_" + "photogrid" + ".jpg");
  printDebug("Adding intro video to post");
  post.addFile("intro", PATH_TO_SKETCH + "data/tmp_videos_mine/"+ "booth" + BOOTH_MINE + "_video_intro.mp4"); 
  println("Adding: " + PATH_TO_SKETCH + "data/tmp_videos_mine/"+ "booth" + BOOTH_MINE + "_video_intro.mp4");  
  for (int sessionCounter = 0; sessionCounter < PHOTOS_MAX; sessionCounter++) {        
    printDebug("Adding session video to post" + (sessionCounter+1) + "...");
    post.addFile("sess" + (sessionCounter+1), PATH_TO_SKETCH + "data/tmp_videos_mine/"+ "booth" + BOOTH_MINE + "_video_sess" + (sessionCounter+1) + ".mp4"); // sending file over
    println("Adding: " + PATH_TO_SKETCH + "data/tmp_videos_mine/"+ "booth" + BOOTH_MINE + "_video_sess" + (sessionCounter+1) + ".mp4");
  }
  
  printDebug("Sending post ...");

  post.send();
//  printDebug("Response Content: " + post.getContent());
//  printDebug("Response Content-Length Header: " + post.getHeader("Content-Length"));    
  printDebug("FInished sending post");
  

  mode = MODE_PRELOADWAIT;      
  
}


void resetVariables() {

    buttonPressed = false;
    photoGridTrans = 25;
    introScreenTimer = 0;

    introVideoMineCounter = 0;
    introVideoTheirsCounter = 0;
    lastGoodIntroImage = 0;   
    
    photosBlended = new PImage[PHOTOS_MAX];    
    introVideoMine = new PImage[300]; 
    animationMine = new PImage [PHOTOS_MAX][150];

    introVideoTheirsCounter = 0; // frame count for playing intro video
    connectionScreenCounter = 0;
    printScreenCounter = 0;
    animationTheirsCounter = 0;
    animationMineCounter = 0;
    introVideoMineCounter = 0;

    waitScreenColor = 0;   
   
/* Searching/ Pairing Mode Variables */
   searchingMode_imageCount = 0;
   searchingMode_currentFrame = 0; 
   searchingMode_direction = 0;
   searchingMode_currentAlpha = 0;
   searchingMode_counter = 0;   

  /* Button press Mode Variables */
  buttonMode_arrowposition = 0;
  buttonMode_positiondir = 1;
  buttonMode_showLine = true;
  buttonModeTitle_counter = 0;
  buttonModeDirective_counter = 0;
  buttonModeTitle_counter = 0;
  buttonModeDirective_counter = 0;
  buttonModeTitle_trans = 50;
  buttonModeTitle_transdir = 1;

countdown_trans = 50;
countdown_transdir = 1;
   
    
}


void handleInput() {
  

  if (mode.equals(MODE_DISPLAYSTRIP)) {
    mode = MODE_UPLOAD; 
    
  } else if (mode.equals(MODE_WAIT)) {
    background(0);
    mode = MODE_COUNTDOWN;       
 
  // This will be handled with motion sensor later
  } else if (mode.equals(MODE_BEGIN)) {
    background(0);
    mode = MODE_CONNECTION;       
   
  } else if (mode.equals(MODE_BUTTONDIRECTIVE)) {
    background(0);
    mode = MODE_COUNTDOWN;       
   
  }

}


void keyPressed() {
  if (KEYBOARD_INPUT) { 
    handleInput();
  }
} 



//boolean buttonPressed() {
void serialListen() {
  
  if(SENSOR_INPUT) {  
  
      while (port.available() > 0) { //as long as there is data coming from serial port, read it and store it 
        serial = port.readStringUntil(LF);
      }
    
      if (serial != null) {  
      
        String[] a = split(serial, ',');  
        // print(a[0] + "," + a[1]); 
        
        if(a[0].equals("1")) {
          buttonPressed = true;
        }
        else if (a[0].equals("0")) {
          buttonPressed = false;
        }
        
        sensorDistance = int(a[1].trim());
        
      }    
  
  }
  
}


void delay(int milliseconds) {
  try {
    Thread.sleep(milliseconds);
  } catch (Exception e) {}
}

void printDebug(String msg) {

  if(DEBUG_MODE) {
    println(msg);
  }
  
}

void printDebug(int msg) {

  if(DEBUG_MODE) {
    println(msg);
  }
  
}

void printDebug(String [] msg) {

    if(DEBUG_MODE) {
    println(msg);
  }

}

// function for running Unix commands inside Processing
void UnixCommand(String commandToRun) {
  File workingDir = new File(sketchPath(""));
  String returnedValues;
  try {
    Process p = Runtime.getRuntime().exec(commandToRun, null, workingDir);
    int i = p.waitFor();
    if (i == 0) {
      BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));
      while ( (returnedValues = stdInput.readLine ()) != null) {
        // enable this option if you want to get updates when the process succeeds
        // printDebug("  " + returnedValues);
      }
    }
    else {
      BufferedReader stdErr = new BufferedReader(new InputStreamReader(p.getErrorStream()));
      while ( (returnedValues = stdErr.readLine ()) != null) {
        // print information if there is an error or warning (like if a file already exists, etc)
        printDebug("  " + returnedValues);
      }
    }
  }

  // if there is an error, let us know
  catch (Exception e) {
    printDebug("Error, sorry!");  
    printDebug("     " + e);
  }
}


public PImage getReversePImage( PImage image ) {
 PImage reverse = new PImage( image.width, image.height );
 for( int i=0; i < image.width; i++ ){
  for(int j=0; j < image.height; j++){
   reverse.set( image.width - 1 - i, j, image.get(i, j) );
  }
 }
 return reverse;
}
 

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}



/****** OLD IMAGE UPLOADING METHOD (TEMPORARY) *******/


/* IMAGE UPLOADING */

/*

void saveFileToWeb(String filename) {

    postData(filename, "video/mp4", loadBytes(filename));

}


void postData(String filename, String ctype, byte[] bytes) {
  
  try {
    URL u = new URL(scriptURL);
    URLConnection c = u.openConnection();
    // post multipart data
 
    c.setDoOutput(true);
    c.setDoInput(true);
    c.setUseCaches(false);
 
    // set request headers
    c.setRequestProperty("Content-Type", "multipart/form-data; boundary=AXi93A");
 
    // open a stream which can write to the url
    DataOutputStream dstream = new DataOutputStream(c.getOutputStream());
 
    // write content to the server, begin with the tag that says a content element is coming
    dstream.writeBytes("--AXi93A\r\n");
 
    // describe the content
    dstream.writeBytes("Content-Disposition: form-data; name=p5uploader; filename=" + filename + 
      " \r\nContent-Type: " + ctype + 
      "\r\nContent-Transfer-Encoding: binary\r\n\r\n");
    dstream.write(bytes, 0, bytes.length);
 
    // close the multipart form request
    dstream.writeBytes("\r\n--AXi93A--\r\n\r\n");
    dstream.flush();
    dstream.close();
 
    // print the response
    try {
      BufferedReader in = new BufferedReader(new InputStreamReader(c.getInputStream()));
      String responseLine = in.readLine();
      while (responseLine != null) {
        printDebug(responseLine);
        responseLine = in.readLine();
      }
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }
  catch(Exception e) { 
    e.printStackTrace();
  }
}

boolean isJPG(String filename) {
  return filename.toLowerCase().endsWith(".jpg") || filename.toLowerCase().endsWith(".jpeg");
}
boolean isPNG(String filename) {
  return filename.toLowerCase().endsWith(".png");
}

*/



