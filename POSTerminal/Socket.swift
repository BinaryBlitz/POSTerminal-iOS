//
//  Socket.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//
//

import Foundation

/* Low level routines for POSIX sockets */

public enum SocketError: ErrorType {
    case SocketCreationFailed(String)
    case SocketSettingReUseAddrFailed(String)
    case BindFailed(String)
    case ListenFailed(String)
    case WriteFailed(String)
    case GetPeerNameFailed(String)
    case ConvertingPeerNameFailed
    case GetNameInfoFailed(String)
    case AcceptFailed(String)
    case RecvFailed(String)
}

public class Socket: Hashable, Equatable {
    
    public class func tcpSocketForListen(port: in_port_t, forceIPv4: Bool = false, maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {
        
//        let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
      let socketFileDescriptor = RedSocketManager.sharedInstance().socket(forceIPv4 ? AF_INET : AF_INET6, type: SOCK_STREAM, protocol: IPPROTO_TCP)
//        _sock = [[RedSocketManager sharedInstance] socket:AF_INET type:SOCK_STREAM protocol:IPPROTO_TCP];
      
        if socketFileDescriptor == -1 {
            throw SocketError.SocketCreationFailed(Socket.descriptionOfLastError())
        }
        
        var value: Int32 = 1
//        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 {
//            let details = Socket.descriptionOfLastError()
//            Socket.release(socketFileDescriptor)
//            throw SocketError.SocketSettingReUseAddrFailed(details)
//        }
        if (RedSocketManager.sharedInstance().setsockopt(socketFileDescriptor, level: SOL_SOCKET, optname: SO_REUSEADDR, optval: &value, optlen: socklen_t(sizeof(Int32))) == -1) {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.SocketSettingReUseAddrFailed(details)
        }
      
        Socket.setNoSigPipe(socketFileDescriptor)
      
//        let sin = sockaddr_in()
//        struct sockaddr_in sin;
//        memset(&sin, 0, sizeof(sin));
//        sin.sin_len = sizeof(sin);
//        sin.sin_family = AF_INET; // or AF_INET6 (address family)
//        sin.sin_port = htons(SERVER_LISTEN_PORT);
//        sin.sin_addr.s_addr= htonl(INADDR_ANY);
      
        var bindResult: Int32 = -1
        if forceIPv4 {
            var addr = sockaddr_in(sin_len: UInt8(strideof(sockaddr_in)),
                sin_family: UInt8(AF_INET),
                sin_port: Socket.htonsPort(port),
                sin_addr: in_addr(s_addr: UInt32(0x00000000)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
         
//            bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in))) }
            bindResult = withUnsafePointer(&addr) { RedSocketManager.sharedInstance().bind(socketFileDescriptor, name: UnsafePointer<sockaddr>($0), namelen: socklen_t(sizeof(sockaddr_in))) }
          
//        if ([[RedSocketManager sharedInstance] bind:listenSocket name:(struct sockaddr *)&sin namelen:sizeof(sin)] < 0)
        } else {
            var addr = sockaddr_in6(sin6_len: UInt8(strideof(sockaddr_in6)),
                sin6_family: UInt8(AF_INET6),
                sin6_port: Socket.htonsPort(port),
                sin6_flowinfo: 0,
                sin6_addr: in6addr_any,
                sin6_scope_id: 0)
            
//            bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6))) }
            bindResult = withUnsafePointer(&addr) { RedSocketManager.sharedInstance().bind(socketFileDescriptor, name: UnsafePointer<sockaddr>($0), namelen: socklen_t(sizeof(sockaddr_in6))) }
        }

        if bindResult == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.BindFailed(details)
        }
      
      
      
//        if listen(socketFileDescriptor, maxPendingConnection ) == -1 {
        if RedSocketManager.sharedInstance().listen(socketFileDescriptor, backlog: maxPendingConnection) == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.ListenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }
    
    private let socketFileDescriptor: Int32
    
    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }
    
    public var hashValue: Int { return Int(self.socketFileDescriptor) }
    
    public func release() {
        Socket.release(self.socketFileDescriptor)
    }
    
    public func shutdwn() {
        Socket.shutdwn(self.socketFileDescriptor)
    }
    
    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()        
        var len: socklen_t = 0
//        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        let clientSocket = RedSocketManager.sharedInstance().accept(self.socketFileDescriptor, addr: &addr, addrlen: &len)
//            int connectFD = [[RedSocketManager sharedInstance] accept:listenSocket addr:NULL addrlen:NULL];
        if clientSocket == -1 {
            throw SocketError.AcceptFailed(Socket.descriptionOfLastError())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
    
    public func writeUTF8(string: String) throws {
        try writeUInt8(ArraySlice(string.utf8))
    }
    
    public func writeUInt8(data: [UInt8]) throws {
        try writeUInt8(ArraySlice(data))
    }
    
    public func writeUInt8(data: ArraySlice<UInt8>) throws {
        try data.withUnsafeBufferPointer {
          var sent = 0
            while sent < data.count {
//                let s = write(self.socketFileDescriptor, $0.baseAddress + sent, Int(data.count - sent))
                let s = RedSocketManager.sharedInstance().send(self.socketFileDescriptor, dataptr: $0.baseAddress + sent, size: Int(data.count - sent), flags: 0)
//              [[RedSocketManager sharedInstance] send:_sock dataptr:[packetData bytes] size:[packetData length] flags:0];
                if s <= 0 {
                    throw SocketError.WriteFailed(Socket.descriptionOfLastError())
                }
                sent += Int(s) //????????????????????
            }
        }
    }
    
    public func read() throws -> UInt8 {
        var buffer = [UInt8](count: 1, repeatedValue: 0)
//        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
      
        let next = RedSocketManager.sharedInstance().recv(self.socketFileDescriptor as Int32, mem: &buffer, len: Int(buffer.count), flags: 0)
        if next <= 0 {
            throw SocketError.RecvFailed(Socket.descriptionOfLastError())
        }
        return buffer[0]
    }
    
    private static let CR = UInt8(13)
    private static let NL = UInt8(10)
    
    public func readLine() throws -> String {
        var characters: String = ""
        var n: UInt8 = 0
        repeat {
            n = try self.read()
            if n > Socket.CR { characters.append(Character(UnicodeScalar(n))) }
        } while n != Socket.NL
        return characters
    }
    
    public func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.GetPeerNameFailed(Socket.descriptionOfLastError())
        }
        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.GetNameInfoFailed(Socket.descriptionOfLastError())
        }
        guard let name = String.fromCString(hostBuffer) else {
            throw SocketError.ConvertingPeerNameFailed
        }
        return name
    }
    
    private class func descriptionOfLastError() -> String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
    
    private class func setNoSigPipe(socket: Int32) {
        #if os(Linux)
            // There is no SO_NOSIGPIPE in Linux (nor some other systems). You can instead use the MSG_NOSIGNAL flag when calling send(),
            // or use signal(SIGPIPE, SIG_IGN) to make your entire application ignore SIGPIPE.
        #else
            // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
            var no_sig_pipe: Int32 = 1
            setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)))
        #endif
    }
    
    private class func shutdwn(socket: Int32) {
//        #if os(Linux)
//            shutdown(socket, Int32(SHUT_RDWR))
//        #else
//            Darwin.shutdown(socket, SHUT_RDWR)
//        #endif
//        [[RedSocketManager sharedInstance] close:_sock];
      RedSocketManager.sharedInstance().shutdown(socket, how: SHUT_RDWR)
    }
    
    private class func release(socket: Int32) {
//        #if os(Linux)
//            shutdown(socket, Int32(SHUT_RDWR))
//        #else
//            Darwin.shutdown(socket, SHUT_RDWR)
//        #endif
//        close(socket)
      RedSocketManager.sharedInstance().shutdown(socket, how: SHUT_RDWR)
      RedSocketManager.sharedInstance().close(socket)
    }
    
    private class func htonsPort(port: in_port_t) -> in_port_t {
        #if os(Linux)
            return htons(port)
        #else
            let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return isLittleEndian ? _OSSwapInt16(port) : port
        #endif
    }
}

public func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}
