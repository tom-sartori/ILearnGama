/**
* Name: Model
* Based on the internal empty template. 
* Author: tom
* Tags: 
*/


model SimpleRandom1

/* Insert your model definition here */

global {
	int width <- 50;
	int height <- 50;
	int nb_turtle_init <- 10;
	int nb_turtle -> {length(turtle)};


	init {
		create turtle number: nb_turtle_init;
	}
}

species turtle skills: [ moving ] {
	list<point> pointList;
	int moveStatus <- 0;
	float speed;
	
   	init {
        name <- "turtle";
    	location <- {rnd(width), rnd(height)};
    	shape <- circle(1);
    	pointList <- pointList + self.location;
    	
    	pointList <- [];
    	speed <- 0.1;
    }
    
    aspect default {
    	draw polyline(pointList) color: #red;
    	draw shape color: #green;
    }
    
    reflex moving {
    	pointList <- pointList + self.location;
    	do move_spirale(8);
    	// do move_cube();
    }
    
    action move_spirale(int a) {
		do move speed: speed heading: heading + (360 / a);
		speed <- speed + 0.1;
    }
    
    action move_cube {
        if (moveStatus = 4) {
            do move speed: 3.0 heading: heading;
            moveStatus <- 0;
        }
        else {
            do move speed: 3.0 heading: heading + 90.0;
            moveStatus <- moveStatus + 1;
        }
	}
}

experiment play_turtle type: gui {
	parameter "Initial number of turtles: " var: nb_turtle_init min: 0 max: 1000;

	output {
		display main_display {
			species turtle aspect: default;
		}

		monitor "Number of turtles" value: nb_turtle;
	}
} 
