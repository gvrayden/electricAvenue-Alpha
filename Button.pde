boolean locked = false;
class Button
{
  int x, y;
  int size;
  String buttonText;
  boolean selected;
  float buttonWidth;
  float buttonHeight;
  color basecolor, highlightcolor;
  color currentcolor;
  boolean over = false;
  boolean pressed = false;   
  
  
  void update() 
  {
    if(over()) {
      currentcolor = highlightcolor;
    } 
    else {
      currentcolor = basecolor;
    }
  }

  boolean pressed(float xPos,float yPos) 
  {
    if (xPos >= x && xPos <= x+buttonWidth && 
      yPos >= y && yPos <= y+buttonHeight) 
      {
        print("button :"+buttonText+" clicked");
        println(buttonText+" pressed:"+pressed);
        println();
        if(pressed)
        {
          pressed = false;
          currentcolor = basecolor;
        }
        else{
          pressed = true;
          currentcolor = highlightcolor;
          
        }
        return true;
      } 
    else {
      return false;
    }
        
  }

  boolean over() 
  { 
    return true; 
  }

  boolean overRect(int x, int y, int width, int height) 
  {
    if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
      return true;
    } 
    else {
      return false;
    }
  }

}
class RectButton extends Button
{
  RectButton(int ix, int iy, int isize, color icolor, color ihighlight) 
  {
    x = ix;
    y = iy;
    size = isize;
    basecolor = icolor;
    highlightcolor = ihighlight;
    currentcolor = basecolor;
  }

  boolean over() 
  {
    if( overRect(x, y, size, size) ) {
      over = true;
      return true;
    } 
    else {
      over = false;
      return false;
    }
  }

  void display() 
  {
      noStroke();
    fill(currentcolor);
    rect(x, y, x+buttonWidth,y+buttonHeight);
    writeText();
  }
  void writeText(){
    fill(255);
    int x1 = x;
    int y1 = y;
    int x2 = ceil(x+buttonWidth);
    int y2 = ceil(y+buttonHeight);
    int xc = x1+((x2-x1)/2);
    int yc = y1-((y1-y2)/2);
    textAlign(CENTER);
    text(buttonText,xc,yc+5);
  }
}
