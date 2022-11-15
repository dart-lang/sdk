// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../../api_prototype/experimental_flags.dart';

abstract class DelayedActionPerformer {
  bool get hasDelayedActions;
  void performDelayedActions({required bool allowFurtherDelays});
}

/// Returns `true` if access to `Record` from `dart:core` is allowed.
bool isRecordAccessAllowed(LibraryFeatures libraryFeatures) {
  return ExperimentalFlag.records.isEnabledByDefault ||
      libraryFeatures.records.isEnabled;
}

/// Returns `true` if [type] is `Record` from  `dart:core`.
bool isDartCoreRecord(DartType type) {
  Class? targetClass;
  if (type is InterfaceType) {
    targetClass = type.classNode;
  }
  return targetClass != null &&
      targetClass.parent != null &&
      targetClass.name == "Record" &&
      targetClass.enclosingLibrary.importUri.scheme == "dart" &&
      targetClass.enclosingLibrary.importUri.path == "core";
}
