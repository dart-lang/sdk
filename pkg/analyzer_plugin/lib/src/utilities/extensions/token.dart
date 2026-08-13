// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';

extension TokenExtensions on Token {
  /// Return the first non-synthetic token after `this` token.
  Token get nextNotSynthetic {
    var current = next!;
    while (current.isSynthetic) {
      current = current.next!;
    }
    return current;
  }
}
