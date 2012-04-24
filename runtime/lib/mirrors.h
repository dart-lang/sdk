// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef LIB_MIRRORS_H_
#define LIB_MIRRORS_H_

namespace dart {

class Instance;

void HandleMirrorsMessage(Isolate* isolate,
                          Dart_Port reply_port,
                          const Instance& message);

}  // namespace dart

#endif  // LIB_MIRRORS_H_
