#include "paths.h"

#include <Foundation/Foundation.h>
#include <SDL.h>
#import <UIKit/UIKit.h>

// Modelled after SDL_AndroidGetExternalStoragePath.
const char* iOSGetDocumentsPath()
{
    static char* s_iOSDocumentsPath = NULL;

    if (s_iOSDocumentsPath == NULL) {
        @autoreleasepool {
            NSArray* array =
                NSSearchPathForDirectoriesInDomains(
                    NSDocumentDirectory,
                    NSUserDomainMask,
                    YES);

            if ([array count] > 0) {
                NSString* str = [array objectAtIndex:0];
                const char* base = [str fileSystemRepresentation];

                if (base) {
                    const size_t len = SDL_strlen(base) + 2;
                    s_iOSDocumentsPath = (char*)SDL_malloc(len);

                    if (s_iOSDocumentsPath == NULL) {
                        SDL_OutOfMemory();
                    } else {
                        SDL_snprintf(
                            s_iOSDocumentsPath,
                            len,
                            "%s/",
                            base);
                    }
                }
            }
        }
    }

    return s_iOSDocumentsPath;
}

bool iOSBootstrapGameData()
{
    @autoreleasepool {
        NSFileManager* fm = [NSFileManager defaultManager];

        NSArray* paths =
            NSSearchPathForDirectoriesInDomains(
                NSDocumentDirectory,
                NSUserDomainMask,
                YES);

        if ([paths count] == 0) {
            return false;
        }

        NSString* documents = [paths objectAtIndex:0];

        NSString* masterDestination =
            [documents stringByAppendingPathComponent:@"master.dat"];

        // Already installed.
        if ([fm fileExistsAtPath:masterDestination]) {
            return true;
        }

        NSString* resourcePath =
            [[NSBundle mainBundle] resourcePath];

        NSString* sourceRoot =
            [resourcePath stringByAppendingPathComponent:@"GameData"];

        NSArray* items = @[
            @"master.dat",
            @"critter.dat",
            @"data"
        ];

        for (NSString* item in items) {
            NSString* source =
                [sourceRoot stringByAppendingPathComponent:item];

            NSString* destination =
                [documents stringByAppendingPathComponent:item];

            if (![fm fileExistsAtPath:source]) {
						    NSString* message = [NSString stringWithFormat:
												        @"FOCE bootstrap missing:\n%@",
													      source];

						    UIAlertController* alert =
						        [UIAlertController alertControllerWithTitle:@"Bootstrap Error"
						                                            message:message
								                                 preferredStyle:UIAlertControllerStyleAlert];

						    [alert addAction:
						        [UIAlertAction actionWithTitle:@"OK"
						                                 style:UIAlertActionStyleDefault
							                             handler:nil]];

						    UIViewController* root =
						        UIApplication.sharedApplication.keyWindow.rootViewController;

						    [root presentViewController:alert animated:YES completion:nil];

						    return false;
						}

            // Remove a partial previous copy.
            if ([fm fileExistsAtPath:destination]) {
                NSError* removeError = nil;
                [fm removeItemAtPath:destination
                               error:&removeError];
            }

            NSError* copyError = nil;

            if (![fm copyItemAtPath:source
                             toPath:destination
                              error:&copyError]) {
                NSLog(
                    @"FOCE bootstrap: failed copying %@: %@",
                    item,
                    copyError);

                return false;
            }
        }

        return true;
    }
}