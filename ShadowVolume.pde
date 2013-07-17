//GPUないとうごかないぽよ
import javax.media.opengl.GL2;
//import ddf.minim.*;

final int S_VOL = 3;//影の長さ
final int V_SIZE = 50;//ステンシルのサイズ
final int G_SIZE = 200;//地面のタイルのサイズ

GL2 gl;
PGraphicsOpenGL pgl;
//Minim minim;
//AudioPlayer ap;
boolean onPause = true;
float[][][] vert = new float[9][4][3];
float[][] ground = new float[18][18];

void setup() {
  size(1024, 768, OPENGL);
  
  //minim = new Minim(this);
  //ap = minim.loadFile("ftnw.mp3");
  //ap.play();
  
  pgl = (PGraphicsOpenGL) g;
  gl = pgl.beginPGL().gl.getGL2();

  //gl.glEnable(GL2.GL_LIGHTING);
  //gl.glEnable(GL2.GL_LIGHT0);
  gl.glEnable(GL2.GL_DEPTH_TEST);
  
  for(int i = 0; i < 3; i++){
    for(int j = 0; j < 3; j++){
      vert[i*3+j][0][0] = (i-1) * 80 + 20;
      vert[i*3+j][0][1] = 0;
      vert[i*3+j][0][2] = (j-1) * 80 - 20;
      
      vert[i*3+j][1][0] = (i-1) * 80 - 20;
      vert[i*3+j][1][1] = 0;
      vert[i*3+j][1][2] = (j-1) * 80 - 20;
      
      vert[i*3+j][2][0] = (i-1) * 80 - 20;
      vert[i*3+j][2][1] = 0;
      vert[i*3+j][2][2] = (j-1) * 80 + 20;
      
      vert[i*3+j][3][0] = (i-1) * 80 + 20;
      vert[i*3+j][3][1] = 0;
      vert[i*3+j][3][2] = (j-1) * 80 + 20;
    }
  }
  
  for(int i = 0; i < 18; i++){
    for(int j = 0; j < 18; j++){
      ground[i][j] = random(100) + 120;
    }
  }
}

void draw() {
  if (!onPause) {
    frameCount--;
    return;
  }
  
  background(255, 192, 128);
  translate(width/2, height/2);
  
  float cangle = 0.0005 * frameCount;
  float cam[] = {
    800.0 * cos(cangle), -120, 800.0 * sin(cangle)
  };
  camera(
    cam[0], cam[1], cam[2], 
    0.0, 0.0, 0.0, 
    0.0, 10.0, 0.0
  );

  float langle = 0.01 * frameCount;
  float light[] = {
    400.0 * cos(langle), -200.0, 400.0 * sin(langle), 0.0
  };

  pgl.beginPGL();
  gl.glClear(GL2.GL_COLOR_BUFFER_BIT | GL2.GL_DEPTH_BUFFER_BIT | GL2.GL_STENCIL_BUFFER_BIT);
  gl.glClearStencil(0);
  
  drawBack(cangle);
  
  gl.glLightfv(GL2.GL_LIGHT0, GL2.GL_POSITION, light, 0);
  gl.glColor4f(1.0, 1.0, 1.0, 1.0);
  drawCube(light[0], light[1], light[2], 10);
  
  gl.glColor4f(0.0, 0.3, 0.5, 0.8);
  drawGround();
  
  gl.glColor4f(1.0, 0.6, 0.6, 1.0);
  for(int i = 0; i < 9; i++){
    drawPolygon(vert[i]);
  }
  
  gl.glColor4f(0.0, 0.0, 0.0, 1.0);
  for(int i = 0; i < 9; i++){
    drawShadow(light, vert[i]);
  }
  
  drawStencil(light, vert[5]);
  
  pgl.endPGL();
}

void drawShadow(float[] light, float[][] vert){
  //ステンシルテストを有効にする
  //gl.glDisable(GL2.GL_LIGHTING);
  gl.glEnable(GL2.GL_STENCIL_TEST);
  
  //これ以降描画を行わない
  gl.glColorMask(false, false, false, false);
  gl.glDepthMask(false);
  
  //片面表示を有効にする
  gl.glEnable(GL2.GL_CULL_FACE);
  
  //ステンシル; どんなときも表示
  gl.glStencilFunc(GL2.GL_ALWAYS, 1, ~0);
  //デプステストに失敗した場合, ステンシル値を+1
  gl.glStencilOp(GL2.GL_KEEP, GL2.GL_INCR, GL2.GL_KEEP);
  
  //裏面だけのオブジェクトを描画
  gl.glCullFace(GL2.GL_BACK);
  drawShadowPolygon(light, vert);
  
  //デプステストに失敗した場合, ステンシル値を-1
  gl.glStencilOp(GL2.GL_KEEP, GL2.GL_DECR, GL2.GL_KEEP);
  
  //表面だけのオブジェクトを描画
  gl.glCullFace(GL2.GL_FRONT);
  drawShadowPolygon(light, vert);
  
  gl.glColorMask(true, true, true, true);
  gl.glDepthMask(true);
  
  //drawStencil(light, vert);
}

void drawShadowPolygon(float[] light, float[][] vert){
  gl.glBegin(GL2.GL_TRIANGLES);
    for(int i = 0; i < 4; i++){
      int j = (i + 1) % 4;
      gl.glVertex3f(light[0], light[1], light[2]);
      gl.glVertex3f(
        light[0] + (vert[i][0] - light[0]) * S_VOL, 
        light[1] + (vert[i][1] - light[1]) * S_VOL, 
        light[2] + (vert[i][2] - light[2]) * S_VOL
      );
      gl.glVertex3f(
        light[0] + (vert[j][0] - light[0]) * S_VOL, 
        light[1] + (vert[j][1] - light[1]) * S_VOL, 
        light[2] + (vert[j][2] - light[2]) * S_VOL
      );
    }
  gl.glEnd();
}

void drawStencil(float[] light, float[][] vert){
  gl.glColor4f(0.0, 0.0, 0.0, 0.5);
  gl.glStencilFunc(GL2.GL_EQUAL, 1, ~0);
  gl.glEnable(GL2.GL_BLEND);
  gl.glDisable(GL2.GL_CULL_FACE);
  gl.glBlendFunc(GL2.GL_SRC_ALPHA, GL2.GL_ONE_MINUS_SRC_ALPHA);
  
  drawInnerPolygon(light, vert);
  
  gl.glDisable(GL2.GL_BLEND);
  //gl.glEnable(GL2.GL_LIGHTING);
  gl.glDisable(GL2.GL_STENCIL_TEST);
  gl.glDisable(GL2.GL_CULL_FACE);
}

void drawPolygon(float[][] vert){
  if (vert.length == 2){
    gl.glBegin(GL2.GL_LINES);
  }else if (vert.length == 3){
    gl.glBegin(GL2.GL_TRIANGLES);
  }else if (vert.length == 4){
    gl.glBegin(GL2.GL_QUADS);
  }
  
  for(int i = 0; i < vert.length; i++){
    gl.glVertex3f(vert[i][0], vert[i][1], vert[i][2]);
  }
  gl.glEnd();
}

/*光源から見たオブジェクトの奥に一回り大きいオブジェクトの描画
*/
void drawInnerPolygon(float[] light, float[][] vert){
  float[] center = {
    (vert[0][0] + vert[1][0] + vert[2][0] + vert[3][0]) / 4,
    (vert[0][1] + vert[1][1] + vert[2][1] + vert[3][1]) / 4,
    (vert[0][2] + vert[1][2] + vert[2][2] + vert[3][2]) / 4
  };
  
  float[] tmp1 = {vert[1][0] - vert[2][0], vert[1][1] - vert[2][1], vert[1][2] - vert[2][2]};
  float[] tmp2 = {vert[1][0] - vert[0][0], vert[1][1] - vert[0][1], vert[1][2] - vert[0][2]};
  
  float[] normal = {
    tmp1[1] * tmp2[2] - tmp1[2] * tmp2[1], 
    tmp1[2] * tmp2[0] - tmp1[0] * tmp2[2],
    tmp1[0] * tmp2[1] - tmp1[1] * tmp2[0]
  };
  
  float[] e_normal = new float[3];
  for(int i = 0; i < 3; i++){
    if (normal[i] != 0){
      e_normal[i] = normal[i] / abs(normal[i]);
      if (light[i] > center[i]){
        e_normal[i] *= -1;
      }
      continue;
    }
    e_normal[i] = 0;
  }
  
  gl.glBegin(GL2.GL_QUADS);
    for(int i = 0; i < 4; i++){
      gl.glVertex3f(
        center[0] + (vert[i][0] - center[0]) * V_SIZE + e_normal[0], 
        center[1] + (vert[i][1] - center[1]) * V_SIZE + e_normal[1], 
        center[2] + (vert[i][2] - center[2]) * V_SIZE + e_normal[2]
      );
    }
    gl.glEnd();
}

void drawCube(float x, float y, float z, float size) {
  gl.glBegin(GL2.GL_QUADS);

  gl.glVertex3f(x-size, y-size, z-size);
  gl.glVertex3f(x-size, y+size, z-size);
  gl.glVertex3f(x-size, y+size, z+size);
  gl.glVertex3f(x-size, y-size, z+size);

  gl.glVertex3f(x+size, y-size, z-size);
  gl.glVertex3f(x+size, y+size, z-size);
  gl.glVertex3f(x+size, y+size, z+size);
  gl.glVertex3f(x+size, y-size, z+size);

  gl.glVertex3f(x-size, y-size, z-size);
  gl.glVertex3f(x+size, y-size, z-size);
  gl.glVertex3f(x+size, y-size, z+size);
  gl.glVertex3f(x-size, y-size, z+size);

  gl.glVertex3f(x-size, y+size, z-size);
  gl.glVertex3f(x+size, y+size, z-size);
  gl.glVertex3f(x+size, y+size, z+size);
  gl.glVertex3f(x-size, y+size, z+size);

  gl.glVertex3f(x-size, y-size, z-size);
  gl.glVertex3f(x-size, y+size, z-size);
  gl.glVertex3f(x+size, y+size, z-size);
  gl.glVertex3f(x+size, y-size, z-size);

  gl.glVertex3f(x-size, y-size, z+size);
  gl.glVertex3f(x-size, y+size, z+size);
  gl.glVertex3f(x+size, y+size, z+size);
  gl.glVertex3f(x+size, y-size, z+size);

  gl.glEnd();
}

void drawGround() {
  for(int i = 0; i < 17; i++){
    for(int j = 0; j < 17; j++){
      
      int i2 = i - 9;
      int j2 = j - 9;
      int i3 = i - 8;
      int j3 = j - 8;
      
      float[][] tmp1 = {
        {i2 * G_SIZE, ground[i][j], j2 * G_SIZE},
        {i3 * G_SIZE, ground[i+1][j], j2 * G_SIZE},
        {i2 * G_SIZE, ground[i][j+1], j3 * G_SIZE}
      };
      drawPolygon(tmp1);
      
      float[][] tmp2 = {
        {i3 * G_SIZE, ground[i+1][j+1], j3 * G_SIZE},
        {i3 * G_SIZE, ground[i+1][j], j2 * G_SIZE},
        {i2 * G_SIZE, ground[i][j+1], j3 * G_SIZE}
      };
      drawPolygon(tmp2);
      
      float[][] tmp3 = {
        {i2 * G_SIZE, ground[i][j], j2 * G_SIZE},
        {i3 * G_SIZE, ground[i+1][j], j2 * G_SIZE}
      };
      
      drawPolygon(tmp3);
      
      float[][] tmp4 = {
        {i2 * G_SIZE, ground[i][j], j2 * G_SIZE},
        {i2 * G_SIZE, ground[i][j+1], j3 * G_SIZE}
      };
      
      drawPolygon(tmp4);
      
      float[][] tmp5 = {
        {i3 * G_SIZE, ground[i+1][j], j2 * G_SIZE},
        {i2 * G_SIZE, ground[i][j+1], j3 * G_SIZE}
      };
      
      drawPolygon(tmp5);
    }
  }
}

void drawBack(float cangle){
  float a1 = cangle - PI / 4 + PI;
  float a2 = cangle + PI / 4 + PI;
  gl.glBegin(GL2.GL_QUADS);
    gl.glColor4f(0.0, 0.2 - 0.0001 * frameCount, 0.8 - 0.0001 * frameCount, 1.0);
    gl.glVertex3f(4800.0 * cos(a2), -2000, 4800.0 * sin(a2));
    gl.glVertex3f(4800.0 * cos(a1), -2000, 4800.0 * sin(a1));
    gl.glColor4f(1.0, 0.75, 0.5, 1.0);
    gl.glVertex3f(4800.0 * cos(a1), 600 + frameCount, 4800.0 * sin(a1));
    gl.glVertex3f(4800.0 * cos(a2), 600 + frameCount, 4800.0 * sin(a2));
  gl.glEnd();
}

void mouseClicked() {
  onPause = !onPause;
}

/*void stop(){
  ap.close();
  minim.stop();
  super.stop();
}*/

