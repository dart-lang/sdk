// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingAlignmentLibrary = MockLibraryUnit(
  'lib/src/painting/alignment.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'basic_types.dart';

class Alignment extends AlignmentGeometry {
  static const Alignment topLeft = Alignment(-1.0, -1.0);

  static const Alignment topCenter = Alignment(0.0, -1.0);

  static const Alignment topRight = Alignment(1.0, -1.0);

  static const Alignment centerLeft = Alignment(-1.0, 0.0);

  static const Alignment center = Alignment(0.0, 0.0);

  static const Alignment centerRight = Alignment(1.0, 0.0);

  static const Alignment bottomLeft = Alignment(-1.0, 1.0);

  static const Alignment bottomCenter = Alignment(0.0, 1.0);

  static const Alignment bottomRight = Alignment(1.0, 1.0);

  final double x;

  final double y;

  const Alignment(this.x, this.y);
}

class AlignmentDirectional extends AlignmentGeometry {
  static const AlignmentDirectional topStart = AlignmentDirectional(-1.0, -1.0);

  static const AlignmentDirectional topCenter = AlignmentDirectional(0.0, -1.0);

  static const AlignmentDirectional topEnd = AlignmentDirectional(1.0, -1.0);

  static const AlignmentDirectional centerStart = AlignmentDirectional(
    -1.0,
    0.0,
  );

  static const AlignmentDirectional center = AlignmentDirectional(0.0, 0.0);

  static const AlignmentDirectional centerEnd = AlignmentDirectional(1.0, 0.0);

  static const AlignmentDirectional bottomStart = AlignmentDirectional(
    -1.0,
    1.0,
  );

  static const AlignmentDirectional bottomCenter = AlignmentDirectional(
    0.0,
    1.0,
  );

  static const AlignmentDirectional bottomEnd = AlignmentDirectional(1.0, 1.0);

  final double start;

  final double y;

  const AlignmentDirectional(this.start, this.y);
}

@immutable
abstract class AlignmentGeometry {
  const AlignmentGeometry();
}

class TextAlignVertical {
  static const TextAlignVertical top = TextAlignVertical(y: -1.0);

  static const TextAlignVertical center = TextAlignVertical(y: 0.0);

  static const TextAlignVertical bottom = TextAlignVertical(y: 1.0);

  final double y;

  const TextAlignVertical({required this.y}) : assert(y >= -1.0 && y <= 1.0);
}
''',
);
