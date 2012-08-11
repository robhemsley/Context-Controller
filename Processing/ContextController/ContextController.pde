/* Context Controller
 * 
 *   Social TV second screen application. Provides contextual information for 
 *   live streamed video content. Demo application plays stored video with closed
 *   captioning data.
 */

import processing.opengl.*;
import codeanticode.glgraphics.*;
import codeanticode.gsvideo.*;
import fullscreen.*;
import bluetoothDesktop.*;
import java.util.HashMap;

String ccFile = "/Users/Rob/Documents/Work/MIT/ContextController/Processing/NewsCaption/bbc.xml";
String videoFile = "/Users/Rob/Documents/Work/MIT/ContextController/Processing/NewsCaption/BBCNews10_08_2012.mp4";





GSMovie mov;
GLTexture tex;

int fcount, lastm;
float frate;
int fint = 3;
FullScreen fs; 
Bluetooth bt;
HashMap subHash = new HashMap();
int offset = 11;
Client connected;
boolean firstRun = true;

void setup() {
  //Create Window
  size(1680, 1050, GLConstants.GLGRAPHICS);
  
  //Process XML File
  XMLElement xml = new XMLElement(this, ccFile);    
  XMLElement body = xml.getChild(1);
  XMLElement div_val = body.getChild(0);
  int numSites = div_val.getChildCount();

  //Add XML to HashMap based on offset in video
  for (int i = 0; i < numSites; i++) {
    XMLElement subtitle = div_val.getChild(i);        
    String[] time = split(subtitle.getString("begin"), ".");
    time = split(time[0], ":");
    int output = Integer.parseInt(time[2])+(Integer.parseInt(time[1])*60)+(Integer.parseInt(time[0])*3600);
    subHash.put(output-offset, subtitle.getContent());
   
    println(subtitle.getContent());
  }
  
  //Setup Video
  frameRate(90);
  mov = new GSMovie(this, videoFile);

  // Use texture tex as the destination for the movie pixels.
  tex = new GLTexture(this);
  mov.setPixelDest(tex);
  tex.setPixelBufferSize(10);
  tex.delPixelsWhenBufferFull(false);

  mov.play();
  background(0);
  noStroke();

  // Create the fullscreen object
  fs = new FullScreen(this); 
  fs.enter();
  
  //Start Bluetooth
  try {
    bt = new Bluetooth(this);
    bt.start("CaptionService");
  } 
  catch (RuntimeException e) {
    println(e);
  }
}

void draw() {
  if (mov.available()) {
    mov.read();
    if (tex.putPixelsIntoTexture()) {
      // Calculating height to keep aspect ratio.      
      float h = width * tex.height / tex.width;
      float b = 0.5 * (height - h);

      image(tex, 0, b, width, h);
      
      fcount += 1;
      int m = millis();
      if (m - lastm > 1000 * fint) {
        frate = float(fcount) / fint;
        fcount = 0;
        lastm = m;
      }
    }
  }

  if(subHash.containsKey((int)mov.time())){
    if((int)mov.time() > lastTime){
      print("CC:"+ subHash.get((int)mov.time()));
      if(connected != null){
        //Send over Bluetooth to tablet
        connected.writeUTF("-"+subHash.get((int)mov.time()));
      }
      lastTime = (int)mov.time();
    }
  }
  
  if (connected != null){
    if (connected.available() > 0){
      int nrBytes = connected.available();
      byte[] inBytes = new byte[nrBytes];
      connected.readBytes(inBytes);
      if (nrBytes>0) {
        //Check data and pause video        
        if(inBytes[0] == 49){
          mov.pause();
        }else{
          mov.play();
        }
      }
    }
  }
  
  if(mov.time() > 0.6 && firstRun){
    //If first run pause after 0.6 seconds.
    firstRun = false;
    mov.pause();
  }
}

int lastTime = 0;
void keyPressed(){
  //Play Pause Video based on space bar
  if (key == ' ') {
    if (mov.isPlaying()){
      mov.pause();
    }else{
      mov.play(); 
    }
  }
    
  if(key == '1'){
    //Skips through the video
    mov.jump(((int)90*20)+mov.frame());
  }
}

void clientConnectEvent(Client c) {
  connected = c;
  //Client connected
  println("Connected:"+connected.device.name);
}

public static double roundToSignificantFigures(double num, int n) {
    if(num == 0) {
        return 0;
    }

    final double d = Math.ceil(Math.log10(num < 0 ? -num: num));
    final int power = n - (int) d;

    final double magnitude = Math.pow(10, power);
    final long shifted = Math.round(num*magnitude);
    return shifted/magnitude;
}

