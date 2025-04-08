PGraphics heatmap;
PGraphics footMask;
PImage img;
PVector[] sensorPositions = new PVector[4];
color[] heatmapColors = new color[4];

void setup() {
  size(1400, 750);
  colorMode(HSB, 360, 100, 100); // Using HSB for smooth color transitions
  img = loadImage("smoothfootoutline.png"); // Load the image. Ensure it's in the 'data' folder
  // Initialize sensor positions (adjust these to match your physical setup)
  sensorPositions[0] = new PVector(130, 340); // Heel
  sensorPositions[1] = new PVector(210, 280); // Midfoot lateral
  sensorPositions[2] = new PVector(170, 180); // Forefoot
  sensorPositions[3] = new PVector(110, 270); // Midfoot medial
  
  // Initialize color gradient (blue to red)
  for(int i = 0; i < 4; i++) {
    heatmapColors[i] = color(240 - (i*60), 90, 90);
  }
  
  heatmap = createGraphics(width, height);

}


void drawHeatmap(float[] sensorValues) {
  heatmap.beginDraw();
  heatmap.clear();
  heatmap.noStroke();
  heatmap.colorMode(HSB, 360, 100, 100);
  
  for(int i = 0; i < 4; i++) {
    float intensity = map(sensorValues[i], 0, 1023, 0, 100);
    float radius = map(sensorValues[i], 0, 1023, 20, 100);
    
    // Create radial gradient effect
    for(int r = 0; r < radius; r++) {
      float alpha = map(r, 0, radius, 90, 10);
      heatmap.fill(240 - (intensity*2.4), 90, 90, alpha);
      heatmap.ellipse(sensorPositions[i].x, sensorPositions[i].y, r*2, r*2);
    }
  }
  heatmap.endDraw();
}

void draw() {
  background(255);
   image(img, 0, 0); // Display the image at the top-left corner of the canvas
  // Simulated sensor readings (replace with actual analog inputs)
  float[] fakeReadings = new float[4];
  for(int i = 0; i < 4; i++) {
    fakeReadings[i] = map(noise(millis()*0.001 + i), 0, 1, 0, 1023); // Animated noise values for demo
  }
  
  drawHeatmap(fakeReadings);
  image(heatmap, 0, 0);
}
