// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_ISOLATE_DATA_H_
#define BIN_ISOLATE_DATA_H_

#include "platform/globals.h"

// Forward declaration.
class EventHandler;

// Data associated with every isolate in the standalone VM
// embedding. This is used to free external resources for each isolate
// when the isolate shuts down.
class IsolateData {
 public:
  IsolateData() : event_handler(NULL) {}

  EventHandler* event_handler;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

#endif  // BIN_ISOLATE_DATA_H_
