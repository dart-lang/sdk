// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test() {
  var {"one": num? v1, 2: v2} = {"one": 1, 2: 2};
  String s = v2; // Error
}
