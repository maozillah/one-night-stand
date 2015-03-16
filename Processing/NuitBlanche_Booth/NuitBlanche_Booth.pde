// IMPORTS
// ======================================================
// Make sure you chmod +x the accompanying .sh scripts, or error may be thrown
import processing.video.*; 
import processing.serial.*;
import processing.data.*;
import cc.arduino.*;

import java.net.*;
import java.io.*;
import java.awt.image.BufferedImage;

import http.requests.*;

import ddf.minim.*;

// APP OPTIONS
// ======================================================

// Custom Settings
// ---------------------------
String PATH_TO_SKETCH = "C:"+File.separator+"0Kaye"+File.separator+"Normative"+File.separator+"test"+File.separator+"Nuit-Blanche"+File.separator+ "Web"+File.separator+ "photos"; //absolute path to this Processing sketch
String PATH_TO_OTHER_BOOTH_PHOTOS = "C:"+File.separator+"0Kaye"+File.separator+"Normative"+File.separator+"test"+File.separator+"Nuit-Blanche"+File.separator+ "Web"; 
int COUNTDOWN_MAX = 1; // length of countdown before photo capture
int PHOTOS_MAX = 4; // max number of photos captured per photo strip

// Booth Settings
// ---------------------------
String BOOTH_MINE = "2";
String BOOTH_THEIRS = "1";

// Application Settings
// ---------------------------
boolean CONSOLE_DEBUG = true; // Displays console messages for debugging
boolean DEBUG_MODE = true; // Displays combined strip after photo capture
boolean BUTTON_INPUT = false; // Control app using Arduino button
boolean KEYBOARD_INPUT = true; // Control app using Arduino button
boolean PRINT_STANDARD = false; // Toggle printing to system's default printer
boolean PRINT_LITTLEPRINTER = false; // Toggle printing to Little Printer

// Server Settings
// ---------------------------
String SERVER_ADDRESS = "dev.kenleung.ca/nuitblanche/"; // IP address of destination web server (the 'other booth')
String LOCAL_ADDRESS = "http://localhost:8080/api"; 

// ISight Settings
// ---------------------------
int CAMERA_WIDTH = 640;
int CAMERA_HEIGHT = 480; 
int CAMERA_ID = 0; // ID for desired camera, as shown in the array of cameras listed on first run (e.g. Isight 640x480, 30 fps is usually 0)

// Audio Settings
// ---------------------------
String SOUNDFILE_SHUTTER = "shutterclick.mp3";

/* Logitech Webcam Settings
// ---------------------------
int CAMERA_WIDTH = 1280;
int CAMERA_HEIGHT = 960; 
int CAMERA_ID = 12; // Id for desired camera, as shown in the array of cameras listed on first run (e.g. Isight 640x480, 30 fps is usually 0)*/



// APP VARIABLES
// ======================================================

// Firmata
// ---------------------------
Arduino arduino;
int buttonPin = 2;
int lightPin = 4;

// Sound
// ---------------------------
Minim minim;
AudioPlayer sound_shutterclick;

// Video 
// ---------------------------
Capture cam; 

// Photos
// ---------------------------
PImage [] photosMine = new PImage[PHOTOS_MAX];
PImage [] photosTheirs = new PImage[PHOTOS_MAX];
PImage [] photosBlended = new PImage[PHOTOS_MAX];
PImage photoStrip;

// File Upload
// ---------------------------
String scriptURL = "http://dev.kenleung.ca/nuitblanche/receive_image.php";
String postURL = "http://localhost:8080/api/photos"; // server url

// App Modes 
// ---------------------------
String mode;
String MODE_WAIT = "Waiting Mode";
String MODE_COUNTDOWN = "Countdown Mode";
String MODE_PHOTOCAPTURE = "Photo Capture Mode";
String MODE_PHOTOPROCESS = "Photo Processing Mode";
String MODE_FLASH = "Flash Mode";
String MODE_DISPLAYSTRIP = "Display Photo Strip"; // only fired when DEBUG_MODE is on
String MODE_PRINTSTRIP = "Printing Photo Strips";

int time;
int countdownInterval = 1000;
int countdown;

int photoCaptureInterval = 1000;
int photoCount = 0;
float flashOpacity = 0;
float waitScreenColor = 0;
float waitScreenColorDir = 1;

 
 
 
 
 
 
 
void setup() { 
     
  size(CAMERA_WIDTH, CAMERA_HEIGHT, JAVA2D);
  colorMode(RGB);
  frameRate(24);
  background(0);

  initializeCamera(CAMERA_ID); 

  // Initialize sound library
  minim = new Minim(this);
  sound_shutterclick = minim.loadFile(SOUNDFILE_SHUTTER);

  
  // Initialize Firmata (for Arduino button input)
  if(BUTTON_INPUT) {  
     arduino = new Arduino(this, Arduino.list()[4], 57600);   
     arduino.pinMode(buttonPin, Arduino.INPUT);   
     arduino.pinMode(lightPin, Arduino.OUTPUT);   
  }
  
  countdown = COUNTDOWN_MAX;

  mode = MODE_WAIT;

} 



void draw() {
 
   // Check if Arduino button has been pressed
   if(buttonPressed()) {
      handleInput();
   }
   
   if(mode.equals(MODE_COUNTDOWN)) {
      drawCountdown();
   } 
   
   else if (mode.equals(MODE_PHOTOCAPTURE)) {
      capturePhotos();
   }
   
   else if (mode.equals(MODE_FLASH)) {
      doFlash(); 
   }
    
   else if (mode.equals(MODE_PHOTOPROCESS)) {
     
      processPhotos();
      // image(photosMine[0],0,0); 
   }   

   else if (mode.equals(MODE_DISPLAYSTRIP)) {
   
      background(0);   
      image(photoStrip, 0, 0);   
     
   }
   
   else if (mode.equals(MODE_WAIT)) {
   
      background(0);         
      displayWaitScreen();
     
   }
   
   else {

     
   }
       
} 


void displayWaitScreen() {
    
  if (waitScreenColor > 50 || waitScreenColor < 0) {
      waitScreenColorDir = -waitScreenColorDir;
  }
  
  fill(waitScreenColor); 
  rect(0,0,CAMERA_WIDTH, CAMERA_HEIGHT);  
  waitScreenColor = waitScreenColor + (1.5 * waitScreenColorDir);

  fill(255); 
  textAlign(CENTER);
  textSize(32);
  text("Press the button to take a photo!", width/2, height/2);
  
  
}

void doFlash() {
  
  println(mode);
  
  if (flashOpacity<255) {
    mode = MODE_FLASH;

    sound_shutterclick.play();
    sound_shutterclick.rewind();
    
    /** Turn on physical light here **/

    fill(color(255,255,255,flashOpacity));
    rect(0,0,CAMERA_WIDTH,CAMERA_HEIGHT);
    flashOpacity = flashOpacity+50;
  }
  
  else {
    mode = MODE_PHOTOCAPTURE;
    flashOpacity = 0;
  }
  
}


void capturePhotos() {
  
  countdown = COUNTDOWN_MAX;

  if(cam.available() == false) {
    cam.start();
  }

  cam.read(); 

  // Flip camera image so that movement is mirrored properly
  pushMatrix();
  scale(-1, 1);
  image(cam.get(), -width, 0);   
  popMatrix();  

  int elapsedTime = millis() - time;

  if (photoCount < PHOTOS_MAX) {
    
    if (elapsedTime > photoCaptureInterval) {
      
      time = millis();
           
      // get and save a local version of the image
      photosMine[photoCount] = get();
      photosMine[photoCount].save(PATH_TO_SKETCH + "booth" + BOOTH_MINE + "-" + photoCount + ".jpg");     
      
      photoCount++;
      
      if (CONSOLE_DEBUG) {
        println("Snapped photo " + photoCount);
      }
      
    }  
    
  } else {    
     
    mode = MODE_PHOTOPROCESS;
    photoCount = 0;
    
    // sending info to server

    PostRequest post = new PostRequest(LOCAL_ADDRESS + "/photos");
    post.addData("booth", BOOTH_MINE); 
    
    for (int i = 0; i < PHOTOS_MAX; i++) {        
      post.addFile("file_" + i, PATH_TO_SKETCH + "booth" + BOOTH_MINE + "-" + i + ".jpg");         // sending file over
    }
    
    post.send();
    
  }

  if (CONSOLE_DEBUG) {
//    println(mode);
  }
  
}


void processPhotos() {
  
  println(mode);

  background(0);
  
  blendPhotos();
  
  generateStrip();
  
  printPhotos();  

  mode = DEBUG_MODE ? MODE_DISPLAYSTRIP : MODE_WAIT;
  
  if (CONSOLE_DEBUG) {
    println("********** Finished Processing **********\n\n");
  }
  
}


void blendPhotos() {
  
  PImage tempImage;

  GetRequest get = new GetRequest(LOCAL_ADDRESS + "/photos/booth/"+BOOTH_THEIRS); 
  get.send(); 
  

  JSONArray json = new JSONArray();
  json = parseJSONArray(get.getContent());
  

    String PATH_TO_PHOTO;
    
    // get latest JSON photoset info. from other booth
    JSONObject photoSetInfo = json.getJSONObject(0); 
   
   
    String photosetid = photoSetInfo.getString("_id");
  
    JSONArray photoSet = photoSetInfo.getJSONArray("files");  

  
   for (int i = 0; i < PHOTOS_MAX; i++) {   
    

       // translate individual photo path from JSON
     PATH_TO_PHOTO = photoSet.getString(i);
      
      // for windows friendliness
     PATH_TO_PHOTO = PATH_TO_PHOTO.replace("/", "\\");
  
      //load images from latest photoset from other booth
      background(loadImage(PATH_TO_OTHER_BOOTH_PHOTOS+File.separator+PATH_TO_PHOTO));  

       // grabbing photo off local computer right now
     // background(loadImage("http://" + SERVER_ADDRESS + "booth" + BOOTH_THEIRS + "_" + (i+1) + ".jpg")); 
   
    
    photosMine[i].save("booth" + BOOTH_MINE + "_" + (i+1) + ".jpg");     
    tempImage = loadImage("booth" + BOOTH_MINE + "_" + (i+1) + ".jpg");
    blend(tempImage, 0, 0, CAMERA_WIDTH, CAMERA_HEIGHT, 0, 0, CAMERA_WIDTH, CAMERA_HEIGHT, MULTIPLY);
    
    /* Figure out why code below doesn't work -- why does PImage have to be loaded from disk vs from array? */
    //blend(photosMine[i], 0, 0, CAMERA_WIDTH, CAMERA_HEIGHT, 0, 0, CAMERA_WIDTH, CAMERA_HEIGHT, MULTIPLY); 
    
    filter(BLUR, 1);    
    photosBlended[i] = get();     
    photosBlended[i].save(PATH_TO_SKETCH + "booth" + BOOTH_MINE + "-" + i + "-blended.jpg");   
    
  }
  

  // get server to update photoset to used
    PostRequest post = new PostRequest(LOCAL_ADDRESS + "/used/"+photosetid);
   post.send();


  if (CONSOLE_DEBUG) {
    println("********** Image blending completed! **********\n\n");
  }
  
}



void generateStrip() {

  fill(255);
  background(255);
  image(photosBlended[0], width/8, height/8, width/3, height/3);
  image(photosBlended[1], 4*(width/8), height/8, width/3, height/3);
  image(photosBlended[2], width/8, 4*(height/8), width/3, height/3);
  image(photosBlended[3], 4*(width/8), 4*(height/8), width/3, height/3);
  fill(0);
  
  photoStrip = get();
  
  if (CONSOLE_DEBUG) {
    println("********** Finished generating photo strip **********\n");
  }
  
}



void printPhotos() {
  
  String[] params_standard = { "lp", "-o", "landscape", "-o", "fit-to-page", "-o", "media=Letter", "booth" + BOOTH_MINE + "_strip" + ".jpg" };
  String[] params_littleprinter = {PATH_TO_SKETCH + "nuitblanche_littleprint_" + "booth" + BOOTH_MINE +".sh"};
  
  if(PRINT_STANDARD) {
    exec(params_standard);
    if (CONSOLE_DEBUG) {
      println("Sending to printer...");
    }
  }
  
  if(PRINT_LITTLEPRINTER) {
    exec(params_littleprinter);
    if (CONSOLE_DEBUG) {
      println("Sending to Little Printer...");
    }
  }
  
}


void drawCountdown() {
  
  int elapsedTime = millis() - time;
  
  if (elapsedTime > countdownInterval) {
    time = millis();
    
    if (countdown >= 1 && countdown <= COUNTDOWN_MAX) {
      background(0);
      textAlign(CENTER);
      textSize(32);
      text(nf(countdown,1), width/2, height/2);
      fill(255);
    } else {
      mode = MODE_PHOTOCAPTURE;
    }  
     
    countdown--;
  }
    
  if (CONSOLE_DEBUG) {
    println("Mode: Countdown");
  }
  
}


void initializeCamera(int cameraId) {
  
  String[] cameras = Capture.list();
  
  cam = new Capture(this,CAMERA_WIDTH,CAMERA_HEIGHT);
  cam.start();
  
  if (CONSOLE_DEBUG) {
    println(cameras);
  }

} 



void handleInput() {
  if (mode.equals(MODE_DISPLAYSTRIP)) {
    mode = MODE_WAIT; 
  } else if (mode.equals(MODE_WAIT)) {
    background(0);
    mode = MODE_COUNTDOWN;       
  }
}


void keyPressed() {
  if (KEYBOARD_INPUT) { 
    handleInput();
  }
} 


boolean buttonPressed() {
  // return true if button is pressed
  if (BUTTON_INPUT) {
    if (arduino.digitalRead(buttonPin) == Arduino.HIGH) {
      return true;    
    }
  }
  
  // return false if not
  return false;
}


void delay(int milliseconds) {
  try {
    Thread.sleep(milliseconds);
  } catch (Exception e) {}
}
