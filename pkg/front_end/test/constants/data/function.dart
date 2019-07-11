// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T method1<T>(T t) => t;
Map<T, S> method2<T, S>(T t, S s) => {t: s};

const function0 = /*cfe.Function(method1)*/ method1;

const int Function(int) instantiation0 =
    /*cfe.Instantiation(method1<int>)*/ method1;

const Map<String, int> Function(String, int) instantiation1 =
    /*cfe.Instantiation(method2<String,int>)*/ method2;

main() {
  print(/*Function(method1)*/ function0);
  print(/*Instantiation(method1<int>)*/ instantiation0);
  print(/*Instantiation(method2<String,int>)*/ instantiation1);
}
