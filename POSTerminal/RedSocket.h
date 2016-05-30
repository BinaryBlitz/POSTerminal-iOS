//
//  RedSocket.h
//
//  Copyright (c) 2014 Redpark. All rights reserved.
//


#import <UIKit/UIKit.h>

#ifndef REDPARK_

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


/* Flags we can use with send and recv. */
#define REDSOCKET_MSG_DONTWAIT   0x08    /* Nonblocking i/o for this operation only */
#define REDSOCKET_MSG_MORE       0x10    /* Sender will send more */



/*
 * Options for level IPPROTO_TCP
 */

#define REDSOCKET_TCP_NODELAY    0x01    /* don't delay send to coalesce packets */
#define REDSOCKET_TCP_KEEPALIVE  0x02    /* send KEEPALIVE probes when idle for pcb->keep_idle milliseconds */
#define REDSOCKET_TCP_KEEPIDLE   0x03    /* set pcb->keep_idle  - Same as TCP_KEEPALIVE, but use seconds for get/setsockopt */
#define REDSOCKET_TCP_KEEPINTVL  0x04    /* set pcb->keep_intvl - Use seconds for get/setsockopt */
#define REDSOCKET_TCP_KEEPCNT    0x05    /* set pcb->keep_cnt   - Use number of probes sent for get/setsockopt */

#endif


@protocol RedSocketManagerDelegate;

/*
 
    This protocol (RedSocketMangerProtocol), describes the main interface to the Redpark Socket Manager layer.
 
    To use, call factory method below [RedparkSocketManager sharedInstance]
 
 */
@protocol RedSocketManagerProtocol <NSObject>


// configure and start local network interface using static IP address deviceIPAddress, and gateway and netmask
// if deviceIPAddress is "0.0.0.0", use DHCP to obtain IP address, gateway and netmask
//
-(void)configureNetworkInterface:(NSString *)deviceIPAddress gateway:(NSString *)gateway netmask:(NSString *)netmask dns:(NSString *)dns;

// returns assigned IP address for local network interface
-(NSString *)ipAddress;

// returns assigned gateway address for local network interface
-(NSString *)gatewayAddress;

// returns assigned netmask for local network interface
-(NSString *)netmask;

// returns assigned DNS address for local network interface
-(NSString *)dnsAddress;

// allocate and return a RedSocket.  domain is ignored
// type is SOCK_RAW, SOCK_DGRAM or SOCK_STREAM
//
-(int)socket:(int)domain type:(int)type protocol:(int)protocol;
//
// blocks until a connection arrives on a Listen RedSocket
//
-(int)accept:(int)s addr:(struct sockaddr *)addr addrlen:(socklen_t *)addrlen;


// posts an async accept
// when new connection arrives, delegate callback didSocketAccept:(int)sock addr:(struct sockaddr *)addr addrlen:(socklen_t *)addrlen will be called
-(void)acceptAsync:(int)listenSocket addr:(struct sockaddr *)addr addrlen:(socklen_t *)addrlen;

//
// associate a local address to a RedSocket <s>
// name->sin_port is the local port
// name->sin_addr is the local address
//
-(int)bind:(int)s name:(const struct sockaddr *)name namelen:(socklen_t)namelen;
-(int)shutdown:(int)s how:(int)how;
-(int)getpeername:(int)s name:(struct sockaddr *)name namelen:(socklen_t *)namelen;
-(int)getsockname:(int)s name:(struct sockaddr *)name namelen:(socklen_t *)namelen;
-(int)getsockopt:(int)s level:(int)level optname:(int)optname optval:(void *)optval optlen:(socklen_t *)optlen;
-(int)setsockopt:(int)s level:(int)level optname:(int)optname optval:(const void *)optval optlen:(socklen_t) optlen;
//
// close RedSocket <s>
//
-(int)close:(int)s;
//
// connect via TCP to a remote host on socket <s>
// blocks until successful connection or timeout
//
-(int)connect:(int)s sockaddr:(const struct sockaddr *)name namelen:(socklen_t)namelen;
//
// put RedSocket <s> into Listen mode
//
-(int)listen:(int)s backlog:(int)backlog;
//
// reads <len> bytes into mem[] with flags, blocks as needed to make up length
//
-(int)recv:(int)s mem:(void *)mem len:(size_t)len flags:(int)flags;
//
// reads <len> bytes into mem[], blocks as needed to make up length
//
-(int)read:(int)s mem:(void *)mem len:(size_t)len;
//
// reads <len> bytes into mem[], blocks as needed to make up length
//
-(int)recvfrom:(int)s mem:(void *)mem len:(size_t)len flags:(int)flags from:(struct sockaddr *)from fromlen:(socklen_t *)fromlen;

//
// posts an asynchronous read to the socket
// when length has been received, the delegate function didSocketRecv:(int)socket buffer(void *)buffer length(size_t)length error:(int)error;
// will get called
-(void)recvAsync:(int)sock buffer:(void *)buffer length:(size_t)length;

//
// send <size> bytes on socket <s>, either TCP or UDP, with flags
//
-(int)send:(int)s dataptr:(const void *)dataptr size:(size_t)size flags:(int)flags;
//
// send a UDP message dataptr[] remote address <to>
//
-(int)sendto:(int)s dataptr:(const void *)dataptr size:(size_t)size flags:(int)flags to:(const struct sockaddr *)to tolen:(socklen_t)tolen;
//
// send <size> bytes on socket <s>, either TCP or UDP
//
-(int)write:(int)s dataptr:(const void *)dataptr size:(size_t)size;
-(int)select:(int)maxfdp1 readset:(fd_set *)readset writeset:(fd_set *)writeset exceptset:(fd_set *)exceptset timeout:(struct timeval *)timeout;
-(int)ioctl:(int)s cmd:(long)cmd argp:(void *)argp;
-(int)fcntl:(int)s cmd:(int)cmd val:(int)val;
//-(int)raw_sendto:(struct raw_pcb *)pcb p:(struct pbuf *)p ipaddr:(ip_addr_t *)ipaddr;

//
// cancel a blocking read on <s>
-(int)abort_recv:(int)s;

// cancel a blocking read, accept and select on <s>
-(int)abort_all:(int)s;

// set delegate for cable connect callbacks
-(void)setDelegate:(id <RedSocketManagerDelegate>) delegate;

-(BOOL)isCableConnected;

-(NSString *)getAccessoryFirmwareVersion;



/////////////////////////////////////////////////////////////////////////////////
// basic stats for debugging (total bytes received since reset or cable connect
-(int)getRxCounter;

// reset rx counter
-(void)resetRxCounter;


///////////////////////////////////////////////////////////
// external logging over WIFI
- (void) enableExternalLogging:(BOOL)enable;
- (void) enableTxRxExternalLogging:(BOOL)enable;
- (void) logEvent:(NSString *)text color:(NSString *)color;

@end


@protocol RedSocketManagerDelegate <NSObject>

//Cable was connected
- (void) cableConnected:(NSString *)protocol;

// Cable was disconnected and/or application moved to background
- (void) cableDisconnected;



@optional

// If DHCP client is enabled - this callback is made when ip address is assigned
- (void) didAssignIpAddress:(NSString *)deviceAddress gateway:(NSString *)gateway netmask:(NSString *)netmask;

// bytesRead > 0 (actual bytes read)
// bytesRead = 0 (connection closed)
// bytesRead < 0 error stored in errno
-(void) didSocketRecv:(int)socket buffer:(void *)buffer bytesRead:(int)bytesRead;

- (void) didSocketAccept:(int)newSocket addr:(struct sockaddr *)addr addrlen:(socklen_t *)addrlen;

- (void) linkStatusChanged:(BOOL)linkIsUp;

@end


@interface RedSocketManager : NSObject

+ (id <RedSocketManagerProtocol>)sharedInstance;

@end


/*
 
 redsocket_gethostbyname()
 
 gethostbyname functionality that uses RedSocket internals
 
 */

struct hostent*
redsocket_gethostbyname(const char *name);

/*
 
 RedEthernet_calcCRC32
 
 returns crc32 for data in buffer.
 
 numWords = length of buffer in bytes / sizeof(uint32_t)
 
 buffer data must be a multiple of uint32_t's.  The caller can choose to pad the data
 to a 32-bit boundary.
 
 */
UInt32 RedEthernet_calcCRC32(UInt32 *buffer, unsigned int numWords);

