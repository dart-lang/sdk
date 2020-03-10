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
        messageJsInteropNonExternalConstructor;

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor<void> {
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticsReporter;

  JsInteropChecks(this._diagnosticsReporter);

  @override
  void visitClass(Class c) {
    if (!hasJSInteropAnnotation(c)) return;
    super.visitClass(c);
  }

  @override
  void visitProcedure(Procedure procedure) {
    if (procedure.isStatic) return;
    if (procedure.name.name == '[]=' || procedure.name.name == '[]') {
      _diagnosticsReporter.report(
          messageJsInteropIndexNotSupported,
          procedure.fileOffset,
          procedure.name.name.length,
          procedure.location.file);
    }
  }

  @override
  void visitConstructor(Constructor constructor) {
    if (!constructor.isExternal && !constructor.isSynthetic) {
      _diagnosticsReporter.report(
          messageJsInteropNonExternalConstructor,
          constructor.fileOffset,
          constructor.name.name.length,
          constructor.location.file);
    }
  }
}
