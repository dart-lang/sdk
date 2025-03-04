// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

external int get topLevelGetter;

external void set topLevelSetter(int value);

external void topLevelMethod(int value);

class Class {
  external Class(int value);

  external Class.redirecting(int value);

  external factory Class.factory(int value);

  external factory Class.redirectingFactory(int value);

  external int get instanceGetter;

  external void set instanceSetter(int value);

  external void instanceMethod(int value);

  external Class operator +(Class a);

  external static int get staticGetter;

  external static void set staticSetter(int value);

  external static void staticMethod(int value);
}

extension Extension on Class {
  external int get extensionInstanceGetter;

  external void set extensionInstanceSetter(int value);

  external void extensionInstanceMethod(int value);

  external Class operator -(Class a);

  external static int get extensionStaticGetter;

  external static void set extensionStaticSetter(int value);

  external static void extensionStaticMethod(int value);
}
