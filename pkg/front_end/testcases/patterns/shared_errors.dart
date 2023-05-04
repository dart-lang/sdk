// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int get field => 42;
  bool operator >=(Class cls) => true;
  Class operator >(int i) => new Class();
}

argumentTypeNotAssignable(Class cls) {
  switch (cls) {
    case >= 0: // Error
      print(0);
  }
}

relationalPatternOperatorReturnTypeNotAssignableToBool(Class cls) {
  switch (cls) {
    case > 0: // Error
      print(0);
  }
}

patternTypeMismatchInIrrefutableContext(List<String> list) {
  var <int>[a] = list; // Error
}

duplicateAssignmentPatternVariable(List<String> list) {
  String a = '';
  [a, a] = list; // Error
}

duplicateRecordPatternField(o) {
  switch (o) {
    case (field: 1, field: 2): // Error
    case Class(field: 1, field: 2): // Error
      print(0);
  }
}

duplicateRestPattern(o) {
  switch (o) {
    case [..., ...]: // Error
    case {..., ...}: // Error
  }
}

emptyMapPattern(o) {
  switch (o) {
    case {}: // Error
  }
}

singleRestPatternInMap(o) {
  switch (o) {
    case {...}: // Error
  }
}

matchedTypeIsStrictlyNonNullable(List<int> list) {
  if (list case [var a!, var b?]) { // Warnings
    print(0);
  }
}

nonBooleanCondition(int i) {
  if (i case 0 when i) { // Error
    print(0);
  }
}

refutablePatternInIrrefutableContext(int? x) {
  var (a?) = x; // Error
}

restPatternNotLastInMap(o) {
  if (o case {..., 5: 3}) { // Error
    print(0);
  }
}

restPatternWithSubPatternInMap(o) {
  if (o case {5: 3, ...var a}) { // Error
    print(0);
  }
}
