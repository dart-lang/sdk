// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/timer.h"
#include "platform/globals.h"
#include "vm/json_stream.h"
#include "vm/thread.h"

namespace dart {

PrintTimeScope::~PrintTimeScope() {
  timer_.Stop();
  OS::PrintErr("%s %s\n", name_,
               timer_.FormatElapsedHumanReadable(Thread::Current()->zone()));
}

}  // namespace dart
