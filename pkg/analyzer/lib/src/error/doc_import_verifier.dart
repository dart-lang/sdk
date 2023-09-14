// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.g.dart';

/// Verifies doc imports, written as `@docImport` inside doc comments.
class DocImportVerifier {
  final ErrorReporter _errorReporter;

  DocImportVerifier(this._errorReporter);

  void docImport(DocImport node) {
    var deferredKeyword = node.import.deferredKeyword;
    if (deferredKeyword != null) {
      _errorReporter.reportErrorForToken(
        WarningCode.DOC_IMPORT_CANNOT_BE_DEFERRED,
        deferredKeyword,
      );
    }
    var configurations = node.import.configurations;
    if (configurations.isNotEmpty) {
      _errorReporter.reportErrorForOffset(
        WarningCode.DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS,
        configurations.first.offset,
        configurations.last.end,
      );
    }
  }
}
