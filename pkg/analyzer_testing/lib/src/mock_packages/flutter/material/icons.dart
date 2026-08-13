// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final materialIconsLibrary = MockLibraryUnit('lib/src/material/icons.dart', r'''
import 'package:flutter/widgets.dart';

abstract final class Icons {
  static const IconData alarm = IconData(
    0xe072,
    fontFamily: 'MaterialIcons',
  );

  static const IconData book = IconData(0xe0ef, fontFamily: 'MaterialIcons');
}
''');
