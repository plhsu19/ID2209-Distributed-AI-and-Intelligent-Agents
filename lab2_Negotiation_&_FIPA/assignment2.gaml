/***
* Name: auction
* Author: peilunhsu
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model auction

/* Insert your model definition here */

global {
	int nb_auctioneers <- 1;
	int nb_participants <- 20;
	rgb colorAuctioneer1 <- #navy;
	rgb colorAuctioneer2 <- #cyan;
	point auct1Location <- {25, 25};
	point auct2Location <- {75, 75};
	
	init {
		create auctioneer number: nb_auctioneers {
			location <- auct1Location;
		}
		create participant number: nb_participants {
			location <- {5 + rnd(90), 5 + rnd(90)};
		}
	}
}

//Agent actioneers
species auctioneer skills: [fipa] {
	int initPrice <- rnd(5000, 6000);
	int price;
	int minimumPrice <- rnd(2000, 3000);
	int step <- 500;
	bool itemSold <- false;
	bool auctionStarted <- false;
	string item <- "watch";
	list<participant> participantList;

	
	//Announce participants that the auction is goint to start
	reflex send_announcement_to_participants when: ((time mod 40) = 1) {
		participantList <- participant at_distance 25;
		write '(Time ' + time + '): ' + name + ' sends an cfp message to participants: the auction is going to start!';
		do start_conversation (to: participantList, protocol: 'no-protocol', performative: 'inform', contents: ['we are going to sell this craft ', item]);
	}
	
	//Start the auction and offer the starting price after all the participants joined the auction
	reflex offer_initial_price when: (!empty(informs) and !auctionStarted) and ((time mod 40) = 3) {
		write '(Time' + time + '): ' + name + ' sends an cfp message to participants to offer the initial price';
		write 'The Auction is now starting! The price starting from ' + initPrice;
		price <- initPrice;
		do start_conversation (to: participantList, protocol: 'fipa-contract-net', performative: 'cfp', contents: [item, initPrice]);
		auctionStarted <- true;
	}
	//lower the price if there is no "buying propose" and not yet reach the minimum price
	reflex lower_price when: !empty(refuses) and empty(proposes) and auctionStarted {
		
		if((price - step) >= minimumPrice) {
			write 'Time ' + time + '): ' + name + ' send a cpf message to participants to offer a lower price';
			price <- (price - step);
			write 'selling at price ' + price;
			loop r over: refuses {
				do cfp (message: r, contents: [item, price]);
			}
		} 
		else if ((price - step) < minimumPrice) {
			write 'Time ' + time + '): ' + name + ' send a failure message to participants to announce the failure of the bid';
			write 'Reach minimum price ' + minimumPrice + ', the auction closed.';
			loop r over: refuses {
				do failure(message: r, contents: ['the auction is failed.']);
			}
			auctionStarted <- false;
		}
	}
	
	//sell the item to the buyer, the auction is successful and ending
	reflex sell_the_item when: !empty(proposes) and auctionStarted {
		write '(Time ' + time + ' ): ' + name + ' receives the buying proposal';
		loop p over: proposes {
			write 'sell the ' + item + ' to ' + p.sender + ' at price ' + price;
			do accept_proposal (message: p, contents: ['Congrats, you got the watch!']);
		}
		loop r over: refuses {
				do failure(message: r, contents: ['the item is sold, the auction is closed.']);
			}
		auctionStarted <- false;
	}
	
	//draw actioneer
	aspect default {
		draw sphere(2) color: colorAuctioneer1;
		draw circle(25) color: colorAuctioneer2;
	}
	
}

//Agent participant
species participant skills: [fipa, moving] {
	
	rgb colorParticipant <- #violet;
	bool joinedAuction <- false;
	point targetPoint <- {10 + rnd(80), 10 + rnd(80)};
	int defaultPrice <- rnd(1000, 4000);
	
	//state1: walk while not joining biding 
	reflex moveToTarget when: (!joinedAuction) {
		do goto target: targetPoint;
		colorParticipant <- #violet;
	}
	
	//state2: set next random target point
	reflex setNextTarget when: (!joinedAuction) and (location distance_to(targetPoint) < 2) {
		targetPoint <- {5 + rnd(90), 5 + rnd(90)};
		colorParticipant <- #violet;
	}
	
	//state3:join biding after receiving the cpf announcement.
	reflex join_auction when: (!empty(informs) and !joinedAuction) {
		colorParticipant <- colorAuctioneer1;
		joinedAuction <- true;
		message announce <- informs[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(announce.sender).name + ' with content: ' + announce.contents;
		write name + ' is interested in ' + announce.contents[1] + ', and will join the auction.';
		do inform (message: announce, contents: ['I will join the auction.']);
		joinedAuction <- true;
	} 
	
	//state4:reveive the price, decide to buy or refuse
	reflex decide_bidding when: !empty(cfps) and joinedAuction {
		message priceOffer <- cfps[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(priceOffer.sender).name + ' with content: ' + priceOffer.contents;
		int price_offer <- priceOffer.contents[1];
		write 'willing to buy at price ' + defaultPrice;
		if (price_offer > defaultPrice) {
			do refuse (message: priceOffer, contents: ['The price is too high !']);
			write '---------' + name + ' rejects ' + price_offer;
		}
		else if (price_offer <= defaultPrice) {
			do propose (message: priceOffer, contents: ['I will buy it!']);
			write '=========' + name + ' buys at price ' + price_offer;
		}
	}
	
	//state5: receive the failure message for auction, go to state1:
	reflex leave_the_auction when: !empty(failures) and joinedAuction {
		message f <- failures[0];
		write '(Time ' + time + '): ' + name + ' receives a failure message from ' + agent(f.sender).name + ' with content: ' + f.contents;
		write name + ' leaves the auction.';
		joinedAuction <- false;
	}
	
	//state6: receive the proposal_accept message, receive the item, go to state1
	reflex win_the_bid when: !empty(accept_proposals) and joinedAuction {
		message a <- accept_proposals[0];
		write '(Time ' + time + '): ' + name + ' receives a accept_proposal message from ' + agent(a.sender).name + ' with content: ' + a.contents;
		write 'Yes! I, ' + name + ', win the bid!' ;
		write name + ' leaves the auction.';
		joinedAuction <- false;
	}
	
	//draw participant
	aspect default {
		draw sphere(1) color: colorParticipant;
	}
}


//main
experiment festival type: gui {
	output {
		display main_display type: opengl {
			species auctioneer;
			species participant;
			}
		}
}