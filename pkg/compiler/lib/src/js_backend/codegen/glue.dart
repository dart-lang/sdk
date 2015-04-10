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
import '../../dart_types.dart' show DartType, TypeVariableType;

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

  Element getStringConversion() {
    return _backend.getStringInterpolationHelper();
  }

  reportInternalError(String message) {
    _compiler.internalError(_compiler.currentElement, message);
  }

  ConstantExpression getConstantForVariable(VariableElement variable) {
    return _backend.constants.getConstantForVariable(variable);
  }

  js.Expression staticFunctionAccess(FunctionElement element) {
    return _backend.emitter.staticFunctionAccess(element);
  }

  js.Expression staticFieldAccess(FieldElement element) {
    return _backend.emitter.staticFieldAccess(element);
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

  FunctionElement get getInterceptorMethod => _backend.getInterceptorMethod;

  void registerUseInterceptorInCodegen() {
    _backend.registerUseInterceptor(_compiler.enqueuer.codegen);
  }

  bool isInterceptedSelector(Selector selector) {
    return _backend.isInterceptedSelector(selector);
  }

  bool isInterceptedMethod(Element element) {
    return _backend.isInterceptedMethod(element);
  }

  Set<ClassElement> getInterceptedClassesOn(Selector selector) {
    return _backend.getInterceptedClassesOn(selector.name);
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    _backend.registerSpecializedGetInterceptor(classes);
  }

  js.Expression constructorAccess(ClassElement element) {
    return _backend.emitter.constructorAccess(element);
  }

  String instanceFieldPropertyName(Element field) {
    return _namer.instanceFieldPropertyName(field);
  }

  String instanceMethodName(FunctionElement element) {
    return _namer.instanceMethodName(element);
  }

  js.Expression prototypeAccess(ClassElement e,
                                {bool hasBeenInstantiated: false}) {
    return _emitter.prototypeAccess(e,
        hasBeenInstantiated: hasBeenInstantiated);
  }


  String getInterceptorName(Set<ClassElement> interceptedClasses) {
    return _backend.namer.nameForGetInterceptor(interceptedClasses);
  }

  js.Expression getInterceptorLibrary() {
    return new js.VariableUse(
        _backend.namer.globalObjectFor(_backend.interceptorsLibrary));
  }

  FunctionElement getCreateRuntimeType() {
    return _backend.getCreateRuntimeType();
  }

  FunctionElement getRuntimeTypeToString() {
    return _backend.getRuntimeTypeToString();
  }

  FunctionElement getTypeArgumentWithSubstitution() {
    return _backend.getGetRuntimeTypeArgument();
  }

  FunctionElement getTypeArgumentByIndex() {
    return _backend.getGetTypeArgumentByIndex();
  }

  js.Expression getSubstitutionName(ClassElement cls) {
    return js.string(_namer.substitutionName(cls));
  }

  int getTypeVariableIndex(TypeVariableType variable) {
    return RuntimeTypes.getTypeVariableIndex(variable.element);
  }

  bool needsSubstitutionForTypeVariableAccess(ClassElement cls) {
    ClassWorld classWorld = _compiler.world;
    if (classWorld.isUsedAsMixin(cls)) return true;

    Iterable<ClassElement> subclasses = _compiler.world.strictSubclassesOf(cls);
    return subclasses.any((ClassElement subclass) {
      return !_backend.rti.isTrivialSubstitution(subclass, cls);
    });
  }

  FunctionElement getAddRuntimeTypeInformation() {
    return _backend.getSetRuntimeTypeInfo();
  }

  js.Expression generateTypeRepresentation(DartType dartType,
                                           List<js.Expression> arguments) {
    int variableIndex = 0;
    js.Expression representation = _backend.rti.getTypeRepresentation(
        dartType,
        (_) => arguments[variableIndex++]);
    assert(variableIndex == arguments.length);
    return representation;
  }
}
