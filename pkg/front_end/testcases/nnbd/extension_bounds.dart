// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension1<T extends Object> on T {
  method1<S extends Object>() {}
  method2<S extends String>() {}
  method3<S extends dynamic>() {}
  method4<S>() {}
  method5<S extends Object?>() {}
}

extension Extension2<T extends String> on T {
  method1<S extends Object>() {}
  method2<S extends String>() {}
  method3<S extends dynamic>() {}
  method4<S>() {}
  method5<S extends Object?>() {}
}

extension Extension3<T extends dynamic> on T {
  method1<S extends Object>() {}
  method2<S extends String>() {}
  method3<S extends dynamic>() {}
  method4<S>() {}
  method5<S extends Object?>() {}
}

extension Extension4<T> on T {
  method1<S extends Object>() {}
  method2<S extends String>() {}
  method3<S extends dynamic>() {}
  method4<S>() {}
  method5<S extends Object?>() {}
}

extension Extension5<T extends Object?> on T {
  method1<S extends Object>() {}
  method2<S extends String>() {}
  method3<S extends dynamic>() {}
  method4<S>() {}
  method5<S extends Object?>() {}
}

main() {}
