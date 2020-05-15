// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  /**/ local1() {}
  /*fields=[local1],free=[local1]*/ local2() => local1();
  return local2;
}
