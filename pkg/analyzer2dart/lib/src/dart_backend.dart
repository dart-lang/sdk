// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.dart_backend;

import 'package:compiler/src/constant_system_dart.dart';
import 'package:compiler/src/constants/constant_system.dart';
import 'package:compiler/src/dart_backend/dart_backend.dart';
import 'package:compiler/src/dart2jslib.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/elements/elements.dart';

import 'driver.dart';
import 'converted_world.dart';

void compileToDart(Driver driver, ConvertedWorld convertedWorld) {
  DiagnosticListener listener = new Listener();
  DartOutputter outputter = new DartOutputter(listener, driver.outputProvider);
  ElementAstCreationContext context = new _ElementAstCreationContext(
      listener, convertedWorld.dartTypes);
  outputter.assembleProgram(
    libraries: convertedWorld.libraries,
    instantiatedClasses: convertedWorld.instantiatedClasses,
    resolvedElements: convertedWorld.resolvedElements,
    mainFunction: convertedWorld.mainFunction,
    computeElementAst: (Element element) {
      return DartBackend.createElementAst(
          context,
          element,
          convertedWorld.getIr(element));
    },
    shouldOutput: (Element element) => !element.isSynthesized,
    isSafeToRemoveTypeDeclarations: (_) => false);
}

class _ElementAstCreationContext implements ElementAstCreationContext {
  final Listener listener;

  @override
  final DartTypes dartTypes;

  _ElementAstCreationContext(this.listener, this.dartTypes);

  @override
  ConstantSystem get constantSystem => DART_CONSTANT_SYSTEM;

  @override
  InternalErrorFunction get internalError => listener.internalError;

  @override
  void traceCompilation(String name) {
    // Do nothing.
  }

  @override
  void traceGraph(String title, irObject) {
    // Do nothing.
  }
}

class Listener implements DiagnosticListener {

  @override
  void internalError(Spannable spannable, message) {
    throw new UnimplementedError(message);
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
  spanFromSpannable(Spannable node) {
    // TODO: implement spanFromSpannable
  }

  @override
  withCurrentElement(element, f()) {
    // TODO: implement withCurrentElement
  }
}
