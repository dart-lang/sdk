// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';

patch class Debugger {
  /* patch */ static void breakHere() native "Debugger_breakHere";
  /* patch */ static void breakHereIf(bool expr) native "Debugger_breakHereIf";
}
