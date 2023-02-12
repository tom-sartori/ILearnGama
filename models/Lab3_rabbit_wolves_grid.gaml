/**
* Name: Lab3rabbitwolvesgrid
* Based on the internal empty template. 
* Author: lorenzoitaliano
* Tags: 
*/


model Lab3rabbitwolvesgrid

/* Insert your model definition here */

global {
	int width <- 50;
	int height <- 50;
	
	int nb_wolf_init <- 5;
	int nb_wolf -> { length(wolf) };
	
	float diffusion_rate_init <- 0.4;
	float evaporation_rate_init <- 0.05;
	
	int nb_rabbit_init <- 20;
	int nb_rabbit -> { length(rabbit) };
	float speed_rabbit <- 3.0;


	init {
		create wolf number: nb_wolf_init;
		create rabbit number: nb_rabbit_init;
	}
}

// Wolves specie
species wolf {
	
	smell_cell my_cell;
	
   	init {
        name <- "wolf";
        my_cell <- one_of(smell_cell);
    	location <- my_cell.location;
    	shape <- circle(1);
    }
    
    aspect default {
    	draw shape color: #blue;
    }
    
    
    reflex moving {
    	if(flip(0.8)){
    		my_cell <- choose_cell();
    		location <- my_cell.location;
    		ask rabbit{
    			if(self.my_cell overlaps myself.my_cell){
    				do die;
    			}
    		}
    	}
    }
    
    smell_cell choose_cell{
		smell_cell tmp_cell <- nil;
		
		int neibors <- length(my_cell.neighbors);
		
		tmp_cell <- my_cell.neighbors with_max_of each.quantity;
		
		return tmp_cell;
	}
}

// Rabbit specie
species rabbit {
	
	string sex;
	
	//bool isRunningAway <- false;
	
	smell_cell my_cell <- one_of(smell_cell);

	init {
        name <- "rabbit";
        location <- my_cell.location;
    	shape <- circle(1);
    	int sexInt <- round(rnd(1));
    	if(sexInt=0){
    		sex <- "male";
    	}
    	else{
    		sex <- "female";	
    	}	
	}
	
	reflex basic_move {
		
		my_cell.current_rabbit <- nil;
		my_cell <- choose_cell();
		location <- my_cell.location;
		my_cell.current_rabbit <- self;
		
		// diffuse to first cell
		ask my_cell{
			if(myself.sex="male"){
				self.male_quantity <- self.male_quantity + 100;
			}
			else{
				self.female_quantity <- self.female_quantity + 100;
				
			}	
		}
	}
	
	/* 
	reflex running_away when:isRunningAway {
		
		my_cell.current_rabbit <- nil;
		my_cell <- choose_cell();
		location <- my_cell.location;
		my_cell.current_rabbit <- self;
		
		// diffuse to first cell
		ask my_cell{
				if(myself.sex="male"){
					self.male_quantity <- self.male_quantity + 100;
				}
				else{
					self.female_quantity <- self.female_quantity + 100;
				}	
		}
	}*/
	
	aspect default {
		draw shape color: #red;
	}
	
	smell_cell choose_cell{
		smell_cell tmp_cell <- nil;
		
		// TODO detect if there is anay wolf around and manage isRunningAway state according to the result
		
		// voir si on ecarte de 2 plutot que de 1

		
		if(sex="female"){
			list impossible <- my_cell.neighbors where (each.current_rabbit != nil);
			
			loop i over:impossible{
				impossible <- impossible + i.neighbors;
			}
			
			list possibilities <- my_cell.neighbors where (each.current_rabbit = nil);
			
			
			loop j over: possibilities{
				if(j in impossible){
					possibilities <- possibilities - j;
				}
			}
			
			tmp_cell <- possibilities with_max_of each.male_quantity;
			
			if(tmp_cell = nil){
				tmp_cell <- my_cell;
			}
			//tmp_cell <- my_cell.neighbors with_max_of each.male_quantity;
			//ask tmp_cell{
			//	if(current_rabbit != nil){
					
			//	}
			//}
		}
		else{
			list impossible <- my_cell.neighbors where (each.current_rabbit != nil);
			
			loop i over:impossible{
				impossible <- impossible + i.neighbors;
			}
			
			list possibilities <- my_cell.neighbors where (each.current_rabbit = nil);
			
			
			loop j over: possibilities{
				if(j in impossible){
					possibilities <- possibilities - j;
				}
			}
			
			tmp_cell <- possibilities with_max_of each.female_quantity;
			
			if(tmp_cell = nil){
				tmp_cell <- my_cell;
			}
			//tmp_cell <- my_cell.neighbors with_max_of each.female_quantity;	
		}
		
		
		return tmp_cell;
	}
	
}

grid smell_cell width: 50 height: 50 neighbors: 8 {
	
	float diffusion_rate <- diffusion_rate_init;
	
	float evaporation_rate <- evaporation_rate_init;
	
	list<smell_cell> neighbors_at_2 <- (self neighbors_at 2);
	
	int male_quantity <- 0 max: 100 min: 0;
	int female_quantity <- 0 max: 100 min: 0; 
	
	int quantity <- male_quantity + female_quantity max: 100 min: 0 update: male_quantity + female_quantity;
	
	rgb color <- rgb(255 - (4 * quantity), 255 , 255 - (4 * quantity)) update:rgb(255 - (4 * quantity), 255 , 255 - (4 * quantity));
	
	rabbit current_rabbit <- nil;
	
	
	reflex evaporate when: quantity > 0 {
		self.male_quantity <- self.male_quantity - round(self.male_quantity * self.evaporation_rate);
		self.female_quantity <- self.female_quantity - round(self.female_quantity * self.evaporation_rate);
	}
	
	reflex diffusion when: quantity > 0{
		self.male_quantity <- self.male_quantity - round(self.male_quantity * self.diffusion_rate);
		self.female_quantity <- self.female_quantity - round(self.female_quantity * self.diffusion_rate);
		
		write self.quantity;
		
		loop i over: self.neighbors  {
			//write i;
			ask i {
				self.male_quantity <- self.male_quantity + round(myself.male_quantity * (myself.diffusion_rate / 8));
				self.female_quantity <- self.female_quantity + round(myself.female_quantity * (myself.diffusion_rate / 8));
			}
		}
	}
}

// Experiment
experiment play_rabbit_wolves type: gui {
	parameter "Initial number of bees: " var: nb_wolf_init min: 1 max: 500;
	parameter "Initial number of rabbits: " var: nb_rabbit_init min: 1 max: 500;
	parameter "Diffusion rate" var:diffusion_rate_init min:0.01 max: 1.0;
	parameter "Evaporation rate" var:evaporation_rate_init min:0.01 max: 0.05;

	output {
		display main_display {
			grid smell_cell border: #black;
			species wolf aspect: default;
			species rabbit aspect: default;
		}

		monitor "Number of bees" value: nb_wolf;
		monitor "Number of queens" value: nb_rabbit;
	}
} 
