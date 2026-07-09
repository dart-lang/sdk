// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test() {
  List<dynamic> l = [1, "hello"];
  List<String> l2 = l.map((dynamic element) => element.toString()).toList();
}

void main() {}
