// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_LIB_STACKTRACE_H_
#define RUNTIME_LIB_STACKTRACE_H_

#include "vm/tagged_pointer.h"

namespace dart {

class StackTrace;

// Creates a StackTrace object from the current stack.  Skips the
// first skip_frames Dart frames.
//
// This function is exposed to provide stack trace printing in
// assertion failures, etc.
const StackTrace& GetCurrentStackTrace(int skip_frames);

// Creates a StackTrace object to be attached to an exception.
StackTracePtr GetStackTraceForException();

// Returns false if there is no Dart stack available.
bool HasStack();

}  // namespace dart

#endif  // RUNTIME_LIB_STACKTRACE_H_
