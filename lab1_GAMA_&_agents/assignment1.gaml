/***
* Name: assignment1_basic
* Author: peilunhsu
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model assignment1_basic

/* Insert your model definition here */
global {
	int nb_guests_init <- 20;
	int nb_info_centers <- 1;
	int nb_food_stores <- 2;
	int nb_drink_stores <- 3;
	int nb_guests -> {length(guest)};
	rgb colorDrink <- #lime;
	rgb colorFood <- #violet;
	rgb colorInfo <- #orange;
	
	init {
		create guest number: nb_guests_init {
			location <- {10 + rnd(80), 10 + rnd(80)};
		}
		create food_store number: nb_food_stores {
			location <- {rnd(100), rnd(100)};	
		}
		create drink_store number: nb_drink_stores {
			location <- {rnd(100), rnd(100)};
			}
		create info_center number: nb_info_centers {
			location <- {50, 50};
		}
	}
	//output each simulation step
	reflex globalPrint {
		write "Step of simulation: " + time;
	}
}

//Agent food store done
species food_store {
	
	//draw food store
	aspect default {
		draw square(4) color: colorFood;
	}
	
}

//Agent drink store done
species drink_store {
	
	//draw drink store
	aspect default {
		draw square(4) color: colorDrink;
	}
	
}

//Agent information center done
species info_center {
	
	point food_location;
	point drink_location;

	//ask location from a random food store and a random drink store in each time step
	reflex ask_store {
		ask one_of(food_store) {
			myself.food_location <- self.location;
		}
		ask one_of(drink_store) {
			myself.drink_location <- self.location;
		}
	}
	//draw information center
	aspect default {
	draw pyramid(6) color: colorInfo;
	}
	
}

species guest skills: [moving] {
	
	rgb guestColor <- #blue;
	point targetPoint <- nil;
	string knownfact <- "dance";
	float max_energy <- 10.0;
	float min_energy <- 0.0;
	float food_consumption <- 0.02;
	float drink_consumption <- 0.05;
	float food_energy <- (rnd(10)/10) * max_energy update: food_energy - food_consumption max: max_energy min:min_energy;
	float drink_energy <- (rnd(10)/10) * max_energy update: drink_energy - drink_consumption max: max_energy min:min_energy;
	
	//state 1: Idle done
	reflex beIdle when: targetPoint = nil {
		
		do wander;
		
		//guard to check and change state
		if (drink_energy <= 0.0 or food_energy <= 0.0) {
			ask info_center {
				myself.targetPoint <- self.location;
			}	
			knownfact <- "info_center";
			guestColor <- colorInfo;
		}
	} 
	
	//state2: Move done
	reflex moveToTarget when: targetPoint != nil {
		do goto target: targetPoint;
	}
	
	//state3: Enter store
	reflex enterStore when: (targetPoint != nil) and (location distance_to(targetPoint) < 2) {
		//action1: when guest arrive info center
		if(knownfact = "info_center") {
			//guest is thirsty, ask drink store location
			if(drink_energy <= 0.0) {
				ask info_center {
					myself.targetPoint <- self.drink_location;
				}
				knownfact <- "drink_store";
				guestColor <- colorDrink;
			}
			//guest is hungry
			else if(food_energy <= 0.0) {
				ask info_center {
					myself.targetPoint <-self.food_location;
				}
				knownfact <- "food_store";
				guestColor <- colorFood;
			}
		}
		//action2: when guest arrive drink store
		else if(knownfact = "drink_store") {
			//drink to full
			drink_energy <- max_energy;
			//if still hungary, go to info center again to get the location of food store
			if(food_energy <= 0.0){
				ask info_center {
					myself.targetPoint <- self.location;
				}
				knownfact <- "info_center";
				guestColor <- colorInfo;
			}
			//guest is satisfied, go to a random place for dancing 
			else {
				targetPoint <- {10 + rnd(80), 10 + rnd(80)};
				knownfact <- "dance";
				guestColor <- #blue;
			}
		}
		//action3: when guest arrive food store
		else if(knownfact = "food_store") {
			//eat to full
			food_energy <- max_energy;
			//if still thirsty, go to info center again
			if(drink_energy <= 0.0) {
				ask info_center {
					myself.targetPoint <- self.location;
				}
				knownfact <- "info_center";
				guestColor <- colorInfo;
			}
			//guest is satisfied, go to a random place for dancing 
			else {
				targetPoint <- {10 + rnd(80), 10 + rnd(80)};
				knownfact <- "dance";
				guestColor <- #blue;
			}
		}
		//action4: when guest arrive the random target to continue dancing
		else if(knownfact = "dance") {
			targetPoint <- nil;
			guestColor <- #blue;
		}
	}
	
	//draw sphere to represent guest agent
	aspect default {
		draw sphere(1) color: guestColor;
	}
	
}

//main
experiment festival type: gui {
	//Input: none
	output {
		display main_display type: opengl {
			species guest;
			species info_center;
			species food_store;
			species drink_store;
			}
			monitor "number of guests" value: nb_guests;
		}
}