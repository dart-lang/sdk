// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator_dependencies;

import '../js_backend.dart';

import '../../common.dart';
import '../../common/registry.dart' show
    Registry;
import '../../common/codegen.dart' show
    CodegenRegistry;
import '../../compiler.dart' show
    Compiler;
import '../../constants/values.dart';
import '../../dart_types.dart' show
    DartType,
    TypeVariableType,
    InterfaceType;
import '../../enqueue.dart' show
    CodegenEnqueuer;
import '../../elements/elements.dart';
import '../../js_emitter/js_emitter.dart';
import '../../js/js.dart' as js;
import '../../native/native.dart' show NativeBehavior;
import '../../universe/selector.dart' show
    Selector;
import '../../world.dart' show
    ClassWorld;


/// Encapsulates the dependencies of the function-compiler to the compiler,
/// backend and emitter.
// TODO(sigurdm): Should be refactored when we have a better feeling for the
// interface.
class Glue {
  final Compiler _compiler;

  CodegenEnqueuer get _enqueuer => _compiler.enqueuer.codegen;

  FunctionElement get getInterceptorMethod => _backend.getInterceptorMethod;

  JavaScriptBackend get _backend => _compiler.backend;

  CodeEmitterTask get _emitter => _backend.emitter;

  Namer get _namer => _backend.namer;

  Glue(this._compiler);

  ClassWorld get classWorld => _compiler.world;

  DiagnosticReporter get reporter => _compiler.reporter;

  js.Expression constantReference(ConstantValue value) {
    return _emitter.constantReference(value);
  }

  reportInternalError(String message) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE, message);
  }

  bool isUsedAsMixin(ClassElement classElement) {
    return classWorld.isUsedAsMixin(classElement);
  }

  ConstantValue getConstantValueForVariable(VariableElement variable) {
    return _backend.constants.getConstantValueForVariable(variable);
  }

  js.Expression staticFunctionAccess(FunctionElement element) {
    return _backend.emitter.staticFunctionAccess(element);
  }

  js.Expression isolateStaticClosureAccess(FunctionElement element) {
    return _backend.emitter.isolateStaticClosureAccess(element);
  }

  js.Expression staticFieldAccess(FieldElement element) {
    return _backend.emitter.staticFieldAccess(element);
  }

  js.Expression isolateLazyInitializerAccess(FieldElement element) {
    return _backend.emitter.isolateLazyInitializerAccess(element);
  }

  bool isLazilyInitialized(FieldElement element) {
    return _backend.constants.lazyStatics.contains(element);
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

  js.Name invocationName(Selector selector) {
    return _namer.invocationName(selector);
  }

  FunctionElement get createInvocationMirrorMethod {
    return _backend.helpers.createInvocationMirror;
  }

  void registerUseInterceptorInCodegen() {
    _backend.registerUseInterceptor(_enqueuer);
  }

  bool isInterceptedSelector(Selector selector) {
    return _backend.isInterceptedSelector(selector);
  }

  bool isInterceptedMethod(Element element) {
    return _backend.isInterceptedMethod(element);
  }

  bool isInterceptorClass(ClassElement element) {
    return element.isSubclassOf(_backend.jsInterceptorClass);
  }

  Set<ClassElement> getInterceptedClassesOn(Selector selector) {
    return _backend.getInterceptedClassesOn(selector.name);
  }

  Set<ClassElement> get interceptedClasses {
    return _backend.interceptedClasses;
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    _backend.registerSpecializedGetInterceptor(classes);
  }

  js.Expression constructorAccess(ClassElement element) {
    return _backend.emitter.constructorAccess(element);
  }

  js.Name instanceFieldPropertyName(Element field) {
    return _namer.instanceFieldPropertyName(field);
  }

  js.Name instanceMethodName(FunctionElement element) {
    return _namer.instanceMethodName(element);
  }

  js.Expression prototypeAccess(ClassElement e,
                                {bool hasBeenInstantiated: false}) {
    return _emitter.prototypeAccess(e,
        hasBeenInstantiated: hasBeenInstantiated);
  }

  js.Name getInterceptorName(Set<ClassElement> interceptedClasses) {
    return _backend.namer.nameForGetInterceptor(interceptedClasses);
  }

  js.Expression getInterceptorLibrary() {
    return new js.VariableUse(
        _backend.namer.globalObjectFor(_backend.interceptorsLibrary));
  }

  FunctionElement getWrapExceptionHelper() {
    return _backend.helpers.wrapExceptionHelper;
  }

  FunctionElement getExceptionUnwrapper() {
    return _backend.helpers.exceptionUnwrapper;
  }

  FunctionElement getTraceFromException() {
    return _backend.helpers.traceFromException;
  }

  FunctionElement getCreateRuntimeType() {
    return _backend.helpers.createRuntimeType;
  }

  FunctionElement getRuntimeTypeToString() {
    return _backend.helpers.runtimeTypeToString;
  }

  FunctionElement getRuntimeTypeArgument() {
    return _backend.helpers.getRuntimeTypeArgument;
  }

  FunctionElement getTypeArgumentByIndex() {
    return _backend.helpers.getTypeArgumentByIndex;
  }

  FunctionElement getAddRuntimeTypeInformation() {
    return _backend.helpers.setRuntimeTypeInfo;
  }

  /// checkSubtype(value, $isT, typeArgs, $asT)
  FunctionElement getCheckSubtype() {
    return _backend.helpers.checkSubtype;
  }

  /// subtypeCast(value, $isT, typeArgs, $asT)
  FunctionElement getSubtypeCast() {
    return _backend.helpers.subtypeCast;
  }

  /// checkSubtypeOfRuntime(value, runtimeType)
  FunctionElement getCheckSubtypeOfRuntimeType() {
    return _backend.helpers.checkSubtypeOfRuntimeType;
  }

  /// subtypeOfRuntimeTypeCast(value, runtimeType)
  FunctionElement getSubtypeOfRuntimeTypeCast() {
    return _backend.helpers.subtypeOfRuntimeTypeCast;
  }

  js.Expression getRuntimeTypeName(ClassElement cls) {
    return js.quoteName(_namer.runtimeTypeName(cls));
  }

  int getTypeVariableIndex(TypeVariableType variable) {
    return variable.element.index;
  }

  bool needsSubstitutionForTypeVariableAccess(ClassElement cls) {
    ClassWorld classWorld = _compiler.world;
    if (classWorld.isUsedAsMixin(cls)) return true;

    Iterable<ClassElement> subclasses = _compiler.world.strictSubclassesOf(cls);
    return subclasses.any((ClassElement subclass) {
      return !_backend.rti.isTrivialSubstitution(subclass, cls);
    });
  }

  js.Expression generateTypeRepresentation(DartType dartType,
                                           List<js.Expression> arguments,
                                           CodegenRegistry registry) {
    int variableIndex = 0;
    js.Expression representation = _backend.rtiEncoder.getTypeRepresentation(
        dartType,
        (_) => arguments[variableIndex++]);
    assert(variableIndex == arguments.length);
    // Representation contains JavaScript Arrays.
    registry.registerInstantiatedClass(_backend.jsArrayClass);
    return representation;
  }

  void registerIsCheck(DartType type, Registry registry) {
    _enqueuer.registerIsCheck(type);
    _backend.registerIsCheckForCodegen(type, _enqueuer, registry);
  }

  js.Name getTypeTestTag(DartType type) {
    return _backend.namer.operatorIsType(type);
  }

  js.Name getTypeSubstitutionTag(ClassElement element) {
    return _backend.namer.substitutionName(element);
  }

  bool operatorEqHandlesNullArgument(FunctionElement element) {
    return _backend.operatorEqHandlesNullArgument(element);
  }

  bool hasStrictSubtype(ClassElement element) {
    return _compiler.world.hasAnyStrictSubtype(element);
  }

  ClassElement get jsFixedArrayClass => _backend.jsFixedArrayClass;
  ClassElement get jsExtendableArrayClass => _backend.jsExtendableArrayClass;
  ClassElement get jsUnmodifiableArrayClass =>
      _backend.jsUnmodifiableArrayClass;
  ClassElement get jsMutableArrayClass => _backend.jsMutableArrayClass;

  bool isStringClass(ClassElement classElement) =>
      classElement == _backend.jsStringClass ||
      classElement == _compiler.stringClass;

  bool isBoolClass(ClassElement classElement) =>
      classElement == _backend.jsBoolClass ||
      classElement == _compiler.boolClass;

  // TODO(sra): Should this be part of CodegenRegistry?
  void registerNativeBehavior(NativeBehavior nativeBehavior, node) {
    if (nativeBehavior == null) return;
    _enqueuer.nativeEnqueuer.registerNativeBehavior(nativeBehavior, node);
  }
}
