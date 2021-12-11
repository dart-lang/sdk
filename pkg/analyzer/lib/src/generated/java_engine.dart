// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/interner.dart';

export 'package:analyzer/exception/exception.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef Predicate<E> = bool Function(E argument);

class StringUtilities {
  static Interner INTERNER = NullInterner();

  static String intern(String string) => INTERNER.intern(string);
}
