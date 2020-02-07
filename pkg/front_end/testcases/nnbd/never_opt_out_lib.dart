// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'never_opt_out.dart';

Never throwing() => throw 'Never!';

Never optInNever = optOutNever;

class A {
  Never neverField = throw "Should not reach here";
  Never neverMethod(Never value) => value;
  Never get neverProperty => throw "Should not reach here";
  void set neverProperty(Never value) {}

  Null nullField = null;
  Null nullMethod(Null value) => value;
  Null get nullProperty => Null;
  void set nullProperty(Null value) {}
}
