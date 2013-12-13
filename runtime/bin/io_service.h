// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_IO_SERVICE_H_
#define BIN_IO_SERVICE_H_

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
  V(Socket, Lookup, 27)                                                        \
  V(Socket, ListInterfaces, 28)                                                \
  V(Socket, ReverseLookup, 29)                                                 \
  V(Directory, Create, 30)                                                     \
  V(Directory, Delete, 31)                                                     \
  V(Directory, Exists, 32)                                                     \
  V(Directory, CreateTemp, 33)                                                 \
  V(Directory, ListStart, 34)                                                  \
  V(Directory, ListNext, 35)                                                   \
  V(Directory, ListStop, 36)                                                   \
  V(Directory, Rename, 37)                                                     \
  V(SSLFilter, ProcessFilter, 38)

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

#endif  // BIN_IO_SERVICE_H_
