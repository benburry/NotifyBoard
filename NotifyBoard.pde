/*
Copyright 2010 Charles Yarnold charlesyarnold@gmail.com
 
 NotifyBoard is free software: you can redistribute it and/or modify it under the terms of
 the GNU General Public License as published by the Free Software Foundation, either
 version 3 of the License, or (at your option) any later version.
 
 NotifyBoard is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with NotifyBoard.
 If not, see http://www.gnu.org/licenses/.
 
 */

/*
This sketch requires the arduino Library from:
 http://github.com/solexious/MatrixDisplay
 
 Version 0.4
 */

#include <SPI.h>
#include <Ethernet.h>
#include <TimedAction.h>
#include "MatrixDisplay.h"
#include "DisplayToolbox.h"
#include "font.h"

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 101, 250 };
byte gateway[] = { 192, 168, 100, 1 };
byte subnet[] = { 255, 255, 254, 0 };
int PORT = 3333;

void scroll();
void initText(void);
void drawString(int x, int y, char* c);


// Easy to use function
#define setMaster(dispNum, CSPin) initDisplay(dispNum,CSPin,true)
#define setSlave(dispNum, CSPin) initDisplay(dispNum,CSPin,false)

// 4 = Number of displays
// Data = 5
// WR == 6
// False - we dont need a shadow buffer for this example. saves 50% memory!

// Init Matrix
MatrixDisplay disp(4, 6, 5, false);
// Pass a copy of the display into the toolbox
DisplayToolbox toolbox(&disp);

// Text settings
int x;
boolean scrolling;
int minLeft;

// Prepare boundaries
int X_MAX = 0;
int Y_MAX = 0;

//serial in stuff
#define INLENGTH 162
char inString[INLENGTH+1];
char inSerialString[INLENGTH+1];
int inCount;

TimedAction timedAction = TimedAction(35, scroll);
Server server(PORT);

void setup() 
{
  // initialize the ethernet device
  Ethernet.begin(mac, ip, gateway, subnet);
  // start listening for clients
  server.begin();
  
  Serial.begin(9600); 
  Serial.print("Listening on ");
  Serial.print(ip[0], DEC);
  Serial.print(".");
  Serial.print(ip[1], DEC);
  Serial.print(".");
  Serial.print(ip[2], DEC);
  Serial.print(".");
  Serial.print(ip[3], DEC);
  Serial.print(":");
  Serial.println(PORT, DEC);
  
  timedAction.disable();

  // Fetch bounds
  X_MAX = disp.getDisplayCount() * disp.getDisplayWidth();
  Y_MAX = disp.getDisplayHeight();

  // Prepare displays
  // The first number represents how the buffer/display is stored in memory. Could be useful for reorganising the displays or matching 
  // he physical layout
  // The number is a array index and is sequential from 0. You can't use 4-8. You must use the numbers 0-4
  disp.setMaster(0, 8);
  disp.setSlave(1, 7);
  disp.setSlave(2, 3);
  disp.setSlave(3, 2);

  // pin13 LED
  pinMode(13, OUTPUT);

  // INITALISE
  initText();
}

//************************ START LOOP **********************

void loop()
{
  // wait for a new client:
  Client client = server.available();

  if (client)
  {
    Serial.println("New data received");
    inCount = 0;
    do 
    {
      inSerialString[inCount] = client.read(); // get it
      if (inSerialString[inCount] == 10) break;
      if (inCount > INLENGTH) break;
      if (inSerialString[inCount] > 0 ) inCount++;
    } 
    while (1==1);

    inSerialString[inCount] = 0;

    for(int a=0; a<162; a++)
    {
      inString[a] = inSerialString[a];
    }

    timedAction.disable();
    if (strlen(inString) < 21)
    {
      x = floor ((128 - ((strlen(inString)*6) - 1)) / 2);
      scrolling = false;
      minLeft = 0;
    }
    else
    {
      x = X_MAX;
      scrolling = true;
      minLeft = 0 - (strlen(inString)*6);
    }

    digitalWrite(13, LOW);       // turn on pullup resistors

    disp.clear();
    drawString(x,0,inString);
    disp.syncDisplays(); 

    Serial.print("Displaying: ");
    Serial.println(inString);
    if (scrolling) timedAction.enable();
  }
  timedAction.check();
}
// ******************************** END LOOP **********************************

void drawChar(int x, int y, char c)
{
  uint8_t dots;
  for (char col=0; col< 5; col++) {
    dots = pgm_read_byte_near(&myfont[c][col]);
    for (char row=0; row < 8; row++) {
      if (x+col<0)
      {

      }
      else if (dots & (0x80>>row))   	     // only 7 rows.
        toolbox.setPixel(x+col, y+row, 1);
      else 
        toolbox.setPixel(x+col, y+row, 0);
    }
  }
}


// Write out an entire string (Null terminated)
void drawString(int x, int y, char* c)
{
  for(char i=0; i< strlen(c); i++)
  {
    if(x>-6)
    {
      if(x<X_MAX)
      {
        drawChar(x, y, c[i]);
      }
    }
    x+=6; // Width of each glyph
  }
}

void fadeIn(void)
{
  for(int i=0; i<16; ++i) // The displays have 15 different brightness settings
  {
    // This will set the brightness for ALL displays
    toolbox.setBrightness(i);
    // Alternatively you could set them individually
    // disp.setBrightness(displayNumber, i);
    delay(200); // Let's wait a bit or you'll miss it!
  }
}

void initText(void)
{
  drawString(0,0,"The Mosh Pit");
  disp.syncDisplays(); 
  fadeIn();
  disp.clear();
  drawString(0,0,"NotificationBoard 0.1");
  disp.syncDisplays(); 
  fadeIn();
  disp.clear();
  delay(100);
  drawString(0,0,"Loading, Please wait");
  disp.syncDisplays();
  delay(500);
  disp.clear();
  disp.syncDisplays(); 
  delay(500);
  drawString(0,0,"Loading, Please wait");
  disp.syncDisplays(); 
  delay(500);
  disp.clear();
  disp.syncDisplays(); 
  delay(500);
  drawString(0,0,"Loading, Please wait");
  disp.syncDisplays(); 
  delay(500);
  disp.clear();
  disp.syncDisplays(); 
  delay(500);
  disp.clear();
  drawString(0,0,"Ready for input");
  disp.syncDisplays(); 
  fadeIn();
  disp.clear();
  disp.syncDisplays(); 
}

void scroll()
{
  x--;
  if (x<minLeft) x = X_MAX;
  disp.clear();
  drawString(x,0,inString);
  disp.syncDisplays();
}







