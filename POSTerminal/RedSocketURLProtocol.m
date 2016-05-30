//
//  RedSocketURLProtocol.m
//  Browser
//
//  Created by Jeremy Bramson on 1/29/15.
//  Copyright (c) 2015 Redpark. All rights reserved.
//

#import "RedSocketURLProtocol.h"
#import "RedSocket.h"
#include <netdb.h>
#include "CanonicalRequest.h"
#include <zlib.h>
//#include "ViewController.h"

#define CONNECTION_BUFFLEN 0x10000


// pertain to session (ie across multiple load requests
static NSString *currentHost;
static NSString *username;
static NSString *password;

//// this is for debugging
//extern int g_rxCounter, g_txCounter;


NSMutableArray *hostConnections = nil;
NSLock *hostConnectionsLock = nil;

typedef struct redsocketConnectionContext
{
    int sockFD;
    int flags;
    
} redsocketConnectionContext;

@implementation RedSocketURLProtocol
{
    dispatch_queue_t requestQueue;
    NSMutableURLRequest *_request;
    int authFailureCount;
    int contentLength;
    int recvContentLength;
    NSHTTPURLResponse *_response;
    NSMutableData *responseData;
    BOOL isGzippedResponse;
    BOOL isChunked;
    BOOL hasReceivedResponse;
    CFHTTPMessageRef httpMessageRef;
    int _sock;
}


/*
 This is required when sub-classing NSURLProtocol
 
 Any time a user attempts a load request this gets called.  We check the scheme
 to see if it matches "redsocket".  If you want to use a different scheme
 name this is where you would change the code.
 
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *reqScheme =[[[request URL] scheme] lowercaseString];
    
    if ([reqScheme isEqualToString:@"redsocket"] ||
       [reqScheme isEqualToString:@"http"] ||
        [reqScheme isEqualToString:@"https"])
    {
        return YES;
    }
    else
    {
        NSLog(@"caninitWithRequest: %@", request);
        return NO;
    }
}

/*
 
 The code that's called here is taken from an Apple sample.  It's main purpose
 is to "normalize" user typed URLs.  Since the accepted conventions for entering
 URLs are not valid some code is required to correct them.  For example, if the user
 does not enter a :<port> it will default to 80.  Or adding an extra "/" for a blank
 path.
 
 */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    NSMutableURLRequest *   result;
    
    assert(request != nil);
    
    // Make a mutable copy of the request.
    
    result = [request mutableCopy];

    result = CanonicalRequestForRequest(result);
    return result;
}


/*
 Also required when sub-classing NSURLProtocol.  Every time a new request is loaded a new instance is created and
 initialized here.  We call the super class first.
 
 There is where we create a concurrent background queue.
 
 */
- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client
{
    // Modify request
    NSMutableURLRequest *myRequest = [request mutableCopy];
    
    self = [super initWithRequest:myRequest
                   cachedResponse:cachedResponse
                           client:client];
    if ( self ) {
        _request = myRequest;
        
        authFailureCount = 0;
        
        requestQueue = dispatch_queue_create("Request Connection Background Queue",DISPATCH_QUEUE_CONCURRENT);
        
        if (hostConnections == nil) {
            
            hostConnectionsLock = [[NSLock alloc] init];
            hostConnections = [[NSMutableArray alloc] init];
        }
    }

    return self;
}



/*
 
  Takes a NSURLRequest and creates the raw bytes ready to send over the wire.
 */
- (NSMutableData *) buildRequestPacket:(NSURLRequest *)request
{
    NSMutableData *packetData;
    
    NSURL *url = request.URL;
    
   // NSLog(@"%@\n%@\n",  url.host, url.path);
    
    NSString *requestString = [NSString stringWithFormat:@"%@ %@", request.HTTPMethod, url.path];
    
    if (url.query) requestString = [requestString stringByAppendingString:[NSString stringWithFormat:@"?%@", url.query]];
    
    requestString = [requestString stringByAppendingString:@" HTTP/1.1\r\n"];
    
    
    NSDictionary *HTTPHeaderFields = [request allHTTPHeaderFields];
    NSEnumerator *HTTPHeaderFieldsEnumerator = [HTTPHeaderFields keyEnumerator];
    NSString *aHTTPHeaderField;
    while (aHTTPHeaderField = [HTTPHeaderFieldsEnumerator nextObject])
    {
        if ([aHTTPHeaderField containsString:@":"] == NO)
        {
            requestString = [requestString stringByAppendingFormat:@"%@: %@\r\n",
                             aHTTPHeaderField,
                             [HTTPHeaderFields objectForKey:aHTTPHeaderField]];
        }
        else{
            requestString = [requestString stringByAppendingFormat:@"%@ %@\r\n",
                         aHTTPHeaderField,
                         [HTTPHeaderFields objectForKey:aHTTPHeaderField]];
        }
    }

    if (request.HTTPBody)
    {
        if ([request.HTTPBody length])
        {
            requestString = [requestString stringByAppendingFormat:@"Content-Length: %lu\r\n", [request.HTTPBody length]];
        }
    }
    
    requestString = [requestString stringByAppendingString:@"\r\n"];
    
    packetData = [NSMutableData dataWithBytes:[requestString UTF8String] length:strlen([requestString UTF8String])];
    
    if (request.HTTPBody)
    {
        NSLog(@"%@", request.HTTPBody);
        
        // append body bytes here
        [packetData appendData:request.HTTPBody];
    }
    
    NSLog(@"%@", requestString);
    
    return packetData;
}


/*
    required when subclassing NSURLProtocol
 
    The iOS load system will call this to start communication with the web server.  Its our job
    to manage the connection, send the request and construct a response object.  We then call the delegate client
    informing it when the load completes, when we receive a response, data for the body and or if an error occurrs.
 
    We also implement our own poor-mans simple handling of HTTP authentication.  After prompting the user for password and login, we store
    the values and then add to the headers of any subsequent requests.
 
 */

-(void)startLoading
{
    id <NSURLProtocolClient> client = self.client;
    
    NSString *reqScheme =[[[_request URL] scheme] lowercaseString];
    
    //return NO;
    
// AFF - 10/22/2015, commented the code rejecting https requests
//    if ([reqScheme isEqualToString:@"https"])
//    {
//        NSString *errorStr = @"ENet Browswer does not support HTTPS";
//        _response = [[NSHTTPURLResponse alloc]
//                    initWithURL:_request.URL statusCode:400
//                    HTTPVersion:@"1.1" headerFields:nil];
//        
//        [client URLProtocol:self didReceiveResponse:_response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//        
//        [client URLProtocol:self didLoadData:[errorStr dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    
//        [client URLProtocolDidFinishLoading:self];
//        
//        return;
//    }


    
    
    ///////////////////////////////////
    // Initiate connection
    
    /*
     Take advantage of GCD so we can call blocking (default) versions of socket
     interface.  This block of code is executed on a different thread than caller.  We
     use the requestQueue created in init.
     */
    
    dispatch_async(requestQueue, ^{
        
        int port = [[_request URL].port integerValue];
        
        if (!port) port = 80;
        
        // if we are still talking to the same host and authentication was required,
        // add username and password to request headers.  Once host changes reset.
        if (currentHost)
        {
            if (![currentHost isEqualToString:[_request URL].host])
            {
                username = nil;
                password = nil;
            }
        }
        
        currentHost = [NSString stringWithString:[_request URL].host];
        
        NSString *argAuth;
        if (username && password) {
            
            NSString *authChunk = [NSString stringWithFormat:@"%@:%@", username, password];
            
            NSData* temp = [authChunk dataUsingEncoding:NSUTF8StringEncoding];
            
            argAuth = [NSString stringWithFormat:@"Basic %@", [temp base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
            
            [_request setValue:argAuth forHTTPHeaderField:@"Authorization:"];
        }
        
        [_request setValue:@"close" forHTTPHeaderField:@"Connection:"];
        
        NSLog(@"StartLoading: \n%@", _request);
        
        hasReceivedResponse = NO;
        isChunked = NO;
        isGzippedResponse = NO;
    
        // use RedSocket interface over L2-NET cable
        if ([[RedSocketManager sharedInstance] isCableConnected])
        {
            if ([reqScheme isEqualToString:@"https"])
            {
                 [self sendSecureRequestAsyncUsingCable];
            }
            else
            {
            
                [self sendRequestAsyncUsingCable];
            }
        }
        
        /*
     
         These functions are useful for debugging the protocol subclass and HTTP parsing.
         Since it uses the native network stack over wifi you can connect XCode to the
         device and debug directly.
         */
        else
        {
             if ([reqScheme isEqualToString:@"https"])
             {
                 [self sendSecureRequestAsyncUsingWifi];
             }
             else {
                 [self sendRequestAsyncUsingWifi];
             }
        }
    });
 }


-(void)sendRequestAsyncUsingCable
{
    
        id <NSURLProtocolClient> client = self.client;
        
        struct sockaddr_in webServerAddr;
        
        int readOffset = 0;
        int port = [[_request URL].port integerValue];
        
        if (!port) port = 80;
        
        BOOL hasReceivedResponse = NO;
        
        unsigned char *connectionReadBuff = (unsigned char *)malloc(CONNECTION_BUFFLEN);
        if (!connectionReadBuff)
        {
            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            return;
        }
        
        //Create socket
        _sock = [[RedSocketManager sharedInstance] socket:AF_INET type:SOCK_STREAM protocol:IPPROTO_TCP];
        
        if (_sock == -1)
        {
            NSLog(@"failed to create socket");

            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            free(connectionReadBuff);
            return;
        }
        
        // use redsocket_gethostbyname() to do DNS lookup on passed in URL
        struct hostent *host_entry = redsocket_gethostbyname([[_request URL].host UTF8String]);
        const char *ipaddrStr;
        
        if (host_entry)
        {
            // we were able to resolve to a IP address
            ipaddrStr = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
        }
        else
        {
            // if gethostbyname failed use as is and hope user entered a real IP address
            ipaddrStr =[[_request URL].host UTF8String];
        }
        
        // CONNECT to remote server
        webServerAddr.sin_addr.s_addr = inet_addr(ipaddrStr);
        webServerAddr.sin_family = AF_INET;
        webServerAddr.sin_port = htons(port);
        
        // connect to web server
        if ([[RedSocketManager sharedInstance] connect:_sock sockaddr:(struct sockaddr *)&webServerAddr namelen:sizeof(webServerAddr)] < 0)
        {
            NSLog(@"failed to connect to host");

            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            [[RedSocketManager sharedInstance] close:_sock];
            
            free(connectionReadBuff);
            return;
        }
        
        
        // connected
        // now send the request
        
        // this function takes the NSURLRequest and builds the HTTP packet to send
        // to the server
        NSMutableData *packetData = [self buildRequestPacket:_request];
        
        // send bytes to web server
        [[RedSocketManager sharedInstance] send:_sock dataptr:[packetData bytes] size:[packetData length] flags:0];
        
        // check if body data was passed as a stream
        if (_request.HTTPBodyStream != nil)
        {
            NSLog(@"body is in stream");
            // body is in stream
            
            // reading the docs - it appears this is to handle case where file to upload is extremely large
            // and the Protocol handler is expected to read the body data out of a stream and send in chunks
            
            // we'll allocate a local buffer to read chunks out and forward on to the server
            uint8_t *buffer = malloc(4096);
            size_t length;
            
            while (_request.HTTPBodyStream.hasBytesAvailable)
            {
                if ((length = [_request.HTTPBodyStream read:buffer maxLength:sizeof(buffer)]) > 0)
                {
                    // write to socket
                    
                    [[RedSocketManager sharedInstance] send:_sock dataptr:buffer size:length flags:0];
                }
            }
            
            free(buffer);
        }
        
        // sent the request
        // now we
        // wait and accumulate the response
        CFHTTPMessageRef httpMessageRef = CFHTTPMessageCreateEmpty(NULL, NO);
        
        for (;;)
        {
            // post blocking read for 1 byte
          int bytesReceived = [[RedSocketManager sharedInstance] recv:_sock mem:connectionReadBuff len:1 flags:0];
            
            if (bytesReceived < 0)
            {
                
                [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
                NSLog(@"- recv failed");
                [[RedSocketManager sharedInstance] close:_sock];
                
                free(connectionReadBuff);
                
                return;
            }
            else if (bytesReceived == 0)
            {
                // this condition usually happens when the other side closes the connection
                
                if (!hasReceivedResponse)
                {
                    [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
                }
                else
                {
                    // we expect server to close the connection after fulll response is received
                    // inform client delegate
                    
                    
                    if ([responseData length] > 0)
                    {
                        if (isGzippedResponse) {
                            
                            NSData *newData = [self gzipInflate:responseData];
                            
                            if (newData != nil) responseData = [newData mutableCopy];
                            
                        }
                        
                        if (isChunked)
                        {
                            NSData *newData = [self doChunked:responseData];
                            
                            if (newData != nil) responseData = [newData mutableCopy];
                        }
                        
                        [client URLProtocol:self didLoadData:responseData];
                    }
                    
                    [client URLProtocolDidFinishLoading:self];
                }
                
                NSLog(@"remote connection closed");
                
                [[RedSocketManager sharedInstance] close:_sock];
                
                free(connectionReadBuff);
                return;
            }
            else
            {
                readOffset++;
                
                // now see if there's  more
                // and read the rest
                
                bytesReceived = [[RedSocketManager sharedInstance] recv:_sock mem:connectionReadBuff+readOffset len:CONNECTION_BUFFLEN-readOffset-1 flags:REDSOCKET_MSG_DONTWAIT];
                
                if (bytesReceived > 0)
                {
                    readOffset += bytesReceived;
                }
                
            }
            
//            // this counter is just for debugging so we can see how many bytes came back
//            g_rxCounter += readOffset;
          
            // have a received a full response yet?
            if (hasReceivedResponse == NO)
            {
                
                
                NSData *bodyData = nil;
                NSHTTPURLResponse *response = nil;
                isGzippedResponse = NO;
                isChunked = NO;
                
                responseData = [[NSMutableData alloc] init];
                
                
                
                
                // accumulate bytes till we get a full response
                // this will also fill in any body data if there is some and
                // create an NSURLHTTPResponse object for us
                if ([self accumulateResponseHeader:httpMessageRef withBytes:connectionReadBuff length:readOffset response:&response bodyData:&bodyData])
                {
                    // we have response with all headers
                    
                    CFRelease(httpMessageRef);
                    
                    // NSLog(@"%@", response);

                    _response = [response copy];
                    

                    /* Handle redirects */
                    if ((response.statusCode == 301)||(response.statusCode == 302)||(response.statusCode == 307)) {
                        NSString *newURL = [[response allHeaderFields] objectForKey:@"Location"];
                        
                        NSLog(@"[ProxyURLProtocol] Got %ld redirect from %@ to %@", (long)response.statusCode, self.request.URL, newURL);
                        
                        
                        NSMutableURLRequest *newRequest = [_request mutableCopy];
                        [newRequest setHTTPShouldUsePipelining:NO];
                        
                        if ([newURL containsString:@"://"])
                        {
                            newRequest.URL = [[NSURL alloc] initWithString:newURL];
                        }
                        else{
                            newRequest.URL = [[NSURL alloc] initWithScheme:@"http" host:_request.URL.host path:newURL];
                        }
                        if ([[_request mainDocumentURL] isEqual:[_request URL]]) {
                            // Previous request *was* the maindocument request.
                            newRequest.mainDocumentURL = newRequest.URL;
                        }
                        
                        
                        NSLog(@"%@ %@", newRequest, self.request);
                        
                        _request = newRequest;
                        
                        [[self client] URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:response];
                        
                        /// cleanup connection here
                        [[RedSocketManager sharedInstance] close:_sock];
                        
                         free(connectionReadBuff);
                         return;
                        
                    }
                    else if ((response.statusCode == 401)||(response.statusCode == 407))
                    {
                        
                        // Server requires HTTP authentication
                        
                        // Prompt user for login info
                        [self performSelectorOnMainThread:@selector(promptForLogin) withObject:nil waitUntilDone:YES];
                        
                        
                        /// cleanup connection here
                        
                        [[RedSocketManager sharedInstance] close:_sock];
                        
                        free(connectionReadBuff);
                        return;
                        
                        
                    }
                    
                    else{
                        
                        // we have an actionable response to send up to the protocol client
                        
                        // lets gather some information about the content data from headers
                        NSString *lenStr = [[response allHeaderFields] objectForKey:@"Content-Length"];
                        if (lenStr)
                        {
                            contentLength = [lenStr integerValue];
                        }
                        
                        NSString *content_encoding = [[response allHeaderFields] objectForKey:@"Content-Encoding"];
                        if ([content_encoding isEqualToString:@"gzip"]) {
                            isGzippedResponse = YES;
                        }
                        
                        if ([content_encoding isEqualToString:@"gzip;"]) {
                            isGzippedResponse = YES;
                        }
                        
                        NSString *transfer_encoding = [[response allHeaderFields] objectForKey:@"Transfer-Encoding"];
                        if ([transfer_encoding isEqualToString:@"chunked"])
                        {
                            isChunked = YES;
                            
                        }
                        

                        
                        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                    }
                    
                    
                    hasReceivedResponse = YES;
                }
                
                if (bodyData && [bodyData length] > 0)
                {
                    // following the response, there were some bytes in the buffer intended for the body
                    // appen here and call client delegate callback
                    
                    [responseData appendData:bodyData];
                }
                
                
                
                
            }
            else
            {
                //NSLog(@"didLoadData2: %d", readOffset);

                [responseData appendBytes:connectionReadBuff length:readOffset];
                
            }
            
            readOffset = 0;
        }
    
}

/*
 
 This function is useful for debugging the protocol subclass and HTTP parsing.
 Since it uses the native network stack over wifi you can connect XCode to the
 device and debug directly.
 */
-(void)sendRequestAsyncUsingWifi
{
    
    NSLog(@"sendRequestAsyncUsingWifi");
    
        int readOffset = 0;
        int bytesReceived = 0;
        
        int port = [[_request URL].port integerValue];
        
        BOOL hasReceivedResponse = NO;
        
        if (!port) port = 80;
        
        id <NSURLProtocolClient> client = self.client;
        
        unsigned char *connectionReadBuff = (unsigned char *)malloc(CONNECTION_BUFFLEN);
        if (!connectionReadBuff)
        {
            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            return;
            
        }
        
        char *ipaddrStr = "";
        char *hostname = [[_request URL].host UTF8String];
        struct hostent *host_entry = gethostbyname(hostname);
        if (host_entry)
        {
            
            ipaddrStr = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
        }
        struct sockaddr_in clientAddr;
        int clientSock,k;
        clientSock = socket(AF_INET,SOCK_STREAM,0);
        memset(&clientAddr,0,sizeof(clientAddr));
        clientAddr.sin_family = AF_INET;
        clientAddr.sin_addr.s_addr = inet_addr(ipaddrStr);
        clientAddr.sin_port = htons(port);
        if (connect(clientSock,(struct sockaddr*)&clientAddr,sizeof(clientAddr)) < 0)
        {
            
            close(clientSock);
            return;
        }
        
        NSMutableData *packetData = [self buildRequestPacket:_request];
        
        send(clientSock, [packetData bytes], [packetData length], 0);
        
        
        if (_request.HTTPBodyStream != nil)
        {
            
            NSLog(@"body is in stream");
            // body is in stream
            
            
            uint8_t *buffer = malloc(4096);
            size_t length;
            
            
            while (_request.HTTPBodyStream.hasBytesAvailable)
            {
                if ((length = [_request.HTTPBodyStream read:buffer maxLength:sizeof(buffer)]) > 0)
                {
                    // write to socket
                    send(clientSock, buffer, length, 0);
                    
                }
            }
            
            free(buffer);
            
        }
        
        
        
        
        // sent the request
        // now we
        // wait and accumulate the response
        CFHTTPMessageRef httpMessageRef = CFHTTPMessageCreateEmpty(NULL, NO);
        if (httpMessageRef == NULL)
        {
            NSLog(@"Bad HTTPMessageRef !!!!!!!!!");
            return;
            
        }
        for (;;)
        {
            
            
            
            bytesReceived = recv(clientSock,connectionReadBuff+readOffset, 1, 0);
            
            if (bytesReceived < 0)
            {
                [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
                NSLog(@"webapi - recv failed");
                close(clientSock);
                free(connectionReadBuff);
                return;
            }
            else if (bytesReceived == 0)
            {
                if (!hasReceivedResponse)
                {
                    [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
                }
                else
                {
                    // we expect server to close the connection after fulll response is received
                    // inform client delegate
                    
                    
                    if ([responseData length] > 0)
                    {
                        if (isGzippedResponse) {
                            
                            NSData *newData = [self gzipInflate:responseData];
                            
                            if (newData != nil) responseData = [newData mutableCopy];
                            
                        }
                        
                        if (isChunked)
                        {
                            NSData *newData = [self doChunked:responseData];
                            
                            if (newData != nil) responseData = [newData mutableCopy];
                        }
                        
                        [client URLProtocol:self didLoadData:responseData];
                    }
                    
                    
                    
                    
                    [client URLProtocolDidFinishLoading:self];
                }
                
                NSLog(@"webapi - remote connection closed");
                close(clientSock);
                free(connectionReadBuff);
                return;
            }
            else
                
            {
                
                readOffset++;
                
                // see if there's  more
                bytesReceived = recv(clientSock, connectionReadBuff+readOffset, CONNECTION_BUFFLEN-readOffset-1, MSG_DONTWAIT);
                
                if (bytesReceived > 0)
                {
                    readOffset += bytesReceived;
                    
                    
                    // null terminate
                    connectionReadBuff[readOffset] = 0;
                    // NSLog(@"webapi - %s", (char *)connectionReadBuff);
                    
                    
                    
                }
//                g_rxCounter += readOffset;
              
                if (hasReceivedResponse == NO)
                {
                    
                    
                    NSData *bodyData = nil;
                    NSHTTPURLResponse *response = nil;
                    
                    responseData = [[NSMutableData alloc] init];
                    
                    isGzippedResponse = NO;
                    isChunked = NO;
                    
                    contentLength = 0;
                    recvContentLength = 0;
                    
                    
                    
                    // accumulate bytes till we get a full response
                    // this will also fill in any body data if there is some and
                    // create an NSURLHTTPResponse object for us
                    if ([self accumulateResponseHeader:httpMessageRef withBytes:connectionReadBuff length:readOffset response:&response bodyData:&bodyData])
                    {
                        // we have response with all headers
                        
                        CFRelease(httpMessageRef);
                        
                        _response = [response copy];
                        
                        NSLog(@"%@", response);
                        
                        /* Handle redirects */
                        if ((response.statusCode == 301)||(response.statusCode == 302)||(response.statusCode == 307)) {
                            NSString *newURL = [[response allHeaderFields] objectForKey:@"Location"];
                            
                            NSLog(@"[ProxyURLProtocol] Got %ld redirect from %@ to %@", (long)response.statusCode, self.request.URL, newURL);
                            
                            
                            NSMutableURLRequest *newRequest = [_request mutableCopy];
                            [newRequest setHTTPShouldUsePipelining:NO];
                            
                            if ([newURL containsString:@"://"])
                            {
                                newRequest.URL = [[NSURL alloc] initWithString:newURL];
                            }
                            else{
                                newRequest.URL = [[NSURL alloc] initWithScheme:@"http" host:_request.URL.host path:newURL];
                            }
                            if ([[_request mainDocumentURL] isEqual:[_request URL]]) {
                                // Previous request *was* the maindocument request.
                                newRequest.mainDocumentURL = newRequest.URL;
                            }
                            
                            
                            NSLog(@"%@ %@", newRequest, self.request);
                            
                            _request = newRequest;
                            
                            
            
                            
                            [client URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:response];
                            
                            
                            /// cleanup connection here
                            
                            shutdown(clientSock, SHUT_RDWR);
                            close(clientSock);
                            free(connectionReadBuff);
                            return;
                            
                            
                        }
                        else if ((response.statusCode == 401)||(response.statusCode == 407)) {
                            
                            
                            
                            // Prompt user for login info
                            [self performSelectorOnMainThread:@selector(promptForLogin) withObject:nil waitUntilDone:YES];
                            
                            
                            /// cleanup connection here
                            
                            shutdown(clientSock, SHUT_RDWR);
                            close(clientSock);
                            free(connectionReadBuff);
                            return;
                            
                            
                        }
                        
                        else{
                            
                            // we have an actionable response to send up to the protocol client
                            
                            // lets gather some information about the content data from headers
                            NSString *lenStr = [[response allHeaderFields] objectForKey:@"Content-Length"];
                            if (lenStr)
                            {
                                contentLength = [lenStr integerValue];
                            }
                            
                            NSString *content_encoding = [[response allHeaderFields] objectForKey:@"Content-Encoding"];
                            if ([content_encoding isEqualToString:@"gzip"]) {
                                isGzippedResponse = YES;
                            }
                            
                            if ([content_encoding isEqualToString:@"gzip;"]) {
                                isGzippedResponse = YES;
                            }
                            
                            NSString *transfer_encoding = [[response allHeaderFields] objectForKey:@"Transfer-Encoding"];
                            if ([transfer_encoding isEqualToString:@"chunked"])
                            {
                                isChunked = YES;
                                
                            }
                            
                            
                            [client URLProtocol:self didReceiveResponse:_response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                            
                            
                            
                        }
                        
                        hasReceivedResponse = YES;
                    }
                    
                    
                    if (bodyData && ([bodyData length] > 0))
                    {
                        recvContentLength += [bodyData length];
                        
                      
                        [responseData appendData:bodyData];
                        
                        
                    }
                    
                    
                }
                else
                {
                  
                    recvContentLength += readOffset;
                    
                    //NSLog(@"didLoadData2: %d", readOffset);
                    
                    [responseData appendBytes:connectionReadBuff length:readOffset];
                    
                }
                
                readOffset = 0;
            }
        }
}



// This is called by Apple's Secure Transport Layer to manage sending over the socket
// TODO create a version of this function to send over Redpark Cable
OSStatus my_send( SSLConnectionRef connection, const void *data, size_t *dataLength )
{
    redsocketConnectionContext *cntx = (redsocketConnectionContext *)connection;
    size_t bytesToWrite = *dataLength;
    int ret = send(cntx->sockFD, data, bytesToWrite, cntx->flags);
    
    if (ret > 0) {
        *dataLength = ret;
        if (bytesToWrite > *dataLength)
            return errSSLWouldBlock;
        else
            return noErr;
    }     else if (ret == 0)
    {
        *dataLength = 0;
        return errSSLClosedGraceful;
    }
    
    else {
        *dataLength = 0;
        if (EAGAIN == errno) {
            return errSSLWouldBlock;
        } else {
            return errSecIO;
        }
    }}

// This is called by Apple's Secure Transport Layer to manage recv over the socket
// TODO create a version of this function to send over Redpark Cable
OSStatus my_recv( SSLConnectionRef connection, void *data, size_t *dataLength )
{
    redsocketConnectionContext *cntx = (redsocketConnectionContext *)connection;
    size_t bytesRequested = *dataLength;
    ssize_t status = recv(cntx->sockFD, data, bytesRequested, cntx->flags);
    if (status > 0) {
        *dataLength = status;
        if (bytesRequested > *dataLength)
            return errSSLWouldBlock;
        else
            return noErr;
    } else if (0 == status) {
        *dataLength = 0;
        return errSSLClosedGraceful;
    } else {
        *dataLength = 0;
        switch (errno) {
            case ENOENT:
                return errSSLClosedGraceful;
            case EAGAIN:
                return errSSLWouldBlock;
            case ECONNRESET:
                return errSSLClosedAbort;
            default:
                return errSecIO;
        }
        return noErr;
    }
}

/*
 
 This function is useful for debugging the protocol subclass and HTTP parsing.
 Since it uses the native network stack over wifi you can connect XCode to the
 device and debug directly.
 */
-(void)sendSecureRequestAsyncUsingWifi
{
    
    NSLog(@"sendRequestAsyncUsingWifi");
    
    int readOffset = 0;
    size_t bytesReceived = 0;
    
    int port = [[_request URL].port integerValue];
    
    BOOL hasReceivedResponse = NO;
    
    if (!port) port = 443;
    
    id <NSURLProtocolClient> client = self.client;
    
    unsigned char *connectionReadBuff = (unsigned char *)malloc(CONNECTION_BUFFLEN+1);
    if (!connectionReadBuff)
    {
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
        return;
        
    }
    
    char *ipaddrStr = "";
    char *hostname = [[_request URL].host UTF8String];
    struct hostent *host_entry = gethostbyname(hostname);
    if (host_entry)
    {
        
        ipaddrStr = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
    }
    struct sockaddr_in clientAddr;
    int clientSock,k;
    clientSock = socket(AF_INET,SOCK_STREAM,0);
    memset(&clientAddr,0,sizeof(clientAddr));
    clientAddr.sin_family = AF_INET;
    clientAddr.sin_addr.s_addr = inet_addr(ipaddrStr);
    clientAddr.sin_port = htons(port);
    if (connect(clientSock,(struct sockaddr*)&clientAddr,sizeof(clientAddr)) < 0)
    {
        
        close(clientSock);
        return;
    }

    //////////////////////////////////////////////////////////////////
    // using Apple's Secure Transport API for our HTTPS connection
    OSStatus ret;

    // create context
    SSLContextRef sslRef = SSLCreateContext(NULL, kSSLClientSide, kSSLStreamType);
    
    // set our send and recv functions
    ret = SSLSetIOFuncs(sslRef, my_recv, my_send);
    
    // we use a custom struct so we can pass socket and a custom flag if needed
    redsocketConnectionContext cntx;
    cntx.sockFD = clientSock;
    cntx.flags = 0;
    
    // tell SSL library to pass our connection context struct for recv and send calls
    ret = SSLSetConnection(sslRef, &cntx);
    
    ret = SSLSetProtocolVersionMin(sslRef, kTLSProtocol12);
    
    // start SSL handshake
    do {
        ret = SSLHandshake(sslRef);
    } while (ret == errSSLWouldBlock);
    
    NSMutableData *packetData = [self buildRequestPacket:_request];
    

    
    size_t bytesSent;
    int counter = 0;
    do {
        ret = SSLWrite(sslRef, [packetData bytes]+counter, [packetData length]-counter, &bytesSent);
        
        counter += bytesSent;
        
    } while(ret == errSSLWouldBlock);
    
    if (_request.HTTPBodyStream != nil)
    {
        
        NSLog(@"body is in stream");
        
        // body is in stream
        
        uint8_t *buffer = malloc(4096);
        size_t length;
        
        
        while (_request.HTTPBodyStream.hasBytesAvailable)
        {
            if ((length = [_request.HTTPBodyStream read:buffer maxLength:sizeof(buffer)]) > 0)
            {
                counter = 0;
                
                do {
                    ret = SSLWrite(sslRef, buffer+counter, length-counter, &bytesSent);
                    
                    counter += bytesSent;
                    
                } while(ret == errSSLWouldBlock);
                
            }
        }
        
        free(buffer);
        
    }
    
    
    
    
    // sent the request
    // now we
    // wait and accumulate the response
    CFHTTPMessageRef httpMessageRef = CFHTTPMessageCreateEmpty(NULL, NO);
    if (httpMessageRef == NULL)
    {
        NSLog(@"Bad HTTPMessageRef !!!!!!!!!");
        return;
        
    }
    for (;;)
    {
        
    
        cntx.flags = 0;
        do {
            ret = SSLRead(sslRef,connectionReadBuff+readOffset, CONNECTION_BUFFLEN, &bytesReceived);
         } while(ret == errSSLWouldBlock);
        
        if (ret < 0 && ret != errSSLClosedGraceful && ret != errSSLClosedAbort)
        {
            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            NSLog(@"webapi - recv failed");
            
            SSLClose(sslRef);
            close(clientSock);
            free(connectionReadBuff);
            return;
        }
        else if (ret == errSSLClosedGraceful || ret == errSSLClosedAbort)
        {
            if (!hasReceivedResponse)
            {
                [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            }
            else
            {
                // we expect server to close the connection after fulll response is received
                // inform client delegate
                if ([responseData length] > 0)
                {

                    
                    if (isChunked)
                    {
                        NSData *newData = [self doChunked:responseData];
                        
                        if (newData != nil) responseData = [newData mutableCopy];
                    }
                    
                    if (isGzippedResponse) {
                        
                        NSData *newData = [self gzipInflate:responseData];
                        
                        if (newData != nil) responseData = [newData mutableCopy];
                        
                    }
                    
                    [client URLProtocol:self didLoadData:responseData];
                }
                
                
                
                
                [client URLProtocolDidFinishLoading:self];
            }
            
            NSLog(@"webapi - remote connection closed");
            SSLClose(sslRef);
            close(clientSock);
            free(connectionReadBuff);
            return;
        }
        else
            
        {

            readOffset += bytesReceived;
                
//            g_rxCounter += readOffset;
          
            if (hasReceivedResponse == NO)
            {
                
                
                NSData *bodyData = nil;
                NSHTTPURLResponse *response = nil;
                
                responseData = [[NSMutableData alloc] init];
                
                isGzippedResponse = NO;
                isChunked = NO;
                
                contentLength = 0;
                recvContentLength = 0;
                
                
                
                // accumulate bytes till we get a full response
                // this will also fill in any body data if there is some and
                // create an NSURLHTTPResponse object for us
                if ([self accumulateResponseHeader:httpMessageRef withBytes:connectionReadBuff length:readOffset response:&response bodyData:&bodyData])
                {
                    // we have response with all headers
                    
                    CFRelease(httpMessageRef);
                    
                    _response = [response copy];
                    
                    NSLog(@"%@", response);
                    
                    /* Handle redirects */
                    if ((response.statusCode == 301)||(response.statusCode == 302)||(response.statusCode == 307)) {
                        NSString *newURL = [[response allHeaderFields] objectForKey:@"Location"];
                        
                        NSLog(@"[ProxyURLProtocol] Got %ld redirect from %@ to %@", (long)response.statusCode, self.request.URL, newURL);
                        
                        
                        NSMutableURLRequest *newRequest = [_request mutableCopy];
                        [newRequest setHTTPShouldUsePipelining:NO];
                        
                        if ([newURL containsString:@"://"])
                        {
                            newRequest.URL = [[NSURL alloc] initWithString:newURL];
                        }
                        else{
                            newRequest.URL = [[NSURL alloc] initWithScheme:@"https" host:_request.URL.host path:newURL];
                        }
                        if ([[_request mainDocumentURL] isEqual:[_request URL]]) {
                            // Previous request *was* the maindocument request.
                            newRequest.mainDocumentURL = newRequest.URL;
                        }
                        
                        
                        NSLog(@"%@ %@", newRequest, self.request);
                        
                        _request = newRequest;
                        
                        
                        
                        
                        [client URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:response];
                        
                        
                        /// cleanup connection here
                        SSLClose(sslRef);
                        shutdown(clientSock, SHUT_RDWR);
                        close(clientSock);
                        free(connectionReadBuff);
                        return;
                        
                        
                    }
                    else if ((response.statusCode == 401)||(response.statusCode == 407)) {
                        
                        
                        
                        // Prompt user for login info
                        [self performSelectorOnMainThread:@selector(promptForLogin) withObject:nil waitUntilDone:YES];
                        
                        
                        /// cleanup connection here
                        SSLClose(sslRef);
                        shutdown(clientSock, SHUT_RDWR);
                        close(clientSock);
                        free(connectionReadBuff);
                        return;
                        
                        
                    }
                    
                    else{
                        
                        // we have an actionable response to send up to the protocol client
                        
                        // lets gather some information about the content data from headers
                        NSString *lenStr = [[response allHeaderFields] objectForKey:@"Content-Length"];
                        if (lenStr)
                        {
                            contentLength = [lenStr integerValue];
                        }
                        
                        NSString *content_encoding = [[response allHeaderFields] objectForKey:@"Content-Encoding"];
                        if ([content_encoding isEqualToString:@"gzip"]) {
                            isGzippedResponse = YES;
                        }
                        
                        if ([content_encoding isEqualToString:@"gzip;"]) {
                            isGzippedResponse = YES;
                        }
                        
                        NSString *transfer_encoding = [[response allHeaderFields] objectForKey:@"Transfer-Encoding"];
                        if ([transfer_encoding isEqualToString:@"chunked"])
                        {
                            isChunked = YES;
                            
                        }
                        
                        
                        [client URLProtocol:self didReceiveResponse:_response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                        
                        
                        
                    }
                    
                    hasReceivedResponse = YES;
                }
                
                
                if (bodyData && ([bodyData length] > 0))
                {
                    recvContentLength += [bodyData length];
                    
                    
                    [responseData appendData:bodyData];
                    
                    
                }
                
                
            }
            else
            {
                
                recvContentLength += readOffset;
                
                //NSLog(@"didLoadData2: %d", readOffset);
                
                [responseData appendBytes:connectionReadBuff length:readOffset];
                
            }
            
            readOffset = 0;
        }
    }
}



// This is called by Apple's Secure Transport Layer to manage sending over the socket
// TODO create a version of this function to send over Redpark Cable
OSStatus my_cable_send( SSLConnectionRef connection, const void *data, size_t *dataLength )
{
    redsocketConnectionContext *cntx = (redsocketConnectionContext *)connection;
    size_t bytesToWrite = *dataLength;
    
    int ret = [[RedSocketManager sharedInstance] send:cntx->sockFD dataptr:data size:bytesToWrite flags:cntx->flags];
    
    if (ret > 0) {
        *dataLength = ret;
        if (bytesToWrite > *dataLength)
            return errSSLWouldBlock;
        else
            return noErr;
    }
    else if (ret == 0)
    {
        *dataLength = 0;
        return errSSLClosedGraceful;
    }
    
    else {
        
        *dataLength = 0;
        if (EAGAIN == errno) {
            return errSSLWouldBlock;
        } else {
            return errSecIO;
        }
    }}

// This is called by Apple's Secure Transport Layer to manage recv over the socket
// TODO create a version of this function to send over Redpark Cable
OSStatus my_cable_recv( SSLConnectionRef connection, void *data, size_t *dataLength )
{
    redsocketConnectionContext *cntx = (redsocketConnectionContext *)connection;
    size_t bytesRequested = *dataLength;
  
    ssize_t status = [[RedSocketManager sharedInstance] recv:cntx->sockFD mem:data len:bytesRequested flags:cntx->flags];
    
    if (status > 0) {
        *dataLength = status;
        if (bytesRequested > *dataLength)
            return errSSLWouldBlock;
        else
            return noErr;
    } else if (0 == status) {
        *dataLength = 0;
        return errSSLClosedGraceful;
    } else {
        *dataLength = 0;
        
        switch (errno) {
            case ENOENT:
                return errSSLClosedGraceful;
            case EAGAIN:
                return errSSLWouldBlock;
            case ECONNRESET:
                return errSSLClosedAbort;
            default:
                return errSecIO;
        }
        return noErr;
    }
}


-(void)sendSecureRequestAsyncUsingCable
{
    
    NSLog(@"sendSecuredRequestAsyncUsingCable");
    
    int readOffset = 0;
    size_t bytesReceived = 0;
    
    int port = [[_request URL].port integerValue];
    
    BOOL hasReceivedResponse = NO;
    
    if (!port) port = 443;
    
    id <NSURLProtocolClient> client = self.client;
    
    unsigned char *connectionReadBuff = (unsigned char *)malloc(CONNECTION_BUFFLEN+1);
    if (!connectionReadBuff)
    {
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
        return;
        
    }
    
    char *ipaddrStr = "";
    const char *hostname = [[_request URL].host UTF8String];
    struct hostent *host_entry = redsocket_gethostbyname(hostname);
    if (host_entry)
    {
        
        ipaddrStr = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
    }
    struct sockaddr_in clientAddr;
    int clientSock;

    clientSock = [[RedSocketManager sharedInstance] socket:AF_INET type:SOCK_STREAM protocol:IPPROTO_TCP];
    
    
    memset(&clientAddr,0,sizeof(clientAddr));
    clientAddr.sin_family = AF_INET;
    clientAddr.sin_addr.s_addr = inet_addr(ipaddrStr);
    clientAddr.sin_port = htons(port);

     if ([[RedSocketManager sharedInstance] connect:clientSock sockaddr:(struct sockaddr *)&clientAddr namelen:sizeof(clientAddr)] < 0)
    {
        
        [[RedSocketManager sharedInstance] close:clientSock];
        return;
    }
    
    //////////////////////////////////////////////////////////////////
    // using Apple's Secure Transport API for our HTTPS connection
    OSStatus ret;
    
    // create context
    SSLContextRef sslRef = SSLCreateContext(NULL, kSSLClientSide, kSSLStreamType);
    
    // set our send and recv functions
    ret = SSLSetIOFuncs(sslRef, my_cable_recv, my_cable_send);
    
    // we use a custom struct so we can pass socket and a custom flag if needed
    redsocketConnectionContext cntx;
    cntx.sockFD = clientSock;
    cntx.flags = 0;
    
    // tell SSL library to pass our connection context struct for recv and send calls
    ret = SSLSetConnection(sslRef, &cntx);
    
    ret = SSLSetProtocolVersionMin(sslRef, kTLSProtocol12);
    
    // start SSL handshake
    do {
        ret = SSLHandshake(sslRef);
    } while (ret == errSSLWouldBlock);
    
    
    NSMutableData *packetData = [self buildRequestPacket:_request];
    
    size_t bytesSent;
    int counter = 0;
    do {
        ret = SSLWrite(sslRef, [packetData bytes]+counter, [packetData length]-counter, &bytesSent);
        
        counter += bytesSent;
        
    } while(ret == errSSLWouldBlock);
    
    
    if (_request.HTTPBodyStream != nil)
    {
        
        NSLog(@"body is in stream");
        // body is in stream
        
        
        uint8_t *buffer = malloc(4096);
        size_t length;
        
        
        while (_request.HTTPBodyStream.hasBytesAvailable)
        {
            if ((length = [_request.HTTPBodyStream read:buffer maxLength:sizeof(buffer)]) > 0)
            {
                // write to SSL session
                counter = 0;
                
                do {
                    ret = SSLWrite(sslRef, buffer+counter, length-counter, &bytesSent);
                    
                    counter += bytesSent;
                    
                } while(ret == errSSLWouldBlock);

                
            }
        }
        
        free(buffer);
        
    }
    
    
    
    
    // sent the request
    // now we
    // wait and accumulate the response
    CFHTTPMessageRef httpMessageRef = CFHTTPMessageCreateEmpty(NULL, NO);
    if (httpMessageRef == NULL)
    {
        NSLog(@"Bad HTTPMessageRef !!!!!!!!!");
        return;
        
    }
    for (;;)
    {
        
        
        cntx.flags = 0;
        do {
            ret = SSLRead(sslRef,connectionReadBuff+readOffset, CONNECTION_BUFFLEN, &bytesReceived);
            
            if (bytesReceived) ret = 0;
            
        } while(ret == errSSLWouldBlock);
        
        
        if (ret < 0 && ret != errSSLClosedGraceful && ret != errSSLClosedAbort)
        {
            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            NSLog(@"webapi - recv failed");
            
            SSLClose(sslRef);
            //close(clientSock);
            [[RedSocketManager sharedInstance] close:clientSock];
            free(connectionReadBuff);
            return;
        }
        else if (ret == errSSLClosedGraceful || ret == errSSLClosedAbort)
        {
            if (!hasReceivedResponse)
            {
                [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"RedSocket" code:-1 userInfo:nil]];
            }
            else
            {
                // we expect server to close the connection after fulll response is received
                // inform client delegate
                
                
                if ([responseData length] > 0)
                {
                    
                    
                    if (isChunked)
                    {
                        NSData *newData = [self doChunked:responseData];
                        
                        if (newData != nil) responseData = [newData mutableCopy];
                    }
                    
                    if (isGzippedResponse) {
                        
                        NSData *newData = [self gzipInflate:responseData];
                        
                        if (newData != nil) responseData = [newData mutableCopy];
                        
                    }
                    
                    [client URLProtocol:self didLoadData:responseData];
                }
                
                
                
                
                [client URLProtocolDidFinishLoading:self];
            }
            
            NSLog(@"webapi - remote connection closed");
            SSLClose(sslRef);
            [[RedSocketManager sharedInstance] close:clientSock];
            free(connectionReadBuff);
            return;
        }
        else
            
        {

            readOffset += bytesReceived;
                
                
            // null terminate
            connectionReadBuff[readOffset] = 0;
                
                
            
//            g_rxCounter += readOffset;
          
            if (hasReceivedResponse == NO)
            {
                
                
                NSData *bodyData = nil;
                NSHTTPURLResponse *response = nil;
                
                responseData = [[NSMutableData alloc] init];
                
                isGzippedResponse = NO;
                isChunked = NO;
                
                contentLength = 0;
                recvContentLength = 0;
                
                
                
                // accumulate bytes till we get a full response
                // this will also fill in any body data if there is some and
                // create an NSURLHTTPResponse object for us
                if ([self accumulateResponseHeader:httpMessageRef withBytes:connectionReadBuff length:readOffset response:&response bodyData:&bodyData])
                {
                    // we have response with all headers
                    
                    CFRelease(httpMessageRef);
                    
                    _response = [response copy];
                    
                    NSLog(@"%@", response);
                    
                    /* Handle redirects */
                    if ((response.statusCode == 301)||(response.statusCode == 302)||(response.statusCode == 307)) {
                        NSString *newURL = [[response allHeaderFields] objectForKey:@"Location"];
                        
                        NSLog(@"[ProxyURLProtocol] Got %ld redirect from %@ to %@", (long)response.statusCode, self.request.URL, newURL);
                        
                        
                        NSMutableURLRequest *newRequest = [_request mutableCopy];
                        [newRequest setHTTPShouldUsePipelining:NO];
                        
                        if ([newURL containsString:@"://"])
                        {
                            newRequest.URL = [[NSURL alloc] initWithString:newURL];
                        }
                        else{
                            newRequest.URL = [[NSURL alloc] initWithScheme:@"https" host:_request.URL.host path:newURL];
                        }
                        if ([[_request mainDocumentURL] isEqual:[_request URL]]) {
                            // Previous request *was* the maindocument request.
                            newRequest.mainDocumentURL = newRequest.URL;
                        }
                        
                        
                        NSLog(@"%@ %@", newRequest, self.request);
                        
                        _request = newRequest;
                        
                        
                        
                        
                        [client URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:response];
                        
                        
                        /// cleanup connection here
                        SSLClose(sslRef);
                        //shutdown(clientSock, SHUT_RDWR);
                        [[RedSocketManager sharedInstance] close:clientSock];
                        free(connectionReadBuff);
                        return;
                        
                        
                    }
                    else if ((response.statusCode == 401)||(response.statusCode == 407)) {
                        
                        
                        
                        // Prompt user for login info
                        [self performSelectorOnMainThread:@selector(promptForLogin) withObject:nil waitUntilDone:YES];
                        
                        
                        /// cleanup connection here
                        SSLClose(sslRef);
                        //shutdown(clientSock, SHUT_RDWR);
                        [[RedSocketManager sharedInstance] close:clientSock];
                        free(connectionReadBuff);
                        return;
                        
                        
                    }
                    
                    else{
                        
                        // we have an actionable response to send up to the protocol client
                        
                        // lets gather some information about the content data from headers
                        NSString *lenStr = [[response allHeaderFields] objectForKey:@"Content-Length"];
                        if (lenStr)
                        {
                            contentLength = [lenStr integerValue];
                        }
                        
                        NSString *content_encoding = [[response allHeaderFields] objectForKey:@"Content-Encoding"];
                        if ([content_encoding isEqualToString:@"gzip"]) {
                            isGzippedResponse = YES;
                        }
                        
                        if ([content_encoding isEqualToString:@"gzip;"]) {
                            isGzippedResponse = YES;
                        }
                        
                        NSString *transfer_encoding = [[response allHeaderFields] objectForKey:@"Transfer-Encoding"];
                        if ([transfer_encoding isEqualToString:@"chunked"])
                        {
                            isChunked = YES;
                            
                        }
                        
                        
                        [client URLProtocol:self didReceiveResponse:_response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                        
                        
                        
                    }
                    
                    hasReceivedResponse = YES;
                }
                
                
                if (bodyData && ([bodyData length] > 0))
                {
                    recvContentLength += [bodyData length];
                    
                    
                    [responseData appendData:bodyData];
                    
                    
                }
                
                
            }
            else
            {
                
                recvContentLength += readOffset;
                
                //NSLog(@"didLoadData2: %d", readOffset);
                
                [responseData appendBytes:connectionReadBuff length:readOffset];
                
            }
            
            readOffset = 0;
        }
    }
}



- (NSData *) doChunked:(NSData *) transferData
{
    NSMutableData *entityData = [[NSMutableData alloc] init];
    
    const char *start;
    const char *cp = start = (const char *)[transferData bytes];
    int length = [transferData length];
    int bytesProcessed = 0;
    
    uint32_t chunksize = 0;
    
    if (sscanf(cp, "%x", &chunksize) == 0)
    {
        chunksize = 0;
    }
    
    while (chunksize > 0)
    {
        cp = strchr(cp, '\n');
        if (cp == NULL) return nil;
        cp++;
        
        bytesProcessed = (cp - start);
        if ((length - bytesProcessed) < chunksize) return nil;
        
        [entityData appendBytes:cp length:chunksize];
        cp += chunksize;
        
        cp = strchr(cp, '\n');
        if (cp == NULL) return nil;
        cp++;
        
        // read next chunk
        if (sscanf(cp, "%x", &chunksize) == 0)
        {
            chunksize = 0;
            return nil;
        }
    }
    
    return entityData;
}



-(BOOL)accumulateResponseHeader:(CFHTTPMessageRef)httpMessageRef withBytes:(uint8_t *)bytes length:(int)length response:(NSHTTPURLResponse * __autoreleasing *)response bodyData:(NSData * __autoreleasing *)bodyData
{
    BOOL res;
    
    res = CFHTTPMessageAppendBytes(httpMessageRef, bytes, length);
    
    if (CFHTTPMessageIsHeaderComplete(httpMessageRef) == YES)
    {
        // look at content length
        *response = [[NSHTTPURLResponse alloc] initWithURL:CFBridgingRelease(CFHTTPMessageCopyRequestURL(httpMessageRef)) statusCode:CFHTTPMessageGetResponseStatusCode(httpMessageRef) HTTPVersion:CFBridgingRelease(CFHTTPMessageCopyVersion(httpMessageRef)) headerFields:CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(httpMessageRef))];
        
        *bodyData = CFBridgingRelease(CFHTTPMessageCopyBody(httpMessageRef));
        
        return YES;
    }
    
    *bodyData = nil;
    return NO;
    
}

-(void)stopLoading
{
    // TODO - we could abort the socket read
}



-(void)promptForLogin
{
    // Login and password alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login"
                                                    message:[NSString stringWithFormat:@"Enter Login ID and Password:"]
                                                   delegate:self cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    
    [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [alert show];
    
    
}

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    username = [[alert textFieldAtIndex:0] text];
    password = [[alert textFieldAtIndex:1] text];
    
    NSLog(@"Login: %@", [[alert textFieldAtIndex:0] text]);
    NSLog(@"Password: %@", [[alert textFieldAtIndex:1] text]);
    
    
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistenceForSession];
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc]
                                             initWithHost:[_request URL].host
                                             port:0
                                             protocol:@"http"
                                             realm:nil
                                             authenticationMethod:nil];
    
    
    [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential
                                                        forProtectionSpace:protectionSpace];
    

        
    [self startLoading];
    
    
}


- (NSData *)zlibInflate:(NSData *)data
{
    if ([data length] == 0) return data;
    
    unsigned int full_length = (unsigned int)[data length];
    unsigned int half_length = (unsigned int)([data length] / 2);
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = (unsigned int)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit (&strm) != Z_OK) return nil;
    
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

- (NSData *)gzipInflate:(NSData *)data
{
    if ([data length] == 0) return data;
    
    unsigned int full_length = (unsigned int)[data length];
    unsigned int half_length = (unsigned int)([data length] / 2);
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = (unsigned int)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

@end
