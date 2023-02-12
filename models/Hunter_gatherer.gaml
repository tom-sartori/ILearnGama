/**
* Name: HunterGatherer
* Based on the internal skeleton template. 
* Author: tom
* Tags: 
*/

model HunterGatherer

global {
	/** Insert the global definitions, variables and actions here */
	
	// Village
	int initial_total_village_food_energy <- 25000;
	int total_village_food_energy <- initial_total_village_food_energy;
	int initial_total_village_fruit_energy <- 12000;
	int total_village_fruit_energy <- initial_total_village_fruit_energy;
	int village_energy <- total_village_food_energy + total_village_fruit_energy - total_energy_consumed update: total_village_food_energy + total_village_fruit_energy - total_energy_consumed;
	int total_energy_consumed <- 0;
	
	// human variables. 
	int initial_number_human <- 50;
	float gatherer_rate <- 0.5;
	string choice_model <- "Choice with gatherer rate";
	int number_gatherer -> {length(human where (each.is_gatherer))};
	int number_hunter -> {length(human where (each.is_hunter))};
	int energy_consumption_by_tick <- 1; 	// Energy consumed by tick, by people. 
	int hunter_radius <- 2;
	
	// Animal variables. 
	int initial_number_animal <- 100;
	int number_animal -> {length(animal)};
	float animal_reproduction_rate <- 0.0005; 	// entre 0.5% et 5%
	int max_number_animals <- 1000; 			// autour de 400
		
	list<cell> village_cell_list;
	list<cell> gathering_cell_list;
		
	init {
		create human number: initial_number_human;
		create animal number: initial_number_animal;
	}
	
	reflex stop_simulation when: (village_energy <= 0) or (number_animal = 0) {
		do pause;
	} 
}

species generic_species {
	float size <- 0.25;
	rgb color;
	image_file my_icon <- image_file("../includes/data/none.png");
	
	cell my_cell <- one_of(cell);
	
	init {
		location <- my_cell.location;
	}
	
	reflex basic_move {
		my_cell <- choose_cell();
		location <- my_cell.location;
	}
	
	aspect base {
		draw circle(size) color: color;
	}
	
	aspect icon {
		draw my_icon size: 2 * size;
	}
	
	cell choose_cell {
		return my_cell;
	}
}

species human parent: generic_species control: fsm {
	rgb color <- #yellow;
	bool is_gatherer;
	bool is_hunter;
	int current_food_energy;
	int current_fruit_energy;
	
    state choicing initial: true { 
	    write string(cycle) + ":" + name + "->" + "choicing";
	    
	    // Add energy to village. 
	    total_village_food_energy <- total_village_food_energy + current_food_energy;
	    total_village_fruit_energy <- total_village_fruit_energy + current_fruit_energy;
	    
	    // Chose random job. 
	    if (choice_model = "Choice with gatherer rate") {
		    is_gatherer <- getBasicChoiceIsGatherer();
	    }
	    else if (choice_model = "Choice with ratio") {
		    is_gatherer <- getRatioChoiceIsGatherer();    	
	    }
	    else {
		    is_gatherer <- getEqualNumberChoiceIsGatherer();
	    }
	    is_hunter <- !is_gatherer;
	    
	    current_food_energy <- 0;
	    current_fruit_energy <- 0;
	    	    
	    transition to: gathering when: is_gatherer;
   		transition to: hunting when: is_hunter; 
    }

    state gathering {
	    write string(cycle) + ":" + name + "->" + "gathering";
		
		color <- #green;
		my_icon <- image_file("../includes/data/gatherer.png");
		
		my_cell <- my_cell.neighbors closest_to(shuffle(gathering_cell_list)[0]);		
		
		if (my_cell.is_gathering) {
			current_fruit_energy <- rnd(1000);
			write "current_fruit_energy : " + current_fruit_energy;
		}
	    
	    transition to: going_home when: current_fruit_energy > 0;
    }
    
    state hunting {
	    write string(cycle) + ":" + name + "->" + "hunting";
	    
	    color <- #red;
		my_icon <- image_file("../includes/data/hunter.png");

		
		// If there is a neighbor with animal, the human goes there. Otherwise, he choses a random neighbor. 
		cell cell_with_animal <- my_cell.hunter_neighbors first_with (!(empty (animal inside (each))));		
		my_cell <- cell_with_animal != nil ? cell_with_animal : shuffle(my_cell.neighbors)[0];
		

		// For each animals inside the same place of the human, kill them. 
		list<animal> reachable_animals <- animal inside (my_cell);
		ask reachable_animals { 
			myself.current_food_energy <- myself.current_food_energy + rnd(1000);
			do die;
		}		

	    transition to: going_home when: current_food_energy > 0;
    }
    
    state going_home {
        write string(cycle) + ":" + name + "->" + "going_home";
        
        color <- #yellow;
		my_icon <- image_file("../includes/data/home.png");

		my_cell <- my_cell.neighbors closest_to(shuffle(village_cell_list)[0]);
        
	    transition to: choicing when: my_cell.is_village;
    } 
    
	cell choose_cell {
		total_energy_consumed <- total_energy_consumed + energy_consumption_by_tick;
		return my_cell;
	}
	
	bool getBasicChoiceIsGatherer {
		return flip(gatherer_rate);
	}
	
	bool getRatioChoiceIsGatherer {
		return (total_village_fruit_energy / (number_gatherer + 1) ) > (total_village_food_energy / (number_hunter + 1) );
	}
	
	bool getEqualNumberChoiceIsGatherer {
		return number_gatherer < number_hunter;
	}
}

species animal parent: generic_species {
	rgb color <- #blue;
	image_file my_icon <- image_file("../includes/data/cow.png");
	
	cell choose_cell {
		return shuffle(my_cell.neighbors)[0];
	}
	
	reflex reproduce when: (flip(animal_reproduction_rate)) {
		if (number_animal < max_number_animals) {
			create species(self) {
				my_cell <- myself.my_cell;
				location <- my_cell.location;
			}		
		}
	}
}

grid cell width: 180 height: 180 neighbors: 8 {
	rgb color <- #grey;
	
	bool is_village <- false;
	bool is_gathering <- false;
	
	list<cell> hunter_neighbors <- (self neighbors_at hunter_radius);
	
	init{		
		if (80 < grid_x and grid_x <= 100 and 80 < grid_y and grid_y <= 100){
			color <- #lightgray;
			is_village <- true;
			village_cell_list <- village_cell_list + self;
		}
		else if (160 < grid_x and grid_x <= 180 and 0 <= grid_y and grid_y < 20){
			color <- #green;
			is_gathering <- true;
			gathering_cell_list <- gathering_cell_list + self;
		}
	}
}

experiment HunterGatherer type: gui {
	/** Insert here the definition of the input and output of the model */
	
	// Village variables. 
	parameter "Initial village food energy: " var: initial_total_village_food_energy min: 0 category: "Village";
	parameter "Initial village fruit energy: " var: initial_total_village_fruit_energy min: 0 category: "Village";

	// Human variables
	parameter "Initial number of humans: " var: initial_number_human min: 0 max: 300 category: "Human";
	parameter "Gatherer rate: " var: gatherer_rate min: 0.0 max: 1.0 category: "Human";
	parameter "Choice model: " var: choice_model among: ["Choice with gatherer rate", "Choice with ratio", "Choice with equal number"] category: "Human";
	parameter "Energy consumption of each human: " var: energy_consumption_by_tick min: 0 max: 5 category: "Human";
	parameter "Hunter radius" var: hunter_radius min: 1 max: 15 category: "Human";

	// Animal variables. 
	parameter "Initial number of animals: " var: initial_number_animal min: 0 max: 1000 category: "Animal";
	parameter "Animal reproduction rate: " var: animal_reproduction_rate min: 0.0 max: 0.1 category: "Animal";
	parameter "Max number of animals: " var: max_number_animals min: 0 max: 400 category: "Animal";
	

	output {
		display main_display {
			grid cell;
			
			species human aspect: base;
			
			species animal aspect: base;
		}

		// Village monitors. 
		monitor "Current village global energy: " value: village_energy;
		monitor "Total village food energy gotten: " value: total_village_food_energy;
		monitor "Total village fruit energy gotten: " value: total_village_fruit_energy;
		
		// Human monitors. 
		monitor "Current number of hunters: " value: number_hunter;
		monitor "Current number of gatherers: " value: number_gatherer;
		
		// Animal monitors. 
		monitor "Number of animals: " value: number_animal;
	}
}
