// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_TEST_UTILS_H_
#define RUNTIME_BIN_TEST_UTILS_H_

namespace dart {
namespace bin {
namespace test {

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
const char* GetFileName(const char* name);

}  // namespace test
}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_TEST_UTILS_H_
