#include <cutil.h>
#include <stdlib.h>
#include <iostream>
#include <cv.h>
#include <ctime>

#include "surfCUDA.h"

const int blocksize = 6;

__global__ void CUDAmakeIntegralImageLignes(uint* a, int width, int height, int pitch ) {
  int n = blockIdx.x * blockDim.x*blockDim.y+blockIdx.y*blockDim.y*blockDim.x*gridDim.x + threadIdx.x + threadIdx.y*blockDim.x;
  uint tmp=0;
  if ( n>=0 && n<height ){
  	for(uint i=0;i<width;i++){
		tmp+= ((uint*)((char*)a + pitch*n))[i];
		((uint*)((char*)a + pitch*n))[i]=tmp;
  	}
  }
}

__global__ void CUDAmakeIntegralImageColonnes(uint* a, int width, int height, int pitch ) {
  int n = blockIdx.x * blockDim.x*blockDim.y+blockIdx.y*blockDim.y*blockDim.x*gridDim.x + threadIdx.x + threadIdx.y*blockDim.x;
  uint tmp=0;
  if ( n>=0 && n<width ){
  	for(uint i=0;i<height;i++){
		tmp+= ((uint*)((char*)a + pitch*i))[n];
		((uint*)((char*)a + pitch*i))[n]=tmp;
  	}
  }
}

void CUDAmakeIntegralImage(const IplImage* in, IplImage* out){
	if(in->depth!=IPL_DEPTH_8U || out->depth!=IPL_DEPTH_32S){
		std::cout << "Mauvais type d'images dans CUDAmakeIntegralImage" << std::endl;
		exit(EXIT_FAILURE);
	}
	//copie d'une image U8 vers une S32
	cvConvert(in, out);
	
	clock_t timer=clock();
	//copie sur le device
	if(cudaSuccess != cudaMemcpy2D(CUDAintegral,CUDAintegralPitch,out->imageData,out->widthStep,
			out->width*sizeof(unsigned int),out->height,cudaMemcpyHostToDevice))
			std::cout << "erreur allocation" << std::endl;
			
	std::cout << "CUDAmakeIntegralImage : " << 1000*(clock()-timer)/CLOCKS_PER_SEC <<"ms"<< std::endl;
	
	//lancement des calculs
	{
	  dim3 dimBlock( blocksize, blocksize );
	  int tmp=(int)(sqrt(in->height/(float)(blocksize*blocksize))+1);
      dim3 dimGrid( tmp,tmp);
      std::cout << "threads pr les lignes " << blocksize*blocksize*tmp*tmp << std::endl;
      CUDAmakeIntegralImageLignes<<<dimGrid, dimBlock>>>( CUDAintegral, in->width, in->height , CUDAintegralPitch );
	  cudaThreadSynchronize();
	}
	{
	  dim3 dimBlock( blocksize, blocksize );
	  int tmp=(int)(sqrt(in->width/(float)(blocksize*blocksize))+1);
      dim3 dimGrid( tmp,tmp);
      std::cout << "threads pr les colonnes " <<  blocksize*blocksize*tmp*tmp << std::endl;
      CUDAmakeIntegralImageColonnes<<<dimGrid, dimBlock>>>( CUDAintegral, in->width, in->height , CUDAintegralPitch );
	  cudaThreadSynchronize();
	}
	//recuperation depuis le device
	if(cudaSuccess != cudaMemcpy2D(out->imageData,out->widthStep,CUDAintegral,CUDAintegralPitch,
			out->width*sizeof(unsigned int),out->height,cudaMemcpyDeviceToHost))
			std::cout << "erreur copie" << std::endl;
			
	std::cout << "CUDAmakeIntegralImage : " << 1000*(clock()-timer)/(double)CLOCKS_PER_SEC <<"ms"<< std::endl;
}
