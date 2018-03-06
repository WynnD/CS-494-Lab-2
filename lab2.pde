import controlP5.*;
import processing.serial.*;
import java.util.HashMap;
import java.time.Clock;

ControlP5 cp5;
Clock time;
Serial myPort;
controlP5.Textarea hr_text;
controlP5.Textarea zone_text;
controlP5.Textarea base_hr_text;
BufferedReader reader;

ArrayList prev_heart_rates;
boolean beat = true;
boolean use_file = true;
int xPos = 1;
int hr;
float height_old = 0;
float height_new = 0;
float inByte = 0;
boolean changed = false;
Chart hrChart, respChart;
int counter = 0;
String textValue = "";
int age;
int[] zones;
double beat_length = 0;
double last_beat = 0;
long start_time;
float last_hr_datapoint = 0;
float second_last_hr_datapoint = 0;
HashMap<String, Integer> colors;

void setup() {
  prev_heart_rates = new ArrayList<Integer>();
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
               .setPosition(220, 0)
               .setSize(980, 300)
               .setRange(1023-900, 900)
               .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
               .setStrokeWeight(2.5)
               ;
  respChart = cp5.addChart("resp chart")
              .setPosition(220, 300)
              .setSize(980, 300)
              .setRange(1023-900, 900)
              .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
              .setStrokeWeight(2.5)
              ;

  hrChart.addDataSet("heart_rate");
  hrChart.setData("heart_rate", new float[490]);
  hrChart.setColors("heart_rate",#FFFFFF);
  hrChart.getColor().setBackground(#000000);
  respChart.addDataSet("resp_rate");
  respChart.setData("resp_rate",new float[490]);
  size(1200,600);
  background(0x444444);
  
  // create a new button with name 'buttonA'
  cp5.addButton("Fitness Mode")
     .setValue(0)
     .setPosition(10,10)
     .setSize(200,30)
     .getCaptionLabel()
     .setFont(font)
     ;
  
  // and add another 2 buttons
  cp5.addButton("Stress Mode")
     .setValue(100)
     .setPosition(10,60)
     .setSize(200,30)
     .getCaptionLabel()
     .setFont(font)
     ;
     
   cp5.addButton("Meditation Mode")
     .setPosition(10,110)
     .setSize(200,30)
     .setValue(0)
     .getCaptionLabel()
     .setFont(font);
  
     
   cp5.addTextfield("Age")
     .setPosition(10,170)
     .setSize(200,30)
     .setAutoClear(false)
     .setFont(font)
     .getCaptionLabel()
     .setFont(font)
     ;
   cp5.addTextlabel("Zone label")
     .setFont(createFont("arial",25))
     .setPosition(10, 500)
     .setValue("Zone:");
   zone_text = cp5.addTextarea("Zone")
     .setFont(createFont("arial", 25))
     .setPosition(90, 500)
     .setText("N/A")
     ;
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
   cp5.addTextlabel("HR label")
     .setFont(createFont("arial",25))
     .setPosition(10, 560)
     .setValue("HR:");
   hr_text = cp5.addTextarea("HR")
     .setFont(createFont("arial",25))
     .setPosition(60,560)
     ;
   if (!use_file) {
    try {
    myPort = new Serial(this, Serial.list()[1], 9600);
    myPort.bufferUntil('\n');
    } catch (Exception e) {
      hr_text.setText("NO SERIAL");
    }
  }
}

boolean retrieved_avg = false;

void draw() {
  background(0x444444);
  
  if (!retrieved_avg && time.millis() - start_time > 30000) {
    int avg = getAvgHr();
    base_hr_text.setText(Integer.toString(avg));
    retrieved_avg = true;
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
    }
    hr_text.setText(calcHr());
    setChartColor();
    last_beat = beat_time;
  }
  
  if (beat && inByte < 700) {
    beat = false;
  }

  if (changed) {
    float smoothed_val = smoothHrVal(inByte);
     hrChart.push("heart_rate", smoothed_val);
     changed = false;
     counter++;
  }
}

float smoothHrVal(float newVal) {
  float smoothed_val;
  if (last_hr_datapoint != 0) {
    if (second_last_hr_datapoint != 0) {
      smoothed_val = (second_last_hr_datapoint+last_hr_datapoint*3+newVal*5)/9;
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

void setChartColor() {
  String[] colors_array = {"grey", "blue", "green", "orange", "red"};
  String[] zones_array = {"very light", "light", "moderate", "hard", "maximum"};
  for (int i = 0; i < zones.length; ++i) {
    println(hr);
    println(zones[i]);
    if (hr < zones[i]) {
      hrChart.setColors("heart_rate", colors.get(colors_array[i]));
      zone_text.setText(zones_array[i]);
      println(i+1);
      return;
    }
  }
}

void readFromFile() {
    try {
      String line = reader.readLine();
      inByte = float(line);
      if (!Float.isNaN(inByte))
        changed = true;
    } catch (Exception e) {
      reader = createReader("hr_data.txt");
      changed = false;
    }
}

String calcHr() {
  double sec_per_beat = beat_length/1000.0;
  Double min_per_beat = sec_per_beat/60.0;
  hr = (int)(1/min_per_beat);
  if (hr < 220) {
    prev_heart_rates.add(hr);
    return Integer.toString(hr);
  } else {
    return "";
  }
}

int getAvgHr() {
  int sum = 0;
  for (Object hr : prev_heart_rates.toArray()) {
    sum += (int) hr;
  }
  return sum/prev_heart_rates.size();
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
     changed = true;   
  }
}

void random_shit () {
  // get the ASCII string:
   stroke(0xff, 0, 0); //Set stroke to red ( R, G, B)
   inByte = random(1023);
   changed = true;
}

void calcZones(int age) {
  for (int i = 0; i < 5; ++i) {
    zones[i] = int((220-age)*(i+5)*0.1);
  }
  
  println(zones);
}


// EVENT HANDLERS

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
  if(theEvent.isAssignableFrom(Textfield.class)) {
    println("controlEvent: accessing a string from controller '"
            +theEvent.getName()+"': "
            +theEvent.getStringValue()
            );}

}

// function colorA will receive changes from 
// controller with name colorA
public void FitnessMode(int theValue) {
  println("a button event from FitnessMode");
  
}

// function colorB will receive changes from 
// controller with name colorB
public void StressMode(int theValue) {
  println("a button event from StressMode");
  
}

// function colorC will receive changes from 
// controller with name colorC
public void MeditationMode(int theValue) {
  println("a button event from MeditationMode");
}

public void Age(String theText) {
  // automatically receives results from controller input
  println("a textfield event for controller 'Age' : "+theText);
  age = int(theText);
  calcZones(age);
  println(age); 
}