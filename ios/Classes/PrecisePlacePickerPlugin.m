#import "PrecisePlacePickerPlugin.h"
#if __has_include(<precise_place_picker/precise_place_picker-Swift.h>)
#import <precise_place_picker/precise_place_picker-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "precise_place_picker-Swift.h"
#endif

@implementation PrecisePlacePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPrecisePlacePickerPlugin registerWithRegistrar:registrar];
}
@end
