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

#import "MSIDTestCacheDataSource.h"
#import "MSIDTokenCacheKey.h"
#import "MSIDKeyedArchiverSerializer.h"
#import "MSIDJsonSerializer.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDAccessToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDIdToken.h"
#import "MSIDKeyedArchiverSerializer.h"
#import "MSIDJsonSerializer.h"
#import "MSIDAccount.h"

@interface MSIDTestCacheDataSource()
{
    NSMutableDictionary<NSString *, NSString *> *_tokenKeys;
    NSMutableDictionary<NSString *, NSString *> *_accountKeys;
    NSMutableDictionary<NSString *, NSData *> *_tokenContents;
    NSMutableDictionary<NSString *, NSData *> *_accountContents;
    NSDictionary *_wipeInfo;
}

@end

@implementation MSIDTestCacheDataSource

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _tokenKeys = [NSMutableDictionary dictionary];
        _accountKeys = [NSMutableDictionary dictionary];
        _tokenContents = [NSMutableDictionary dictionary];
        _accountContents = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - MSIDTokenCacheDataSource

- (BOOL)saveToken:(MSIDTokenCacheItem *)item
              key:(MSIDTokenCacheKey *)key
       serializer:(id<MSIDTokenItemSerializer>)serializer
          context:(id<MSIDRequestContext>)context
            error:(NSError **)error
{
    if (!item
        || !key
        || !serializer)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    NSData *serializedItem = [serializer serializeTokenCacheItem:item];
    return [self saveItemData:serializedItem
                          key:key
                    cacheKeys:_tokenKeys
                 cacheContent:_tokenContents
                      context:context
                        error:error];
}

- (MSIDTokenCacheItem *)tokenWithKey:(MSIDTokenCacheKey *)key
                          serializer:(id<MSIDTokenItemSerializer>)serializer
                             context:(id<MSIDRequestContext>)context
                               error:(NSError **)error
{
    if (!serializer)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSData *itemData = [self itemDataWithKey:key
                              keysDictionary:_tokenKeys
                           contentDictionary:_tokenContents
                                     context:context
                                       error:error];

    MSIDTokenCacheItem *token = [serializer deserializeTokenCacheItem:itemData];
    return token;
}

- (BOOL)removeItemsWithKey:(MSIDTokenCacheKey *)key
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if (!key)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    NSString *uniqueKey = [self uniqueIdFromKey:key];
    
    @synchronized (self) {
        
        NSString *tokenComponentsKey = _tokenKeys[uniqueKey];
        [_tokenKeys removeObjectForKey:uniqueKey];
        
        if (tokenComponentsKey)
        {
            [_tokenContents removeObjectForKey:tokenComponentsKey];
        }
        
        NSString *accountComponentsKey = _accountKeys[uniqueKey];
        [_accountKeys removeObjectForKey:uniqueKey];
        
        if (accountComponentsKey)
        {
            [_accountContents removeObjectForKey:accountComponentsKey];
        }
    }
    
    return YES;
}

- (NSArray<MSIDTokenCacheItem *> *)tokensWithKey:(MSIDTokenCacheKey *)key
                                      serializer:(id<MSIDTokenItemSerializer>)serializer
                                         context:(id<MSIDRequestContext>)context
                                           error:(NSError **)error
{
    if (!serializer)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSMutableArray *resultItems = [NSMutableArray array];
    
    NSArray<NSData *> *items = [self itemsWithKey:key
                                   keysDictionary:_tokenKeys
                                contentDictionary:_tokenContents
                                          context:context
                                            error:error];
    
    for (NSData *itemData in items)
    {
        MSIDTokenCacheItem *token = [serializer deserializeTokenCacheItem:itemData];
        
        if (token)
        {
            [resultItems addObject:token];
        }
    }
    
    return resultItems;
}

- (BOOL)saveWipeInfoWithContext:(id<MSIDRequestContext>)context
                          error:(NSError **)error
{
    _wipeInfo = @{@"wiped": [NSDate date]};
    return YES;
}

- (NSDictionary *)wipeInfo:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    return _wipeInfo;
}

- (BOOL)saveAccount:(MSIDAccountCacheItem *)item
                key:(MSIDTokenCacheKey *)key
         serializer:(id<MSIDAccountItemSerializer>)serializer
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error
{
    if (!item
        || !serializer)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    NSData *serializedItem = [serializer serializeAccountCacheItem:item];
    return [self saveItemData:serializedItem
                          key:key
                    cacheKeys:_accountKeys
                 cacheContent:_accountContents
                      context:context
                        error:error];
}

- (MSIDAccountCacheItem *)accountWithKey:(MSIDTokenCacheKey *)key
                              serializer:(id<MSIDAccountItemSerializer>)serializer
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    if (!serializer)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSData *itemData = [self itemDataWithKey:key
                              keysDictionary:_accountKeys
                           contentDictionary:_accountContents
                                     context:context
                                       error:error];
    
    MSIDAccountCacheItem *token = [serializer deserializeAccountCacheItem:itemData];
    return token;
}

- (NSArray<MSIDAccountCacheItem *> *)accountsWithKey:(MSIDTokenCacheKey *)key
                                          serializer:(id<MSIDAccountItemSerializer>)serializer
                                             context:(id<MSIDRequestContext>)context
                                               error:(NSError **)error
{
    if (!serializer)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSMutableArray *resultItems = [NSMutableArray array];
    
    NSArray<NSData *> *items = [self itemsWithKey:key
                                   keysDictionary:_accountKeys
                                contentDictionary:_accountContents
                                          context:context
                                            error:error];
    
    for (NSData *itemData in items)
    {
        MSIDAccountCacheItem *account = [serializer deserializeAccountCacheItem:itemData];
        
        if (account)
        {
            [resultItems addObject:account];
        }
    }
    
    return resultItems;
}

#pragma mark - Helpers

- (NSString *)uniqueIdFromKey:(MSIDTokenCacheKey *)key
{
    // Simulate keychain behavior by using account and service as unique key
    return [NSString stringWithFormat:@"%@_%@", key.account, key.service];
}

- (NSString *)keyComponentsStringFromKey:(MSIDTokenCacheKey *)key
{
    NSString *generic = key.generic ? [[NSString alloc] initWithData:key.generic encoding:NSUTF8StringEncoding] : nil;
    return [NSString stringWithFormat:@"%@_%@_%@_%@", key.account, key.service, key.type, generic];
}

- (NSString *)regexFromKey:(MSIDTokenCacheKey *)key
{
    NSString *accountStr = key.account ?
        [self absoluteRegexFromString:key.account] : @".*";
    NSString *serviceStr = key.service ?
        [self absoluteRegexFromString:key.service] : @".*";
    NSString *typeStr = key.type ? key.type.stringValue : @".*";
    NSString *generic = key.generic ? [[NSString alloc] initWithData:key.generic encoding:NSUTF8StringEncoding] : nil;
    NSString *genericStr = generic ? [self absoluteRegexFromString:generic] : @".*";
    
    NSString *regexString = [NSString stringWithFormat:@"%@_%@_%@_%@", accountStr, serviceStr, typeStr, genericStr];
    return regexString;
}

- (NSString *)absoluteRegexFromString:(NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    string = [string stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
    string = [string stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    string = [string stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
    return string;
}

#pragma mark - Private

- (NSData *)itemDataWithKey:(MSIDTokenCacheKey *)key
             keysDictionary:(NSDictionary *)cacheKeys
          contentDictionary:(NSDictionary *)cacheContent
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    if (!key || !cacheKeys || !cacheContent)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSArray<NSData *> *items = [self itemsWithKey:key
                                   keysDictionary:cacheKeys
                                contentDictionary:cacheContent
                                          context:context
                                            error:error];
    
    if ([items count])
    {
        NSData *itemData = items[0];
        return itemData;
    }
    
    return nil;
}

- (BOOL)saveItemData:(NSData *)serializedItem
                 key:(MSIDTokenCacheKey *)key
           cacheKeys:(NSMutableDictionary *)cacheKeys
        cacheContent:(NSMutableDictionary *)cacheContent
             context:(id<MSIDRequestContext>)context
               error:(NSError **)error
{
    if (!key || !cacheKeys || !cacheContent)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    if (!serializedItem)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Couldn't serialize the MSIDBaseToken item", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    /*
     This is trying to simulate keychain behavior for generic password type,
     where account and service are used as unique key, but both type and generic
     can be used for queries. So, cache keys will store key to the item in the cacheContent dictionary.
     That way there can be only one item with unique combination of account and service,
     but we'll still be able to query by generic and type.
     */
    
    NSString *uniqueIdKey = [self uniqueIdFromKey:key];
    NSString *componentsKey = [self keyComponentsStringFromKey:key];
    
    @synchronized (self) {
        cacheKeys[uniqueIdKey] = componentsKey;
    }
    
    @synchronized (self) {
        cacheContent[componentsKey] = serializedItem;
    }
    
    return YES;
}

- (NSArray<NSData *> *)itemsWithKey:(MSIDTokenCacheKey *)key
                     keysDictionary:(NSDictionary *)cacheKeys
                  contentDictionary:(NSDictionary *)cacheContent
                            context:(id<MSIDRequestContext>)context
                              error:(NSError **)error
{
    if (!key
        || !cacheKeys
        || !cacheContent)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSData *itemData = nil;
    
    if (key.account
        && key.service
        && key.generic
        && key.type)
    {
        // If all key attributes are set, look for an exact match
        NSString *componentsKey = [self keyComponentsStringFromKey:key];
        itemData = cacheContent[componentsKey];
    }
    else if (key.account
             && key.service)
    {
        // If all key attributes that are part of unique id are set, look for an exact match in keys
        NSString *uniqueId = [self uniqueIdFromKey:key];
        NSString *itemKey = cacheKeys[uniqueId];
        itemData = cacheContent[itemKey];
    }
    
    if (itemData)
    {
        // Direct match, return without additional lookup
        return @[itemData];
    }
    
    // If no direct match found, do a partial query
    NSMutableArray *resultItems = [NSMutableArray array];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[self regexFromKey:key]
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    @synchronized (self) {
        
        for (NSString *dictKey in [cacheContent allKeys])
        {
            NSUInteger numberOfMatches = [regex numberOfMatchesInString:dictKey
                                                                options:0
                                                                  range:NSMakeRange(0, [dictKey length])];
            
            if (numberOfMatches > 0)
            {
                NSData *object = cacheContent[dictKey];
                [resultItems addObject:object];
            }
        }
        
    }
    
    return resultItems;
}

#pragma mark - Test methods

- (void)reset
{
    @synchronized (self)  {
        _tokenContents = [NSMutableDictionary dictionary];
        _wipeInfo = nil;
    }
}

- (NSArray *)allLegacySingleResourceTokens
{
    return [self allTokensWithType:MSIDTokenTypeLegacySingleResourceToken
                        serializer:[[MSIDKeyedArchiverSerializer alloc] init]];
}

- (NSArray *)allLegacyAccessTokens
{
    return [self allTokensWithType:MSIDTokenTypeAccessToken
                        serializer:[[MSIDKeyedArchiverSerializer alloc] init]];
}

- (NSArray *)allLegacyRefreshTokens
{
    return [self allTokensWithType:MSIDTokenTypeRefreshToken
                        serializer:[[MSIDKeyedArchiverSerializer alloc] init]];
}

- (NSArray *)allDefaultAccessTokens
{
    return [self allTokensWithType:MSIDTokenTypeAccessToken
                        serializer:[[MSIDJsonSerializer alloc] init]];
}

- (NSArray *)allDefaultRefreshTokens
{
    return [self allTokensWithType:MSIDTokenTypeRefreshToken
                        serializer:[[MSIDJsonSerializer alloc] init]];
}

- (NSArray *)allDefaultIDTokens
{
    return [self allTokensWithType:MSIDTokenTypeIDToken
                        serializer:[[MSIDJsonSerializer alloc] init]];
}

- (NSArray *)allTokensWithType:(MSIDTokenType)type
                    serializer:(id<MSIDTokenItemSerializer>)serializer
{
    NSMutableArray *results = [NSMutableArray array];
    
    @synchronized (self) {
        
        for (NSData *tokenData in [_tokenContents allValues])
        {
            MSIDTokenCacheItem *token = [serializer deserializeTokenCacheItem:tokenData];
            
            if (token)
            {
                MSIDBaseToken *baseToken = [token tokenWithType:type];
                
                if (baseToken)
                {
                    [results addObject:baseToken];
                }
            }
        }
    }
    
    return results;
}

- (NSArray *)allAccounts
{
    NSMutableArray *results = [NSMutableArray array];
    
    MSIDJsonSerializer *serializer = [[MSIDJsonSerializer alloc] init];
    
    @synchronized (self) {
        
        for (NSData *accountData in [_accountContents allValues])
        {
            MSIDAccountCacheItem *accountCacheItem = [serializer deserializeAccountCacheItem:accountData];
            
            if (accountCacheItem)
            {
                MSIDAccount *account = [[MSIDAccount alloc] initWithAccountCacheItem:accountCacheItem];
                
                if (account)
                {
                    [results addObject:account];
                }
            }
        }
    }
    
    return results;
}

@end
