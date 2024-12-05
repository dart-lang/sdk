// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../api_prototype/experimental_flags.dart';
import '../source/source_library_builder.dart';

/// Returns `true` if access to `Record` from `dart:core` is allowed.
bool isRecordAccessAllowed(SourceLibraryBuilder library) {
  return library
          .loader.target.context.options.globalFeatures.records.isEnabled ||
      // Coverage-ignore(suite): Not run.
      ExperimentalFlag.records.isEnabledByDefault ||
      // Coverage-ignore(suite): Not run.
      library.libraryFeatures.records.isEnabled;
}

// Coverage-ignore(suite): Not run.
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

/// The positional record index of the identifier [name].
///
/// Accepts identifiers of the form `$digits` where `digits` is an integer
/// numeral with no leading zeros and a value *n* in the range
/// 1 &le; *n* &le; [positionalFieldCount].
///
/// Returns a zero-based index, one less than the value *n*,
/// if [name] is such an identifier, and `null` if not.
int? tryParseRecordPositionalGetterName(String name, int positionalFieldCount) {
  const int c$ = 0x24; // ASCII code of '$'.
  const int c0 = 0x30; // ASCII code of '0'.
  if (name.length >= 2 &&
      name.codeUnitAt(0) == c$ &&
      name.codeUnitAt(1) != c0) {
    // Starts with `$`, not followed by leading zero.
    String suffix = name.substring(1);
    int? impliedIndex = int.tryParse(suffix);
    if (impliedIndex != null &&
        impliedIndex >= 1 &&
        impliedIndex <= positionalFieldCount) {
      return impliedIndex - 1;
    }
  }
  return null;
}
