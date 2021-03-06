import Jcg.geometry.Point_3;
import Jcg.polyhedron.LoadMesh;
import Jcg.polyhedron.MeshRepresentation;
import Jcg.polyhedron.Polyhedron_3;

public class Matching {
	enum ModeCourbure{GAUSS,TAUBIN};
	public static ModeCourbure mode = ModeCourbure.GAUSS ;
	
	public static void test1(String fichier1, String fichier2,String fichier3) {
		String fichierOFF1=fichier1;
		MeshRepresentation mesh1 = new MeshRepresentation();
		mesh1.readOffFile(fichierOFF1);
    	LoadMesh<Point_3> load3D=new LoadMesh<Point_3>();
    	Polyhedron_3<Point_3> poly1=
    		load3D.createPolyhedron(mesh1.points,mesh1.faceDegrees,mesh1.faces,mesh1.sizeHalfedges);
		System.out.println("Fichier "+fichierOFF1+" chargé!");

		String fichierOFF2=fichier2;
		MeshRepresentation mesh2 = new MeshRepresentation();
		mesh2.readOffFile(fichierOFF2);
		LoadMesh<Point_3> load3D2=new LoadMesh<Point_3>();
    	Polyhedron_3<Point_3> poly2=
    		load3D2.createPolyhedron(mesh2.points,mesh2.faceDegrees,mesh2.faces,mesh2.sizeHalfedges);
		System.out.println("Fichier "+fichierOFF2+" chargé!");

		String fichierOFF3=fichier3;
		MeshRepresentation mesh3 = new MeshRepresentation();
		mesh3.readOffFile(fichierOFF3);
		LoadMesh<Point_3> load3D3=new LoadMesh<Point_3>();
    	Polyhedron_3<Point_3> poly3=
    		load3D3.createPolyhedron(mesh3.points,mesh3.faceDegrees,mesh3.faces,mesh3.sizeHalfedges);
		System.out.println("Fichier "+fichierOFF3+" chargé!");

		//Calcul de la courbure
		GaussianCourbureEstimator estimator1 = new GaussianCourbureEstimator(poly1);
		estimator1.computeCurvature();
		estimator1.computeSignature();
		GaussianCourbureEstimator estimator2 = new GaussianCourbureEstimator(poly2);
		estimator2.computeCurvature();
		estimator2.computeSignature();
		GaussianCourbureEstimator estimator3 = new GaussianCourbureEstimator(poly3);
		estimator3.computeCurvature();
		estimator3.computeSignature();
		System.out.println(fichierOFF1+" - "+fichierOFF2+" : " + estimator1.compareTo(estimator2));
		System.out.println(fichierOFF1+" - "+fichierOFF3+" : "+ estimator1.compareTo(estimator3));

		estimator1.show();
		estimator2.show();
		estimator3.show();
		
		estimator1.print(fichierOFF1+".dat");
		estimator2.print(fichierOFF2+".dat");
		estimator3.print(fichierOFF3+".dat");
	}

	public static void test2(String fichier1, String fichier2,String fichier3) {
		String fichierOFF1 = fichier1;
		MeshRepresentation mesh1 = new MeshRepresentation();
		mesh1.readOffFile(fichierOFF1);
		LoadMesh<Point_3> load3D = new LoadMesh<Point_3>();
		Polyhedron_3<Point_3> poly1 = load3D.createPolyhedron(mesh1.points,
				mesh1.faceDegrees, mesh1.faces, mesh1.sizeHalfedges);
		System.out.println("Fichier " + fichierOFF1 + " chargé!");

		String fichierOFF2 = fichier2;
		MeshRepresentation mesh2 = new MeshRepresentation();
		mesh2.readOffFile(fichierOFF2);
		LoadMesh<Point_3> load3D2 = new LoadMesh<Point_3>();
		Polyhedron_3<Point_3> poly2 = load3D2.createPolyhedron(mesh2.points,
				mesh2.faceDegrees, mesh2.faces, mesh2.sizeHalfedges);
		System.out.println("Fichier " + fichierOFF2 + " chargé!");

		String fichierOFF3 = fichier3;
		MeshRepresentation mesh3 = new MeshRepresentation();
		mesh2.readOffFile(fichierOFF3);
		LoadMesh<Point_3> load3D3 = new LoadMesh<Point_3>();
		Polyhedron_3<Point_3> poly3 = load3D2.createPolyhedron(mesh2.points,
				mesh2.faceDegrees, mesh2.faces, mesh2.sizeHalfedges);
		System.out.println("Fichier " + fichierOFF3 + " chargé!");

		// Calcul de la courbure
		Taubin estimator1 = new Taubin(poly1);
		estimator1.computeCurvature();
		estimator1.computeSignature();
		Taubin estimator2 = new Taubin(poly2);
		estimator2.computeCurvature();
		estimator2.computeSignature();
		Taubin estimator3 = new Taubin(poly3);
		estimator3.computeCurvature();
		estimator3.computeSignature();
		System.out.println(fichierOFF1+" - "+fichierOFF2+" : "
				+ estimator1.compareTo(estimator2));
		 System.out.println(fichierOFF1+" - "+fichierOFF3+" : " +
		 estimator1.compareTo(estimator3));

		estimator1.show();
		estimator2.show();
		estimator3.show();
		
		/*new MeshViewer(poly1) ;
		new MeshViewer(poly2) ;*/
		//new MeshViewer(poly3) ;
		 
		TenseurCourbure k1 = estimator1.courbureMap.get(poly1.vertices.get((int) (poly1.vertices.size()*Math.random() ))) ;
		TenseurCourbure k2 = estimator2.courbureMap.get(poly2.vertices.get((int) (poly2.vertices.size()*Math.random() ))) ;
		
		double[] []angles = Utils.getRotation(k1, k2) ;
		System.out.println(angles[0] + " - " + angles[1] + " - " + angles[2]) ;
		/*Matrix m = Utils.getTransformation(k1, k2) ;
		Matrix c1 = m.times(k1.getEigenvector(1)) ;
		Matrix c2 = m.times(k1.getEigenvector(2)) ;
		c1 = c1.times(1/c1.norm2()) ;
		c2 = c2.times(1/c2.norm2()) ;
		double v1 = k2.kappa.times(c1).norm2() ;
		double v2 = k2.kappa.times(c2).norm2() ;
		
		System.out.println(v1 + " " + v2) ;
		System.out.println(k2.getEigenvalue(1) + " " + k2.getEigenvalue(2)) ;*/
	}

	public static void test(String fichier1, String fichier2, String fichier3) {
		switch (mode) {
		case GAUSS:
			test1(fichier1, fichier2, fichier3);
			break;

		case TAUBIN:
			test2(fichier1, fichier2, fichier3);
			break;
		default:
			break;
		}
		
	}

}
