// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  /*1:main*/ test();
}

void test /*ddk.2:test*/ () /*ddc.2:test*/ async {
  /*3:test*/ throw '>ExceptionMarker<';
}
