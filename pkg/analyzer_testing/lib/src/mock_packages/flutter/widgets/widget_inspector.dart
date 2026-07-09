// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsWidgetInspectorLibrary = MockLibraryUnit(
  'lib/src/widgets/widget_inspector.dart',
  r'''
@Target(<TargetKind>{TargetKind.method})
class _WidgetFactory {}

const _WidgetFactory widgetFactory = _WidgetFactory();
''',
);
