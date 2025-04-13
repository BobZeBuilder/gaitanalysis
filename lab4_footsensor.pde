import controlP5.*;

PImage footImage;
PGraphics heatmap;
ControlP5 cp5;

// Gait metrics
float stepLength = 0.72;
float strideLength = 1.44;
float cadence = 110;
float speed = 1.32;
int stepCount = 0;

// Pressure history
float[][] pressureHistory = new float[4][100];
int historyIndex = 0;

Textfield stepLengthInput, strideLengthInput;

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
  
  // Set up input fields
  setupInputFields();
  
  // Create heatmap buffer
  heatmap = createGraphics(footImage.width, footImage.height);
  
  // Initialize pressure history
  initializeHistory();
}

void setupCharts() {
  int chartWidth = 150;
  int chartHeight = 150;
  int startX = 400;
  
  for (int i = 0; i < sensors.length; i++) {
    sensors[i].chart = cp5.addChart(sensors[i].name + " Chart")
      .setPosition(startX + i*(chartWidth + 40), 300)
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
    .setPosition(800, 500)
    .setSize(150, 30)
    .setFont(createFont("Arial", 16))
    .setAutoClear(false)
    .setCaptionLabel("Step Length (m)")
    .setColorCaptionLabel(0)
    .setText(str(stepLength));
    
  // Stride Length Input  
  strideLengthInput = cp5.addTextfield("strideLengthInput")
    .setPosition(800, 550)
    .setSize(150, 30)
    .setFont(createFont("Arial", 16))
    .setAutoClear(false)
    .setCaptionLabel("Stride Length (m)")
    .setColorCaptionLabel(0)
    .setText(str(strideLength));
}

void initializeHistory() {
  for (int i = 0; i < pressureHistory.length; i++) {
    for (int j = 0; j < pressureHistory[0].length; j++) {
      pressureHistory[i][j] = 0;
    }
  }
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
  
  // Display metrics
  setupMetricsDisplay();
  
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

void updateCharts() {
  for (int i = 0; i < sensors.length; i++) {
    sensors[i].chart.push(sensors[i].name + "Pressure", sensors[i].pressure);
  }
}

void setupMetricsDisplay() {
  // Create metrics group with semi-transparent background
  Group metricsGroup = cp5.addGroup("metricsGroup")
    .setPosition(400, 500)
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
    .setPosition(10, 50)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("cadenceValue")
    .setText(nf(cadence, 1, 0) + " steps/min")
    .setPosition(120, 50)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 16))
    .moveTo(metricsGroup);

  // Speed display  
  cp5.addTextlabel("speedLabel")
    .setText("Speed:")
    .setPosition(10, 90)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("speedValue")
    .setText(nf(speed, 1, 2) + " m/s")
    .setPosition(120, 90)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 16))
    .moveTo(metricsGroup);

  // Step count display
  cp5.addTextlabel("stepLabel")
    .setText("Step Count:")
    .setPosition(10, 130)
    .setColorValue(color(0))
    .setFont(createFont("Arial", 16))
    .moveTo(metricsGroup);
    
  cp5.addTextlabel("stepValue")
    .setText(str(stepCount))
    .setPosition(120, 130)
    .setColorValue(color(0, 100, 200))
    .setFont(createFont("Arial Bold", 16))
    .moveTo(metricsGroup);
}

void updateMetricsDisplay() {
  // Update dynamic values through ControlP5
  cp5.get(Textlabel.class, "cadenceValue").setText(nf(cadence, 1, 0) + " steps/min");
  cp5.get(Textlabel.class, "speedValue").setText(nf(speed, 1, 2) + " m/s");
  cp5.get(Textlabel.class, "stepValue").setText(str(stepCount));
}


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

// Handle input field changes
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(stepLengthInput)) {
    stepLength = float(theEvent.getStringValue());
  } else if (theEvent.isFrom(strideLengthInput)) {
    strideLength = float(theEvent.getStringValue());
  }
}
