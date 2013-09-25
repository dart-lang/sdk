// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_IO_SERVICE_H_
#define BIN_IO_SERVICE_H_

#include "bin/builtin.h"
#include "bin/utils.h"


namespace dart {
namespace bin {

#define IO_SERVICE_REQUEST_LIST(V)                                             \
  V(File, Exists, 0)                                                           \
  V(File, Create, 1)                                                           \
  V(File, Delete, 2)                                                           \
  V(File, Rename, 3)                                                           \
  V(File, Open, 4)                                                             \
  V(File, ResolveSymbolicLinks, 5)                                             \
  V(File, Close, 6)                                                            \
  V(File, Position, 7)                                                         \
  V(File, SetPosition, 8)                                                      \
  V(File, Truncate, 9)                                                         \
  V(File, Length, 10)                                                          \
  V(File, LengthFromPath, 11)                                                  \
  V(File, LastModified, 12)                                                    \
  V(File, Flush, 13)                                                           \
  V(File, ReadByte, 14)                                                        \
  V(File, WriteByte, 15)                                                       \
  V(File, Read, 16)                                                            \
  V(File, ReadInto, 17)                                                        \
  V(File, WriteFrom, 18)                                                       \
  V(File, CreateLink, 19)                                                      \
  V(File, DeleteLink, 20)                                                      \
  V(File, RenameLink, 21)                                                      \
  V(File, LinkTarget, 22)                                                      \
  V(File, Type, 23)                                                            \
  V(File, Identical, 24)                                                       \
  V(File, Stat, 25)                                                            \
  V(Socket, Lookup, 26)                                                        \
  V(Socket, ListInterfaces, 27)                                                \
  V(Socket, ReverseLookup, 28)                                                 \
  V(Directory, Create, 29)                                                     \
  V(Directory, Delete, 30)                                                     \
  V(Directory, Exists, 31)                                                     \
  V(Directory, CreateTemp, 32)                                                 \
  V(Directory, ListStart, 33)                                                  \
  V(Directory, ListNext, 34)                                                   \
  V(Directory, ListStop, 35)                                                   \
  V(Directory, Rename, 36)                                                     \
  V(SSLFilter, ProcessFilter, 37)

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

