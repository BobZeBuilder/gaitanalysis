PGraphics heatmap;
PGraphics footMask;
PVector[] sensorPositions = new PVector[4];
color[] heatmapColors = new color[4];

void setup() {
  size(1200, 800);
  colorMode(HSB, 360, 100, 100); // Using HSB for smooth color transitions
  
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
  footMask = createFootMask();
}

PGraphics createFootMask() {
  PGraphics mask = createGraphics(width, height);
  mask.beginDraw();
  mask.background(0);
  mask.fill(255);
  mask.noStroke();
  mask.beginShape();
  mask.vertex(100, 350);
  mask.bezierVertex(80, 320, 110, 180, 200, 150);
  mask.bezierVertex(280, 180, 320, 300, 250, 380);
  mask.bezierVertex(200, 400, 120, 380, 100, 350);
  mask.endShape(CLOSE);
  mask.endDraw();
  return mask;
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
  
  // Simulated sensor readings (replace with actual analog inputs)
  float[] fakeReadings = new float[4];
  for(int i = 0; i < 4; i++) {
    fakeReadings[i] = map(noise(millis()*0.001 + i), 0, 1, 0, 1023); // Animated noise values for demo
  }
  
  drawHeatmap(fakeReadings);
  heatmap.mask(footMask);
  image(heatmap, 0, 0);
  
  // Draw foot outline for reference
  noFill();
  stroke(0);
  beginShape();
  vertex(100, 350);
  bezierVertex(80, 320, 110, 180, 200, 150);
  bezierVertex(280, 180, 320, 300, 250, 380);
  bezierVertex(200, 400, 120, 380, 100, 350);
  endShape(CLOSE);
}
