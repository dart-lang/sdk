// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue46719.dart' as self;

class A<T> {
  A();
  A.named();

  List<X> m<X>(X x) => [x];

  static List<X> n<X>(X x) => [x];
}

List<X> m<X>(X x) => [x];

extension FunctionApplier on Function {
  void applyAndPrint(List<Object?> positionalArguments) =>
      print(Function.apply(this, positionalArguments, const {}));
}

test() {
  A.named<int>.toString(); // error
}

void main() {
  var a = A();
  a.m<int>.applyAndPrint([2]);
  a.m<String>.applyAndPrint(['three']);
  A.n<int>.applyAndPrint([2]);
  A.n<String>.applyAndPrint(['three']);
  self.m<int>.applyAndPrint([2]);
  self.m<String>.applyAndPrint(['three']);
  self.A.n<int>.applyAndPrint([2]);
  self.A.n<String>.applyAndPrint(['three']);
  A.named.toString();
  A<int>.named.toString();
}
