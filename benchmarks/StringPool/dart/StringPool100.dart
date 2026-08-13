// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See `StringPool.dart` for comments.

import 'StringPool.dart' show StringPoolBase, sink;
import 'version1a.dart';
import 'version1b.dart';
import 'version2.dart';

class V1 extends StringPoolBase {
  V1() : super('100.pooled');

  @override
  late final functions = version1ax100();
}

class V1Copy extends StringPoolBase {
  V1Copy() : super('100.pooled.copy');

  @override
  late final functions = version1bx100();
}

class V2 extends StringPoolBase {
  V2() : super('100.unpooled');

  @override
  late final functions = version2x100();
}

void main() {
  // Compare results of V1 and V1Copy to ensure both are in the program.
  V1()
    ..setup()
    ..run()
    ..run();
  final sink1a = sink;
  V1Copy()
    ..setup()
    ..run()
    ..run();
  final sink1b = sink;
  if (sink1a.length != sink1b.length) throw StateError('Not same length');

  V2()
    ..setup()
    ..run()
    ..run();
  final sink2 = sink;
  if (sink1a.length != sink2.length) throw StateError('Not same length');

  V1().report();
  V2().report();
}
