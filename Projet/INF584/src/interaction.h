/*
 * interaction.h
 *
 *  Created on: 10 mars 2011
 *      Author: benoit
 */

#ifndef INTERACTION_H_
#define INTERACTION_H_


//pour g�rer les interactions avec l'utilisateur
void userInteraction(const Vec3Df & selectedPos, const Vec3Df & selectedNormal, int selectedIndex, Vec3Df origin, Vec3Df direction)
{
	if(selectedIndex<0)
		return;
	//LightPos[0]=selectedPos-direction/direction.getSquaredLength();
	direction.normalize();
	LightPos[0]-=Vec3Df::dotProduct(direction,selectedPos+LightPos[0])*direction;
	LightPos[0].normalize();
	LightPos[0]*=1.5;
	std::cout << LightPos[0] << std::endl;
}



// prise en compte du clavier
//Vous allez ajouter quelques fonctionalites pendant le TP
//ce qui est important pour vous: key contient le caract�re correspondant � la touche appuy� par l'utilisateur

void keyboard(unsigned char key, int x, int y)
{
	printf("key %d pressed at %d,%d\n",key,x,y);
	fflush(stdout);

	switch (key)
	{
	case 'm':
	{
		viewingMode=ViewingMode((viewingMode+1)%NB_MODES);
		return;
	}
	case 'r':
		break;
	case 'R':
		break;
	case 'g':
		break;
	case 'G':
		break;
	case 'b':
		break;
	case 'B':
		break;

		//a pas y toucher!!!

		//ARRETEZ DE LIRE � PARTIR D'ICI!!!
		//________________________________
		//________________________________
		//________________________________
		//________________________________
		//________________________________


	case 'l':
	{
		LightPos[SelectedLight]=getCameraPosition();
		return;
	}
	case 'L':
	{
		LightPos.push_back(getCameraPosition());
		LightColor.push_back(Vec3Df(1,1,1));
		return;
	}
	case '+':
	{
		++SelectedLight;
		if (SelectedLight>=LightPos.size())
			SelectedLight=0;
		return;
	}
	case '-':
	{
		--SelectedLight;
		if (SelectedLight<0)
			SelectedLight=LightPos.size()-1;
		return;
	}
	case 'U':
	{
		updateAlways=!updateAlways;
		return;
	}

	}

}


#endif /* INTERACTION_H_ */
