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
    CodegenEnqueuer;
import '../js_backend/js_backend.dart' show
    JavaScriptBackend;
import '../resolution/tree_elements.dart' show
    TreeElements;
import '../universe/selector.dart' show
    Selector;
import '../universe/universe.dart' show
    UniverseSelector;
import '../universe/world_impact.dart' show
    WorldImpact,
    WorldImpactBuilder;
import '../util/util.dart' show
    Pair,
    Setlet;
import 'registry.dart' show
    Registry,
    EagerRegistry;
import 'work.dart' show
    ItemCompilationContext,
    WorkItem;

class CodegenImpact extends WorldImpact {
  const CodegenImpact();

  // TODO(johnniwinther): Remove this.
  Registry get registry => null;

  Iterable<Element> get getterForSuperElements => const <Element>[];

  Iterable<Element> get fieldGetters => const <Element>[];

  Iterable<Element> get fieldSetters => const <Element>[];

  Iterable<ConstantValue> get compileTimeConstants => const <ConstantValue>[];

  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return const <Pair<DartType, DartType>>[];
  }

  Iterable<String> get constSymbols => const <String>[];

  Iterable<Set<ClassElement>> get specializedGetInterceptors {
    return const <Set<ClassElement>>[];
  }

  bool get usesInterceptor => false;

  Iterable<ClassElement> get typeConstants => const <ClassElement>[];

  Iterable<Element> get asyncMarkers => const <FunctionElement>[];
}

class _CodegenImpact extends WorldImpactBuilder implements CodegenImpact {
  // TODO(johnniwinther): Remove this.
  final Registry registry;


  Setlet<Element> _getterForSuperElements;
  Setlet<Element> _fieldGetters;
  Setlet<Element> _fieldSetters;
  Setlet<ConstantValue> _compileTimeConstants;
  Setlet<Pair<DartType, DartType>> _typeVariableBoundsSubtypeChecks;
  Setlet<String> _constSymbols;
  List<Set<ClassElement>> _specializedGetInterceptors;
  bool _usesInterceptor = false;
  Setlet<ClassElement> _typeConstants;
  Setlet<FunctionElement> _asyncMarkers;

  _CodegenImpact(this.registry);

  void registerGetterForSuperMethod(Element element) {
    if (_getterForSuperElements == null) {
      _getterForSuperElements = new Setlet<Element>();
    }
    _getterForSuperElements.add(element);
  }

  Iterable<Element> get getterForSuperElements {
    return _getterForSuperElements != null
        ? _getterForSuperElements : const <Element>[];
  }

  void registerFieldGetter(Element element) {
    if (_fieldGetters == null) {
      _fieldGetters = new Setlet<Element>();
    }
    _fieldGetters.add(element);
  }

  Iterable<Element> get fieldGetters {
    return _fieldGetters != null
        ? _fieldGetters : const <Element>[];
  }

  void registerFieldSetter(Element element) {
    if (_fieldSetters == null) {
      _fieldSetters = new Setlet<Element>();
    }
    _fieldSetters.add(element);
  }

  Iterable<Element> get fieldSetters {
    return _fieldSetters != null
        ? _fieldSetters : const <Element>[];
  }

  void registerCompileTimeConstant(ConstantValue constant) {
    if (_compileTimeConstants == null) {
      _compileTimeConstants = new Setlet<ConstantValue>();
    }
    _compileTimeConstants.add(constant);
  }

  Iterable<ConstantValue> get compileTimeConstants {
    return _compileTimeConstants != null
        ? _compileTimeConstants : const <ConstantValue>[];
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType subtype,
                                              DartType supertype) {
    if (_typeVariableBoundsSubtypeChecks == null) {
      _typeVariableBoundsSubtypeChecks = new Setlet<Pair<DartType, DartType>>();
    }
    _typeVariableBoundsSubtypeChecks.add(
        new Pair<DartType, DartType>(subtype, supertype));
  }

  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return _typeVariableBoundsSubtypeChecks != null
        ? _typeVariableBoundsSubtypeChecks : const <Pair<DartType, DartType>>[];
  }

  void registerConstSymbol(String name) {
    if (_constSymbols == null) {
      _constSymbols = new Setlet<String>();
    }
    _constSymbols.add(name);
  }

  Iterable<String> get constSymbols {
    return _constSymbols != null
        ? _constSymbols : const <String>[];
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    if (_specializedGetInterceptors == null) {
      _specializedGetInterceptors = <Set<ClassElement>>[];
    }
    _specializedGetInterceptors.add(classes);
  }

  Iterable<Set<ClassElement>> get specializedGetInterceptors {
    return _specializedGetInterceptors != null
        ? _specializedGetInterceptors : const <Set<ClassElement>>[];
  }

  void registerUseInterceptor() {
    _usesInterceptor = true;
  }

  bool get usesInterceptor => _usesInterceptor;

  void registerTypeConstant(ClassElement element) {
    if (_typeConstants == null) {
      _typeConstants = new Setlet<ClassElement>();
    }
    _typeConstants.add(element);
  }

  Iterable<ClassElement> get typeConstants {
    return _typeConstants != null
        ? _typeConstants : const <ClassElement>[];
  }

  void registerAsyncMarker(FunctionElement element) {
    if (_asyncMarkers == null) {
      _asyncMarkers = new Setlet<FunctionElement>();
    }
    _asyncMarkers.add(element);
  }

  Iterable<Element> get asyncMarkers {
    return _asyncMarkers != null
        ? _asyncMarkers : const <FunctionElement>[];
  }
}

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry extends Registry {
  final Compiler compiler;
  final Element currentElement;
  final _CodegenImpact worldImpact;

  CodegenRegistry(Compiler compiler, AstElement currentElement)
      : this.compiler = compiler,
        this.currentElement = currentElement,
        this.worldImpact = new _CodegenImpact(new EagerRegistry(
          'EagerRegistry for $currentElement', compiler.enqueuer.codegen));

  bool get isForResolution => false;

  String toString() => 'CodegenRegistry for $currentElement';

  void registerInstantiatedClass(ClassElement element) {
    registerInstantiatedType(element.rawType);
  }

  void registerInstantiatedType(InterfaceType type) {
    worldImpact.registerInstantiatedType(type);
  }

  void registerStaticUse(Element element) {
    worldImpact.registerStaticUse(element);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    worldImpact.registerDynamicInvocation(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerDynamicSetter(UniverseSelector selector) {
    worldImpact.registerDynamicSetter(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerDynamicGetter(UniverseSelector selector) {
    worldImpact.registerDynamicGetter(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerGetterForSuperMethod(Element element) {
    worldImpact.registerGetterForSuperMethod(element);
  }

  void registerFieldGetter(Element element) {
    worldImpact.registerFieldGetter(element);
  }

  void registerFieldSetter(Element element) {
    worldImpact.registerFieldSetter(element);
  }

  void registerIsCheck(DartType type) {
    worldImpact.registerIsCheck(type);
  }

  void registerCompileTimeConstant(ConstantValue constant) {
    worldImpact.registerCompileTimeConstant(constant);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType subtype,
                                              DartType supertype) {
    worldImpact.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
  }

  void registerInstantiatedClosure(LocalFunctionElement element) {
    worldImpact.registerClosure(element);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    worldImpact.registerClosurizedFunction(element);
  }

  void registerSelectorUse(Selector selector) {
    if (selector.isGetter) {
      registerDynamicGetter(new UniverseSelector(selector, null));
    } else if (selector.isSetter) {
      registerDynamicSetter(new UniverseSelector(selector, null));
    } else {
      registerDynamicInvocation(new UniverseSelector(selector, null));
    }
  }

  void registerConstSymbol(String name) {
    worldImpact.registerConstSymbol(name);
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    worldImpact.registerSpecializedGetInterceptor(classes);
  }

  void registerUseInterceptor() {
    worldImpact.registerUseInterceptor();
  }

  void registerTypeConstant(ClassElement element) {
    worldImpact.registerTypeConstant(element);
  }

  void registerStaticInvocation(Element element) {
    registerStaticUse(element);
  }

  void registerSuperInvocation(Element element) {
    registerStaticUse(element);
  }

  void registerDirectInvocation(Element element) {
    registerStaticUse(element);
  }

  void registerInstantiation(InterfaceType type) {
    registerInstantiatedType(type);
  }

  void registerAsyncMarker(FunctionElement element) {
    worldImpact.registerAsyncMarker(element);
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

    registry = new CodegenRegistry(compiler, element);
    return compiler.codegen(this, world);
  }
}
