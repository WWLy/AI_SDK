//
//  BAASLanguageDetection.m
//  caiyunInterpreter
//
//  Created by yu-he on 09/12/2016.
//  Copyright © 2016 北京彩彻区明科技有限公司. All rights reserved.
//

#import "BNNSLanguageDetection.h"
#import <Foundation/Foundation.h>


void fillbuf(float* buf, int bufsize)
{
    for (int i = 0; i < bufsize; i++) {
        *(buf + i) = 0.0f;
    }
}


/* static BNNSFilter* running_layers; */
void create_network_with_data()
{

    FILE* datafile;
    struct bnns_network a_net;
    NSString* pathwithbundel = [[NSBundle mainBundle] pathForResource:@"bnns_model"
                                                               ofType:nil];

    datafile = fopen([pathwithbundel cStringUsingEncoding:NSUTF8StringEncoding], "r");
    fscanf(datafile, "%zd", &a_net.nb_layers);
    a_net.cells_in_layers = (uint16_t*)malloc(sizeof(uint16_t) * a_net.nb_layers);
    for (size_t i = 0; i < a_net.nb_layers; i++) {
        fscanf(datafile, "%hu", &a_net.cells_in_layers[i]);
    }

    a_net.weights = (float**)malloc(sizeof(float*) * (a_net.nb_layers - 1));
    for (size_t ip = 0; ip < (a_net.nb_layers - 1);ip++) {
        printf("%d", a_net.nb_layers);
        int input_size = a_net.cells_in_layers[ip];
        int output_size = a_net.cells_in_layers[ip+1];
        a_net.weights[ip] = (float*)malloc(sizeof(float) * input_size * output_size);
        for (size_t j = 0; j < (a_net.cells_in_layers[ip + 1]); j++) {
            for (size_t k = 0; k < (a_net.cells_in_layers[ip]); k++) {
                fscanf(datafile, "%f", &(a_net.weights[ip][j * a_net.cells_in_layers[ip] + k]));
            }
        }
    }

    a_net.biases = (float**)malloc(sizeof(float*) * (a_net.nb_layers - 1));
    for (size_t i = 0; i < a_net.nb_layers - 1; i++) {

        a_net.biases[i] = (float*)malloc(sizeof(float) * a_net.cells_in_layers[i + 1]);
        for (size_t j = 0; j < a_net.cells_in_layers[i + 1]; j++)
            fscanf(datafile, "%f", &a_net.biases[i][j]);
    }

    // notice cause hidden layer and activation didn't count input layer. so
    // there just n-1 bnnsfiler and n-1 activations
    a_net.activations = (BNNSActivation*)malloc(sizeof(BNNSActivation) * (a_net.nb_layers - 1));
    for (size_t i = 0; i < a_net.nb_layers - 1; i++) {
        int temp;
        fscanf(datafile, "%d", &temp);
        switch (temp){
            case 0:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionIdentity;
                break;
            case 1:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionRectifiedLinear;
                break;
            case 2:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionLeakyRectifiedLinear;
                break;
            case 3:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionSigmoid;
                break;
            case 4:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionTanh;
                break;
            case 5:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionScaledTanh;
                break;
            case 6:
                bzero(&a_net.activations[i], sizeof(a_net.activations[i]));
                a_net.activations[i].function = BNNSActivationFunctionAbs;
                break;
        }
    }


    model.nb_runnings = a_net.nb_layers -1;
    model.running_layers = (BNNSFilter*)malloc(sizeof(BNNSFilter) * (a_net.nb_layers - 1));
    BNNSVectorDescriptor input_desc;
    bzero(&input_desc, sizeof(input_desc));
    input_desc.size = a_net.cells_in_layers[0];
    input_desc.data_type = BNNSDataTypeFloat32;

    BNNSFilterParameters filter_params;
    bzero(&filter_params, sizeof(filter_params));

    BNNSVectorDescriptor previous_desc = input_desc;
    for(size_t i=0; i<a_net.nb_layers - 1;i++){

        // n-th layer apply n's input to n+1's output
        BNNSVectorDescriptor output_desc;
        bzero(&output_desc, sizeof(output_desc));
        output_desc.size = a_net.cells_in_layers[i + 1];
        // i+1 cause running_filter didn't contain input layer
        output_desc.data_type = BNNSDataTypeFloat32;

        BNNSFullyConnectedLayerParameters input_to_output_params;
        bzero(&input_to_output_params, sizeof(input_to_output_params));
        input_to_output_params.in_size = previous_desc.size;
        input_to_output_params.out_size = output_desc.size;
        input_to_output_params.activation = a_net.activations[i];
        input_to_output_params.weights.data = a_net.weights[i];
        input_to_output_params.weights.data_type = BNNSDataTypeFloat32;
        input_to_output_params.bias.data = a_net.biases[i];
        input_to_output_params.bias.data_type = BNNSDataTypeFloat32;


        model.running_layers[i] = BNNSFilterCreateFullyConnectedLayer(&previous_desc, &output_desc, &input_to_output_params, &filter_params);
        previous_desc = output_desc;
    }

    model.running_dimension = (uint16_t*)malloc(sizeof(uint16_t) * (a_net.nb_layers - 1));
    for (size_t i = 0; i < model.nb_runnings; i++) {
        model.running_dimension[i] = a_net.cells_in_layers[i+1];
    }
}

float bnns_predict(float* input){
    float* previous_input = input;
    if (input[1]<0) input[1]=0;
    int status;
    float * output = NULL;
    for (size_t i = 0; i < model.nb_runnings; i++){
        output = (float*)malloc(sizeof(float) * model.running_dimension[i]);
        fillbuf(output, model.running_dimension[i]);
        status = BNNSFilterApply(model.running_layers[i], previous_input, output); 
        if (status != 0) {
            fprintf(stderr, "BNNSFilterApply failed on hidden1_layer\n");
        }
        
        previous_input = output;
    }

    printf("\nnetwork debug: [%f %f %f %f] -> %f\n", input[0],input[1],input[2],input[3], output[0]);
    
    return output[0];
}
