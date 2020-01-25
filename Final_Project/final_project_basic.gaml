/***
* Name: finalprojectbasic
* Author: peilunhsu
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model finalprojectbasic

/* Insert your model definition here */

global {
	int nb_bars <- 4;
	int nb_atms <- 2;
	int nb_toilets <- 2;
	int nb_wine_lovers <- 25;
	int nb_beer_lovers <- 25;
	int nb_whiskey_lovers <- 25;
	int nb_cocktail_lovers <- 25;
	rgb colorWineBar <- #blue;
	rgb colorBeerBar <- #cyan;
	rgb colorWhiskeyBar <- #navy;
	rgb colorCocktailBar <- #lightblue;
	rgb colorAtm <- #gold;
	rgb colorToilet <- #green;
	rgb colorWine <- #purple;
	rgb colorBeer <- #darkgoldenrod;
	rgb colorWhiskey <- #brown;
	rgb colorCocktail <- #pink;
	rgb colorWasted <- #black;
	list<point> barLocation <- [{20, 30}, {80, 30}, {20, 70}, {80, 70}];
	list<string> barType <- ['wine_lover', 'beer_lover', 'whiskey_lover', 'cocktail_lover'];
	list<rgb> barColor <- [colorWineBar, colorBeerBar, colorWhiskeyBar, colorCocktailBar];
	list<point> atmLocation <- [{50, 1}, {50, 99}];
	list<point> toiletLocation <- [{1, 50}, {99, 50}];
	float totalHappiness <- 0.0;
	float totalMoney <- 0.0;
	
	int i <- 0;
	int j <- 0;
	int k <- 0;

	init {
		create bar number: nb_bars {
			location <- barLocation at i;
			typeBar <- barType at i;
			colorBar <- barColor at i;
			i <- i + 1;
		}
		create atm number: nb_atms {
			location <- atmLocation at j;
			j <- j + 1;
		}
		create toilet number: nb_toilets {
			location <- toiletLocation at k;
			k <- k + 1;
		}
		
		create wine_lover number: nb_wine_lovers {
			location <- {5 + rnd(90), 5 + rnd(90)};
		}
		create beer_lover number: nb_beer_lovers {
			location <- {5 + rnd(90), 5 + rnd(90)};
		}
		create whiskey_lover number: nb_whiskey_lovers {
			location <- {5 + rnd(90), 5 + rnd(90)};
		}
		create cocktail_lover number: nb_cocktail_lovers {
			location <- {5 + rnd(90), 5 + rnd(90)};
		}
	}
}
//agent bar
species bar skills: [fipa] {
	
	string goal <- 'sell_alcohol';
	string typeBar;
	rgb colorBar;
	
	//draw bar
	aspect default {
		draw square(25) color: colorBar;
	}
	
}

//agent atm
species atm skills: [fipa] {
	//state 0 reply the guests with the location information with FIPA
	reflex provideLocation when: !empty(cfps) {
        write '(Time ' + time + '): ' + name + ' provide the atm location to guests who need to withdraw money.';
        
		loop c over: cfps {  //c = the message from one of requesting guests
			do propose (message: c, contents:[location]);
		}
	}
	//draw atm
	aspect default {
		draw square(5) color: colorAtm;
	}
}

//agent toilet
species toilet skills: [fipa] {
	//state 0 reply the guests with the location information with FIPA
	reflex provideLocation when: !empty(cfps) {
        write '(Time ' + time + '): ' + name + ' provide the toilet location to guests who need to vomit.';       
		loop c over: cfps {  //c = the message from one of requesting guests
			do propose (message: c, contents:[location]);
		}
	}
	//draw toilet
	aspect default {
		draw square(5) color: colorToilet;
	}
}

//parent agent generic guest
species generic_guest skills: [fipa, moving] {
	
	float maxMoney <- 1.0;
	//attributes that decide the agent's behaviors
	float friendliness <- rnd(float(1));
	float hostility <- rnd(float(1));
	float alcoholTolerance <- (0.5 + rnd(0.5));
	//behavior utility
	float treatUtility <- 0.0;
	float fightUtility <- 0.0;
	//monitor values
	float happiness <- 0.5;
	float money <- 1.0;
	float drunkenness <- 0.0;
	//other basic variables
	string myType;
	point targetPoint <- nil;
	string goal <- nil;
	point memoryAtmLocation <- nil;
	point memoryToiletLocation <- nil;
	list<atm> atmList;
	list<toilet> toiletList;
	int waitAtm <- 0;
	int waitToilet <- 0;
	int waitDrink <- 0;
	float temp;
	rgb color;
	rgb colorState;
	float happiness_loss_ratio <- 0.7;
	//variables for the other agent met in bar
	string otherType;
	string otherGoal;
	float otherFriendliness;
	float otherHostility;
	float otherHappiness;
	//variable for the visiting bar type
	string currentBarType;
	float discountWeight <- float(1);

	init {
		totalHappiness <- totalHappiness + happiness;
		totalMoney <- totalMoney + money;
		//totaldrunkenness <- totaldrunkenness + drunkenness;
		atmList <- list(atm);
		toiletList <- list(toilet);
	}
	

	//state0: decide the next goal: Bar/ATM/Toilet
	reflex decide when: (goal = nil) and (targetPoint = nil) {
		//check drunkenness
		if (drunkenness > alcoholTolerance) {
			colorState <- colorWasted;
			if(memoryToiletLocation = nil and empty(proposes)) {
				write '(Time ' + time + '): ' + name + ' is drunk, but does not know where is the toilet.';
				write name + ' ask toilet agent for the location via cfp message';
				do start_conversation (to: toiletList, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['where is the toilet?']);
			}
			if(memoryToiletLocation = nil and !empty(proposes)) {
				list<point> toilet_location_list;
				loop p over: proposes {
					add p.contents[0] to: toilet_location_list; 
				}
				memoryToiletLocation <- one_of(toilet_location_list);
			}
			if(memoryToiletLocation != nil) {
				write '(Time ' + time + '): ' + name + ' go to toilet to vomit.';
				goal <- 'go_toilet';
				targetPoint <- memoryToiletLocation;
			}
		}
		//check money amount
		else if (money < 0.4) {
			if(memoryAtmLocation = nil and empty(proposes)) {
				write '(Time ' + time + '): ' + name + ' runs out money, but does not know where is the atm.';
				write name + ' ask atm agent for the location via cfp message';
				do start_conversation (to: atmList, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['where is the atm?']);
			}
			if(memoryAtmLocation = nil and !empty(proposes)) {
				list<point> atm_location_list;
				loop p over: proposes {
					add p.contents[0] to: atm_location_list; 
				}
				memoryAtmLocation <- one_of(atm_location_list);
			}
			if(memoryAtmLocation != nil) {
				write '(Time ' + time + '): ' + name + ' go to atm to withdraw money.';
				goal <- 'go_atm';
				targetPoint <- memoryAtmLocation;
			}
		}
		//go to bar if not wasted and still have money
		else {
			goal <- 'go_bar';
			bar targetBar <- one_of(bar);
			targetPoint <- targetBar.location;
		}
	}

	//state1: go to target location
	reflex moveToTarget when: (goal != nil) and (targetPoint != nil) and (location distance_to(targetPoint) > 5) {
		do goto target: targetPoint;
		speed <- 3.0;
	}
	
	//state2: enter ATM, wait and withdraw money
	reflex enterATM when: (goal = 'go_atm') and (targetPoint != nil) and (location distance_to(targetPoint) <= 5) {
		if (waitAtm > 6){
		totalMoney <- totalMoney - money; 
		money <- maxMoney;
		totalMoney <- totalMoney + money;
		goal <- nil;
		targetPoint <- nil; //go to state 0
		waitAtm <- 0;
		}
		waitAtm <- waitAtm + 1;
	}
	
	//state2.5: enter Toilet, wait until recovering conscious
	reflex enterToilet when: (goal = 'go_toilet') and (targetPoint != nil) and (location distance_to(targetPoint) <= 5) {
		if (waitToilet > 20){
		totalHappiness <- totalHappiness - happiness;
		happiness <- (happiness * happiness_loss_ratio);	
		totalHappiness <- totalHappiness + happiness;
		drunkenness <- 0.0;
		goal <- nil;
		targetPoint <- nil; //go to state 0
		colorState <- color;
		waitToilet <- 0;
		}
		waitToilet <- waitToilet + 1;
	}
	
	
	//state3: enter the Bar, ask the type of the bar, update the discount weight
	reflex enterBar when: (goal = 'go_bar') and (targetPoint != nil) and (location distance_to(targetPoint) <= 5) {
		do wander;
		bar currentBar <- list(bar) closest_to(self);
		ask currentBar {
			myself.currentBarType <- typeBar;
		}
		if (currentBarType = myType) {
			discountWeight <- 0.60;
		}
		else {
			discountWeight <- 1.0;
		}
		goal <- 'wait_in_bar';
	}
	
	//state4: wait for drink (wait for a treat/a fight)
	reflex waitInBar when: (goal = 'wait_in_bar') and (targetPoint != nil) and (location distance_to(targetPoint) <=  10) {
		do wander;
		if (waitDrink > 4) {
			goal <- 'search_in_bar';
			waitDrink <- 0;
		}
		waitDrink <- waitDrink + 1;
	}
	
		//state5: search another guest in the Bar (buying a drink or picking up a fight) 
	reflex searchInBar when: (goal = 'search_in_bar') and (targetPoint != nil) and (location distance_to(targetPoint) <= 10) {
		do wander;
		//search the agents nearest to me 
		agent closestAgent <- agent_closest_to(self);
		//check the status of the closest agent
		ask closestAgent {
			myself.otherType <- myType ;
			myself.otherGoal <- goal;
			myself.otherFriendliness <- friendliness;
			myself.otherHostility <- hostility;
			myself.otherHappiness <- happiness;
			}
			treatUtility <- friendliness + otherFriendliness;
			fightUtility <- hostility + otherHostility;
			
		if(otherGoal = 'wait_in_bar' or otherGoal = 'search_in_bar') {
			//rule1: agents with same test
			if(otherType = myType) {
				//2 freindly people with same test, buying a drink
				if (treatUtility >= (1.0 * discountWeight)) {
					write '(Time ' + time + '): ' + name + ' buy ' + closestAgent.name + ' some drinks, both are very happy !';
					happiness <- happiness + 0.3;
					money <- money - 0.4;
					drunkenness <- drunkenness + 0.1; // 0.5/glass
					goal <- nil; //back to state 0
					targetPoint <- nil;
					ask closestAgent {
						happiness <- happiness + 0.3;
						drunkenness <- drunkenness + 0.1;
						goal <- nil;
						targetPoint <- nil;//other agent also back to state 0
						waitDrink <- 0;
					}
					totalHappiness <- totalHappiness + 0.6;
					totalMoney <- totalMoney - 0.4;
				} 
				//Both of agents are not so friendly, only have a short and delight chat
				else {
					write '(Time ' + time + '): ' + name + ' has a short chat with ' + closestAgent.name + ', both are happy~';
					happiness <-happiness + 0.1;
					goal <- nil; //back to state 0
					targetPoint <- nil;
					ask closestAgent {
						happiness <- happiness + 0.1;
						goal <- nil;
						targetPoint <- nil;//other agent also back to state 0
						waitDrink <- 0;
					}
					totalHappiness <- totalHappiness + 0.2;
				}
			}
			//rule2: agents with different tastes
			else if (otherType != myType) { 
				//Both agents are aggressive, pick a fight
				if(fightUtility > (1.0 / discountWeight)) {
					write '(Time ' + time + '): ' + name + ' has a fight with ' + closestAgent.name + ', both are not happy :(';
					happiness <- happiness - 0.2;
					goal <- nil; //back to state 0
					targetPoint <- nil;
					ask closestAgent {
						happiness <- happiness - 0.2;
						goal <- nil;//also back to state 0
						targetPoint <- nil;
						waitDrink <- 0;
					}
					totalHappiness <- totalHappiness - 0.4;
				}
				//both agent are not aggressive
				else {
					//both agents (with different) are friendly, buy each other a drink that they like
					 if (treatUtility > (1.0 * discountWeight)) {
					 	write '(Time ' + time + '): ' + name + ' and ' + closestAgent.name + ' buy each other a drink, both are happy ~';
						happiness <- happiness + 0.1;
						drunkenness <- drunkenness + 0.05;
						money <- money - 0.1;
						goal <- nil; //back to state 0
						targetPoint <- nil;
						ask closestAgent {
							happiness <- happiness + 0.1;
							drunkenness <- drunkenness + 0.05;
							money <- money - 0.1;
							goal <- nil;
							targetPoint <- nil;//other agent also back to state 0
							waitDrink <- 0;
						}
						totalHappiness <- totalHappiness + 0.2;
						totalMoney <- totalMoney - 0.2;
					 }
					 else if(treatUtility <= (1.0 * discountWeight)) {
					 	write '(Time ' + time + '): ' + name + ' has an akward conversation with ' + closestAgent.name + ', both are neither happy nor unhappy.';
					 	temp <- happiness;
					 	happiness <- (happiness + otherHappiness) / 2; //final happiness is average happiness of 2 agents
					 	goal <- nil; //back to state 0
						targetPoint <- nil;
						ask closestAgent {
							happiness <- (happiness + myself.temp) / 2 ;
							goal <- nil;//also back to state 0
							targetPoint <- nil;
							waitDrink <- 0;
							}				 
					 	} 
					  }
				}	
			}
		}
	
	//draw guest
	aspect default {
		draw sphere(1) color: colorState;
	}
}
 
//agent wine lover
species wine_lover parent: generic_guest skills: [fipa, moving] {
	
	string myType <- 'wine_lover';
	rgb color <- colorWine;
	rgb colorState <- color;
	
}

//agent beer lover
species beer_lover parent: generic_guest skills: [fipa, moving] {
	
	string myType <- 'beer_lover';
	rgb color <- colorBeer;
	rgb colorState <- color;
	
}

//agent whiskey lover
species whiskey_lover parent: generic_guest skills: [fipa, moving] {
	
	string myType <- 'whiskey_lover';
	rgb color <- colorWhiskey;
	rgb colorState <- color;
	
}

//agent cocktail lover
species cocktail_lover parent: generic_guest skills: [fipa, moving] {
	
	string myType <- 'cocktail_lover';
	rgb color <- colorCocktail;
	rgb colorState <- color;
	
}

//main
experiment festival type: gui {
	output {
		display main_display type: opengl {
			species bar;
			species atm;
			species toilet;
			species wine_lover;
			species beer_lover;
			species whiskey_lover;
			species cocktail_lover;
			}
		monitor "Total Happiness" value: totalHappiness;
		monitor "Total Money" value: totalMoney;
		display Happiness_information refresh: every(10#cycles) {
	    	chart "Global Happiness & Money" type: series size:{1, 0.5} position: {0, 0} {
	    		data "total_happiness_of_guests" value: totalHappiness color: #blue;
	    		data "total_money_of_guests" value: totalMoney color: #darkgoldenrod;
	    	}
	    	chart "Beer Lovers' Happiness Distribution" type: histogram size:{1.0, 0.5} position: {0, 0.5} {
	    		data "[-;0.25]" value: beer_lover count(each.happiness <= 0.25) color: #blue;
	    		data "[0.25; 0.5]" value: beer_lover count((each.happiness > 0.25) and (each.happiness <= 0.5)) color: #blue;
	    		data "[0.5; 0.75]" value: beer_lover count ((each.happiness > 0.5) and (each.happiness <= 0.75)) color: #blue;
	    		data "[0.75; 1.0]" value: beer_lover count ((each.happiness > 0.75) and(each.happiness <= 1.0)) color: #blue;
	    		data "[1.0; 1.25]" value: beer_lover count ((each.happiness > 1.0) and (each.happiness <= 1.25)) color: #blue;
	    		data "[1.25; 1.5]" value: beer_lover count ((each.happiness > 1.25) and (each.happiness <= 1.5)) color: #blue;
	    		data "[1.5-]" value: beer_lover count (each.happiness > 1.5) color: #blue;
	    	}
	    }
		}
}















