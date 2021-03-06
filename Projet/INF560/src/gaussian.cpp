
#include "surf.h"

// Calcul de les derivees gaussiennes d'ordre 2
void calculateGaussianDerivative(const IplImage* imageIntegrale, IplImage** out, int octave, int intervals)
{
	// Calcul de la taille du filtre et des bordures
	int power = 1 ;
	for (int t=0 ; t<octave+1 ; t++)
	{
		power *= 2 ;
	}
	int borderSize = (3*(power*intervals + 1))/2+1  ;
	
	for (int inter=0 ; inter<intervals ; inter++)
	{
		// Calcul de la surface pour normalisation d'echelle
		int lobe = power*(inter+1) + 1 ;
		int area = (3*lobe) * (3*lobe) ;
		
		// Construction du filtre
		//int filtre[filterSize][filterSize] ;
		for (int y=borderSize ; y<(imageIntegrale->height)-borderSize ; y++)
			for (int x=borderSize ; x<(imageIntegrale->width)-borderSize ; x++)
			{
				IplImage* current = out[inter] ;
				
				// On calcule la reponse des differents filtres
				
				// Derivee selon x
				int lobeGauche = 0, lobeCentre = 0, lobeDroit = 0 ;
				lobeGauche += unsignedGetPixel(imageIntegrale, x-(lobe+1)/2, y + lobe-1) ;
				lobeGauche -= unsignedGetPixel(imageIntegrale, x-(lobe+1)/2, y - lobe) ;
				lobeGauche += unsignedGetPixel(imageIntegrale, x-(lobe+1)/2 - lobe, y - lobe) ;
				lobeGauche -= unsignedGetPixel(imageIntegrale, x-(lobe+1)/2 - lobe, y + lobe-1) ;

				lobeCentre += unsignedGetPixel(imageIntegrale, x-(lobe+1)/2, y - lobe) ;
				lobeCentre -= unsignedGetPixel(imageIntegrale, x-(lobe+1)/2, y + lobe-1) ;
				lobeCentre += unsignedGetPixel(imageIntegrale, x+(lobe-1)/2, y + lobe-1) ;
				lobeCentre -= unsignedGetPixel(imageIntegrale, x+(lobe-1)/2, y - lobe) ;
				
				lobeDroit += unsignedGetPixel(imageIntegrale, x+(lobe-1)/2, y - lobe) ;
				lobeDroit -= unsignedGetPixel(imageIntegrale, x+(lobe-1)/2, y + lobe-1) ;
				lobeDroit += unsignedGetPixel(imageIntegrale, x+(lobe-1)/2 + lobe, y + lobe-1) ;
				lobeDroit -= unsignedGetPixel(imageIntegrale, x+(lobe-1)/2 + lobe, y - lobe) ;
				
				int dxx = lobeCentre - lobeDroit - lobeGauche ;
				
				// Derivee selon y
				int lobeHaut = 0, lobeBas = lobeCentre = 0 ;
				lobeHaut += unsignedGetPixel(imageIntegrale, x-lobe, y - (3*lobe +1)/2) ;
				lobeHaut -= unsignedGetPixel(imageIntegrale, x+lobe-1, y - (3*lobe +1)/2) ;
				lobeHaut += unsignedGetPixel(imageIntegrale, x+lobe-1, y - (lobe +1)/2) ;
				lobeHaut -= unsignedGetPixel(imageIntegrale, x-lobe, y - (lobe +1)/2) ;
				
				lobeCentre += unsignedGetPixel(imageIntegrale, x-lobe, y - (lobe +1)/2) ;
				lobeCentre -= unsignedGetPixel(imageIntegrale, x+lobe-1, y - (lobe +1)/2) ;
				lobeCentre += unsignedGetPixel(imageIntegrale, x+lobe-1, y + (lobe -1)/2) ;
				lobeCentre -= unsignedGetPixel(imageIntegrale, x-lobe, y + (lobe -1)/2) ;
				
				lobeBas += unsignedGetPixel(imageIntegrale, x-lobe, y + (lobe -1)/2) ;
				lobeBas -= unsignedGetPixel(imageIntegrale, x+lobe-1, y + (lobe -1)/2) ;
				lobeBas += unsignedGetPixel(imageIntegrale, x+lobe-1, y + (3*lobe -1)/2) ;
				lobeBas -= unsignedGetPixel(imageIntegrale, x-lobe, y + (3*lobe -1)/2) ;
				
				int dyy = lobeCentre - lobeHaut - lobeBas ;
				
				// Derivee selon xy
				int lobe00=0, lobe01=0, lobe10=0, lobe11=0;
				
				lobe00 += unsignedGetPixel(imageIntegrale, x-lobe-1, y-lobe -1) ;
				lobe00 -= unsignedGetPixel(imageIntegrale, x-1, y-lobe -1) ;
				lobe00 += unsignedGetPixel(imageIntegrale, x-1, y-1) ;
				lobe00 -= unsignedGetPixel(imageIntegrale, x-lobe-1, y-1) ;
				
				lobe01 += unsignedGetPixel(imageIntegrale, x, y-lobe-1) ;
				lobe01 -= unsignedGetPixel(imageIntegrale, x, y-1) ;
				lobe01 += unsignedGetPixel(imageIntegrale, x+lobe, y-1) ;
				lobe01 -= unsignedGetPixel(imageIntegrale, x+lobe, y-lobe-1) ;
				
				lobe10 += unsignedGetPixel(imageIntegrale, x-lobe-1, y) ;
				lobe10 -= unsignedGetPixel(imageIntegrale, x-1, y) ;
				lobe10 += unsignedGetPixel(imageIntegrale, x-1, y+lobe) ;
				lobe10 -= unsignedGetPixel(imageIntegrale, x-lobe-1, y+lobe) ;

				lobe11 += unsignedGetPixel(imageIntegrale, x, y) ;
				lobe11 -= unsignedGetPixel(imageIntegrale, x, y+lobe) ;
				lobe11 -= unsignedGetPixel(imageIntegrale, x+lobe, y) ;
				lobe11 += unsignedGetPixel(imageIntegrale, x+lobe, y+lobe) ;
				
				int dxy = lobe00 + lobe11 - lobe10 - lobe01 ;
				
				((int*)(current->imageData + current->widthStep*x))[y] = (int)((dxx*dyy- (0.9*dxy)*(0.9*dxy))/(area*area)) ;
			}
	}
}
