// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../source/source_library_builder.dart';

abstract class DelayedActionPerformer {
  bool get hasDelayedActions;
  void performDelayedActions({required bool allowFurtherDelays});
}

bool checkRecordOrItsAliasAccessAllowed(
    DartType type, SourceLibraryBuilder accessorLibrary) {
  Class? targetClass;
  if (type is InterfaceType) {
    targetClass = type.classNode;
  } else if (type is TypedefType) {
    DartType unaliasedType = type.unalias;
    if (unaliasedType is InterfaceType) {
      targetClass = unaliasedType.classNode;
    }
  }
  return accessorLibrary.libraryFeatures.records.isEnabled ||
      accessorLibrary.libraryFeatures.records.flag.isEnabledByDefault ||
      !(targetClass != null &&
          targetClass.name == "Record" &&
          targetClass.enclosingLibrary.importUri.scheme == "dart" &&
          targetClass.enclosingLibrary.importUri.path == "core");
}
