// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic duplicateNamedFields = (a: 0, a: 1);
dynamic duplicateNamedFields2 = (a: 0, a: 1, a: 2, b: 3, b: 4);
dynamic missingNamedElement = (0, a:);
dynamic keywordElement = (0, in);
dynamic keywordProperty = (0, 1.in);


void method() {
  dynamic duplicateNamedFields = (a: 0, a: 1);
  dynamic duplicateNamedFields2 = (a: 0, a: 1, a: 2, b: 3, b: 4);
  dynamic missingNamedElement = (0, a:);
  dynamic keywordElement = (0, in);
  dynamic keywordProperty = (0, 1.in);
}

class Class {
  void method() {
    (0, super);
    (0, 1.in);
  }
}