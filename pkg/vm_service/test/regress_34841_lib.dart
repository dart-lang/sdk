// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Foo {
  String baz() => StackTrace.current.toString();
  final String foo = () {
    return StackTrace.current.toString();
  }();
}
