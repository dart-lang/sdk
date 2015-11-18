// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_IO_SERVICE_NO_SSL_H_
#define BIN_IO_SERVICE_NO_SSL_H_

#include "bin/builtin.h"
#include "bin/utils.h"


namespace dart {
namespace bin {

// This list must be kept in sync with the list in sdk/lib/io/io_service.dart
// In this modified version, though, the request 39 for SSLFilter::ProcessFilter
// is removed, for use in contexts in which secure sockets are not enabled.
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
  V(File, LastModified, 13)                                                    \
  V(File, Flush, 14)                                                           \
  V(File, ReadByte, 15)                                                        \
  V(File, WriteByte, 16)                                                       \
  V(File, Read, 17)                                                            \
  V(File, ReadInto, 18)                                                        \
  V(File, WriteFrom, 19)                                                       \
  V(File, CreateLink, 20)                                                      \
  V(File, DeleteLink, 21)                                                      \
  V(File, RenameLink, 22)                                                      \
  V(File, LinkTarget, 23)                                                      \
  V(File, Type, 24)                                                            \
  V(File, Identical, 25)                                                       \
  V(File, Stat, 26)                                                            \
  V(File, Lock, 27)                                                            \
  V(Socket, Lookup, 28)                                                        \
  V(Socket, ListInterfaces, 29)                                                \
  V(Socket, ReverseLookup, 30)                                                 \
  V(Directory, Create, 31)                                                     \
  V(Directory, Delete, 32)                                                     \
  V(Directory, Exists, 33)                                                     \
  V(Directory, CreateTemp, 34)                                                 \
  V(Directory, ListStart, 35)                                                  \
  V(Directory, ListNext, 36)                                                   \
  V(Directory, ListStop, 37)                                                   \
  V(Directory, Rename, 38)

#define DECLARE_REQUEST(type, method, id)                                      \
  k##type##method##Request = id,

class IOService {
 public:
  enum {
IO_SERVICE_REQUEST_LIST(DECLARE_REQUEST)
  };

  static Dart_Port GetServicePort();
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_IO_SERVICE_NO_SSL_H_
