// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=SubPos1|SubPos2|SubNamed|SubOptionalPos|SubOptionalNamed|SubMixin
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0

void main() {
  final bs = <Base<Object>>[
    SubPos1<int>(1, 1, 1, 1),
    SubPos1<int>(2, 2, 2, 2),
    SubPos2<int>(3, 3),
    SubPos2<int>(4, 4),
    SubNamed<int>(onlyUsedInSubField: 5, onlyUsedInSuper: 5),
    SubNamed<int>(onlyUsedInSubField: 6, onlyUsedInSuper: 6),
    SubOptionalPos<int>(),
    SubOptionalPos<int>(7, 7, 7, 7),
    SubOptionalNamed<int>(),
    SubOptionalNamed<int>(onlyUsedInSubField: 8, onlyUsedInSuper: 8),
  ];
  for (final b in bs) {
    print(b.onlyUsedInBaseField);
    print(b.onlyUsedInSubField);
    print(b.baseInitializerField);
    print(b.subInitializerField);
  }
}

mixin SubMixin<T> {}

abstract class Base<T> {
  final baseInitializerField = [];
  final onlyUsedInBaseField;

  Base.sub1(this.onlyUsedInBaseField, int onlyUsedInBaseBody) {
    print('Base<$T>: $baseInitializerField $onlyUsedInBaseBody');
  }
  Base.sub2(this.onlyUsedInBaseField) {
    print('Base<$T>: $baseInitializerField');
  }
  Base.named({required this.onlyUsedInBaseField}) {
    print('Base<$T>.named: $baseInitializerField');
  }

  int get onlyUsedInSubField;
  dynamic get subInitializerField;
}

class SubPos1<T> extends Base<Iterable<T>> with SubMixin<T> {
  final dynamic subInitializerField = [];
  final int onlyUsedInSubField;
  SubPos1(
    this.onlyUsedInSubField,
    int onlyUsedInSubBody,
    int onlyUsedInSuper1,
    int onlyUsedInSuper2,
  ) : super.sub1(onlyUsedInSuper1, onlyUsedInSuper2) {
    print('SubPos1<$T>: $subInitializerField, $onlyUsedInSubBody');
  }
}

class SubPos2<T> extends Base<T> with SubMixin<T> {
  final dynamic subInitializerField = [];
  final int onlyUsedInSubField;
  SubPos2(this.onlyUsedInSubField, int onlyUsedInSuper1)
    : super.sub2(onlyUsedInSuper1) {
    print('SubPos2<$T>: $subInitializerField');
  }
}

class SubOptionalPos<T> extends Base<List<T>> with SubMixin<T> {
  final dynamic subInitializerField = [];
  final int onlyUsedInSubField;
  SubOptionalPos([
    this.onlyUsedInSubField = 10,
    int onlyUsedInSubBody = 11,
    int onlyUsedInSuper1 = 12,
    int onlyUsedInSuper2 = 13,
  ]) : super.sub1(onlyUsedInSuper1, onlyUsedInSuper2) {
    print('SubOptionalPos<$T>: $subInitializerField, $onlyUsedInSubBody');
  }
}

class SubNamed<T> extends Base<T> with SubMixin<T> {
  final dynamic subInitializerField = [];
  final int onlyUsedInSubField;
  SubNamed({required this.onlyUsedInSubField, required int onlyUsedInSuper})
    : super.named(onlyUsedInBaseField: onlyUsedInSuper) {
    print('SubNamed<$T>: $subInitializerField');
  }
}

class SubOptionalNamed<T> extends Base<Comparable<T>> with SubMixin<T> {
  final dynamic subInitializerField = [];
  final int onlyUsedInSubField;
  SubOptionalNamed({this.onlyUsedInSubField = 20, int onlyUsedInSuper = 21})
    : super.named(onlyUsedInBaseField: onlyUsedInSuper) {
    print('SubOptionalNamed<$T>: $subInitializerField');
  }
}
