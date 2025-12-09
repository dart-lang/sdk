// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsTickerProviderLibrary = MockLibraryUnit(
  'lib/src/widgets/ticker_provider.dart',
  r'''
import 'package:flutter/src/widgets/framework.dart';

@optionalTypeArgs
mixin SingleTickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {}
''',
);
