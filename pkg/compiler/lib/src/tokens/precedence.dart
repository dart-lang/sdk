// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.tokens.precedence;

import '../util/util.dart' show
    computeHashCode;

class PrecedenceInfo {
  final String value;
  final int precedence;
  final int kind;

  const PrecedenceInfo(this.value, this.precedence, this.kind);

  toString() => 'PrecedenceInfo($value, $precedence, $kind)';

  int get hashCode => computeHashCode(value, precedence, kind);
}
