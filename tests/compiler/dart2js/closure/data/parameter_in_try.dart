// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

readInFinally(/*inTry*/ parameter) {
  try {
    if (parameter) {
      throw '';
    }
  } finally {}
}

writeInFinally(/*inTry*/ parameter) {
  try {
    parameter = 42;
    throw '';
  } finally {}
}

main() {
  readInFinally(null);
  writeInFinally(null);
}
