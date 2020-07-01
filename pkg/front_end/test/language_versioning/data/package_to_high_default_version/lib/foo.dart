/*error: errors=LanguageVersionTooHigh*/
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: languageVersion=2.8*/

import 'foo2.dart';
import 'foo3.dart';

foo() {
  print("Hello from foo!");
  foo2();
  foo3();
}
