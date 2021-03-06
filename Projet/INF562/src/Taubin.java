import java.awt.Color;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Vector;

import Jama.Matrix;
import Jcg.geometry.Point_3;
import Jcg.geometry.Vector_3;
import Jcg.polyhedron.Halfedge;
import Jcg.polyhedron.Polyhedron_3;
import Jcg.polyhedron.Vertex;
import Jcg.viewer.MeshViewer;


public class Taubin extends CourbureEstimator {
	
	// Variables
	static final int tailleSignature = 64 ;
	static final double moyenneCourbure = 0.4 ; // Coefficient dans le Arctan
	HashMap<Vertex<Point_3>, TenseurCourbure> courbureMap;
	double[][] signature ;
	static double maxSignature ;
	static int tailleGauss = 5 ;
	
	// Constructeur
	public Taubin (Polyhedron_3<Point_3> poly) {
		this.poly=poly;
		courbureMap= new HashMap<Vertex<Point_3>, TenseurCourbure>();
		weightMap= new HashMap<Vertex<Point_3>, Double>();
		signature = new double [tailleSignature][tailleSignature] ;
	}
	
	@Override
	public double compareTo(CourbureEstimator ce) {
		Taubin te = (Taubin) ce ;
		
		double distanceEuclidienne = 0 ;
		
		for (int i=0 ; i<tailleSignature ; i++)
			for (int j=0 ; j<tailleSignature ; j++)
			{
				double diff = (te.signature[i][j] - signature[i][j]) ;
				//signature[i][j] = Math.abs(signature[i][j] - te.signature[i][j]) ;
				distanceEuclidienne += diff*diff ;
			}
		
		distanceEuclidienne = Math.sqrt(distanceEuclidienne) ;
		
		return distanceEuclidienne ;
	}

	@Override
	protected void computeCurvatureAtVertex(final Vertex<Point_3> v) 
	{	
		// Vecteur normal
		Vector_3 normal = Utils.vecteurNormal(v) ;
		double[][] arrayNormal = {{normal.getX().doubleValue()},{normal.getY().doubleValue()},{normal.getZ().doubleValue()}} ;
		Matrix mNormal = new Matrix (arrayNormal) ;
		//System.out.println(normal.toString()) ;
		
		// Liste des voisins
		LinkedList<Vertex<Point_3>> voisins = new LinkedList<Vertex<Point_3>>() ; 
		Halfedge<Point_3> he = v.getHalfedge() ;
		Halfedge<Point_3> premier = he ;
		boolean debut = true ;
		while (debut || he != premier)
		{
			debut = false ;
			voisins.add(he.getNext().getVertex()) ;
			
			//System.out.println(he.getFace().degree()) ;
			
			he = he.getNext().getOpposite() ;
		}
		int nVoisins = voisins.size() ;
		
		
		// Calcul des surfaces
		double[] surfaces = new double[nVoisins] ;
		int i=0 ;
		Vertex<Point_3> premierVoisin = null ;
		Vertex<Point_3> precedent = voisins.get(0) ;
		double w = 0 ; // Somme des surfaces
		for (Vertex<Point_3> vertex : voisins)
		{
			// Cas du premier vertex
			if (premierVoisin == null)
			{
				premierVoisin = vertex ;
				precedent = premierVoisin ;
				continue ;
			}
			Vector_3 v1 = (Vector_3) vertex.getPoint().minus(v.getPoint()) ;
			Vector_3 v2 = (Vector_3) precedent.getPoint().minus(v.getPoint()) ;
			surfaces[i] = Math.sqrt(v1.crossProduct(v2).squaredLength().doubleValue()) / 2 ;
			//System.out.println(v1.getX() + " " + v2.getX() + " " + surfaces[i]) ;
			w += surfaces[i]*2 ;
			i++ ;
			precedent = vertex ;
		}
		Vector_3 v1 = (Vector_3) premierVoisin.getPoint().minus(v.getPoint()) ;
		Vector_3 v2 = (Vector_3) precedent.getPoint().minus(v.getPoint()) ;
		surfaces[i] = Math.sqrt(v1.crossProduct(v2).squaredLength().doubleValue()) / 2 ;
		w += surfaces[i]*2 ;
		
		// w est la somme des surface avoisinantes fois deux ;
		weightMap.put(v, w/2) ;
		
		// R�cup�ration des projections des voisins sur le plan tangent
		Matrix Mvi = new Matrix(3,3) ;
		i = 0 ;
		for (Vertex<Point_3> vertex : voisins) {
			
			Vector_3 vij = (Vector_3) vertex.getPoint().minus(v.getPoint()) ;
			
			int j = (i-1 + nVoisins) % nVoisins ;
			double wij = surfaces[i]+surfaces[j] ;
			double kij = vij.innerProduct(normal).doubleValue()*2/(vij.squaredLength().doubleValue()) ;
			//System.out.println("dedzf : " + kij) ;
			
			double[][] array = {{vij.getX().doubleValue()},{vij.getY().doubleValue()},{vij.getZ().doubleValue()}} ; 
			Matrix mVij = new Matrix (array) ;
			Matrix Tij = Matrix.identity(3, 3).minus(mNormal.times(mNormal.transpose())).times(mVij) ;
			Tij = Tij.times(1./Tij.norm2()) ;
			
			//Mvi.plusEquals(Tij.times(Tij.transpose())).times(wij*kij/w) ;
			Mvi = Mvi.plus(Tij.times(Tij.transpose()).times(wij*kij/w)) ;
			
			i++ ;
		}
		
		// on l'ajoute dans la hashmap des courbures
		courbureMap.put(v, new TenseurCourbure(v, Mvi, mNormal)) ;
	}
	
	@Override
	protected void computeIntegralCurvature() {
		HashMap<Vertex<Point_3>, TenseurCourbure> newCourbureMap = new HashMap<Vertex<Point_3>, TenseurCourbure>();
		HashMap<Vertex<Point_3>, Double> newWeightMap = new HashMap<Vertex<Point_3>, Double>();
		for(Vertex<Point_3> v : courbureMap.keySet()){
			TenseurCourbure courbure = new TenseurCourbure(v);
		
			Collection<Vertex<Point_3>> iN = integralNeighbors(v);
			for (Vertex<Point_3> v2 : iN) {
				courbure.add(courbureMap.get(v2),weightMap.get(v2));
			}
			courbure.normalize();
			newCourbureMap.put(v, courbure);
			newWeightMap.put(newCourbureMap.get(v).point, weightMap.get(v));
		}
		courbureMap=newCourbureMap;
		weightMap = newWeightMap;
	}
	
	public void computeSignature ()
	{
		
		// On calcule la moyenne des courbures
		int nVertex = 0 ;
		double courbureMoyenne = 0 ;
		double wTot=0 ; // Poids total des points
		for(TenseurCourbure k : courbureMap.values()){
			double poids = weightMap.get(k.point) ;
			courbureMoyenne += (k.getEigenvalue(1) + k.getEigenvalue(2))*poids/2 ;
			wTot += poids ;
			nVertex++ ;
		}
		courbureMoyenne /= wTot ;
		
		// On recense chaque courbure
		double sommeSignatures = 0 ; // Pour normaliser
		for(TenseurCourbure k : courbureMap.values()){
			double dx = (Math.atan(moyenneCourbure * k.getEigenvalue(1)/courbureMoyenne)/Math.PI + 0.5) * tailleSignature ;
			double dy = (Math.atan(moyenneCourbure * k.getEigenvalue(2)/courbureMoyenne)/Math.PI + 0.5) * tailleSignature ;
			int x = (int) dx ;
			int y = (int) dy ;
			double px = x - dx + 1 ; // Ponderation dans l'arrondi inferieur pour x
			double py = y - dy + 1 ; // Ponderation dans l'arrondi inferieur pour y
			if (x == 511) px = 1 ; // Effets de bord
			if (y == 511) py = 1 ;
			if (x >= 0 && y >= 0 && x < tailleSignature && y < tailleSignature) // On ne sait jamais...
			{
				double w = weightMap.get(k.point) ;
				//System.out.println(px*(1-py)*w) ;
				signature[y][x] = signature[x][y] = signature[x][y] + px*py*w ;
				if (y+1 < tailleSignature) signature[y+1][x] = signature[x][y+1] = signature[x][y+1] + px*(1-py)*w ;
				if (x+1 < tailleSignature) signature[y][x+1] = signature[x+1][y] = signature[x+1][y] + (1-px)*py*w ;
				if (x+1 < tailleSignature && y+1 < tailleSignature) signature[y+1][x+1] = signature[x+1][y+1] = signature[x+1][y+1] + (1-px)*(1-py)*w ;
				sommeSignatures += w ;
			}
		}
		
		// On normalise
		//maxSignature = 0 ;
		for (int i=0 ; i<tailleSignature ; i++)
			for (int j=0 ; j<tailleSignature ; j++)
				{
					signature[i][j] = signature[i][j] / sommeSignatures ;
					if (signature[i][j] > maxSignature) maxSignature = signature[i][j] ;
				}
		
		// On applique un filtre de Gauss
		double[][] signatureBis = new double[tailleSignature][tailleSignature] ;
		Matrix gauss = Masque.MasqueGauss(1.3, tailleGauss) ;
		for (int i=tailleGauss/2 ; i<tailleSignature-tailleGauss/2 ; i++)
			for (int j=tailleGauss/2 ; j<tailleSignature-tailleGauss/2 ; j++)
			{
				signatureBis[i][j] = 0 ;
				for (int k=0 ; k<tailleGauss ; k++)
					for (int l=0 ; l<tailleGauss ; l++)
					{
						signatureBis[i][j] += signature[i+k-tailleGauss/2][j+l-tailleGauss/2] * gauss.get(k, l) ;
					}
			}
		signature = signatureBis ;
		
		
	}

	@Override
	void show() {
		Vector<Point_3> pts = new Vector<Point_3>();
		Color[] col = new Color[tailleSignature*tailleSignature];
		
		int k = 0 ;
		for (int i=0 ; i<tailleSignature ; i++)
			for (int j=0 ; j<tailleSignature ; j++)
			{
				pts.add(new Point_3((double) (i-tailleSignature/2)/10, (double) (j-tailleSignature/2)/10, signature[i][j]*100)) ;
				//System.out.println(signature[i][j]*100) ;
				col[k] = new Color((int) (signature[i][j]/maxSignature * 255), 255 - (int) (signature[i][j]/maxSignature * 255), 255) ;
				//col[k] = new Color(0.0f, 1.0f, 1.0f) ;
				k++ ;
			}
		//pts.add(new Point_3(10,5,10)) ;

		new MeshViewer(pts, col);
	}

	void print(String fileName){
		FileWriter fw;
		try {
			fw = new FileWriter(fileName);
			for(int i=0;i<tailleSignature;i++){
				for(int j=0;j<tailleSignature;j++){
				fw.write(signature[i][j]+"\t");
				}
				fw.write("\n");
			}
			fw.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
