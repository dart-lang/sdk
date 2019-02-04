// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic _defaultCallback<T>(T t) => t;

void bar<T>([dynamic Function(T) f = _defaultCallback]) {}  //# 01: compile-time error

class C<T> {
  // Should be statically rejected
  foo([dynamic Function(T) f = _defaultCallback]) {}  //# 02: compile-time error

  // Should be statically rejected
  const C({this.callback = _defaultCallback});  //# 03: compile-time error

  final dynamic Function(T) callback;  //# 03: continued
}

void main() {
  bar<int>();                    //# 01: continued
  print(new C<int>().foo());     //# 02: continued
  print(new C<int>().callback);  //# 03: continued
}
