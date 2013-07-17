// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_ISOLATE_DATA_H_
#define BIN_ISOLATE_DATA_H_

#include "include/dart_api.h"
#include "platform/globals.h"


namespace dart {
namespace bin {

// Forward declaration.
class EventHandler;

// Data associated with every isolate in the standalone VM
// embedding. This is used to free external resources for each isolate
// when the isolate shuts down.
class IsolateData {
 public:
  IsolateData()
      : object_array_class(NULL),
        growable_object_array_class(NULL), immutable_array_class(NULL) {
  }

  Dart_PersistentHandle object_array_class;
  Dart_PersistentHandle growable_object_array_class;
  Dart_PersistentHandle immutable_array_class;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_ISOLATE_DATA_H_
