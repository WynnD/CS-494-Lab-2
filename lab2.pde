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
controlP5.Textarea rhymeHR_text;
controlP5.Textarea musHR_text;
controlP5.Textarea base_hr_text, resp_text, resp_base_text;
BufferedReader reader;


ArrayList prev_heart_rates, prev_resp, prev_resp_rates;
boolean beat = true;
boolean breath = true;
boolean use_file = true;
int xPos = 1;
int hr;
int br;
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

void setup() {
  prev_heart_rates = new ArrayList<Integer>();
  prev_resp = new ArrayList<Float>();
  prev_resp_rates = new ArrayList<Integer>();
  reader = createReader("hr_data.txt");
  try {
    use_file = reader.ready();
  } catch (Exception e) {
    use_file = false;
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
              .setRange(1023, 0)
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
  
  // create a new button with name 'buttonA'
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
     
     
   cp5.addTextfield("Age")
     .setPosition(10,150)
     .setSize(150,30)
     .setAutoClear(false)
     .setFont(font)
     .getCaptionLabel()
     .setFont(font)
     ;
     
       cp5.getController("Age").moveTo("Fitness Mode");
     
   
   cp5.addTextlabel("RESP base label")
     .setFont(createFont("arial",25))
     .setPosition(10, 440)
     .setValue("Base RESP:");
   resp_base_text = cp5.addTextarea("RESP base")
     .setFont(createFont("arial",25))
     .setPosition(150,440)
     ;
     
   cp5.getController("RESP base label").moveTo("global");
   //cp5.getController("RESP base").moveTo("global");

   cp5.addTextlabel("RESP label")
     .setFont(createFont("arial",25))
     .setPosition(10, 470)
     .setValue("RESP Rate:");
   resp_text = cp5.addTextarea("RESP")
     .setFont(createFont("arial",25))
     .setPosition(150,470)
     ;
     
     cp5.getController("RESP label").moveTo("global");
    // cp5.getController("RESP").moveTo("global");

     

   cp5.addTextlabel("Zone label")
     .setFont(createFont("arial",25))
     .setPosition(10, 210)
     .setValue("Zone:");
   zone_text = cp5.addTextarea("Zone")
     .setFont(createFont("arial", 25))
     .setPosition(90, 210)
     .setText("N/A")
     ;
     cp5.getController("Zone label").moveTo("Fitness Mode");
     zone_text.moveTo("Fitness Mode");

     
     
   cp5.addTextlabel("Avg HR label")
     .setFont(createFont("arial", 25))
     .setPosition(10, 530)
     .setValue("Base HR:")
     ;
   base_hr_text = cp5.addTextarea("Avg HR")
     .setFont(createFont("arial", 25))
     .setPosition(130, 530)
     .setText("N/A")
     ;
   cp5.getController("Avg HR label").moveTo("global");
   base_hr_text.moveTo("global");

   cp5.addTextlabel("HR label")
     .setFont(createFont("arial",25))
     .setPosition(10, 560)
     .setValue("HR:");
   hr_text = cp5.addTextarea("HR")
     .setFont(createFont("arial",25))
     .setPosition(60,560)
     ;
  cp5.getController("HR label").moveTo("global");
  hr_text.moveTo("global");

  
     cp5.getController("resp chart").moveTo("global");
     cp5.getController("hr chart").moveTo("global");

cp5.addButton("Reset")
.setPosition(10,100)
     .setSize(200,30)
     .setValue(0)
//     .setFont(button_font)
     ;
     
     cp5.getController("Reset").moveTo("global");
     
     cp5.addButton("Start")
     .setPosition(10, 50)
     .setSize(200,30);
//     .setFont(createFont("arial", 25));
     cp5.getController("Start").moveTo("global");

     
     
  cp5.addButton("Music Start")
  .setPosition(10,100)
     .setSize(190,30)
     .setValue(0)
     //.setFont(createFont("arial", 25))
     ;
     cp5.addButton("Music End")
  .setPosition(10,135)
     .setSize(190,30)
     .setValue(0)
     //.setFont(createFont("arial", 25))
     ;
     
     cp5.getController("Music Start").moveTo("StressMode");
     cp5.getController("Music End").moveTo("StressMode");
     
     
     cp5.addTextlabel("HRMus")
     .setFont(createFont("arial",25))
     .setPosition(10, 165)
     .setValue("Avg HR:");
   musHR_text = cp5.addTextarea("MusHR")
     .setFont(createFont("arial", 25))
     .setPosition(100, 165)
     .setText("N/A")
     ;
     
      cp5.getController("HRMus").moveTo("StressMode");
      musHR_text.moveTo("StressMode");
      //cp5.getController("MusHR").moveTo("StressMode");



    
     
     cp5.addButton("Rhyme Start")
     .setPosition(10,205)
     .setSize(190,30)
     .setValue(0)
     //.setFont(createFont("arial", 25))
     ;
     cp5.addButton("Rhyme End")
     .setPosition(10,240)
     .setSize(190,30)
     .setValue(0)
     //.setFont(createFont("arial", 25))
     ;
     
     
     cp5.getController("Rhyme Start").moveTo("StressMode");

     cp5.getController("Rhyme End").moveTo("StressMode");
     
     
     cp5.addTextlabel("RhymeLabel")
     .setFont(createFont("arial",25))
     .setPosition(10, 270)
     .setValue("Avg HR:");
   rhymeHR_text = cp5.addTextarea("rhymeHR")
     .setFont(createFont("arial", 25))
     .setPosition(100, 270)
     .setText("N/A")
     ;
     
     cp5.getController("RhymeLabel").moveTo("StressMode");

     rhymeHR_text.moveTo("StressMode");
     

   
   if (!use_file) {
    try {
    myPort = new Serial(this, Serial.list()[1], 9600);
    myPort.bufferUntil('\n');
    } catch (Exception e) {
      hr_text.setText("NO SERIAL");
    }
  }
}

boolean retrieved_hr_avg = false;
boolean retrieved_resp_avg_val = false;

void reset(){
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
}

void draw() {
  background(0x444444);
  
  if (!retrieved_hr_avg && time.millis() - start_time > 30000) {
    int avg = getAvgHr();
    int br_avg = getAvgBr();
    resp_base_text.setText(Float.toString(br_avg));
    base_hr_text.setText(Integer.toString(avg));
    retrieved_hr_avg = true;
    println("retrieved avg hr and resp rate");
    println(resp_avg);
  }
  
  if (!retrieved_resp_avg_val && time.millis() - start_time > 10000) {
    resp_avg = getAvgRespVal();
    retrieved_resp_avg_val = true;
  }
  
  if (use_file) {
    for (int i = 0; i < 5; ++i)
      readFromFile();
  }
  
  // detect heartbeat
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
  // end detecting heartbeat
  
  // detect breath
  float inByteResp = fakeBreathData();
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
      inByte = float(line);
      if (!Float.isNaN(inByte))
        hr_changed = true;
    } catch (Exception e) {
      reader = createReader("hr_data.txt");
      hr_changed = false;
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

float getAvgRespVal() {
  float sum = 0;
  for (Object val : prev_resp.toArray()) {
    sum += (float) val;
  }
  println("Avg resp val: ", sum/prev_resp.size());
  return sum/prev_resp.size();
}

void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = myPort.readStringUntil('\n');

  if (inString != null) {
    // trim off any whitespace:
    
    inString = trim(inString);

    // If leads off detection is true notify with blue line
    if (inString.equals("!")) { 
      stroke(0, 0, 0xff); //Set stroke to blue ( R, G, B)
      inByte = 512;  // middle of the ADC range (Flat Line)
    }
    // If the data is good let it through
    else {
      stroke(0xff, 0, 0); //Set stroke to red ( R, G, B)
      inByte = float(inString); 
     }
     //Map and draw the line for new data point
     inByte = map(inByte, 0, 1023, 0, height);
     // at the edge of the screen, go back to the beginning:
     hr_changed = true;   
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

public void controlEvent(ControlEvent theEvent) {
 // println(theEvent.getController().getName());
  if (theEvent.isTab()) {
    println("got an event from tab : "+theEvent.getTab().getName()+" with id "+theEvent.getTab().getId());
  }
  else if(theEvent.isAssignableFrom(Textfield.class)) {
    println("controlEvent: accessing a string from controller '"
            +theEvent.getName()+"': "
            +theEvent.getStringValue()
            );}
  else{
    println(theEvent.getController().getName());

  }

}

public void Start( ){
      hrChart.setColors("heart_rate", colors.get("orange"));
      start = true;
}


public void Age(String theText) {
  // automatically receives results from controller input
  println("a textfield event for controller 'Age' : "+theText);
  age = int(theText);
  calcZones(age);
}

public void Reset(int theValue){
  reset();
}