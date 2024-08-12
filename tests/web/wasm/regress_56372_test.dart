// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  final funs = <String Function({Object? shared})>[
    foo,
    bar,
  ];

  final one = int.parse('1');
  final barS = funs[one] as String Function({Object? barSpecific});
  if (barS(barSpecific: 1) != 'bar(null, 1)') {
    throw 'failed: ${barS(barSpecific: 1)}';
  }
}

String foo<T>({Object? shared, Object? fooSpecific}) =>
    'foo<$T>($shared, $fooSpecific)';

String bar({Object? shared, Object? barSpecific}) =>
    'bar($shared, $barSpecific)';
