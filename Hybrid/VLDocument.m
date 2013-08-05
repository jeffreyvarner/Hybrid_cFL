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
                        [[self myConsoleTextField] setStringValue:message];
                    }];
    
    // VLTransformationJobCompletedNotification -
    [center addObserverForName:VLTransformationJobDidCompleteNotification
                        object:nil
                         queue:mainQueue
                    usingBlock:^(NSNotification *notification){
                        
                        // shutdown the progress bar animation -
                        [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
                        
                        // Set the completed text -
                        [[self myConsoleTextField] setStringValue:@"Status: Transformation completed."];
                    }];

}


#pragma mark - actions
-(IBAction)codeGenerationBeginGenerationButtonWasTapped:(NSButton *)button
{
    // ok, so check to make sure we have a URL - if we do then begin the generation
    // process. If not, then open the open panel -
    if ([self myBlueprintFileURL]!=nil)
    {
        // start the progress bar animation -
        [[self myCodeGenerationProgressIndicator] startAnimation:nil];
        
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
                NSString *progressText = [NSString stringWithFormat:@"Status: Loaded %@ block",transformationName];
                [[self myConsoleTextField] setStringValue:progressText];
                
                // Get the input and output classname -
                NSString *inputClassNameXPath = [NSString stringWithFormat:@"//Transformation[@name='%@']/@classname",transformationName];
                NSString *languageXPath = [NSString stringWithFormat:@"//Transformation[@name='%@']/@language",transformationName];
                
                // execute the query -
                NSString *inputClassName = [[[VLCoreUtilitiesLib executeXPathQuery:inputClassNameXPath
                                                                       withXMLTree:blueprintTree] lastObject] stringValue];
                
                NSString *languageClassName = [[[VLCoreUtilitiesLib executeXPathQuery:languageXPath
                                                                          withXMLTree:blueprintTree] lastObject] stringValue];
                
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
