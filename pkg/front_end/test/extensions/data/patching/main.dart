// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[origin.dart.Extension,origin.dart.GenericExtension]*/

// ignore: uri_does_not_exist
import 'dart:test';

main() {
  "".instanceMethod();
  "".genericInstanceMethod<int>(0);
  "".instanceProperty = "".instanceProperty;
  Extension.staticMethod();
  Extension.genericStaticMethod<int>(0);
  Extension.staticProperty = Extension.staticProperty;
  true.instanceMethod();
  true.genericInstanceMethod<int>(0);
  true.instanceProperty = true.instanceProperty;
  GenericExtension.staticMethod();
  GenericExtension.genericStaticMethod<int>(0);
  GenericExtension.staticProperty = GenericExtension.staticProperty;
}
