// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;

method<S>(S s) {
  /*strong.fields=[S],free=[S]*/
  /*omit.*/
  S Function(S) getId() => id;
  return getId();
}

main() {
  method(0);
}
