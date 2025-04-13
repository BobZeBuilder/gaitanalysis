import controlP5.*;

PImage footImage;
PGraphics heatmap;
ControlP5 cp5;
Group metricsGroup; // global section1
Group forceMeasurements; //global section2

// SECTION BUTTONS
boolean showSection1 = true;
boolean showSection2 = true;
boolean showSection3 = true;
boolean showSection4 = true;
boolean prevSection1 = false;
boolean prevSection2 = false;
boolean prevSection3 = false;
boolean prevSection4 = false;

// Gait metrics SECTION 1
float stepLength = 0.72;
float strideLength = 1.44;
float strideWidth = 0.44;
float cadence = 110;
float speed = 1.32;

int stepCount = 0;


// Variables for data collection SECTION 2
String currentGaitPattern = "Analyzing...";
color patternColor = color(0);


// Metrics variables SECTION 2
float footAngle = 180.2;
float cumulativeMM = 0;
float cumulativeMF = 0;
float cumulativeLF = 0;
float cumulativeHEEL = 0;
float MFP = 0;
int time = 0;

//Metrics variables SECTION 3
boolean isActive = true;   // Control the timer
int startTime = 0;          // Time when timer started or resumed
int elapsedTime = 0;        // Accumulated time when paused
int displayTime = 0;

//
// SECTION 4 JUMPING
//
Group jumpMetrics;
boolean isJumping = false;
int jumpCount = 0;
float jumpHeight = 0;
float airTime = 0;
float peakForce = 0;
float powerOutput = 0;
float personalBest = 0;

String[] profileNames = {"Normal Gait", "In-toeing", "Out-toeing", "Tiptoeing", "Walking on Heel"};

// Pressure history
float[][] pressureHistory = new float[4][100];
int historyIndex = 0;

Textfield stepLengthInput, strideLengthInput, strideWidthInput;

class Sensor {
  PVector position;
  float pressure;
  String name;
  Chart chart;
  
  Sensor(float x, float y, String n) {
    position = new PVector(x, y);
    pressure = 0;
    name = n;
  }
}

class Accelerometer {
  float coordinate;    // coordinate
  float acc;           // acceleration
  char dir;            // direction : x, y, or z

  Accelerometer(float position, float acceleration, char orientation) {
    coordinate = position;
    acc = acceleration;
    dir = orientation;
  }
}


Sensor[] sensors;

void setup() {
  size(1200, 750);
  footImage = loadImage("smoothfootoutline.png");
  cp5 = new ControlP5(this);
  
  // Initialize sensors
  sensors = new Sensor[4];
  sensors[0] = new Sensor(0.35, 0.25, "Medial Forefoot");
  sensors[1] = new Sensor(0.75, 0.3, "Lateral Forefoot");
  sensors[2] = new Sensor(0.4, 0.5, "Midfoot");
  sensors[3] = new Sensor(0.5, 0.9, "Heel");
  
  
  //draw the big ol title
  cp5.addTextlabel("appTitle")
    .setText("Smart Gait Analysis")
    .setPosition(400, 24)
    .setColorValue(color(0))
    .setFont(createFont("Arial Bold", 48));
  
  // Set up pressure charts
  setupCharts();
  
  //SETUP SECTIONS BUTTONS
  setupSections();
  
  // Set up input fields SECTION 1
  setupInputFields();
  
  // Set up the gait metrics for SECTION 1
  setupMetricsDisplay();
  
  //setup section 2
  setupForceMeasurementsDisplay();
  
  //SETUP SECTION 4
  setupJumpMetricsGroup();
  
  // Simulate jump detection (replace with real sensor input)
  cp5.addButton("simulateJump")
     .setPosition(400, 480)
     .setSize(150, 20)
     .setLabel("Simulate Jump");
  
  // Create heatmap buffer
  heatmap = createGraphics(footImage.width, footImage.height);
  
  // Initialize pressure history
  initializeHistory();
}

void updateForceDisplay(){
// Update display values
      for (int i = 0; i < 4; i++) {
        cp5.get(Textlabel.class, "sensor"+i+"Value").setText(nf(sensors[i].pressure, 1, 2));
      }
      
      // Calculate MFP (using your formula)
      MFP = (sensors[0].pressure + sensors[1].pressure) * 100 / 
            (sensors[0].pressure + sensors[1].pressure + sensors[2].pressure + sensors[3].pressure + 0.001);
      
      cp5.get(Textlabel.class, "mfpValue").setText(nf(MFP, 1, 2) + "%");
      
      // Determine gait pattern automatically based on MFP
      determineGaitPattern();
      cp5.get(Textlabel.class, "patternDisplay").setText(currentGaitPattern)
         .setColorValue(patternColor);
}

void draw() {
  background(210);
  // Foot visualization
  pushMatrix();
  image(footImage, 0, 0);
  updateHeatmap();
  image(heatmap, 0, 0);
  drawSensorMarkers();
  popMatrix();
  
  // Update charts
  updateCharts();
  updateMetricsDisplay();
  updateForceDisplay();
  if (isActive) {
    displayTime = millis() - startTime + elapsedTime;
  } else {
    displayTime = elapsedTime;
  }
  cp5.get(Textlabel.class, "timeValue").setText(nf(displayTime / 1000, 2) + "s");
  // SECTIONING 4 UPDATES
  // Update display with current values
  updateJumpMetrics();
  
  // Visual indicator
  if (isJumping) {
    fill(255, 100, 100, 150);
    ellipse(700, 420, 100 + jumpHeight * 100, 100 + jumpHeight * 100);
  }
  
  
  
  
  if (showSection1 != prevSection1) {
    if (showSection1) {
      //metricsGroup.show();
      stepLengthInput.show();
      strideLengthInput.show();
      strideWidthInput.show();
    } else {
      //metricsGroup.hide();
      stepLengthInput.hide();
      strideLengthInput.hide();
      strideWidthInput.hide();
    }
    prevSection1 = showSection1;
  }
  if (showSection2 != prevSection2) {
    if (showSection2) {
    forceMeasurements.show();
    } else {
    forceMeasurements.hide();
    }
    prevSection2 = showSection2;
  }
  if (showSection3 != prevSection3) {
    if (showSection3) {
    metricsGroup.show();
    } else {
    metricsGroup.hide();
    }
    prevSection3 = showSection3;
  }
  if (showSection4 != prevSection4) {
    if (showSection4) {
    jumpMetrics.show();
    } else {
    jumpMetrics.hide();
    }
    prevSection4 = showSection4;
  }
  
  
  // Simulate data changes
  if (frameCount % 10 == 0) {
    updatePressureHistory();
    randomizePressures();
    stepCount++;
  }
  //lines to section out the places to make it look pretty
  strokeWeight(5);
  stroke(10);
  line(350, 0, 350, 750);
}

//
// SETUP FOR ALL SECTIONS INCLUDING HEATMAP ================================================
// 

void updatePressureHistory() {
  for (int i = 0; i < sensors.length; i++) {
    pressureHistory[i][historyIndex] = sensors[i].pressure;
  }
  historyIndex = (historyIndex + 1) % pressureHistory[0].length;
}

void randomizePressures() {
  sensors[0].pressure = constrain(random(0.85, 0.95), 0, 1);
  sensors[1].pressure = constrain(random(0.55, 0.65), 0, 1);
  sensors[2].pressure = constrain(random(0.25, 0.35), 0, 1);
  sensors[3].pressure = constrain(random(0.9, 1.0), 0, 1);
  
  // Update gait metrics based on pressures
  cadence = map(sensors[0].pressure + sensors[1].pressure, 1.4, 1.6, 90, 130);
  speed = map(sensors[3].pressure, 0.8, 1.0, 1.0, 1.5);
}

void updateHeatmap() {
  heatmap.beginDraw();
    heatmap.loadPixels();
    
    for (int x = 0; x < footImage.width; x++) {
      for (int y = 0; y < footImage.height; y++) {
        if (alpha(footImage.get(x, y)) > 0) { // Only process foot area
          float totalInfluence = 0;
          
          // Convert to normalized coordinates
          float nx = norm(x, 0, footImage.width);
          float ny = norm(y, 0, footImage.height);
          
          // Combine sensor influences with Gaussian falloff
          for (Sensor s : sensors) {
            float dx = nx - s.position.x;
            float dy = ny - s.position.y;
            float distanceSq = dx*dx + dy*dy;
            float influence = exp(-distanceSq * 15) * s.pressure;
            totalInfluence += influence;
          }
          
          // Apply vibrant color mapping with transparency
          heatmap.pixels[y*footImage.width + x] = getVibrantHeatColor(totalInfluence);
        } else {
          heatmap.pixels[y*footImage.width + x] = color(0, 0, 0, 0); // Transparent
        }
      }
    }
    
    heatmap.updatePixels();
    heatmap.endDraw();
}

color getVibrantHeatColor(float pressure) {
  // Enhanced medical-grade color gradient
  color[] palette = {
    color(0, 0, 255, 100),    // Cool blue (low pressure)
    color(0, 128, 255, 150),  // Light blue
    color(0, 255, 0, 180),    // Green
    color(255, 255, 0, 210),  // Yellow
    color(255, 128, 0, 230),  // Orange
    color(255, 0, 0, 250)     // Red (high pressure)
  };
  
  pressure = constrain(pressure, 0, 1);
  float segment = 1.0/(palette.length-1);
  int index = min(floor(pressure/segment), palette.length-2);
  float lerpAmt = (pressure - index*segment)/segment;
  
  color base = palette[index];
  color next = palette[index+1];
  
  return color(
    lerp(red(base), red(next), lerpAmt),
    lerp(green(base), green(next), lerpAmt),
    lerp(blue(base), blue(next), lerpAmt),
    lerp(alpha(base), alpha(next), lerpAmt)
  );
}

void drawSensorMarkers() {
  for (Sensor s : sensors) {
    float px = s.position.x * footImage.width;
    float py = s.position.y * footImage.height;
    
    fill(0, 150);
    noStroke();
    ellipse(px, py, 20, 20);
    
    fill(255);
    textSize(14);
    text(nf(s.pressure, 1, 2), px-15, py+25);
  }
}



void updateCharts() {
  for (int i = 0; i < sensors.length; i++) {
    sensors[i].chart.push(sensors[i].name + "Pressure", sensors[i].pressure);
  }
}

//
// SETUP FOR SECTION 1 ================================================================================================
//
//

void setupSections() {
  // Create 4 toggle buttons
  cp5.addToggle("section1")
     .setPosition(400, 100)
     .setSize(100, 25)
     .setFont(createFont("Arial", 14))
     .setValue(true)
     .setCaptionLabel("Toggle Inputs")
     .setColorCaptionLabel(0)
     .setMode(ControlP5.SWITCH);
     
  cp5.addToggle("section2")
     .setPosition(590, 100)
     .setSize(100, 25)
     .setValue(true)
     .setFont(createFont("Arial", 14))
     .setCaptionLabel("Toggle Force")
     .setColorCaptionLabel(0)
     .setMode(ControlP5.SWITCH);
     
  cp5.addToggle("section3")
     .setPosition(780, 100)
     .setSize(100, 25)
     .setValue(true)
     .setFont(createFont("Arial", 14))
     .setCaptionLabel("Toggle Gait")
     .setColorCaptionLabel(0)
     .setMode(ControlP5.SWITCH);
     
  cp5.addToggle("section4")
     .setPosition(970, 100)
     .setSize(100, 25)
     .setValue(true)
     .setFont(createFont("Arial", 14))
     .setCaptionLabel("Toggle Jump")
     .setColorCaptionLabel(0)
     .setMode(ControlP5.SWITCH);
}


// Toggle control functions
void section1(boolean state) {
  showSection1 = state;
}

void section2(boolean state) {
  showSection2 = state;
}

void section3(boolean state) {
  showSection3 = state;
}

void section4(boolean state) {
  showSection4 = state;
}


void setupCharts() {
  int chartWidth = 150;
  int chartHeight = 150;
  int startX = 400;
  
  for (int i = 0; i < sensors.length; i++) {
    sensors[i].chart = cp5.addChart(sensors[i].name + " Chart")
      .setPosition(startX + i*(chartWidth + 40), 150)
      .setSize(chartWidth, chartHeight)
      .setRange(0, 1)
      .setView(Chart.LINE)
      .setStrokeWeight(1.5)
      .setColorCaptionLabel(color(0))
      .setColorBackground(color(255, 150));
    
    sensors[i].chart.addDataSet(sensors[i].name + "Pressure");
    sensors[i].chart.setColors(sensors[i].name + "Pressure", 
      color(255, 100, 100), color(200, 0, 0));
    sensors[i].chart.setData(sensors[i].name + "Pressure", new float[100]);
  }
}

void setupInputFields() {
  // Step Length Input
  stepLengthInput = cp5.addTextfield("stepLengthInput")
    .setPosition(400, 340)
    .setSize(150, 30)
    .setFont(createFont("Arial", 10))
    .setAutoClear(false)
    .setCaptionLabel("Step Length (m)")
    .setColorCaptionLabel(0)
    .setText(str(stepLength));
    
  // Stride Length Input  
  strideLengthInput = cp5.addTextfield("strideLengthInput")
    .setPosition(400, 385)
    .setSize(150, 30)
    .setFont(createFont("Arial", 10))
    .setAutoClear(false)
    .setCaptionLabel("Stride Length (m)")
    .setColorCaptionLabel(0)
    .setText(str(strideLength));
  
  // Stride Width Input  
  strideWidthInput = cp5.addTextfield("strideWidthInput")
    .setPosition(400, 430)
    .setSize(150, 30)
    .setFont(createFont("Arial", 10))
    .setAutoClear(false)
    .setCaptionLabel("Stride Width (m)")
    .setColorCaptionLabel(0)
    .setText(str(strideWidth));
}

void initializeHistory() {
  for (int i = 0; i < pressureHistory.length; i++) {
    for (int j = 0; j < pressureHistory[0].length; j++) {
      pressureHistory[i][j] = 0;
    }
  }
}

String isActive(boolean active) {
  if(active){
    return "In Motion";
  } else {
    return "Standing Still";
  }
}

void setupMetricsDisplay() {
  // Create metrics group with semi-transparent background
  metricsGroup = cp5.addGroup("metricsGroup")
    .setPosition(400, 525)
    .setWidth(340)
    .setBackgroundColor(color(255, 180))
    .setBackgroundHeight(200)
    .setLabel("")
    .moveTo("global");

  // Big title using Textlabel
  cp5.addTextlabel("metricsTitle")
    .setText("GAIT METRICS")
    .setPosition(10, 5)
    .setColorValue(color(0))
    .setFont(createFont("Arial Bold", 24))
    .moveTo(metricsGroup);

  // Cadence display
  cp5.addTextlabel("cadenceLabel")
    .setText("Cadence:")
    .setPosition(10, 30)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 14))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("cadenceValue")
    .setText(nf(cadence, 1, 0) + " steps/min")
    .setPosition(120, 30)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 14))
    .moveTo(metricsGroup);

  // Speed display  
  cp5.addTextlabel("speedLabel")
    .setText("Speed:")
    .setPosition(10, 60)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 14))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("speedValue")
    .setText(nf(speed, 1, 2) + " m/s")
    .setPosition(120, 60)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 14))
    .moveTo(metricsGroup);

  // Step count display
  cp5.addTextlabel("stepLabel")
    .setText("Step Count:")
    .setPosition(10, 90)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 14))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("stepValue")
    .setText(str(stepCount))
    .setPosition(120, 90)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 14))
    .moveTo(metricsGroup);
  //
  // Time Active display for SECTION 3
  //
  cp5.addTextlabel("activeLabel")
    .setText("Status:")
    .setPosition(10, 120)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 14))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("activeValue")
    .setText(isActive(isActive))
    .setPosition(120, 120)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 14))
    .moveTo(metricsGroup);
  cp5.addTextlabel("timeLabel")
    .setText("Time Active:")
    .setPosition(10, 150)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 14))
    .moveTo(metricsGroup);
  cp5.addTextlabel("timeValue")
    .setText(nf(displayTime / 1000, 2) + "s")
    .setPosition(120, 150)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 14))
    .moveTo(metricsGroup);
  //initially hide

}

void updateMetricsDisplay() {
  // Update dynamic values through ControlP5
  cp5.get(Textlabel.class, "cadenceValue").setText(nf(cadence, 1, 0) + " steps/min");
  cp5.get(Textlabel.class, "speedValue").setText(nf(speed, 1, 2) + " m/s");
  cp5.get(Textlabel.class, "stepValue").setText(str(stepCount));
  
}

//
// SETUP FOR SECTION2 ================================================================================================
//

void determineGaitPattern() {
  // Thresholds based on your research (adjust as needed)
  if (MFP < 30) {
    currentGaitPattern = "Heel Walking";
    patternColor = color(200, 100, 0); // Orange
  } 
  else if (MFP < 45) {
    currentGaitPattern = "Out-toeing";
    patternColor = color(200, 0, 200); // Purple
  }
  else if (MFP < 60) {
    currentGaitPattern = "Normal Gait";
    patternColor = color(0, 150, 0); // Green
  }
  else if (MFP < 75) {
    currentGaitPattern = "In-toeing";
    patternColor = color(0, 100, 200); // Blue
  }
  else {
    currentGaitPattern = "Tiptoeing";
    patternColor = color(200, 0, 0); // Red
  }
}


void setupForceMeasurementsDisplay() {
  // Create metrics group with semi-transparent background
  forceMeasurements = cp5.addGroup("forceMeasurements")
    .setPosition(765, 525)
    .setWidth(400)
    .setBackgroundColor(color(255, 180))
    .setBackgroundHeight(200)
    .setLabel("")
    .moveTo("global");
// Sensor readings display
  for (int i = 0; i < 4; i++) {
    String sensorName = "";
    switch(i) {
      case 0: sensorName = "Medial Midfoot"; break;
      case 1: sensorName = "Medial Forefoot"; break;
      case 2: sensorName = "Lateral Forefoot"; break;
      case 3: sensorName = "Heel"; break;
    }
    
    cp5.addTextlabel("sensor"+i+"Label")
      .setText(sensorName + ":")
      .setPosition(10, 30 + i*30)
      .setColorValue(0)
      .setFont(createFont("Arial", 12))
      .moveTo(forceMeasurements);
      
    cp5.addTextlabel("sensor"+i+"Value")
      .setText("0.00")
      .setPosition(150, 30 + i*30)
      .setColorValue(color(200, 0, 0))
      .setFont(createFont("Arial Bold", 12))
      .moveTo(forceMeasurements);
  }
  cp5.addTextlabel("forcemetricsTitle")
    .setText("FORCE METRICS")
    .setPosition(10, 5)
    .setColorValue(color(0))
    .setFont(createFont("Arial Bold", 24))
    .moveTo(forceMeasurements);
  // MFP display
  cp5.addTextlabel("mfpLabel")
    .setText("MEDIAL FORCE %:")
    .setPosition(10, 150)
    .setColorValue(0)
    .setFont(createFont("Arial Bold", 14))
    .moveTo(forceMeasurements);
    
  cp5.addTextlabel("mfpValue")
    .setText("0.00%")
    .setPosition(150, 150)
    .setColorValue(color(0, 150, 0))
    .setFont(createFont("Arial Bold", 16))
    .moveTo(forceMeasurements);
    
  // Gait pattern detection display
  cp5.addTextlabel("patternLabel")
    .setText("DETECTED PATTERN:")
    .setPosition(225, 60)
    .setColorValue(0)
    .setFont(createFont("Arial Bold", 14))
    .moveTo(forceMeasurements);
    
  cp5.addTextlabel("patternDisplay")
    .setText(currentGaitPattern)
    .setPosition(225, 80)
    .setColorValue(patternColor)
    .setFont(createFont("Arial Bold", 16))
    .moveTo(forceMeasurements);
  //initially hide
  forceMeasurements.hide();
  
}

///
/// SECTION 4 JUMPING ==================================================================
///

void setupJumpMetricsGroup() {
  // Create the jump metrics group
  jumpMetrics = cp5.addGroup("jumpMetrics")
    .setPosition(575, 325)
    .setWidth(585)
    .setBackgroundColor(color(255, 180))
    .setBackgroundHeight(180)
    .setLabel("")
    .moveTo("global");
  
  // Title
  cp5.addTextlabel("title")
     .setText("JUMP ANALYSIS")
     .setPosition(10, 5)
     .setColorValue(color(0))
     .setFont(createFont("Arial Bold", 24))
     .moveTo(jumpMetrics);
  
  // Current status
  cp5.addTextlabel("statusLabel")
     .setText("Status:")
     .setPosition(10, 35)
     .setColorValue(color(0))
     .setFont(createFont("Arial", 16))
     .moveTo(jumpMetrics);
     
  cp5.addTextlabel("statusValue")
     .setText("GROUNDED")
     .setPosition(100, 35)
     .setColorValue(color(200, 0, 0))
     .setFont(createFont("Arial Bold", 16))
     .moveTo(jumpMetrics);
  
  // Metrics grid
  String[] metrics = {"Height:", "Air Time:", "Power Output:"};
  String[] units = {" m", " s", " N"};
  
  for (int i = 0; i < metrics.length; i++) {
    // Labels
    cp5.addTextlabel("metric"+i+"Label")
       .setText(metrics[i])
       .setPosition(10, 70 + i*40)
       .setColorValue(color(0))
       .setFont(createFont("Arial", 14))
       .moveTo(jumpMetrics);
    
    // Values
    cp5.addTextlabel("metric"+i+"Value")
       .setText("0.00" + units[i])
       .setPosition(150, 70 + i*40)
       .setColorValue(color(0, 100, 200))
       .setFont(createFont("Arial Bold", 14))
       .moveTo(jumpMetrics);
  }
  
  // Counters
  cp5.addTextlabel("countLabel")
     .setText("Jump Count:")
     .setPosition(300, 70)
     .setColorValue(color(0))
     .setFont(createFont("Arial", 14))
     .moveTo(jumpMetrics);
     
  cp5.addTextlabel("countValue")
     .setText("0")
     .setPosition(420, 70)
     .setColorValue(color(200, 0, 0))
     .setFont(createFont("Arial Bold", 14))
     .moveTo(jumpMetrics);
     
  // Personal best
  cp5.addTextlabel("bestLabel")
     .setText("Personal Best:")
     .setPosition(300, 110)
     .setColorValue(color(0))
     .setFont(createFont("Arial", 14))
     .moveTo(jumpMetrics);
     
  cp5.addTextlabel("bestValue")
     .setText("0.00 m")
     .setPosition(420, 110)
     .setColorValue(color(0, 150, 0))
     .setFont(createFont("Arial Bold", 14))
     .moveTo(jumpMetrics);
}

void updateJumpMetrics() {
  // Update status
  cp5.get(Textlabel.class, "statusValue")
     .setText(isJumping ? "AIRBORNE" : "GROUNDED")
     .setColorValue(isJumping ? color(0, 150, 0) : color(200, 0, 0));
  
  // Update metrics
  cp5.get(Textlabel.class, "metric0Value").setText(nf(jumpHeight, 1, 2) + " m");
  cp5.get(Textlabel.class, "metric1Value").setText(nf(airTime, 1, 2) + " s");
  cp5.get(Textlabel.class, "metric2Value").setText(nf(peakForce, 1, 2) + " N");
  
  // Update counters
  cp5.get(Textlabel.class, "countValue").setText(str(jumpCount));
  cp5.get(Textlabel.class, "bestValue").setText(nf(personalBest, 1, 2) + " m");
}

void simulateJump() {
  // Simulate a jump with random values
  isJumping = true;
  jumpCount++;
  
  // Generate random jump metrics
  jumpHeight = random(0.2, 0.8);
  airTime = random(0.3, 0.7);
  peakForce = random(800, 1500);
  
  // Update personal best if needed
  if (jumpHeight > personalBest) {
    personalBest = jumpHeight;
  }
  
  // Simulate landing after delay
  new Thread(() -> {
    try {
      Thread.sleep(1000); // Simulate air time
      isJumping = false;
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }).start();
}

// Handle input field changes
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(stepLengthInput)) {
    stepLength = float(theEvent.getStringValue());
  } else if (theEvent.isFrom(strideLengthInput)) {
    strideLength = float(theEvent.getStringValue());
  }
}
