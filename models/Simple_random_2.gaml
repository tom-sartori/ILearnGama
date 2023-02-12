/**
* Name: Model
* Based on the internal empty template. 
* Author: tom
* Tags: 
*/


model SimpleRandom2

/* Insert your model definition here */

global {
	int width <- 50;
	int height <- 50;
	
	int nb_bee_init <- 50;
	int nb_bee -> { length(bee) };
	float speed_bee <- 2.5;
	bool always_targeting <- false;
	
	int nb_queen_init <- 5;
	int nb_queen -> { length(queen) };
	float speed_queen <- 3.0;


	init {
		create bee number: nb_bee_init;
		create queen number: nb_queen_init;
	}
}

species bee skills: [ moving ] {
	int moveStatus <- 0;
	queen queenFollowed;
	
   	init {
        name <- "bee";
    	location <- { rnd(width), rnd(height) };
    	shape <- circle(1);
    	
    	queenFollowed <- nil;
    }
    
    aspect default {
    	draw shape color: #blue;
    }
    
    reflex searching when: queenFollowed = nil {
    	do move_cube();
    }

    action move_cube {
        if (moveStatus = 4) {
            do move speed: speed_bee heading: heading;
            moveStatus <- 0;
        }
        else {
            do move speed: speed_bee heading: heading + 90.0;
            moveStatus <- moveStatus + 1;
        }
	}
	
	reflex detection when: always_targeting or queenFollowed = nil {
		list<queen> neighbourList <- queen at_distance(5);
		if (length(neighbourList) != 0) {
			queenFollowed <- neighbourList[0];
		}
	}
	
	reflex following when: queenFollowed != nil {
		do goto target: queenFollowed;
	}
}

species queen skills: [moving] {
	init {
        name <- "queen";
    	location <- { rnd(width), rnd(height) };
    	shape <- circle(1);	
	}
	
	aspect default {
		draw shape color: #red;
	}
	
	reflex moving {
		do wander speed: speed_queen amplitude: 90.0;
	}
}

experiment play_bee type: gui {
	parameter "Initial number of bees: " var: nb_bee_init min: 0 max: 1000;
	parameter "Initial number of queens: " var: nb_queen_init min: 0 max: 1000;

	output {
		display main_display {
			species bee aspect: default;
			species queen aspect: default;
		}

		monitor "Number of bees" value: nb_bee;
		monitor "Number of queens" value: nb_queen;
	}
} 
