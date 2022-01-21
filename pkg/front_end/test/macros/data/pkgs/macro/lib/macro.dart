// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class Macro1 implements Macro {
  const Macro1();

  const Macro1.named();
}

macro class Macro2 implements Macro {
  const Macro2();

  const Macro2.named();
}

macro class Macro3<T> implements Macro {
  const Macro3();

  const Macro3.named();
}

class NonMacro {
  const NonMacro();
}
