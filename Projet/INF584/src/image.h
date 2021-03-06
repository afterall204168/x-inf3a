/* loadppm.h
 *  v1.3 11.10.2005
 */

#ifndef __LOADPPM_H
#define __LOADPPM_H

#include <iostream>
#include <fstream>
#include <math.h>
#include "Vec3D.h"
#include <GL/glut.h>

using namespace std;

class Image {
public:
	int sizeX, sizeY;
	GLubyte *data;
	Image(const char *filename){
		load(filename);
	}
	Image() : sizeX(0),sizeY(0) {};
	Image(int x, int y): sizeX(x),sizeY(y) {
		data= new  GLubyte[3*sizeX * sizeY];
	};
	void resize(int x,int y){
		if (data)
			delete [] data;
		sizeX=x;
		sizeY=y;
		data= new GLubyte[3*sizeX * sizeY];
	}
	void load(const char *filename);
	~Image(){
		if (data)
			delete [] data;
	}
	inline float operator () (float x, float y, int color=0) const{
		if(x<0) x=0;
		if(x>=sizeX) x=sizeX-1;
		if(y<0) y=0;
		if(y>=sizeY) y=sizeY-1;
		int x0=(int)x;
		int y0=(int)y;
		return data[3*(y0*sizeX+x0)+color];
		return data[3*(y0+x0*sizeY)+color]*(x0+1-x)*(y0+1-y)+
				data[3*(y0+1+x0*sizeY)+color]*(x0+1-x)*(y0-y)+
				data[3*(y0+1+(x0+1)*sizeY)+color]*(x0-x)*(y0-y)+
				data[3*(y0+(x0+1)*sizeY)+color]*(x0-x)*(y0+1-y);
	}
	inline unsigned char& operator () (int x, int y, int color=0){
		if(x<0) x=0;
		if(x>=sizeX) x=sizeX-1;
		if(y<0) y=0;
		if(y>=sizeY) y=sizeY-1;
		return data[3*(x+y*sizeX)+color];
	}
	inline void set(int x, int y, const Vec3Df& color){
		if(color[0]<0)
			data[3*(x+y*sizeX)]=0;
		else if(color[0]>255)
			data[3*(x+y*sizeX)]=255;
		else data[3*(x+y*sizeX)]=(unsigned char)(color[0]);

		if(color[1]<0)
			data[3*(x+y*sizeX)+1]=0;
		else if(color[1]>255)
			data[3*(x+y*sizeX)+1]=255;
		else data[3*(x+y*sizeX)+1]=(unsigned char)(color[1]);

		if(color[2]<0)
			data[3*(x+y*sizeX)+2]=0;
		else if(color[2]>255)
			data[3*(x+y*sizeX)+2]=255;
		else data[3*(x+y*sizeX)+2]=(unsigned char)(color[2]);

	}
	inline float getInRealWorld(float x, float y, int color=0) const{
		return operator()(x*sizeX,y*sizeY,color);
	}
	inline bool estSous(const Vec3Df courant) const{
		return getInRealWorld(courant[0],courant[1])/255> courant[2];
	}

	inline float tangente(float x, float y, float theta) const{
		return (operator()(x*sizeX+1,y*sizeY,0)-operator()(x*sizeX,y*sizeY,0))*sizeX*cos(theta)+
			(operator()(x*sizeX,y*sizeY+1,0)-operator()(x*sizeX,y*sizeY,0))*sizeY*sin(theta);
	}
};


#endif
