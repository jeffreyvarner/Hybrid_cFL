//
//  VLMatlabMLanguageAdaptor.m
//  Hybrid
//
//  Created by Jeffrey Varner on 8/5/13.
//  Copyright (c) 2013 Varnerlab. All rights reserved.
//

#import "VLMatlabMLanguageAdaptor.h"

@implementation VLMatlabMLanguageAdaptor

-(NSString *)generateSystemBalancesWithOptions:(NSDictionary *)options
{
    // get the options from the dictionary -
    NSXMLDocument *model_tree = [options objectForKey:kXMLModelTree];
    NSXMLDocument *transformation_tree = [options objectForKey:kXMLTransformationTree];
    
    // build the buffer -
    NSMutableString *buffer = [NSMutableString string];
    NSString *balances_buffer = [self buildSystemBalancesBufferFromBlueprintTree:transformation_tree andSBMLTree:model_tree];
    [buffer appendString:balances_buffer];
    
    // return -
    return [NSString stringWithString:buffer];
}


-(NSString *)generateKineticsBufferWithOptions:(NSDictionary *)options
{
    // get the options from the dictionary -
    NSXMLDocument *model_tree = [options objectForKey:kXMLModelTree];
    NSXMLDocument *transformation_tree = [options objectForKey:kXMLTransformationTree];
    
    // build the buffer -
    NSMutableString *buffer = [NSMutableString string];
    NSString *kinetics_buffer = [self buildKineticsBufferFromBlueprintTree:transformation_tree andSBMLTree:model_tree];
    [buffer appendString:kinetics_buffer];
    
    // return -
    return [NSString stringWithString:buffer];
}


-(NSString *)generateDataFileBufferWithOptions:(NSDictionary *)options
{
    // get the options from the dictionary -
    NSXMLDocument *model_tree = [options objectForKey:kXMLModelTree];
    NSXMLDocument *transformation_tree = [options objectForKey:kXMLTransformationTree];
    
    // build the buffer -
    NSMutableString *buffer = [NSMutableString string];
    NSString *header_block = [self buildHeaderBlockFromBlueprintTree:transformation_tree andSBMLTree:model_tree];
    NSString *parameter_block = [self buildRateConstantListFromSBMLTree:model_tree];
    NSString *ic_block = [self buildInitialConditionListFromSBMLTree:model_tree];
    NSString *footer_block = [self buildFooterBlockFromBlueprintTree:transformation_tree andSBMLTree:model_tree];
    [buffer appendString:header_block];
    [buffer appendString:parameter_block];
    [buffer appendString:ic_block];
    [buffer appendString:footer_block];
    
    // return -
    return [NSString stringWithString:buffer];
}

#pragma mark - private logic methods
-(NSString *)buildSystemBalancesBufferFromBlueprintTree:(NSXMLDocument *)blueprintTree
                                            andSBMLTree:(NSXMLDocument *)sbmlTree
{
    
    
    
    // Initialize the buffer -
    NSMutableString *buffer = [NSMutableString string];
    [buffer appendString:@"function [state_vector_dot] = SystemBalanceEquations(t,x,DF)\n"];
    [buffer appendString:@"% ------------------------------------------------------------------------------------- %\n"];
    [buffer appendString:@"% Copyright (c) 2013 Varnerlab,\n"];
    [buffer appendString:@"% School of Chemical and Biomolecular Engineering,\n"];
    [buffer appendString:@"% Cornell University, Ithaca NY 14853 USA.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% Permission is hereby granted, free of charge, to any person obtaining a copy\n"];
    [buffer appendString:@"% of this software and associated documentation files (the \"Software\"), to deal\n"];
    [buffer appendString:@"% in the Software without restriction, including without limitation the rights\n"];
    [buffer appendString:@"% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"];
    [buffer appendString:@"% copies of the Software, and to permit persons to whom the Software is\n"];
    [buffer appendString:@"% furnished to do so, subject to the following conditions:\n"];
    [buffer appendString:@"% The above copyright notice and this permission notice shall be included in\n"];
    [buffer appendString:@"% all copies or substantial portions of the Software.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"];
    [buffer appendString:@"% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"];
    [buffer appendString:@"% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"];
    [buffer appendString:@"% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"];
    [buffer appendString:@"% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"];
    [buffer appendString:@"% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\n"];
    [buffer appendString:@"% THE SOFTWARE.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% SystemBalanceEquations.m \n"];
    [buffer appendString:@"% SystemBalanceEquations takes the time, state_vector and the data struct and calculates \n"];
    [buffer appendString:@"% the state_vector_dot for a given model.\n"];
    [buffer appendString:@"% ------------------------------------------------------------------------------------- %\n"];
    [buffer appendFormat:@"\n"];
    [buffer appendString:@"% Define the state vector - \n"];
    [buffer appendString:@"NUMBER_OF_STATES = DF.NUMBER_OF_STATES;\n"];
    [buffer appendString:@"state_vector_dot = zeros(NUMBER_OF_STATES,1);\n"];
    [buffer appendString:@"\n"];
    [buffer appendString:@"% Calculate the kinetics vector - \n"];
    [buffer appendString:@"rate_vector = Kinetics(x,DF);\n"];
    [buffer appendString:@"\n"];
    
    [buffer appendString:@"% Formulate balance equations - \n"];
    [buffer appendString:@"\n"];
    
    // get the list of species -
    NSArray *species_array = [sbmlTree nodesForXPath:@".//species" error:nil];
    NSUInteger species_counter = 1;
    for (NSXMLElement *species_node in species_array)
    {
        // Get the species symbol, and type -
        NSString *species_symbol = [[species_node attributeForName:@"symbol"] stringValue];
        NSString *species_type = [[species_node attributeForName:@"type"] stringValue];
        
        // ok, if we have a constant node, the generate a state_vector_dot = 0;
        if ([species_type isEqualToString:@"constant"] == YES)
        {
            [buffer appendFormat:@"%%\t %lu - %@\n",species_counter,species_symbol];
            [buffer appendFormat:@"state_vector_dot(%lu,1) = 0.0;\n",species_counter];
        }
        
        // next, lets generate the dynamic equations -
        if ([species_type isEqualToString:@"dynamic"] == YES)
        {
            [buffer appendFormat:@"%%\t %lu - %@\n",species_counter,species_symbol];
            [buffer appendFormat:@"state_vector_dot(%lu,1) = code_here;\n",species_counter];
        }
        
        // update the counter -
        species_counter = species_counter + 1;
    }
    
    
    
    
    
    
    
    [buffer appendString:@"% Formulate dynamic balances - \n"];
    
    [buffer appendString:@"return;\n"];

    
    // return -
    return buffer;
}

-(NSString *)buildKineticsBufferFromBlueprintTree:(NSXMLDocument *)blueprintTree
                                      andSBMLTree:(NSXMLDocument *)sbmlTree
{
    // Initialize the buffer -
    NSMutableString *buffer = [NSMutableString string];
    
    // DataFile function -
    [buffer appendString:@"function rate_vector = Kinetics(state_vector,DF)\n"];
    [buffer appendString:@"% ------------------------------------------------------------------------------------- %\n"];
    [buffer appendString:@"% Copyright (c) 2013 Varnerlab,\n"];
    [buffer appendString:@"% School of Chemical and Biomolecular Engineering,\n"];
    [buffer appendString:@"% Cornell University, Ithaca NY 14853 USA.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% Permission is hereby granted, free of charge, to any person obtaining a copy\n"];
    [buffer appendString:@"% of this software and associated documentation files (the \"Software\"), to deal\n"];
    [buffer appendString:@"% in the Software without restriction, including without limitation the rights\n"];
    [buffer appendString:@"% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"];
    [buffer appendString:@"% copies of the Software, and to permit persons to whom the Software is\n"];
    [buffer appendString:@"% furnished to do so, subject to the following conditions:\n"];
    [buffer appendString:@"% The above copyright notice and this permission notice shall be included in\n"];
    [buffer appendString:@"% all copies or substantial portions of the Software.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"];
    [buffer appendString:@"% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"];
    [buffer appendString:@"% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"];
    [buffer appendString:@"% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"];
    [buffer appendString:@"% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"];
    [buffer appendString:@"% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\n"];
    [buffer appendString:@"% THE SOFTWARE.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% Kinetics.m \n"];
    [buffer appendString:@"% Kinetics takes the state_vector and the data struct and calculates the transfer\n"];
    [buffer appendString:@"% function values for a given model.\n"];
    [buffer appendString:@"% ------------------------------------------------------------------------------------- %\n"];
    [buffer appendFormat:@"\n"];
    [buffer appendString:@"% State symbols - \n"];
    
    // Get the species vectors -
    NSArray *states_array = [sbmlTree nodesForXPath:@"//listOfSpecies/species/@symbol" error:nil];
    NSInteger species_counter = 1;
    for (NSXMLElement *node in states_array)
    {
        NSString *species_symbol = [node stringValue];
        [buffer appendFormat:@"%@ = state_vector(%lu,1);\n",species_symbol,species_counter];
        
        // update counter -
        species_counter = species_counter + 1;
    }
    
    // new line -
    [buffer appendString:@"\n"];
    
    // parameters -
    NSArray *parameter_array = [sbmlTree nodesForXPath:@".//parameter/@symbol" error:nil];
    [buffer appendString:@"% Parameter symbols - \n"];
    [buffer appendString:@"RATE_CONSTANT_VECTOR = DF.RATE_CONSTANT_VECTOR;\n"];
    NSInteger parameter_counter = 1;
    for (NSXMLElement *parameter_node in parameter_array)
    {
        NSString *parameter_symbol = [parameter_node stringValue];
        [buffer appendFormat:@"%@ = RATE_CONSTANT_VECTOR(%lu,1);\n",parameter_symbol,parameter_counter];
        parameter_counter = parameter_counter + 1;
    }
    
    // new line -
    [buffer appendString:@"\n"];
    
    // get the rates -
    NSArray *rates = [sbmlTree nodesForXPath:@".//operation/@name" error:nil];
    
    // initialize -
    [buffer appendString:@"% Initialize and populate the rate vector - \n"];
    [buffer appendString:@"NUMBER_OF_RATES = DF.NUMBER_OF_RATES;\n"];
    [buffer appendString:@"rate_vector = zeros(NUMBER_OF_RATES,1);\n"];
    
    // new line -
    [buffer appendString:@"\n"];
    NSInteger rate_counter = 1;
    for (NSXMLElement *rate_node in rates)
    {
        // Get the operation name -
        NSString *operation_name = [rate_node stringValue];
        
        // what type of operation is this?
        NSString *operation_type_xpath = [NSString stringWithFormat:@".//operation[@name='%@']/rule/@type",operation_name];
        NSString *operation_type = [[[sbmlTree nodesForXPath:operation_type_xpath error:nil] lastObject] stringValue];
        
        // reactants?
        NSString *operation_reactants_xpath = [NSString stringWithFormat:@".//operation[@name='%@']/listOfReactants/species_reference/@symbol",operation_name];
        NSArray *operation_reactants = [sbmlTree nodesForXPath:operation_reactants_xpath error:nil];
        
        // ok, so I we need to build the rate law -
        [buffer appendFormat:@"%%\tOperation: %@ type: %@\n",operation_name,operation_type];
        
        // need to lookup the value for each type of parameter -
        NSString *parameter_symbol_xpath_scale = [NSString stringWithFormat:@".//operation[@name='%@']/rule[@type='%@']/listOfParameters/parameter[@type = 'SCALE']/@symbol",operation_name,operation_type];
        NSString *parameter_symbol_xpath_sat = [NSString stringWithFormat:@".//operation[@name='%@']/rule[@type='%@']/listOfParameters/parameter[@type = 'SATURATION']/@symbol",operation_name,operation_type];
        NSString *parameter_symbol_xpath_hill = [NSString stringWithFormat:@".//operation[@name='%@']/rule[@type='%@']/listOfParameters/parameter[@type = 'HILL']/@symbol",operation_name,operation_type];
        NSString *parameter_symbol_scale = [[[sbmlTree nodesForXPath:parameter_symbol_xpath_scale error:nil] lastObject] stringValue];
        NSString *parameter_symbol_saturation = [[[sbmlTree nodesForXPath:parameter_symbol_xpath_sat error:nil] lastObject] stringValue];
        NSString *parameter_symbol_hill = [[[sbmlTree nodesForXPath:parameter_symbol_xpath_hill error:nil] lastObject] stringValue];
        
        // ok, so if we have activating -
        if ([operation_type isEqualToString:@"SINGLE_REACTANT_ACTIVATION"]==YES)
        {
            // what are the inouts?
            NSString *reactant_symbol = [[operation_reactants lastObject] stringValue];
            [buffer appendFormat:@"INPUT_%@ = %@;\n",operation_name,reactant_symbol];
        }
        else if ([operation_type isEqualToString:@"MULTIPLE_REACTANT_AND"]==YES)
        {
            // ok, so here we are *multiple* inputs -
            NSMutableString *local_buffer = [NSMutableString string];
            NSInteger COUNT = [operation_reactants count];
            NSInteger reactant_counter = 0;
            for (NSXMLElement *reactant_node in operation_reactants)
            {
                NSString *reactant_symbol = [reactant_node stringValue];
                
                // ok, so I need to figure out the proptionality -
                NSString *prop_xpath = [NSString stringWithFormat:@".//operation[@name='%@']/listOfReactants/species_reference[@symbol='%@']/@proportionality",operation_name,reactant_symbol];
                NSString *prop_direction = [[[sbmlTree nodesForXPath:prop_xpath error:nil] lastObject] stringValue];
                if ([prop_direction isEqualToString:@"inverse"]==YES)
                {
                    [local_buffer appendFormat:@"(1 - %@)",reactant_symbol];
                }
                else
                {
                    [local_buffer appendFormat:@"%@",reactant_symbol];
                }
                
                if (reactant_counter == COUNT - 1)
                {
                    [local_buffer appendString:@";\n"];
                }
                else
                {
                    reactant_counter = reactant_counter + 1;
                    [local_buffer appendString:@"*"];
                }
            }
            
            [buffer appendFormat:@"INPUT_%@ = %@",operation_name,local_buffer];
        }
        else if ([operation_type isEqualToString:@"SINGLE_PRODUCT_INHIBITION"]==YES)
        {
            // what are the inouts?
            NSString *reactant_symbol = [[operation_reactants lastObject] stringValue];
            [buffer appendFormat:@"INPUT_%@ = 1 - %@;\n",operation_name,reactant_symbol];
        }
        
        [buffer appendFormat:@"rate_vector(%lu,1) = %@*(%@^%@ + 1)*(INPUT_%@^%@)/(%@^%@ + INPUT_%@^%@);\n",rate_counter,
         parameter_symbol_scale,parameter_symbol_saturation,parameter_symbol_hill,operation_name,parameter_symbol_hill,parameter_symbol_saturation,
         parameter_symbol_hill,operation_name,parameter_symbol_hill];
        
        // new line -
        [buffer appendString:@"\n"];
        
        // update the counter -
        rate_counter = rate_counter + 1;
    }
    
    [buffer appendString:@"return;\n"];
    
    // return buffer
    return [NSString stringWithString:buffer];
}

-(NSString *)buildHeaderBlockFromBlueprintTree:(NSXMLDocument *)blueprintTree
                                   andSBMLTree:(NSXMLDocument *)sbmlTree
{
    // Initialize the buffer -
    NSMutableString *buffer = [NSMutableString string];
    
    // DataFile function -
    [buffer appendString:@"function DF = DataFile(TSTART,TSTOP,Ts,INDEX)\n"];
    [buffer appendString:@"% ------------------------------------------------------------------------------------- %\n"];
    [buffer appendString:@"% Copyright (c) 2013 Varnerlab,\n"];
    [buffer appendString:@"% School of Chemical and Biomolecular Engineering,\n"];
    [buffer appendString:@"% Cornell University, Ithaca NY 14853 USA.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% Permission is hereby granted, free of charge, to any person obtaining a copy\n"];
    [buffer appendString:@"% of this software and associated documentation files (the \"Software\"), to deal\n"];
    [buffer appendString:@"% in the Software without restriction, including without limitation the rights\n"];
    [buffer appendString:@"% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"];
    [buffer appendString:@"% copies of the Software, and to permit persons to whom the Software is\n"];
    [buffer appendString:@"% furnished to do so, subject to the following conditions:\n"];
    [buffer appendString:@"% The above copyright notice and this permission notice shall be included in\n"];
    [buffer appendString:@"% all copies or substantial portions of the Software.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"];
    [buffer appendString:@"% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"];
    [buffer appendString:@"% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"];
    [buffer appendString:@"% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"];
    [buffer appendString:@"% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"];
    [buffer appendString:@"% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\n"];
    [buffer appendString:@"% THE SOFTWARE.\n"];
    [buffer appendString:@"%\n"];
    [buffer appendString:@"% DataFile.m \n"];
    [buffer appendString:@"% DataFile holds the parameters and initial conditions for the cFL model. This struct\n"];
    [buffer appendString:@"% is passed around to the various functions and *can* be modfied in memory.\n"];
    [buffer appendString:@"% ------------------------------------------------------------------------------------- %\n"];
    [buffer appendFormat:@"\n"];
    [buffer appendString:@"% Dimension of the system - \n"];
    
    // Get the dimension of rates, and states -
    NSArray *rates = [sbmlTree nodesForXPath:@".//operation/@name" error:nil];
    NSArray *states_not_unique_array = [sbmlTree nodesForXPath:@".//species/@symbol" error:nil];
    NSMutableSet *state_vector = [NSMutableSet set];
    for (NSXMLElement *node in states_not_unique_array)
    {
        // Get the state -
        NSString *state_symbol = [node stringValue];
        
        // add -
        [state_vector addObject:state_symbol];
    }
    
    
    // put the dimension -
    [buffer appendFormat:@"NUMBER_OF_RATES = %ld;\n",[rates count]];
    [buffer appendFormat:@"NUMBER_OF_STATES = %ld;\n",[state_vector count]];
    
    // return buffer
    return [NSString stringWithString:buffer];
}

-(NSString *)buildFooterBlockFromBlueprintTree:(NSXMLDocument *)blueprintTree
                                   andSBMLTree:(NSXMLDocument *)sbmlTree
{
    // Initialize the buffer -
    NSMutableString *buffer = [NSMutableString string];
    
    // Footer block -
    // open -
    [buffer appendString:@"\n"];
    [buffer appendString:@"% =========== DO NOT EDIT BELOW THIS LINE ================ %\n"];
    [buffer appendString:@"DF.RATE_CONSTANT_VECTOR = RATE_CONSTANT_VECTOR;\n"];
    [buffer appendString:@"DF.INITIAL_CONDITION_VECTOR = INITIAL_CONDITION_VECTOR;\n"];
    [buffer appendString:@"DF.NUMBER_OF_RATES = NUMBER_OF_RATES;\n"];
    [buffer appendString:@"DF.NUMBER_OF_STATES = NUMBER_OF_STATES;\n"];
    [buffer appendString:@"DF.MEASUREMENT_SELECTION_VECTOR = 1:NUMBER_OF_STATES;\n"];
    // close -
    [buffer appendString:@"% ======================================================== %\n"];
    [buffer appendString:@"return;\n"];
    
    // return buffer
    return [NSString stringWithString:buffer];
}

-(NSString *)buildInitialConditionListFromSBMLTree:(NSXMLDocument *)sbmlTree
{
    // Initialize the buffer -
    NSMutableString *buffer = [NSMutableString string];
    
    // get my species -
    NSArray *states_not_unique_array = [sbmlTree nodesForXPath:@".//species" error:nil];
    NSMutableArray *state_vector = [NSMutableArray array];
    for (NSXMLElement *node in states_not_unique_array)
    {
        [state_vector addObject:node];
    }
    
    // Formulate rate constant buffer -
    // open -
    [buffer appendString:@"\n"];
    [buffer appendString:@"INITIAL_CONDITION_VECTOR = [\n"];
    
    NSArray *compartmentArray = [sbmlTree nodesForXPath:@"//listOfCompartments/compartment/@name" error:nil];
    NSInteger counter = 0;
    for (NSXMLElement *compartmentNode in compartmentArray)
    {
        // Get the compartment -
        NSString *compartmentID = [compartmentNode stringValue];
        
        // alias the species -
        @autoreleasepool {
            
            // ok, iterate through the species, check for matching compartment
            for (NSXMLElement *species_node in state_vector)
            {
                // Species symbol -
                NSString *species_symbol = [[species_node attributeForName:@"symbol"] stringValue];
                
                // What is the compartment for this species?
                NSString *species_compartment = [[species_node attributeForName:@"compartment"] stringValue];
                if ([species_compartment isEqualToString:compartmentID] == YES)
                {
                    // Get the initial amount -
                    NSString *initial_amount = [[species_node attributeForName:@"initial_amount"] stringValue];
                    NSString *type_flag = [[species_node attributeForName:@"type"] stringValue];
                    
                    // write the line -
                    [buffer appendFormat:@"\t%@\t;\t%% %ld %@ (type: %@) %@\n",initial_amount,counter+1,species_symbol,type_flag,compartmentID];
                    
                    // update counter -
                    counter = counter + 1;
                }
            }
        }
    }
    
    // close -
    [buffer appendString:@"];\n"];
    
    
    // return buffer
    return [NSString stringWithString:buffer];
}

-(NSString *)buildRateConstantListFromSBMLTree:(NSXMLDocument *)sbmlTree
{
    // Initialize the buffer -
    NSMutableString *buffer = [NSMutableString string];
    
    // Formulate rate constant buffer -
    // open -
    [buffer appendString:@"\n"];
    [buffer appendString:@"RATE_CONSTANT_VECTOR = [\n\n"];
    
    // Get the operation names -
    NSArray *operationArray = [sbmlTree nodesForXPath:@".//listOfOperations/operation/@name" error:nil];
    NSInteger counter = 0;
    NSInteger operation_counter = 0;
    for (NSXMLElement *name_node in operationArray)
    {
        // Get the name -
        NSString *operation_name = [name_node stringValue];
        
        // ok, so get the parameters for this operation -
        NSString *parameter_xpath = [NSString stringWithFormat:@".//operation[@name='%@']/rule/listOfParameters/parameter/@symbol",operation_name];
        NSArray *parameterArray = [sbmlTree nodesForXPath:parameter_xpath error:nil];
        
        // what is the operation name?
        [buffer appendFormat:@"\t%% Operation: %lu %@\n",(operation_counter + 1),operation_name];
        
        // ok, so write a schematic of the reaction for debugging -
        NSString *operation_reaction_string = [self buildReactionStringRepresentationForOperationWithName:operation_name fromSBMLTree:sbmlTree];
        [buffer appendFormat:@"\t%% %@",operation_reaction_string];
        
        __unused NSInteger NUMBER_OF_RATES = [parameterArray count];
        for (NSXMLElement *parameterNode in parameterArray)
        {
            // Get id of rate -
            NSString *parameterID = [parameterNode stringValue];
            
            // Ok, so I don't have the reaction name -
            NSString *xpath = [NSString stringWithFormat:@".//parameter[@symbol='%@']/@value",parameterID];
            NSString *value = [[[sbmlTree nodesForXPath:xpath error:nil] lastObject] stringValue];
            [buffer appendFormat:@"\t%@\t;\t%% %ld %@\n",value,counter+1,parameterID];
            
            // update the counter -
            counter = counter + 1;
        }
        
        // update operation counter -
        operation_counter = operation_counter + 1;
        
        // add a new line -
        [buffer appendString:@"\n"];
    }
    
    // ok, so we need to have zero-order input and first-order degradation constants for all *basal* species -
    NSArray *basal_states_array = [sbmlTree nodesForXPath:@".//species[@type='basal']" error:nil];
    for (NSXMLElement *species_node in basal_states_array)
    {
        NSString *state_symbol = [[species_node attributeForName:@"symbol"] stringValue];
        [buffer appendFormat:@"\t1.0\t;\t%% %ld %@ generation constant\n",counter+1,state_symbol];
        
        // update the counter -
        counter = counter + 1;
    }
    
    for (NSXMLElement *species_node in basal_states_array)
    {
        NSString *state_symbol = [[species_node attributeForName:@"symbol"] stringValue];
        [buffer appendFormat:@"\t0.1\t;\t%% %ld %@ degradation constant\n",counter+1,state_symbol];
        
        // update the counter -
        counter = counter + 1;
    }

    
    // close -
    [buffer appendString:@"];\n"];
    
    // return buffer
    return [NSString stringWithString:buffer];
}

-(NSString *)buildReactionStringRepresentationForOperationWithName:(NSString *)operatioName
                                                      fromSBMLTree:(NSXMLDocument *)sbmlTree
{
    // ok, so I need to get the reactants and products for this reaction (including whether or not they are direct or indirect)
    
    // get productions -
    NSString *products_string = [NSString stringWithFormat:@".//operation[@name='%@']/listOfProducts/species_reference/@symbol",operatioName];
    NSArray *products_array = [sbmlTree nodesForXPath:products_string error:nil];
    
    // get reactants -
    NSString *reactants_string = [NSString stringWithFormat:@".//operation[@name='%@']/listOfReactants/species_reference/@symbol",operatioName];
    NSArray *reactants_array = [sbmlTree nodesForXPath:reactants_string error:nil];
    
    // ok, so let's formulate the string -
    NSMutableString *buffer = [NSMutableString string];
    NSInteger counter = 0;
    NSInteger NUMBER_OF_REACTANTS = [reactants_array count];
    for (NSXMLElement *reactant_node in reactants_array)
    {
        // get the symbol -
        NSString *reactant_symbol = [reactant_node stringValue];
        
        // need to check the proportionality -
        NSString *xpath_proportionality = [NSString stringWithFormat:@".//operation[@name='%@']/listOfReactants/species_reference[@symbol='%@']/@proportionality",operatioName,reactant_symbol];
        NSString *direction = [[[sbmlTree nodesForXPath:xpath_proportionality error:nil] lastObject] stringValue];
        if ([direction isEqualToString:@"direct"] == YES)
        {
            [buffer appendString:reactant_symbol];
        }
        else if ([direction isEqualToString:@"inverse"] == YES)
        {
            NSString *inverse = [NSString stringWithFormat:@"(1 - %@)",reactant_symbol];
            [buffer appendString:inverse];
        }
        
        if (counter != (NUMBER_OF_REACTANTS - 1))
        {
            [buffer appendString:@"*"];
        }
        
        // update the counter -
        counter = counter + 1;
    }
    
    // arrow -
    [buffer appendString:@" ---------> "];
    
    // process the products -
    [buffer appendString:@"["];
    for (NSXMLElement *product_node in products_array)
    {
        // get the symbol -
        NSString *product_symbol = [product_node stringValue];
        
        // add to buffer -
        [buffer appendString:product_symbol];
    }
    
    // close -
    [buffer appendString:@"];\n"];
    
    // return buffer
    return [NSString stringWithString:buffer];
}


@end
