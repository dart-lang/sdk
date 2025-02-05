// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_IO_SERVICE_H_
#define RUNTIME_BIN_IO_SERVICE_H_

#if defined(DART_IO_SECURE_SOCKET_DISABLED)
#error "io_service.h can only be included on builds with IO and SSL enabled"
#endif

#include "bin/builtin.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

// This list must be kept in sync with the list in sdk/lib/io/io_service.dart
#define IO_SERVICE_REQUEST_LIST(V)                                             \
  V(File, Exists, 0)                                                           \
  V(File, Create, 1)                                                           \
  V(File, Delete, 2)                                                           \
  V(File, Rename, 3)                                                           \
  V(File, Copy, 4)                                                             \
  V(File, Open, 5)                                                             \
  V(File, ResolveSymbolicLinks, 6)                                             \
  V(File, Close, 7)                                                            \
  V(File, Position, 8)                                                         \
  V(File, SetPosition, 9)                                                      \
  V(File, Truncate, 10)                                                        \
  V(File, Length, 11)                                                          \
  V(File, LengthFromPath, 12)                                                  \
  V(File, LastAccessed, 13)                                                    \
  V(File, SetLastAccessed, 14)                                                 \
  V(File, LastModified, 15)                                                    \
  V(File, SetLastModified, 16)                                                 \
  V(File, Flush, 17)                                                           \
  V(File, ReadByte, 18)                                                        \
  V(File, WriteByte, 19)                                                       \
  V(File, Read, 20)                                                            \
  V(File, ReadInto, 21)                                                        \
  V(File, WriteFrom, 22)                                                       \
  V(File, CreateLink, 23)                                                      \
  V(File, DeleteLink, 24)                                                      \
  V(File, RenameLink, 25)                                                      \
  V(File, LinkTarget, 26)                                                      \
  V(File, Type, 27)                                                            \
  V(File, Identical, 28)                                                       \
  V(File, Stat, 29)                                                            \
  V(File, Lock, 30)                                                            \
  V(File, CreatePipe, 31)                                                      \
  V(Socket, Lookup, 32)                                                        \
  V(Socket, ListInterfaces, 33)                                                \
  V(Socket, ReverseLookup, 34)                                                 \
  V(Directory, Create, 35)                                                     \
  V(Directory, Delete, 36)                                                     \
  V(Directory, Exists, 37)                                                     \
  V(Directory, CreateTemp, 38)                                                 \
  V(Directory, ListStart, 39)                                                  \
  V(Directory, ListNext, 40)                                                   \
  V(Directory, ListStop, 41)                                                   \
  V(Directory, Rename, 42)                                                     \
  V(SSLFilter, ProcessFilter, 43)

#define DECLARE_REQUEST(type, method, id) k##type##method##Request = id,

class IOService {
 public:
  enum { IO_SERVICE_REQUEST_LIST(DECLARE_REQUEST) };

  static Dart_Port GetServicePort();

  static intptr_t max_concurrency() { return max_concurrency_; }
  static void set_max_concurrency(intptr_t value) { max_concurrency_ = value; }

 private:
  static intptr_t max_concurrency_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(IOService);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_IO_SERVICE_H_
