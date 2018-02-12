// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:checks=[]*/
class A<T> {}

/*class: B:checks=[]*/
class B<T> {}

main() {
  print("A<B<int>>" == new A<B<int>>().runtimeType.toString());
}
