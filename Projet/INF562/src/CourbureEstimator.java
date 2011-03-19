import java.util.HashMap;

import Jcg.geometry.Point_3;
import Jcg.polyhedron.Polyhedron_3;
import Jcg.polyhedron.Vertex;


public abstract class CourbureEstimator {
	protected Polyhedron_3<Point_3> poly;
	protected HashMap<Vertex<Point_3>, Double> weightMap;

	public abstract double compareTo(CourbureEstimator ce);

	public void computeCurvature(){
		for(Vertex<Point_3> v : poly.vertices){
			computeCurvatureAtVertex(v);
		}
	}
	public abstract void computeSignature();

	protected abstract void computeCurvatureAtVertex(Vertex<Point_3> v);
	
	
	abstract void show();
}
