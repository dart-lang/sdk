// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        messageJsInteropIndexNotSupported,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor;

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor<void> {
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticsReporter;

  JsInteropChecks(this._diagnosticsReporter);

  @override
  void visitProcedure(Procedure procedure) {
    if (!procedure.isExternal || !isJSInteropMember(procedure)) return;

    if (!procedure.isStatic &&
        (procedure.name.name == '[]=' || procedure.name.name == '[]')) {
      _diagnosticsReporter.report(
          messageJsInteropIndexNotSupported,
          procedure.fileOffset,
          procedure.name.name.length,
          procedure.location.file);
    }

    if (!isAnonymousClassMember(procedure) || !procedure.isFactory) {
      // Only factory constructors for anonymous classes are allowed to have
      // named parameters.
      _checkNoNamedParameters(procedure.function);
    }
  }

  @override
  void visitConstructor(Constructor constructor) {
    if (!isJSInteropMember(constructor)) return;

    if (!constructor.isExternal && !constructor.isSynthetic) {
      _diagnosticsReporter.report(
          messageJsInteropNonExternalConstructor,
          constructor.fileOffset,
          constructor.name.name.length,
          constructor.location.file);
    }

    _checkNoNamedParameters(constructor.function);
  }

  /// Reports an error if [functionNode] has named parameters.
  void _checkNoNamedParameters(FunctionNode functionNode) {
    if (functionNode != null && !functionNode.namedParameters.isEmpty) {
      var firstNameParam = functionNode.namedParameters[0];
      _diagnosticsReporter.report(
          messageJsInteropNamedParameters,
          firstNameParam.fileOffset,
          firstNameParam.name.length,
          firstNameParam.location.file);
    }
  }
}
