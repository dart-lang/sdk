// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_LIB_STACKTRACE_H_
#define RUNTIME_LIB_STACKTRACE_H_

namespace dart {

class Stacktrace;

// Creates a Stacktrace object from the current stack.  Skips the
// first skip_frames Dart frames.
//
// This function is exposed to provide stack trace printing in
// assertion failures, etc.
const Stacktrace& GetCurrentStacktrace(int skip_frames);

}  // namespace dart

#endif  // RUNTIME_LIB_STACKTRACE_H_
