// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final materialButtonLibrary = MockLibraryUnit(
  'lib/src/material/button.dart',
  r'''
import 'package:flutter/widgets.dart';

class RawMaterialButton extends StatefulWidget {
  const RawMaterialButton({
    super.key,
    required this.onPressed,
    this.child,
  });

  final VoidCallback? onPressed;

  final Widget? child;
}
''',
);
