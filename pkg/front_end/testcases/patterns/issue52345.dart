// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  final works = ['b', 'l'];
  final fails = ['c'];

  for (final test in [works, fails]) {
    final _ = switch (test) {
      [final b, final d, ...final x] => print('$b $d $x'),
      [final f, ...final args] => print('$f $args'),
      _ => throw UnimplementedError(),
    };
  }
}
