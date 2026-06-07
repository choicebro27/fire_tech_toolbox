//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<audio_streamer/SwiftAudioStreamerPlugin.h>)
#import <audio_streamer/SwiftAudioStreamerPlugin.h>
#else
@import audio_streamer;
#endif

#if __has_include(<file_picker/FilePickerPlugin.h>)
#import <file_picker/FilePickerPlugin.h>
#else
@import file_picker;
#endif

#if __has_include(<flutter_gemma/FlutterGemmaPlugin.h>)
#import <flutter_gemma/FlutterGemmaPlugin.h>
#else
@import flutter_gemma;
#endif

#if __has_include(<in_app_purchase_storekit/InAppPurchasePlugin.h>)
#import <in_app_purchase_storekit/InAppPurchasePlugin.h>
#else
@import in_app_purchase_storekit;
#endif

#if __has_include(<large_file_handler/LargeFileHandlerPlugin.h>)
#import <large_file_handler/LargeFileHandlerPlugin.h>
#else
@import large_file_handler;
#endif

#if __has_include(<pdfx/PdfxPlugin.h>)
#import <pdfx/PdfxPlugin.h>
#else
@import pdfx;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [SwiftAudioStreamerPlugin registerWithRegistrar:[registry registrarForPlugin:@"SwiftAudioStreamerPlugin"]];
  [FilePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FilePickerPlugin"]];
  [FlutterGemmaPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterGemmaPlugin"]];
  [InAppPurchasePlugin registerWithRegistrar:[registry registrarForPlugin:@"InAppPurchasePlugin"]];
  [LargeFileHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"LargeFileHandlerPlugin"]];
  [PdfxPlugin registerWithRegistrar:[registry registrarForPlugin:@"PdfxPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
}

@end
