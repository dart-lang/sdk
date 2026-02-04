// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsValueListenableBuilderLibrary = MockLibraryUnit(
  'lib/src/widgets/value_listenable_builder.dart',
  r'''
import 'package:flutter/foundation.dart';

import 'framework.dart';

typedef ValueWidgetBuilder<T> =
    Widget Function(BuildContext context, T value, Widget? child);

class ValueListenableBuilder<T> extends StatefulWidget {
  const ValueListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.builder,
    this.child,
  });

  final ValueListenable<T> valueListenable;

  final Widget Function(BuildContext, T, Widget?) builder;

  final Widget? child;
}
''',
);
