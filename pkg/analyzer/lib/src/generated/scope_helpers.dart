// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/error/codes.dart';

/// Methods useful for [Scope] for resolution, but not belonging to it. This
/// mixin exists to allow code to be more easily shared between separate
/// resolvers.
mixin ScopeHelpers {
  ErrorReporter get errorReporter;

  void reportDeprecatedExportUse({
    required ScopeLookupResult scopeLookupResult,
    required Token nameToken,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (hasRead) {
      reportDeprecatedExportUseGetter(
        scopeLookupResult: scopeLookupResult,
        nameToken: nameToken,
      );
    }

    if (hasWrite) {
      reportDeprecatedExportUseSetter(
        scopeLookupResult: scopeLookupResult,
        nameToken: nameToken,
      );
    }
  }

  void reportDeprecatedExportUseGetter({
    required ScopeLookupResult scopeLookupResult,
    required Token nameToken,
  }) {
    if (scopeLookupResult is PrefixScopeLookupResult &&
        scopeLookupResult.getterIsFromDeprecatedExport) {
      _reportDeprecatedExportUse(
        nameToken: nameToken,
      );
    }
  }

  void reportDeprecatedExportUseSetter({
    required ScopeLookupResult scopeLookupResult,
    required Token nameToken,
  }) {
    if (scopeLookupResult is PrefixScopeLookupResult &&
        scopeLookupResult.setterIsFromDeprecatedExport) {
      _reportDeprecatedExportUse(
        nameToken: nameToken,
      );
    }
  }

  void _reportDeprecatedExportUse({
    required Token nameToken,
  }) {
    errorReporter.atToken(
      nameToken,
      WarningCode.DEPRECATED_EXPORT_USE,
      arguments: [nameToken.lexeme],
    );
  }
}
