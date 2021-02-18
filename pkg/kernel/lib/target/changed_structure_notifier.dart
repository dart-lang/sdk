// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show Class;

/// Meant for notifying the backend (the compiler) that the structure has
/// changed, in turn allowing it to update its internal model.
abstract class ChangedStructureNotifier {
  /// Mark the members of class [cls] have changed.
  void registerClassMemberChange(Class cls);

  /// Mark that the class hierarchy for class [cls] has changed.
  void registerClassHierarchyChange(Class cls);
}
