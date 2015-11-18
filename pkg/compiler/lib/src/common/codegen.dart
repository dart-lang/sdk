// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import '../common.dart';
import '../compiler.dart' show
    Compiler;
import '../constants/values.dart' show
    ConstantValue;
import '../dart_types.dart' show
    DartType,
    InterfaceType;
import '../elements/elements.dart' show
    AstElement,
    ClassElement,
    Element,
    FunctionElement,
    LocalFunctionElement;
import '../enqueue.dart' show
    CodegenEnqueuer,
    WorldImpact;
import '../js_backend/js_backend.dart' show
    JavaScriptBackend;
import '../resolution/tree_elements.dart' show
    TreeElements;
import '../universe/selector.dart' show
    Selector;
import '../universe/universe.dart' show
    UniverseSelector;
import '../util/util.dart' show
    Setlet;
import 'registry.dart' show
    Registry;
import 'work.dart' show
    ItemCompilationContext,
    WorkItem;

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry extends Registry {
  final Compiler compiler;
  final TreeElements treeElements;

  CodegenRegistry(this.compiler, this.treeElements);

  bool get isForResolution => false;

  Element get currentElement => treeElements.analyzedElement;

  String toString() => 'CodegenRegistry for $currentElement';

  CodegenEnqueuer get world => compiler.enqueuer.codegen;
  JavaScriptBackend get backend => compiler.backend;

  void registerAssert(bool hasMessage) {
    // Codegen does not register asserts.  They have been lowered to calls.
    assert(false);
  }

  void registerInstantiatedClass(ClassElement element) {
    backend.registerInstantiatedType(element.rawType, world, this);
  }

  void registerInstantiatedType(InterfaceType type) {
    backend.registerInstantiatedType(type, world, this);
  }

  void registerStaticUse(Element element) {
    world.registerStaticUse(element);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    world.registerDynamicInvocation(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerDynamicSetter(UniverseSelector selector) {
    world.registerDynamicSetter(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerDynamicGetter(UniverseSelector selector) {
    world.registerDynamicGetter(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerGetterForSuperMethod(Element element) {
    world.registerGetterForSuperMethod(element);
  }

  void registerFieldGetter(Element element) {
    world.registerFieldGetter(element);
  }

  void registerFieldSetter(Element element) {
    world.registerFieldSetter(element);
  }

  void registerIsCheck(DartType type) {
    world.registerIsCheck(type);
    backend.registerIsCheckForCodegen(type, world, this);
  }

  void registerCompileTimeConstant(ConstantValue constant) {
    backend.registerCompileTimeConstant(constant, this);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType subtype,
                                              DartType supertype) {
    backend.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
  }

  void registerInstantiatedClosure(LocalFunctionElement element) {
    backend.registerInstantiatedClosure(element, this);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    world.registerGetOfStaticFunction(element);
  }

  void registerSelectorUse(Selector selector) {
    world.registerSelectorUse(new UniverseSelector(selector, null));
  }

  void registerConstSymbol(String name) {
    backend.registerConstSymbol(name);
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    backend.registerSpecializedGetInterceptor(classes);
  }

  void registerUseInterceptor() {
    backend.registerUseInterceptor(world);
  }

  void registerTypeConstant(ClassElement element) {
    backend.customElementsAnalysis.registerTypeConstant(element, world);
    backend.lookupMapAnalysis.registerTypeConstant(element);
  }

  void registerStaticInvocation(Element element) {
    world.registerStaticUse(element);
  }

  void registerSuperInvocation(Element element) {
    world.registerStaticUse(element);
  }

  void registerDirectInvocation(Element element) {
    world.registerStaticUse(element);
  }

  void registerInstantiation(InterfaceType type) {
    backend.registerInstantiatedType(type, world, this);
  }

  void registerAsyncMarker(FunctionElement element) {
    backend.registerAsyncMarker(element, world, this);
  }

}

/// [WorkItem] used exclusively by the [CodegenEnqueuer].
class CodegenWorkItem extends WorkItem {
  CodegenRegistry registry;

  factory CodegenWorkItem(
      Compiler compiler,
      AstElement element,
      ItemCompilationContext compilationContext) {
    // If this assertion fails, the resolution callbacks of the backend may be
    // missing call of form registry.registerXXX. Alternatively, the code
    // generation could spuriously be adding dependencies on things we know we
    // don't need.
    assert(invariant(element,
        compiler.enqueuer.resolution.hasBeenProcessed(element),
        message: "$element has not been resolved."));
    assert(invariant(element, element.resolvedAst.elements != null,
        message: 'Resolution tree is null for $element in codegen work item'));
    return new CodegenWorkItem.internal(element, compilationContext);
  }

  CodegenWorkItem.internal(
      AstElement element,
      ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  TreeElements get resolutionTree => element.resolvedAst.elements;

  WorldImpact run(Compiler compiler, CodegenEnqueuer world) {
    if (world.isProcessed(element)) return const WorldImpact();

    registry = new CodegenRegistry(compiler, resolutionTree);
    return compiler.codegen(this, world);
  }
}
