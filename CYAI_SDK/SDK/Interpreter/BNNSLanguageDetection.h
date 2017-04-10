//
//  BAASLanguageDetection.h
//  caiyunInterpreter
//
//  Created by yu-he on 09/12/2016.
//  Copyright © 2016 北京彩彻区明科技有限公司. All rights reserved.
//


#import <Accelerate/Accelerate.h>

#ifndef BAASLanguageDetection_h
#define BAASLanguageDetection_h

struct bnns_network {
    uint8_t nb_layers;
    // you can define a network with 255 layers at most
    uint16_t* cells_in_layers;
    // every layer support 65535 cell at most
    float** weights;
    float** biases;
    BNNSActivation* activations;
};

struct running_network {
	uint8_t nb_runnings;
	uint16_t* running_dimension;
	BNNSFilter* running_layers;
};

static struct running_network model;

void create_network_with_data();
float bnns_predict(float* input);

#endif /* BAASLanguageDetection_h */
