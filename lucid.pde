import processing.net.*;
import omicronAPI.*;

OmicronAPI omicronManager;
TouchListener touchListener;


// For the Commons Wall

// Link to this Processing applet - used for touchDown() callback example
PApplet applet;

// Override of PApplet init() which is called before setup()
public void init() {
  super.init();
  
  // Creates the OmicronAPI object. This is placed in init() since we want to use fullscreen
  omicronManager = new OmicronAPI(this);
  
  // Removes the title bar for full screen mode (present mode will not work on Cyber-commons wall)
  omicronManager.setFullscreen(true);
}

int scaleFactor = 2;
// 5 for cyber-commons
// 2 for full screen macbook




FloatTable data;
HashMap<String,FloatTable> datasets = new HashMap<String,FloatTable>();
float dataMin, dataMax;
String[] fileNameArray = {"TPEP1","TPEC","TCDE","TREP","PCCDE","TPECPC"};
HashMap<String,String> labelArray = new HashMap<String,String>();
HashMap<String,Float> intervalMap = new HashMap<String,Float>();
String currentLabel;

float plotX1, plotY1;
float plotX2, plotY2;
float labelX, labelY;

int rowCount;
int columnCount;
int currentColumn = 0;

int yearMin, yearMax;
int[] years;

int yearInterval = 2;
int volumeInterval = 100;
int volumeIntervalMinor = 5;

PFont plotFont; 
Integrator[] interpolators;

ArrayList<RectButton> buttonArray;


float buttonHeight = 10*scaleFactor;//20;//30;
float buttonWidth = 50*scaleFactor;
float buttonPadding = 5*scaleFactor;
color currentcolor;
float maxButtonX;


int canvasX = 800*(scaleFactor/2);
int canvasY = 600*(scaleFactor/2);

void setup() {
  size(canvasX,canvasY);
  
  //SETTING UP STUFF FOR OMICRON
  size(1024,768); //size for laptop
        //size( 8160, 2304, P3D ); //for commons wall
  // Make the connection to the tracker machine
  //omicronManager.ConnectToTracker(7001, 7340, "131.193.77.104");
  
  // Create a listener to get events
  touchListener = new TouchListener();
  
  // Register listener with OmicronAPI
  omicronManager.setTouchListener(touchListener);

  // Sets applet to this sketch
  applet = this;
  //END OF OMICRON SETUP
  setupData();
  loadDataSets();
  // Corners of the plotted time series
  plotX1 = 60*scaleFactor; 
  plotX2 = width - 80*scaleFactor;
  labelX = 30*scaleFactor;
  plotY1 = 30*scaleFactor;
  plotY2 = height - 140 - 15*scaleFactor;
  labelY = height - 100 - 5*scaleFactor;
  //setting up buttons
  //dataset buttons
  createButtons();
  //Set Font
  plotFont = createFont("SansSerif", 10*scaleFactor);
  textFont(plotFont);

  smooth();
}

//Sets up data init
void setupData(){
  
  if(data==null){
    data = new FloatTable("TPEP1.csv");
    data.label = "TPEP1";
  } 
  rowCount = data.getRowCount();
  columnCount = data.getColumnCount();
  
  years = int(data.getRowNames());
  yearMin = years[0];
  yearMax = years[years.length - 1];
  dataMin = 0;
  dataMax = ceil(data.getTableMax() / volumeInterval) * volumeInterval;

  //setting up interpolators
  interpolators = new Integrator[rowCount];
  for (int row = 0; row < rowCount; row++) {
    float initialValue = data.getFloat(row, 0);
    interpolators[row] = new Integrator(initialValue);
    interpolators[row].attraction = 0.3;  // Set lower than the default
  }
  
}

//Call to load all datasets in an arraylist-TODO change to Hashmap
void loadDataSets(){
  for(int i=0;i<6;i++){      
      String filename = fileNameArray[i];
      FloatTable energyData = new FloatTable(filename+".csv");
      datasets.put(filename,energyData);
  }
  //Y Axis Labels for datasets
  labelArray.put("TPEP1","Total \nPrimary Energy \nProduction\n in\n Quadrillion Btu");
  labelArray.put("TPEC","Total \nPrimary Energy \nConsumption\n in\n Quadrillion Btu");
  labelArray.put("TCDE","Total \nCarbon Dioxide\n Emissions\n in\n Million\n Metric Tons");
  labelArray.put("TREP","Total \nRenewable Electricity\n Net Generation\n in\n Billion KWH");
  labelArray.put("PCCDE","Per Capita\n Carbon Dioxide\n Emissions\n in\n Metric\n Ton/Person");
  labelArray.put("TPECPC","Total \nPrimary Energy \nConsumption\n Per Capita\n in\n Million\n Btu/Person");
  
  //Y Axis Intervals for datasets
  intervalMap.put("TPEP1",100.0);
  intervalMap.put("TPEC",100.0);
  intervalMap.put("TCDE",10000.0);
  intervalMap.put("TREP",10.0);
  intervalMap.put("PCCDE",10.0);
  intervalMap.put("TPECPC",200.0);
}

//Begin draw functions
void draw() {
  background(0);
  omicronManager.process();
  
  // Show the plot area as a white box  
  fill(0);
  rectMode(CORNERS);
  noStroke();
  rect(plotX1, plotY1, plotX2, plotY2);

  drawTitle();
  drawAxisLabels();
  
  drawYearLabels();
  drawVolumeLabels();

  stroke(#5679C1);
  strokeWeight(5);
  for (int row = 0; row < rowCount; row++) { 
  interpolators[row].update();  
  }
  
  drawDataLine(currentColumn);
  drawButtons();
 
}


void drawTitle() {
  fill(255);
  textSize(20);
  textAlign(LEFT);
  String title = data.getColumnName(currentColumn);
  text(title, plotX1, plotY1 - 10);
}


void drawAxisLabels() {
    String yAxisLabel=null;
    if(currentLabel == null)
      yAxisLabel = labelArray.get("TPEP1");
    else
      yAxisLabel = currentLabel;
    fill(255);
    textSize(13);
    textLeading(15);
    
    textAlign(CENTER, CENTER);
    // Use \n (enter/linefeed) to break the text into separate lines
    text(yAxisLabel, labelX, (plotY1+plotY2)/2);
    textAlign(CENTER);
    text("Year", (plotX1+plotX2)/2, labelY);
}


void drawYearLabels() {
  fill(255);
  textSize(10);
  textAlign(CENTER, TOP);
  
  // Use thin, gray lines to draw the grid
  stroke(224);
  strokeWeight(1);
  
  for (int row = 0; row < rowCount; row++) {
    if (years[row] % yearInterval == 0) {
      float x = map(years[row], yearMin, yearMax, plotX1, plotX2);
      text(years[row], x, plotY2 + 10);
      line(x, plotY1, x, plotY2);
    }
  }
}


void drawVolumeLabels() {
  fill(255);
  textSize(10);
  
  stroke(128);
  strokeWeight(1);
  volumeInterval = ceil(intervalMap.get(data.label));
  
  for (float v = dataMin; v <= dataMax; v += volumeIntervalMinor) {
    if (v % volumeIntervalMinor == 0) {     // If a tick mark
      float y = map(v, dataMin, dataMax, plotY2, plotY1);  
      if (v % volumeInterval == 0) {        // If a major tick mark
        if (v == dataMin) {
          textAlign(RIGHT);                 // Align by the bottom
        } else if (v == dataMax) {
          textAlign(RIGHT, TOP);            // Align by the top
        } else {
          textAlign(RIGHT, CENTER);         // Center vertically
        }
        text(floor(v), plotX1 - 10, y);
        line(plotX1 - 4, y, plotX1, y);     // Draw major tick
      } else {
        // Commented out, too distracting visually
        //line(plotX1 - 2, y, plotX1, y);   // Draw minor tick
      }
    }
  }
}


void drawDataPoints(int col) {
  for (int row = 0; row < rowCount; row++) {
    if (data.isValid(row, col)) {
      float value = data.getFloat(row, col);
      float x = map(years[row], yearMin, yearMax, plotX1, plotX2);
      float y = map(value, dataMin, dataMax, plotY2, plotY1);
      point(x, y);
    }
  }
}


void drawDataLine(int col) {
  noFill();  
  beginShape();
  for (int row = 0; row < rowCount; row++) {
    if (data.isValid(row, col)) {
      //float value = data.getFloat(row, col);
      float value = interpolators[row].value; 
      float x = map(years[row], yearMin, yearMax, plotX1, plotX2);
      float y = map(value, dataMin, dataMax, plotY2, plotY1);      
      vertex(x, y);
    }
  }
  endShape();
}


//Event

void keyPressed() {
  
  if (key == '[') {
    currentColumn--;
    if (currentColumn < 0) {
      currentColumn = columnCount - 1;
    }
  } else if (key == ']') {
    currentColumn++;
    if (currentColumn == columnCount) {
      currentColumn = 0;
    }
  }
  else if(key == '0'){
    currentColumn = 0;
  }
   setCurrent(currentColumn);
}
void setCurrent(int col) {
  currentColumn = col;  
  for (int row = 0; row < rowCount; row++) 
  {    
    interpolators[row].target(data.getFloat(row, col));  
  } 
}

//draw buttons
void createButtons(){
  buttonArray= new ArrayList<RectButton>();
  color baseColor = color(102);
  currentcolor = baseColor;
  color buttoncolor = color(204);
  color highlight = color(153);
  buttoncolor = color(102);
  highlight = color(51); 
  int rect1X1 = ceil(plotX1);
  int rect1Y1 = ceil(labelY+20);
  RectButton rect1;
  for(int i=0;i<6;i++){
      int rectX1 = int(plotX1+(buttonWidth+buttonPadding)*i);
      int rectY1 =0;
      if(i<3)
        rectY1 = ceil(labelY+20);
      else{
        rectX1 = ceil(plotX1+(buttonWidth+buttonPadding)*(i-3));
        rectY1 = ceil(labelY+50);
      }
      rect1 = new RectButton(rectX1,rectY1, 10, buttoncolor, highlight);
      rect1.buttonWidth = buttonWidth;
      rect1.buttonHeight = buttonHeight;
      rect1.buttonText = fileNameArray[i];
      buttonArray.add(rect1);
  }
}

//display Buttons
void drawButtons(){
  for(RectButton btn : buttonArray){
    btn.display();
  }
}

//MOUSE/TOUCH UPDATES FOR BUTTONS - used in touchdown
void updateTouchDown(float x, float y)
{
   for(Button btn : buttonArray){
     if(btn.pressed(x,y)){
       currentcolor = btn.highlightcolor;
       data = datasets.get(btn.buttonText);
       data.label = btn.buttonText;
       currentLabel = labelArray.get(btn.buttonText);
       setupData();
     }
   }
   resetOtherButtons();
}
void resetOtherButtons(){
  String   btnText = data.label;
  for(Button btn: buttonArray){
    if(!btn.buttonText.equals(btnText)){
      btn.currentcolor = btn.basecolor;
    }
  }
}

//For Touch interaction

//omicron specific code here
void touchDown(int ID, float xPos, float yPos, float xWidth, float yWidth){
  noFill();
  stroke(255,0,0);
  ellipse( xPos, yPos, xWidth * 2, yWidth * 2 );
  updateTouchDown(xPos,yPos);
}// touchDown

void touchMove(int ID, float xPos, float yPos, float xWidth, float yWidth){
  noFill();
  stroke(0,255,0);
  ellipse( xPos, yPos, xWidth * 2, yWidth * 2 );
}// touchMove

void touchUp(int ID, float xPos, float yPos, float xWidth, float yWidth){
  noFill();
  stroke(0,0,255);
  ellipse( xPos, yPos, xWidth * 2, yWidth * 2 );
}// touchUp
