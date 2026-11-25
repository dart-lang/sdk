// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from tests/language/records/type_inference_test.dart

import 'package:expect/static_type_helper.dart';

void contextRecordUnknown<T>((T,) x) {}
void contextRecordNamedUnknown<T>(({T f1}) x) {}
void contextRecordListOfUnknown<T>((List<T>,) x) {}
void contextRecordNamedListOfUnknown<T>(({List<T> f1}) x) {}
void contextRecordFunctionReturningUnknown<T>((T Function(),) x) {}
void contextRecordNamedFunctionReturningUnknown<T>(({T Function() f1}) x) {}

class C {
  int call() => 0;
}

void main() {
  {
    var d = 0 as dynamic;
    contextRecordUnknown(
      (d,)
        ..expectStaticType<Exactly<(dynamic,)>>()
        // Double check that it's truly `dynamic` (and not `Object?`) using a
        // dynamic invocation.
        ..$1.abs(),
    );
    contextRecordNamedUnknown(
      (f1: d)
        ..expectStaticType<Exactly<({dynamic f1})>>()
        ..f1.abs(),
    );
  }
  {
    var d = [1] as dynamic;
    contextRecordListOfUnknown(
      (d,)..expectStaticType<Exactly<(List<Object?>,)>>(),
    );
    contextRecordNamedListOfUnknown(
      (f1: d)..expectStaticType<Exactly<({List<Object?> f1})>>(),
    );
  }
  {
    contextRecordFunctionReturningUnknown(
      (C(),)..expectStaticType<Exactly<(int Function(),)>>(),
    );
    contextRecordNamedFunctionReturningUnknown(
      (f1: C())..expectStaticType<Exactly<({int Function() f1})>>(),
    );
  }
}
