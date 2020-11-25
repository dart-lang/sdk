// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  final int length;

  const Class({this.length});

  method1a() {
    const Class(length: this.length);
  }

  method1b() {
    const Class(length: length);
  }

  method2a() {
    const a = this.length;
  }

  method2b() {
    const a = length;
  }
}

main() {}
