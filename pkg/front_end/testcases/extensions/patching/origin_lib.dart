// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on String {
  external int instanceMethod();

  external T genericInstanceMethod<T>(T t);

  external static int staticMethod();

  external static T genericStaticMethod<T>(T t);

  external int get instanceProperty;

  external void set instanceProperty(int value);

  external static int get staticProperty;

  external static void set staticProperty(int value);
}

extension GenericExtension<T> on T {
  external int instanceMethod();

  external T genericInstanceMethod<T>(T t);

  external static int staticMethod();

  external static T genericStaticMethod<T>(T t);

  external int get instanceProperty;

  external void set instanceProperty(int value);

  external static int get staticProperty;

  external static void set staticProperty(int value);
}
