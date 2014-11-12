// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.dart_backend;

import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/dart_backend/dart_backend.dart';
import 'package:compiler/src/dart2jslib.dart';

import 'driver.dart';
import 'converted_world.dart';

void compileToDart(Driver driver, ConvertedWorld convertedWorld) {
  DartOutputter outputter =
      new DartOutputter(new Listener(), driver.outputProvider);
  outputter.assembleProgram(
    libraries: convertedWorld.libraries,
    instantiatedClasses: convertedWorld.instantiatedClasses,
    resolvedElements: convertedWorld.resolvedElements,
    mainFunction: convertedWorld.mainFunction,
    computeElementAst: (Element element) {
      return DartBackend.createElementAst(
          null, // No compiler.
          null, // No tracer.
          DART_CONSTANT_SYSTEM,
          element,
          convertedWorld.getIr(element));
    },
    shouldOutput: (_) => true,
    isSafeToRemoveTypeDeclarations: (_) => false);

}

class Listener implements DiagnosticListener {

  @override
  void internalError(Spannable spannable, message) {
    // TODO: implement internalError
  }

  @override
  void log(message) {
    // TODO: implement log
  }

  @override
  void reportError(Spannable node,
                   MessageKind errorCode,
                   [Map arguments = const {}]) {
    // TODO: implement reportError
  }

  @override
  void reportFatalError(Spannable node,
                        MessageKind errorCode,
                        [Map arguments = const {}]) {
    // TODO: implement reportFatalError
  }

  @override
  void reportHint(Spannable node,
                  MessageKind errorCode,
                  [Map arguments = const {}]) {
    // TODO: implement reportHint
  }

  @override
  void reportInfo(Spannable node,
                  MessageKind errorCode,
                  [Map arguments = const {}]) {
    // TODO: implement reportInfo
  }

  @override
  void reportWarning(Spannable node,
                     MessageKind errorCode,
                     [Map arguments = const {}]) {
    // TODO: implement reportWarning
  }

  @override
  SourceSpan spanFromSpannable(Spannable node) {
    // TODO: implement spanFromSpannable
  }

  @override
  withCurrentElement(element, f()) {
    // TODO: implement withCurrentElement
  }
}
