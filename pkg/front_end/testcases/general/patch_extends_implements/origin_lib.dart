// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {}

mixin Mixin {}

class SuperClass {}

abstract class Class1a {}

class Class1b {}

class Class2a extends SuperClass {}

class Class2b {}

class Class3a implements Interface {}

class Class3b {}

class Class4a with Mixin {}

class Class4b {}

class Class5a {
  external factory Class5a();
}

class Class5aImpl implements Class5a {}

class Class5b {
  external factory Class5b();
}

class Class5bImpl {}

class Class5c {
  external factory Class5c();
}

class Class5cImpl {}

class Class6a<T> {
  external factory Class6a(void Function(T) f);
}

class Class6b<T> {
  external factory Class6b(void Function(T) f);
}

class Class6c<T> {
  external factory Class6c(void Function(T) f);
}
