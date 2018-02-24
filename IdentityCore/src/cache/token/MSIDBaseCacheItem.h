// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "MSIDJsonSerializable.h"
#import "MSIDTokenResponse.h"
#import "MSIDRequestParameters.h"
#import "MSIDClientInfo.h"
#import "MSIDTokenType.h"

/*!
 This is the base class for all possible cache entries.
 It's meant to be subclassed to provide additional fields.
 */

@interface MSIDBaseCacheItem : NSObject <NSCopying, NSSecureCoding, MSIDJsonSerializable>
{
    NSURL *_authority;
    NSString *_clientId;
    MSIDClientInfo *_clientInfo;
    NSDictionary *_additionalInfo;
    NSString *_username;
}

@property (readwrite) NSURL *authority;
@property (readwrite) NSString *clientId;

@property (readonly) NSString *uniqueUserId;
@property (readonly) MSIDClientInfo *clientInfo;
@property (readonly) NSDictionary *additionalInfo;
@property (readonly) NSString *username;

- (BOOL)isEqualToItem:(MSIDBaseCacheItem *)item;

- (instancetype)initWithTokenResponse:(MSIDTokenResponse *)response
                              request:(MSIDRequestParameters *)requestParams;

@end
