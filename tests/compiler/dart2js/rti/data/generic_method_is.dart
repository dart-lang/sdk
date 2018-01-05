// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: method:needsArgs,explicit=[method.T]*/
method<T>(T t) => t is T;

/*element: main:*/
main() {
  method<int>(0);
}
