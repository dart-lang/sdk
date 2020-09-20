// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        messageJsInteropAnonymousFactoryPositionalParameters,
        messageJsInteropEnclosingClassJSAnnotation,
        messageJsInteropEnclosingClassJSAnnotationContext,
        messageJsInteropIndexNotSupported,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor;

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor<void> {
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticsReporter;

  JsInteropChecks(this._diagnosticsReporter);

  @override
  void defaultMember(Member member) {
    _checkMemberJSInteropAnnotation(member);
    super.defaultMember(member);
  }

  @override
  void visitProcedure(Procedure procedure) {
    _checkMemberJSInteropAnnotation(procedure);

    if (!procedure.isExternal || !isJSInteropMember(procedure)) return;

    if (!procedure.isStatic &&
        (procedure.name.text == '[]=' || procedure.name.text == '[]')) {
      _diagnosticsReporter.report(
          messageJsInteropIndexNotSupported,
          procedure.fileOffset,
          procedure.name.text.length,
          procedure.location.file);
    }

    var isAnonymousFactory =
        isAnonymousClassMember(procedure) && procedure.isFactory;

    if (isAnonymousFactory) {
      if (procedure.function != null &&
          !procedure.function.positionalParameters.isEmpty) {
        var firstPositionalParam = procedure.function.positionalParameters[0];
        _diagnosticsReporter.report(
            messageJsInteropAnonymousFactoryPositionalParameters,
            firstPositionalParam.fileOffset,
            firstPositionalParam.name.length,
            firstPositionalParam.location.file);
      }
    } else {
      // Only factory constructors for anonymous classes are allowed to have
      // named parameters.
      _checkNoNamedParameters(procedure.function);
    }
  }

  @override
  void visitConstructor(Constructor constructor) {
    _checkMemberJSInteropAnnotation(constructor);

    if (!isJSInteropMember(constructor)) return;

    if (!constructor.isExternal && !constructor.isSynthetic) {
      _diagnosticsReporter.report(
          messageJsInteropNonExternalConstructor,
          constructor.fileOffset,
          constructor.name.text.length,
          constructor.location.file);
    }

    _checkNoNamedParameters(constructor.function);
  }

  /// Reports an error if [functionNode] has named parameters.
  void _checkNoNamedParameters(FunctionNode functionNode) {
    if (functionNode != null && !functionNode.namedParameters.isEmpty) {
      var firstNamedParam = functionNode.namedParameters[0];
      _diagnosticsReporter.report(
          messageJsInteropNamedParameters,
          firstNamedParam.fileOffset,
          firstNamedParam.name.length,
          firstNamedParam.location.file);
    }
  }

  /// Reports an error if [m] has a JS interop annotation and is part of a class
  /// that does not.
  void _checkMemberJSInteropAnnotation(Member m) {
    if (!hasJSInteropAnnotation(m)) return;
    var enclosingClass = m.enclosingClass;
    if (enclosingClass != null && !hasJSInteropAnnotation(enclosingClass)) {
      _diagnosticsReporter.report(messageJsInteropEnclosingClassJSAnnotation,
          m.fileOffset, m.name.text.length, m.location.file,
          context: <LocatedMessage>[
            messageJsInteropEnclosingClassJSAnnotationContext.withLocation(
                enclosingClass.location.file,
                enclosingClass.fileOffset,
                enclosingClass.name.length)
          ]);
    }
  }
}
