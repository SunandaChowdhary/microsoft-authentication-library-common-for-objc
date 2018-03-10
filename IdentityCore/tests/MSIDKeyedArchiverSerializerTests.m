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

#import <XCTest/XCTest.h>
#import "MSIDKeyedArchiverSerializer.h"
#import "NSDictionary+MSIDTestUtil.h"
#import "MSIDTokenCacheItem.h"
#import "MSIDAccountCacheItem.h"

@interface MSIDKeyedArchiverSerializerTests : XCTestCase

@end

@implementation MSIDKeyedArchiverSerializerTests

#pragma mark - Token cache item

- (void)test_whenSerializeToken_shouldReturnSameTokenOnDeserialize
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    MSIDTokenCacheItem *cacheItem = [[MSIDTokenCacheItem alloc] init];
    cacheItem.refreshToken = @"refresh token value";
    cacheItem.familyId = @"familyId value";
    cacheItem.clientInfo = [self createClientInfo:@{@"key" : @"value"}];
    cacheItem.additionalInfo = @{@"spe_info" : @"test"};
    cacheItem.authority = [NSURL URLWithString:@"https://contoso.com/common"];
    cacheItem.clientId = @"some clientId";
    cacheItem.tokenType = MSIDTokenTypeRefreshToken;
    
    NSData *data = [serializer serializeTokenCacheItem:cacheItem];
    MSIDTokenCacheItem *resultToken = [serializer deserializeTokenCacheItem:data];
    
    XCTAssertNotNil(data);
    XCTAssertEqualObjects(resultToken, cacheItem);
}

- (void)testSerialize_whenTokenNil_shouldReturnNil
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    NSData *data = [serializer serializeTokenCacheItem:nil];
    
    XCTAssertNil(data);
}

- (void)testSerialize_whenTokenWithDefaultProperties_shouldReturnNotNilData
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    NSData *data = [serializer serializeTokenCacheItem:[MSIDTokenCacheItem new]];
    
    XCTAssertNotNil(data);
}

- (void)testDeserialize_whenDataNilNil_shouldReturnNil
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    MSIDTokenCacheItem *token = [serializer deserializeTokenCacheItem:nil];
    
    XCTAssertNil(token);
}

- (void)testDeserialize_whenDataInvalid_shouldReturnNil
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    NSData *data = [@"some" dataUsingEncoding:NSUTF8StringEncoding];
    
    MSIDTokenCacheItem *token = [serializer deserializeTokenCacheItem:data];
    
    XCTAssertNil(token);
}

#pragma mark - Account

- (void)test_whenSerializeAccountCacheItem_shouldReturnSameAccountOnDeserialize
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    MSIDAccountCacheItem *cacheItem = [[MSIDAccountCacheItem alloc] init];
    cacheItem.clientInfo = [self createClientInfo:@{@"key" : @"value"}];
    cacheItem.additionalInfo = @{@"spe_info" : @"test"};
    cacheItem.authority = [NSURL URLWithString:@"https://contoso.com/common"];
    cacheItem.lastName = @"last name";
    cacheItem.legacyUserIdentifier = @"upn";
    cacheItem.firstName = @"name";
    
    NSData *data = [serializer serializeAccountCacheItem:cacheItem];
    MSIDAccountCacheItem *resultItem = [serializer deserializeAccountCacheItem:data];
    
    XCTAssertNotNil(data);
    XCTAssertEqualObjects(resultItem, cacheItem);
}

- (void)testSerializeAccountCacheItem_whenAccountNil_shouldReturnNil
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    NSData *data = [serializer serializeAccountCacheItem:nil];
    
    XCTAssertNil(data);
}

- (void)testSerializeAccountCacheItem_whenAccountWithDefaultProperties_shouldReturnNotNilData
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    NSData *data = [serializer serializeAccountCacheItem:[MSIDAccountCacheItem new]];
    
    XCTAssertNotNil(data);
}

- (void)testDeserializeAccountCacheItem_whenDataNilNil_shouldReturnNil
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    
    MSIDAccountCacheItem *account = [serializer deserializeAccountCacheItem:nil];
    
    XCTAssertNil(account);
}

- (void)testDeserializeAccountCacheItem_whenDataInvalid_shouldReturnNil
{
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    NSData *data = [@"some" dataUsingEncoding:NSUTF8StringEncoding];
    
    MSIDAccountCacheItem *token = [serializer deserializeAccountCacheItem:data];
    
    XCTAssertNil(token);
}

#pragma mark - Wipe data

- (void)testDeserializeTokenCacheItem_whenWipeData_shouldReturnNil
{
    NSDictionary *wipeInfo = @{ @"bundleId" : @"bundleId",
                                @"wipeTime" : [NSDate date]
                                };
    
    NSData *wipeData = [NSKeyedArchiver archivedDataWithRootObject:wipeInfo];
    
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    MSIDTokenCacheItem *token = [serializer deserializeTokenCacheItem:wipeData];
    
    XCTAssertNil(token);
}

- (void)testDeserializeAccountCacheItem_whenWipeData_shouldReturnNil
{
    NSDictionary *wipeInfo = @{ @"bundleId" : @"bundleId",
                                @"wipeTime" : [NSDate date]
                                };
    
    NSData *wipeData = [NSKeyedArchiver archivedDataWithRootObject:wipeInfo];
    
    MSIDKeyedArchiverSerializer *serializer = [[MSIDKeyedArchiverSerializer alloc] init];
    MSIDAccountCacheItem *account = [serializer deserializeAccountCacheItem:wipeData];
    
    XCTAssertNil(account);
}

#pragma mark - Private

- (MSIDClientInfo *)createClientInfo:(NSDictionary *)clientInfoDict
{
    NSString *base64String = [clientInfoDict msidBase64UrlJson];
    return [[MSIDClientInfo alloc] initWithRawClientInfo:base64String error:nil];
}

@end
