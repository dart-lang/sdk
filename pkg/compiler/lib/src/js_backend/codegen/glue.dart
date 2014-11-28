// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator_dependencies;

import '../js_backend.dart';
import '../../dart2jslib.dart';
import '../../js_emitter/js_emitter.dart';
import '../../js/js.dart' as js;
import '../../constants/values.dart';
import '../../elements/elements.dart';
import '../../constants/expressions.dart';

/// Encapsulates the dependencies of the function-compiler to the compiler,
/// backend and emitter.
// TODO(sigurdm): Should be refactored when we have a better feeling for the
// interface.
class Glue {
  final Compiler _compiler;

  JavaScriptBackend get _backend => _compiler.backend;

  CodeEmitterTask get _emitter => _backend.emitter;
  Namer get _namer => _backend.namer;

  Glue(this._compiler);

  js.Expression constantReference(ConstantValue value) {
    return _emitter.constantReference(value);
  }

  reportInternalError(String message) {
    _compiler.internalError(_compiler.currentElement, message);
  }

  ConstantExpression getConstantForVariable(VariableElement variable) {
    return _backend.constants.getConstantForVariable(variable);
  }

  js.Expression elementAccess(Element element) {
    return _namer.elementAccess(element);
  }

  String safeVariableName(String name) {
    return _namer.safeVariableName(name);
  }

  ClassElement get listClass => _compiler.listClass;

  ConstructorElement get mapLiteralConstructor {
    return _backend.mapLiteralConstructor;
  }

  ConstructorElement get mapLiteralConstructorEmpty {
    return _backend.mapLiteralConstructorEmpty;
  }

  FunctionElement get identicalFunction => _compiler.identicalFunction;

  String invocationName(Selector selector) {
    return _namer.invocationName(selector);
  }

  bool isIntercepted(Selector selector) {
    return _backend.isInterceptedSelector(selector);
  }

}
