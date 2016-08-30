//
//  NSURLConnection+Inspected.h
//
//

#import <Foundation/Foundation.h>

/**
  * Notification keys for observers.
  */
#define k_SENDING_REQUEST   @"k_SENDING_REQUEST"
#define k_RECEIVED_RESPONSE @"k_RECEIVED_RESPONSE"

/**
 * NSURLConnection extension to log the request/response.
 *
 * Can be useful when using 3rd party binary library and
 * wants to inspect what data is going on.
 */
@interface NSURLConnection (MtInspected)
+ (void) setInspectionMt:(BOOL)enabled;
+ (BOOL) inspectionMtEnabled;
@end