//
//  VLDocument.m
//  Hybrid
//
//  Created by Jeffrey Varner on 8/5/13.
//  Copyright (c) 2013 Varnerlab. All rights reserved.
//

#import "VLDocument.h"
#import "VLTransformationServiceVendor.h"

@interface VLDocument ()

// private properties -
@property (strong) IBOutlet NSButton *myGenerateCodeButton;
@property (strong) IBOutlet NSButton *myCancelButton;
@property (strong) IBOutlet NSButton *myOpenModelFileButton;
@property (strong) IBOutlet NSButton *myOverwriteModelFilesCheckBox;
@property (strong) IBOutlet NSComboBox *myModelOutputTypeComboBox;
@property (strong) IBOutlet NSTextField *myConsoleTextField;
@property (strong) IBOutlet NSTextField *myModelSpecificationPathTextField;
@property (strong) IBOutlet NSProgressIndicator *myCodeGenerationProgressIndicator;

@property (strong) NSWindowController *myWindowController;
@property (strong) NSURL *myBlueprintFileURL;
@property (strong) NSArray *myDefaultOutputTypes;
@property (strong) NSString *mySelectedLanguageAdaptor;

// private methdos
-(void)setup;


@end

@implementation VLDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"VLDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    // Ok, call the super -
    [super windowControllerDidLoadNib:aController];
    
    // grab the controller -
    self.myWindowController = aController;
    
    // Start the foundation server -
    [VLCodeGenerationFoundationServer sharedFoundationServer];
    
    // initialize me -
    [self setup];
    
    // Setup completion notification -
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    // VLTransformationJobUpdateNotification -
    [center addObserverForName:VLTransformationJobProgressUpdateNotification
                        object:nil
                         queue:mainQueue
                    usingBlock:^(NSNotification *notification){
                        
                        // Get the message from the notification -
                        NSString *message = [notification object];
                        
                        // update the label -
                        NSString *current_text = [[self myConsoleTextField] stringValue];
                        NSString *new_text = [NSString stringWithFormat:@"%@\n%@",current_text,message];
                        [[self myConsoleTextField] setStringValue:new_text];
                    }];
    
    // VLTransformationJobCompletedNotification -
    [center addObserverForName:VLTransformationJobDidCompleteNotification
                        object:nil
                         queue:mainQueue
                    usingBlock:^(NSNotification *notification){
                        
                        // shutdown the progress bar animation -
                        [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
                        
                        // what is my end time?
                        CFTimeInterval _myExecutionDuration = CFAbsoluteTimeGetCurrent() - _myExecutionStartTime;
                        
                        // Set the completed text -
                        NSString *current_text = [[self myConsoleTextField] stringValue];
                        NSString *new_text = [NSString stringWithFormat:@"%@\n%@ in %f seconds",current_text,@"Status: Transformation completed ",_myExecutionDuration];
                        [[self myConsoleTextField] setStringValue:new_text];
                    }];

}


#pragma mark - actions
-(IBAction)codeGenerationBeginGenerationButtonWasTapped:(NSButton *)button
{
    // ok, so check to make sure we have a URL - if we do then begin the generation
    // process. If not, then open the open panel -
    if ([self myBlueprintFileURL]!=nil)
    {
        // grab my start time -
        _myExecutionStartTime = CFAbsoluteTimeGetCurrent();
        
        // start the progress bar animation -
        [[self myCodeGenerationProgressIndicator] startAnimation:nil];
        
        // clear out the console -
        [[self myConsoleTextField] setStringValue:@""];
        
        // Ok, so when I get here I have the blueprint file URL.
        // We need to start the code generation process for this blueprint file.
        // Get the blueprint URL -
        NSURL *localBlueprintURL = [self myBlueprintFileURL];
        
        // Load the blueprint file -
        NSXMLDocument *blueprintTree = [VLCoreUtilitiesLib createXMLDocumentFromFile:localBlueprintURL];
        
        // do we have a blueprint tree?
        if (blueprintTree != nil)
        {
            // Get the transformation xml blocks -
            NSArray *transformBlockNames = [VLCoreUtilitiesLib executeXPathQuery:@"//Transformation/@name"
                                                                     withXMLTree:blueprintTree];
            // Process the transformations -
            for (NSXMLElement *node in transformBlockNames)
            {
                // Get the name of this transformation -
                NSString *transformationName = [node stringValue];
                
                // update the progress text label -
                NSString *current_text = [[self myConsoleTextField] stringValue];
                if ([current_text length]>0)
                {
                    NSString *progressText = [NSString stringWithFormat:@"%@\nStatus: Processing %@ block",current_text,transformationName];
                    [[self myConsoleTextField] setStringValue:progressText];
                }
                else
                {
                    NSString *progressText = [NSString stringWithFormat:@"Status: Processing %@ block",transformationName];
                    [[self myConsoleTextField] setStringValue:progressText];
                }
                
                
                // Get the input and output classname -
                NSString *inputClassNameXPath = [NSString stringWithFormat:@"//Transformation[@name='%@']/@classname",transformationName];
                

                
                
                
                
                // execute the query -
                NSString *inputClassName = [[[VLCoreUtilitiesLib executeXPathQuery:inputClassNameXPath
                                                                       withXMLTree:blueprintTree] lastObject] stringValue];
                
                // do we have a selected language adaptor?
                NSString *languageClassName = nil;
                if ([self mySelectedLanguageAdaptor]!=nil)
                {
                    languageClassName = [self mySelectedLanguageAdaptor];
                }
                else
                {
                    NSString *languageXPath = [NSString stringWithFormat:@"//Transformation[@name='%@']/@language",transformationName];
                    languageClassName = [[[VLCoreUtilitiesLib executeXPathQuery:languageXPath
                                                                              withXMLTree:blueprintTree] lastObject] stringValue];
                }
                
                
                
                // Build the input and output handlers -
                VLTransformationServiceVendor *vendor = [[NSClassFromString(inputClassName) alloc] init];
                VLAbstractLanguageAdaptor *language = [[NSClassFromString(languageClassName) alloc] init];
                
                // set the blueprint tree -
                [vendor setMyBlueprintTree:blueprintTree];
                [vendor setMyLanguageAdaptor:language];
                
                // execute the transformations -
                [vendor startTransformationWithName:transformationName];
            }
        }
        else
        {
            // stop progress bar
            [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
            
            // ok, we don't have a blueprint file ... through up a error view
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Try again"];
            [alert setMessageText:@"Ooops! Are you sure you want to load this transformation file?"];
            [alert setInformativeText:@"This file does not appear to be the correct format."];
            [alert setAlertStyle:NSCriticalAlertStyle];
            
            [alert beginSheetModalForWindow:[[self myWindowController] window]
                              modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        }
    }
    else
    {
        [self codeGenerationLoadTransformationBlueprintButtonWasTapped:nil];
    }
}

-(IBAction)codeGenerationCancelGenerationButtonWasTapped:(NSButton *)button
{
    
}

-(IBAction)codeGenerationLoadTransformationBlueprintButtonWasTapped:(NSButton *)button
{
    // Launch the NSOpenPanel logic, capture the user filename and present the path in the text fld
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    // Configure the panel -
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanCreateDirectories:YES];
    
    // Run the panel as a sheet -
    [openPanel beginSheetModalForWindow:[[self myWindowController] window]
                      completionHandler:^(NSInteger resultIndex){
                          
                          // Ok, so this block gets executed *after* we have selected a file
                          if (resultIndex == NSFileHandlingPanelOKButton)
                          {
                              // Ok, so when I get here the user has hit the OK button
                              NSURL *mySelectedURL = [openPanel URL];
                              
                              // grab this URL for later -
                              self.myBlueprintFileURL = mySelectedURL;
                              
                              // Create a file path string -
                              NSString *pathString = [mySelectedURL absoluteString];
                              
                              // Set the value in the text fld -
                              [[self myModelSpecificationPathTextField] setStringValue:pathString];
                          }
                          else if (resultIndex == NSFileHandlingPanelCancelButton)
                          {
                              // Ok, so when I get here the user has hit the cancel button
                              // for now, do nothing.
                          }
                          
                      }];
}


#pragma mark - combobox datasource/delegate methods
- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    // ok, the combox box selection changed. What item is selected?
    NSUInteger selected_language_index = [[self myModelOutputTypeComboBox] indexOfSelectedItem];
    
    // grab the node for this selection -
    NSXMLElement *node = [[self myDefaultOutputTypes] objectAtIndex:selected_language_index];
    
    // get the language_adaptor attribute -
    NSString *language_adaptor_string = [[node attributeForName:@"language_adaptor"] stringValue];
    
    // grab this string -
    self.mySelectedLanguageAdaptor = language_adaptor_string;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if ([self myDefaultOutputTypes]!=nil)
    {
        return [[self myDefaultOutputTypes] count];
    }
    
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if ([self myDefaultOutputTypes] != nil &&
        [[self myDefaultOutputTypes] count]>index)
    {
        // get the node, return the label attribute
        NSXMLElement *node = [[self myDefaultOutputTypes] objectAtIndex:index];
        NSString *display_label = [[node attributeForName:@"label"] stringValue];
        return display_label;
    }
    
    return nil;
}

#pragma mark - alert delegate
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        
        // stop progress bar
        [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
        
        // KIA my blueprint file URL -
        self.myBlueprintFileURL = nil;
        
        // clean the text fld -
        [[self myModelSpecificationPathTextField] setStringValue:@""];
    }
}


#pragma mark - setup methods
-(void)setup
{

    // ok, have we loaded the default output types?
    if ([self myDefaultOutputTypes] == nil)
    {
        // load the defaults -
        NSString *path_to_outputs = [[NSBundle mainBundle] pathForResource:@"Outputs" ofType:@"xml"];
        if (path_to_outputs!=nil)
        {
            // load XML file and get output nodes -
            NSXMLDocument *output_document = [VLCoreUtilitiesLib createXMLDocumentFromFile:[NSURL fileURLWithPath:path_to_outputs]];
            
            // get the nodes -
            NSArray *nodes_array = [output_document nodesForXPath:@"//output" error:nil];
            if (nodes_array!=nil)
            {
                self.myDefaultOutputTypes = [NSArray arrayWithArray:nodes_array];
            }
        }
    }
}



+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

@end
