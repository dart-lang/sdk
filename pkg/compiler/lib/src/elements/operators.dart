// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.operators;

/// The names of all operators that can be used to define instance methods.
const Set<String> instanceMethodOperatorNames = {
  '[]=',
  ..._unaryOperatorNames,
  ..._binaryOperatorNames,
};

const Set<String> _unaryOperatorNames = {
  '~',
  'unary-',
};

const Set<String> _binaryOperatorNames = {
  '==',
  '[]',
  '*',
  '/',
  '%',
  '~/',
  '+',
  '-',
  '<<',
  '>>',
  '>>>',
  '>=',
  '>',
  '<=',
  '<',
  '&',
  '^',
  '|',
};
