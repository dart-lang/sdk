// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;

class Class {
  S Function<S>(S) get idFunction => id;
  dynamic get dynFunction => id;
}

main() {
  Class c = new Class();
  c.idFunction(0);
  c.idFunction<int>(0);
  c.dynFunction(0);
}
