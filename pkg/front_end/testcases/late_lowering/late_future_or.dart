// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

FutureOr method1() => null;
FutureOr? method2() => null;
FutureOr<dynamic> method3() => null;
FutureOr<int> method4() => 0;
FutureOr<int?> method5() => null;
FutureOr<int?>? method6() => null;

late var field1 = method1();
late var field2 = method2();
late var field3 = method3();
late var field4 = method4();
late var field5 = method5();
late var field6 = method6();

class C<T> {
  late FutureOr field1;
  late FutureOr? field2;
  late FutureOr<T> field3;
  late FutureOr<T?> field4;
  late FutureOr<T?>? field5;

  method() {
    late FutureOr local1;
    late FutureOr? local2;
    late FutureOr<T> local3;
    late FutureOr<T?> local4;
    late FutureOr<T?>? local5;
  }
}

// TODO(johnniwinther): Add test for override inference when the consolidated
// model is implemented.

main() {}
