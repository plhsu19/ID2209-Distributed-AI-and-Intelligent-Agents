/***
* Name: assignbasic3
* Author: peilunhsu
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model lab3basic2

/* Insert your model definition here */

global {
	int nb_stages <- 4;
	int nb_guests <- 20;
	rgb colorStage <- #navy;
	list<point> stageLocation <- [{25,25}, {75, 25}, {25, 75}, {75, 75}];
	int i <- 0;
	
	init {
		create stage number: nb_stages {
			location <- stageLocation at i;
			i <- i + 1;
		}
		create guest number: nb_guests {
			location <- {5 + rnd(90), 5 + rnd(90)};
		}
	}
}
//agent stage
species stage skills: [fipa] {
	float lightW <- rnd(float(1));
	float soundW <- rnd(float(1));
	float bandW <- rnd(float(1));
	float foodW <- rnd(float(1));
	float drinkW <- rnd(float(1));
	float crowdW <- rnd(float(1));
	bool concertStarted <- false;
	//list<guest> guestList <- list(guest);

	
	/*Announce guests that the auction is goint to start
	reflex send_announcement_to_guests when: ((time mod 40) = 1) {
		guestList <- guest at_distance 25;
		write '(Time ' + time + '): ' + name + ' sends an cfp message to guests: the auction is going to start!';
		do start_conversation (to: guestList, protocol: 'no-protocol', performative: 'inform', contents: ['we are going to sell this craft ', item]);
	}*/
	
	//Send the stage variables to guests
	reflex send_variables when: !concertStarted and ((time mod 50) = 1) {
		lightW <- rnd(float(1));
		soundW <- rnd(float(1));
		bandW <- rnd(float(1));
		foodW <- rnd(float(1));
		drinkW <- rnd(float(1));
		crowdW <- rnd(float(1));
		write '(Time' + time + '): ' + name + ' sends an cfp message to guests to provide the stage values of the upcoming concert';
		do start_conversation (to: list(guest), protocol: 'fipa-contract-net', performative: 'cfp', contents: [lightW, soundW, bandW, foodW, drinkW, crowdW]);
		concertStarted <- true;
	}
	
	//end the concert
	reflex end_the_concert when: concertStarted and ((time mod 50) = 35) {
		concertStarted <- false;
	}
	
	/*sell the item to the buyer, the auction is successful and ending
	reflex sell_the_item when: !empty(proposes) and auctionStarted {
		write '(Time ' + time + ' ): ' + name + ' receives the buying proposal';
		loop p over: proposes {
			write 'sell the ' + item + ' to ' + p.sender + ' at price ' + price;
			do accept_proposal (message: p, contents: ['Congrats, you got the watch!']);
		}
		loop r over: refuses {
				do failure(message: r, contents: ['the item is sold, the auction is closed.']);
			
		auctionStarted <- false;
	}*/
	
	//draw stage
	aspect default {
		draw square(20) color: colorStage;
	}
	
}

//Agent guest
species guest skills: [fipa, moving] {
	float light <- rnd(float(1));
	float sound <- rnd(float(1));
	float band <- rnd(float(1));
	float food <- rnd(float(1));
	float drink <- rnd(float(1));
	float crowd <- rnd(float(1));
	rgb colorguest <- #violet;
	bool joinedConcert <- false;
	point targetPoint <- nil;
	float utility <- float(0);
	float maxUtility <- float(0);
	stage targetStage;

	//state1: go to target stage
	reflex moveToTarget when: targetPoint != nil {
		do goto target: targetPoint;
		speed <- 3.0;
	}
	
	/*
	reflex join_auction when: (!empty(informs) and !joinedAuction) {
		colorguest <- colorStage;
		joinedAuction <- true;
		message announce <- informs[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(announce.sender).name + ' with content: ' + announce.contents;
		write name + ' is interested in ' + announce.contents[1] + ', and will join the auction.';
		do inform (message: announce, contents: ['I will join the auction.']);
		joinedAuction <- true;
	} */
	
	//state2: decide which stage to go
	reflex decide_stage when: !empty(cfps) and !joinedConcert {

		loop c over: cfps { //c = the message from one stage
			message attrs <- c;
			float light_w <- attrs.contents[0];
			float sound_w <- attrs.contents[1];
			float band_w <- attrs.contents[2];
			float food_w <- attrs.contents[3];
			float drink_w <- attrs.contents[4];
			float crowd_w <- attrs.contents[5];
			utility <- (light * light_w + sound * sound_w + band * band_w + food * food_w + drink * drink_w + crowd * crowd_w);
			if (utility > maxUtility) {
				maxUtility <- utility;
				targetStage <- c.sender;
			}
		}
		write '(Time ' + time + '): ' + name + ' will go to ' + targetStage.name + ', that has highest utility: ' + maxUtility;
		targetPoint <- {targetStage.location.x + rnd(5), targetStage.location.y + rnd(5)};
		joinedConcert <- true;
	}
	
	//state3: leave the concert
	reflex leave_the_concert when: (time mod 50 = 35) and joinedConcert {
		write name + ' left the concert.';
		utility <- float(0);
		maxUtility <- float(0);
		targetStage <- nil;
		joinedConcert <- false;
		targetPoint <- {10 + rnd(80), 10 + rnd(80)};
	}
	
	/*state6: receive the proposal_accept message, receive the item, go to state1
	reflex win_the_bid when: !empty(accept_proposals) and joinedAuction {
		message a <- accept_proposals[0];
		write '(Time ' + time + '): ' + name + ' receives a accept_proposal message from ' + agent(a.sender).name + ' with content: ' + a.contents;
		write 'Yes! I, ' + name + ', win the bid!' ;
		write name + ' leaves the auction.';
		joinedAuction <- false;
	}*/
	
	//draw guest
	aspect default {
		draw sphere(1) color: colorguest;
	}
}


//main
experiment festival type: gui {
	output {
		display main_display type: opengl {
			species stage;
			species guest;
				}
			}
		}
