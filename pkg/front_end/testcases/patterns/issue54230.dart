// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test() {
  if ({0} case const {0: 0})
    print("Success");
  else
    print("Failure");
}
