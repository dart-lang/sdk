// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/**
 * Helps dealing with reflection in the case that the source code has been
 * changed as a result of compiling with dart2dart.
 */
library _mirror_helper;

import 'dart:mirrors';

/// The compiler will replace this variable with a map containing all the
/// renames made in dart2dart.
const Map<String, String> _SYMBOLS = null;

/// This method is a wrapper for MirrorSystem.getName() and will be inlined and
/// called in the generated output Dart code.
String helperGetName(Symbol sym) {
  var name = MirrorSystem.getName(sym);
  if (_SYMBOLS.containsKey(name)) {
    return _SYMBOLS[name];
  } else {
    return name;
  }
}
