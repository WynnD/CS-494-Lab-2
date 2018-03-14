import controlP5.*;
import processing.serial.*;
import java.util.HashMap;
import java.time.Clock;
import java.lang.Math.*;

ControlP5 cp5;
Clock time;
Serial myPort;
controlP5.Textarea hr_text;
controlP5.Textarea zone_text;
controlP5.Textarea riddleHR_text, riddleRESP_text;
controlP5.Textarea musHR_text, musRESP_text;
controlP5.Textarea base_hr_text, resp_text, resp_base_text;
BufferedReader reader;
float inByteResp = 0;

ArrayList prev_heart_rates, prev_resp, prev_resp_rates;
boolean beat = true;
boolean breath = true;
int xPos = 1;
int hr, br;
float height_old = 0;
float height_new = 0;
float inByte = 0;
float resp_avg;
float resp_avg_val;
boolean hr_changed = false;
boolean resp_changed = false;
Chart hrChart, respChart;
int counter = 0;
String textValue = "";
int age;
int[] zones;
double beat_length = 0;
double breath_length = 0;
double last_beat = 0;
double last_breath = 0;

long start_time;
float last_hr_datapoint = 0;
float second_last_hr_datapoint = 0;
float last_resp_datapoint = 0;
float second_last_resp_datapoint = 0;
HashMap<String, Integer> colors;
boolean start= false;
boolean use_file = false;
boolean riddleE = false;
boolean musicE = false;

void setup() {
  prev_heart_rates = new ArrayList<Integer>();
  prev_resp = new ArrayList<Float>();
  prev_resp_rates = new ArrayList<Integer>();
  reader = createReader("hr_data.txt");
  if (use_file) {
    try {
      use_file = reader.ready();
    } catch (Exception e) {
      e.printStackTrace();
      use_file = false;
    }
  }
  PFont pfont = createFont("arial",30);
  ControlFont font = new ControlFont(pfont,18);
  frameRate(100);
  
  cp5 = new ControlP5(this);
  time = Clock.systemUTC();
  start_time = time.millis();
  colors = new HashMap<String, Integer>();
  colors.put("red", #FF0000);
  colors.put("orange", #FFA500);
  colors.put("green", #00FF00);
  colors.put("blue", #00BFFF);
  colors.put("grey", #F0F8FF);
  colors.put("pink", #FFB6C1);
  colors.put("white", #FFFFFF);

  zones = new int[5];
  hrChart = cp5.addChart("hr chart")
               .setPosition(220, 15)
               .setSize(980, 300)
               .setRange(1023-900, 900)
               .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
               .setStrokeWeight(2.5)
               ;
  respChart = cp5.addChart("resp chart")
              .setPosition(220, 315)
              .setSize(980, 300)
              .setRange(0, 1023)
              .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
              .setStrokeWeight(2.5)
              ;

  hrChart.addDataSet("heart_rate");
  hrChart.setData("heart_rate", new float[490]);
  hrChart.setColors("heart_rate",#FFFFFF);
  hrChart.getColor().setBackground(#000000);
  respChart.addDataSet("resp_rate");
  respChart.setData("resp_rate",new float[490]);
  respChart.setColors("resp_rate",#FFFFFF);
  respChart.getColor().setBackground(#111111);
  size(1200,615);
  background(0x444444);
  

  /***************************************************************************************************/
  /*******************************************TABS********************************************************/
  /***************************************************************************************************/
  cp5.addTab("Fitness Mode")
     .setValue(0)
     .setPosition(10,10)
     .setSize(200,30)
     .getCaptionLabel()
     .setFont(font)
     ;
  
  // and add another 2 buttons
  cp5.addTab("StressMode")
     .setValue(100)
     .setPosition(10,60)
     .setSize(200,30)
     .getCaptionLabel()
     .setFont(font)
     ;
     
   cp5.addTab("Meditation Mode")
     .setPosition(10,110)
     .setSize(200,30)
     .setValue(0)
     .getCaptionLabel()
     .setFont(font);
     
     cp5.getTab("Fitness Mode")
     .activateEvent(true)
     .setId(1)
     ;
     
     cp5.getTab("StressMode")
     .activateEvent(true)
     .setId(2)
     ;
  cp5.getTab("Meditation Mode")
     .activateEvent(true)
     .setId(3)
     ;
     
  cp5.getTab("default").hide();
     
     
  /***************************************************************************************************/
  /***********************Fitness Sections***************************************************************************/
  /***************************************************************************************************/
     
     
   cp5.addTextfield("Age")
     .setPosition(10,150)
     .setSize(150,30)
     .setAutoClear(false)
     .setFont(font)
     .getCaptionLabel()
     .setFont(font)
     ;
     
       cp5.getController("Age").moveTo("Fitness Mode");
       
       
       
   cp5.addTextlabel("Zone label")
     .setFont(createFont("arial",20))
     .setPosition(10, 210)
     .setValue("Zone:");
   zone_text = cp5.addTextarea("Zone")
     .setFont(createFont("arial", 20))
     .setPosition(90, 210)
     .setText("N/A")
     ;
     cp5.getController("Zone label").moveTo("Fitness Mode");
     zone_text.moveTo("Fitness Mode");
     

  /***************************************************************************************************/  
  /**********************GLOBAL*****************************************************************************/
  /***************************************************************************************************/
   cp5.addTextlabel("RESP base label")
     .setFont(createFont("arial",20))
     .setPosition(10, 460)
     .setValue("BASE RESP Rate:");
   resp_base_text = cp5.addTextarea("RESP base")
     .setFont(createFont("arial",20))
     .setPosition(180,460)
     ;
     
   cp5.getController("RESP base label").moveTo("global");
   resp_base_text.moveTo("global");
   
   

   cp5.addTextlabel("RESP label")
     .setFont(createFont("arial",20))
     .setPosition(10, 485)
     .setValue("RESP Rate:");
   resp_text = cp5.addTextarea("RESP")
     .setFont(createFont("arial",20))
     .setPosition(160,485)
     ;
     
     cp5.getController("RESP label").moveTo("global");
    resp_text.moveTo("global");
    
    
    
    cp5.addTextlabel("Avg HR label")
     .setFont(createFont("arial", 20))
     .setPosition(10, 510)
     .setValue("BASE HR:")
     ;
     
   base_hr_text = cp5.addTextarea("Avg HR")
     .setFont(createFont("arial", 20))
     .setPosition(160, 510)
     .setText("N/A")
     ;

   cp5.getController("Avg HR label").moveTo("global");
   base_hr_text.moveTo("global");
   
   

   cp5.addTextlabel("HR label")
     .setFont(createFont("arial",20))
     .setPosition(10, 535)
     .setValue("HR:");
     
   hr_text = cp5.addTextarea("HR")
     .setFont(createFont("arial",20))
     .setPosition(160,535)
     ;
     
  cp5.getController("HR label").moveTo("global");
  hr_text.moveTo("global");

  
     cp5.getController("resp chart").moveTo("global");
     cp5.getController("hr chart").moveTo("global");
     
     
     cp5.addButton("Reset")
     .setPosition(10,100)
     .setSize(200,30)
     ; 
     cp5.getController("Reset").moveTo("global");
     
     cp5.addButton("Start")
     .setPosition(10, 50)
     .setSize(200,30)
     ;
     cp5.getController("Start").moveTo("global");
    
    
  /***************************************************************************************************/
  /*******************STRESS MODE********************************************************************************/
  /***************************************************************************************************/

     
  cp5.addButton("MusicStart")
  .setPosition(10,100)
     .setSize(190,25)
     .setCaptionLabel("Music Start")
     ;
     cp5.addButton("MusicEnd")
  .setPosition(10,130)
     .setSize(190,25)
     .setCaptionLabel("Music End")
     ;
     
     cp5.getController("MusicStart").moveTo("StressMode");
     cp5.getController("MusicEnd").moveTo("StressMode");
     
     
     cp5.addTextlabel("HRMus")
     .setFont(createFont("arial",20))
     .setPosition(10, 160)
     .setValue("Avg HR:");
     musHR_text = cp5.addTextarea("MusHR")
     .setFont(createFont("arial", 20))
     .setPosition(100, 160)
     .setText("N/A")
     ;
      cp5.getController("HRMus").moveTo("StressMode");
      musHR_text.moveTo("StressMode");
      
      
      
      cp5.addTextlabel("RESPMus")
     .setFont(createFont("arial",20))
     .setPosition(10, 185)
     .setValue("Avg RESP:");
     musRESP_text = cp5.addTextarea("RESPM")
     .setFont(createFont("arial", 20))
     .setPosition(120, 185)
     .setText("N/A")
     ;
     
      cp5.getController("RESPMus").moveTo("StressMode");
      musRESP_text.moveTo("StressMode");     



    
     
     cp5.addButton("RiddleStart")
     .setPosition(10,230)
     .setSize(190,25)
     .setCaptionLabel("Riddle Start")
     ;
     cp5.addButton("RiddleEnd")
     .setPosition(10,260)
     .setSize(190,25)
     .setCaptionLabel("Riddle End")
     ;
     
     
     cp5.getController("RiddleStart").moveTo("StressMode");
     cp5.getController("RiddleEnd").moveTo("StressMode");
     
     
     cp5.addTextlabel("RiddleLabel")
     .setFont(createFont("arial",20))
     .setPosition(10, 290)
     .setValue("Avg HR:");
   riddleHR_text = cp5.addTextarea("riddleHR")
     .setFont(createFont("arial", 20))
     .setPosition(100, 290)
     .setText("N/A")
     ;  
     cp5.getController("RiddleLabel").moveTo("StressMode");
     riddleHR_text.moveTo("StressMode");
     
     
      cp5.addTextlabel("RiddleLabelRESP")
     .setFont(createFont("arial",20))
     .setPosition(10, 315)
     .setValue("Avg RESP:");
     riddleRESP_text = cp5.addTextarea("riddleRESP")
     .setFont(createFont("arial", 20))
     .setPosition(120, 315)
     .setText("N/A")
     ;  
     cp5.getController("RiddleLabelRESP").moveTo("StressMode");
     riddleRESP_text.moveTo("StressMode");
     
 /***************************************************************************************************/
 /*******************MEDITATION MODE********************************************************************************/
 /***************************************************************************************************/
 cp5.addButton("MeditationButt")
     .setPosition(5,100)
     .setSize(200,25)
     .setCaptionLabel("Start Meditation")
     ;
 
 cp5.getController("MeditationButt").moveTo("Meditation Mode");
 
  /***************************************************************************************************/
  /***************************************************************************************************/
  /***************************************************************************************************/

     
        

   
   if (!use_file) {
    println("Trying to use serial port");
    try {
    myPort = new Serial(this, Serial.list()[0], 9600);
    myPort.bufferUntil('\n');
    } catch (Exception e) {
      hr_text.setText("NO SERIAL");
    }
   } else {
    println("Using file");
  }
}

void resets(){
    retrieved_hr_avg = false;
    retrieved_resp_avg_val = false;
    resp_avg = -1;
    resp_avg_val = 0;
    prev_heart_rates = new ArrayList<Integer>();
    prev_resp = new ArrayList<Float>();
    prev_resp_rates = new ArrayList<Integer>();
    base_hr_text.setText("N/A");
    resp_base_text.setText("N/A");
    start_time = time.millis();
    hrChart.setColors("heart_rate", colors.get("white"));
    respChart.setColors("resp_rate", colors.get("white"));
}

void draw() {
  background(0x444444);
  
  if (!retrieved_hr_avg && start == true && time.millis() - start_time > 30000) {
    int avg = getAvgHr();
    int br_avg = getAvgBr();
    resp_base_text.setText(Float.toString(br_avg));
    base_hr_text.setText(Integer.toString(avg));
    retrieved_hr_avg = true;
    println("retrieved avg hr and resp rate");
    println(resp_avg);
    hrChart.setColors("heart_rate", colors.get("white"));
    respChart.setColors("resp_rate", colors.get("white"));
    println(last_beat);
  }

  if (!retrieved_resp_avg_val && time.millis() - start_time > 10000) {
    resp_avg = getAvgRespVal();
    retrieved_resp_avg_val = true;
  }
  if (musicE == true){
    int avg = getAvgHr();
    int br_avg = getAvgBr();
    musHR_text.setText(Float.toString(avg));
    musRESP_text.setText(Integer.toString(br_avg));
    println("retrieved avg hr and resp rate");
    println(resp_avg);
   // hrChart.setColors("heart_rate", colors.get("white"));
    //respChart.setColors("heart_rate", colors.get("white"));
    musicE = false;
  }
  
  if (riddleE == true ){
    
    int avg = getAvgHr();
    int br_avg = getAvgBr();
    riddleHR_text.setText(Float.toString(avg));
    riddleRESP_text.setText(Integer.toString(br_avg));
    retrieved_hr_avg = true;
    println("retrieved avg hr and resp rate");
    println(resp_avg);
    //hrChart.setColors("heart_rate", colors.get("white"));
   // respChart.setColors("heart_rate", colors.get("white"));
    riddleE = false;
  }
  
  if (use_file) {
    for (int i = 0; i < 5; ++i)
      readFromFile();
  }
  
   if (!beat && inByte > 700) {
    beat = true;
    long beat_time = time.millis();
    if (last_beat != 0) {
      beat_length = beat_time - last_beat;
      hr_text.setText(calcHr());
      setChartColor();
    }

    last_beat = beat_time;
  }
  
  if (beat && inByte < 700) {
    beat = false;
  }
  
  // detect breath
  if (retrieved_resp_avg_val && !breath && inByteResp >= resp_avg) {
    breath = true;
    long breath_time = time.millis();
    if (last_breath != 0) {
      breath_length = breath_time - last_breath;
      resp_text.setText(calcBr());
    }
    last_breath = breath_time;

  }
  
  if (breath && inByteResp < resp_avg) {
    breath = false;
  }
  // end detect breath

  if (hr_changed) {
    float smoothed_val = smoothHrVal(inByte);
     hrChart.push("heart_rate", smoothed_val);
     hr_changed = false;
     counter++;
  }
  if (resp_changed) {
    cacheRespVal(inByteResp);
    float smoothed_val = smoothRespVal(inByteResp);
    respChart.push("resp_rate", smoothed_val);
    resp_changed = false;
  }
}

float smoothHrVal(float newVal) {
  float smoothed_val;
  if (last_hr_datapoint != 0) {
    if (second_last_hr_datapoint != 0) {
      smoothed_val = (second_last_hr_datapoint+last_hr_datapoint*2+newVal*3)/6;
      second_last_hr_datapoint = last_hr_datapoint;
    } else {
      smoothed_val = newVal;
      second_last_hr_datapoint = last_hr_datapoint;
    }
  } else {
    smoothed_val = newVal;
  }
  last_hr_datapoint = newVal;

  return smoothed_val;
}

float smoothRespVal(float newVal) {
  float smoothed_val;
  if (last_resp_datapoint != 0) {
    if (second_last_resp_datapoint != 0) {
      smoothed_val = (second_last_resp_datapoint+last_resp_datapoint*2+newVal*3)/6;
      second_last_resp_datapoint = last_resp_datapoint;
    } else {
      smoothed_val = newVal;
      second_last_resp_datapoint = last_resp_datapoint;
    }
  } else {
    smoothed_val = newVal;
  }
  last_resp_datapoint = newVal;

  return smoothed_val;
}

void setChartColor() {
  String[] colors_array = {"grey", "blue", "green", "orange", "red"};
  String[] zones_array = {"very light", "light", "moderate", "hard", "maximum"};
  for (int i = 0; i < zones.length; ++i) {
    if (hr < zones[i]) {
      hrChart.setColors("heart_rate", colors.get(colors_array[i]));
      zone_text.setText(zones_array[i]);
      return;
    }
  }
}


void readFromFile() {
    try {
      String line = reader.readLine();
      String array[] = line.split(", ");
      if (array.length != 2) {
        return;
      }
      String hrString = array[0];
      String respString = array[1];
      inByte = float(hrString);
      inByteResp = float(respString);
      if (!Float.isNaN(inByte))
        hr_changed = true;
      if (!Float.isNaN(inByteResp)) {
        resp_changed = true;
      }
    } catch (Exception e) {
      e.printStackTrace();
      reader = createReader("hr_data1.txt");
      hr_changed = false;
      resp_changed = false;
    }
}

String calcHr() {
  double sec_per_beat = beat_length/1000.0;
  Double min_per_beat = sec_per_beat/60.0;
  hr = (int)(1/min_per_beat);
  if (hr < 220) {
    println("cached hr");
    prev_heart_rates.add(hr);
    return Integer.toString(hr);
  } else {
    return "";
  }
}

String calcBr() {
  double sec_per_breath = breath_length/1000.0;
  Double min_per_breath = sec_per_breath/60.0;
  println("Breath length", sec_per_breath);
  println("Minutes per breath", min_per_breath);
  br = (int)(1/min_per_breath);
  cacheBr(br);
  println(br);
  return Integer.toString(br);
}

void cacheRespVal(float resp) {
   prev_resp.add(resp);
}

void cacheBr(float resp_rate) {
  println("Cached breath rate");
  prev_resp_rates.add(resp_rate);
}

int getAvgHr() {
  int sum = 0;
  for (Object hr : prev_heart_rates.toArray()) {
    sum += (int) hr;
  }
  int n = prev_heart_rates.size();
  if (n == 0) {
    return -1;
  }
  return sum/prev_heart_rates.size();
}

int getAvgBr() {
  int sum = 0;
  for (Object br : prev_resp_rates.toArray()) {
    sum += (float) br;
  }
  println(prev_resp_rates);
  int n = prev_resp_rates.size();
  if (n == 0) {
    return -1;
  }
  return sum/n;
}
/**********************************************************************************************************************/
/**********************************************************************************************************************/



float getAvgRespVal() {
  float sum = 0;
  for (Object val : prev_resp.toArray()) {
    sum += (float) val;
  }
  println("Avg resp val: ", sum/prev_resp.size());
  return sum/prev_resp.size();
}


 /***************************************************************************************************/
 /*******************START/RESET********************************************************************************/
 /***************************************************************************************************/
  boolean retrieved_hr_avg = false;
  boolean retrieved_resp_avg_val = false;
  
  void starts(){
      hrChart.setColors("heart_rate", colors.get("pink"));
      respChart.setColors("resp_rate", colors.get("pink"));
      start = true;
      start_time = time.millis();
      //prev_heart_rates = new ArrayList<Integer>();
      prev_resp = new ArrayList<Float>();
      prev_resp_rates = new ArrayList<Integer>();
      retrieved_hr_avg = false;
      retrieved_resp_avg_val = false;
      resp_avg = -1;
      resp_avg_val = 0;
      //prev_heart_rates.clear();
      //prev_resp.clear();
      
  }
   /***************************************************************************************************/
  /***************************************************************************************************/
  /***************************************************************************************************/

void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = myPort.readStringUntil('\n');

  if (inString != null) {
    String array[] = inString.split(", ");
    if (array.length != 2) {
      println("input was !");
      return;
    }
    
    inString = array[0];
    String resp_string = array[1];
    println(resp_string);
    // trim off any whitespace:
    inString = trim(inString);
    resp_string = trim(resp_string);

    // If leads off detection is true notify with blue line
    if (inString.equals("!")) { 
      stroke(0, 0, 0xff); //Set stroke to blue ( R, G, B)
      inByte = 512;  // middle of the ADC range (Flat Line)
    }
    // If the data is good let it through
    else {
      stroke(0xff, 0, 0); //Set stroke to red ( R, G, B)
      inByteResp = float(resp_string);
      inByte = float(inString); 
     }
     //Map and draw the line for new data point
     //  inByte = map(inByte, 0, 1023, 0, height);
     //  inByteResp = map(inByteResp, 0, 1023, 0, height);
     // at the edge of the screen, go back to the beginning:
     hr_changed = true;
     resp_changed = true;
  }
}

void calcZones(int age) {
  for (int i = 0; i < 5; ++i) {
    zones[i] = int((220-age)*(i+5)*0.1);
  }
}

double theta = 0;
boolean up = true;

float fakeBreathData() {
  theta += 3 * Math.PI/750;
  resp_changed = true;
  return (float) (Math.sin(theta) * 512) + 512;
}

// EVENT HANDLERS

 /***************************************************************************************************/
  /*******************EVENT HANDLERS********************************************************************************/
  /***************************************************************************************************/

public void controlEvent(ControlEvent theEvent) {
 // println(theEvent.getController().getName());
 /* if (theEvent.isTab()) {
    println("got an event from tab : "+theEvent.getTab().getName()+" with id "+theEvent.getTab().getId());
  }
  else if(theEvent.isAssignableFrom(Textfield.class)) {
    println("controlEvent: accessing a string from controller '"
            +theEvent.getName()+"': "
            +theEvent.getStringValue()
            );}
  else{
    println(theEvent.getController().getName());

  }*/

}

public void Start( ){
      starts();
}


public void Age(String theText) {
  // automatically receives results from controller input
  println("a textfield event for controller 'Age' : "+theText);
  age = int(theText);
  calcZones(age);
}

public void Reset(){
  resets();
}

public void RiddleStart(){
  prev_heart_rates = new ArrayList<Integer>();
  prev_resp = new ArrayList<Float>();
  prev_resp_rates = new ArrayList<Integer>();
}

public void RiddleEnd(){
  riddleE = true;
}

public void MusicStart(){
   prev_heart_rates = new ArrayList<Integer>();
   prev_resp = new ArrayList<Float>();
   prev_resp_rates = new ArrayList<Integer>();
 }

public void MusicEnd(){
    musicE = true;
}

public void Meditation(){
  myPort.write(1);

}