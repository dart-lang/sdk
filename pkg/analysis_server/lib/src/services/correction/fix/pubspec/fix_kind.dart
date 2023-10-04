// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// An enumeration of quick fix kinds found in a pubspec file.
class PubspecFixKind {
  static const addName = FixKind(
    'pubspec.fix.add.name',
    PubspecFixKindPriority.DEFAULT,
    "Add 'name' key",
  );
  static const addDependency = FixKind(
    'pubspec.fix.add.dependency',
    PubspecFixKindPriority.DEFAULT,
    'Update pubspec with the missing dependencies',
  );

  /// Prevent the creation of instances of this class.
  PubspecFixKind._();
}

class PubspecFixKindPriority {
  static const int DEFAULT = 50;
}
