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
        
      let socketFileDescriptor = RedSocketManager.sharedInstance().socket(forceIPv4 ? AF_INET : AF_INET6, type: SOCK_STREAM, protocol: IPPROTO_TCP)
      
        if socketFileDescriptor == -1 {
            throw SocketError.SocketCreationFailed(Socket.descriptionOfLastError())
        }
        
        var value: Int32 = 1
        if (RedSocketManager.sharedInstance().setsockopt(socketFileDescriptor, level: SOL_SOCKET, optname: SO_REUSEADDR, optval: &value, optlen: socklen_t(sizeof(Int32))) == -1) {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.SocketSettingReUseAddrFailed(details)
        }
      
        Socket.setNoSigPipe(socketFileDescriptor)
      
        var bindResult: Int32 = -1
        if forceIPv4 {
            var addr = sockaddr_in(sin_len: UInt8(strideof(sockaddr_in)),
                sin_family: UInt8(AF_INET),
                sin_port: Socket.htonsPort(port),
                sin_addr: in_addr(s_addr: UInt32(0x00000000)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
         
            bindResult = withUnsafePointer(&addr) { RedSocketManager.sharedInstance().bind(socketFileDescriptor, name: UnsafePointer<sockaddr>($0), namelen: socklen_t(sizeof(sockaddr_in))) }
          
        } else {
            var addr = sockaddr_in6(sin6_len: UInt8(strideof(sockaddr_in6)),
                sin6_family: UInt8(AF_INET6),
                sin6_port: Socket.htonsPort(port),
                sin6_flowinfo: 0,
                sin6_addr: in6addr_any,
                sin6_scope_id: 0)
            
            bindResult = withUnsafePointer(&addr) { RedSocketManager.sharedInstance().bind(socketFileDescriptor, name: UnsafePointer<sockaddr>($0), namelen: socklen_t(sizeof(sockaddr_in6))) }
        }

        if bindResult == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.BindFailed(details)
        }
      
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
        let clientSocket = RedSocketManager.sharedInstance().accept(self.socketFileDescriptor, addr: &addr, addrlen: &len)
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
                let s = RedSocketManager.sharedInstance().send(self.socketFileDescriptor, dataptr: $0.baseAddress + sent, size: Int(data.count - sent), flags: 0)
                if s <= 0 {
                    throw SocketError.WriteFailed(Socket.descriptionOfLastError())
                }
                sent += Int(s)
            }
        }
    }
    
    public func read() throws -> UInt8 {
        var buffer = [UInt8](count: 1, repeatedValue: 0)
      
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
        var no_sig_pipe: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)))
    }
    
    private class func shutdwn(socket: Int32) {
        RedSocketManager.sharedInstance().shutdown(socket, how: SHUT_RDWR)
    }
    
    private class func release(socket: Int32) {
        RedSocketManager.sharedInstance().shutdown(socket, how: SHUT_RDWR)
        RedSocketManager.sharedInstance().close(socket)
    }
    
    private class func htonsPort(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
}

public func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}
