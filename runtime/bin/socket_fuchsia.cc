// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/socket.h"
#include "bin/socket_fuchsia.h"

#include "bin/file.h"

namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct sockaddr* sa) {
  UNIMPLEMENTED();
}


bool Socket::FormatNumericAddress(const RawAddr& addr, char* address, int len) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::Initialize() {
  UNIMPLEMENTED();
  return true;
}


intptr_t Socket::CreateConnect(const RawAddr& addr) {
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::CreateBindConnect(const RawAddr& addr,
                                   const RawAddr& source_addr) {
  UNIMPLEMENTED();
  return -1;
}


bool Socket::IsBindError(intptr_t error_number) {
  UNIMPLEMENTED();
  return false;
}


intptr_t Socket::Available(intptr_t fd) {
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::Read(intptr_t fd, void* buffer, intptr_t num_bytes) {
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::RecvFrom(
    intptr_t fd, void* buffer, intptr_t num_bytes, RawAddr* addr) {
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::SendTo(
    intptr_t fd, const void* buffer, intptr_t num_bytes, const RawAddr& addr) {
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::GetPort(intptr_t fd) {
  UNIMPLEMENTED();
  return -1;
}


SocketAddress* Socket::GetRemotePeer(intptr_t fd, intptr_t* port) {
  UNIMPLEMENTED();
  return NULL;
}


void Socket::GetError(intptr_t fd, OSError* os_error) {
  UNIMPLEMENTED();
}


int Socket::GetType(intptr_t fd) {
  UNIMPLEMENTED();
  return File::kOther;
}


intptr_t Socket::GetStdioHandle(intptr_t num) {
  UNIMPLEMENTED();
  return num;
}


AddressList<SocketAddress>* Socket::LookupAddress(const char* host,
                                                  int type,
                                                  OSError** os_error) {
  // UNIMPLEMENTED
  ASSERT(*os_error == NULL);
  *os_error = new OSError(-1,
                          "Socket::LookupAddress not implemented in "
                          "Fuchsia Dart VM runtime",
                          OSError::kGetAddressInfo);
  return NULL;
}


bool Socket::ReverseLookup(const RawAddr& addr,
                           char* host,
                           intptr_t host_len,
                           OSError** os_error) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::ParseAddress(int type, const char* address, RawAddr* addr) {
  UNIMPLEMENTED();
  return false;
}


intptr_t Socket::CreateBindDatagram(const RawAddr& addr, bool reuseAddress) {
  UNIMPLEMENTED();
  return -1;
}


bool Socket::ListInterfacesSupported() {
  return false;
}


AddressList<InterfaceSocketAddress>* Socket::ListInterfaces(
    int type,
    OSError** os_error) {
  UNIMPLEMENTED();
  return NULL;
}


intptr_t ServerSocket::CreateBindListen(const RawAddr& addr,
                                        intptr_t backlog,
                                        bool v6_only) {
  UNIMPLEMENTED();
  return -1;
}


bool ServerSocket::StartAccept(intptr_t fd) {
  UNIMPLEMENTED();
  return false;
}


intptr_t ServerSocket::Accept(intptr_t fd) {
  UNIMPLEMENTED();
  return -1;
}


void Socket::Close(intptr_t fd) {
  UNIMPLEMENTED();
}


bool Socket::GetNoDelay(intptr_t fd, bool* enabled) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetNoDelay(intptr_t fd, bool enabled) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::GetMulticastLoop(intptr_t fd, intptr_t protocol, bool* enabled) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetMulticastLoop(intptr_t fd, intptr_t protocol, bool enabled) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::GetBroadcast(intptr_t fd, bool* enabled) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetBroadcast(intptr_t fd, bool enabled) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::JoinMulticast(
    intptr_t fd, const RawAddr& addr, const RawAddr&, int interfaceIndex) {
  UNIMPLEMENTED();
  return false;
}


bool Socket::LeaveMulticast(
    intptr_t fd, const RawAddr& addr, const RawAddr&, int interfaceIndex) {
  UNIMPLEMENTED();
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
