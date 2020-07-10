// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for ddc failure triggered by
// https://dart-review.googlesource.com/c/sdk/+/124683

class Class {
  String toString() {
    void local() {}

    return '${runtimeType.toString()}';
  }
}

main() {
  new Class().toString();
}
