
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.resolution;

import '../common.dart';
import '../compiler.dart' show
    Compiler;
import '../core_types.dart' show
    CoreTypes;
import '../dart_types.dart' show
    DartType,
    InterfaceType;
import '../elements/elements.dart' show
    AstElement,
    ClassElement,
    Element,
    ErroneousElement,
    FunctionElement,
    FunctionSignature,
    LocalFunctionElement,
    MetadataAnnotation,
    MethodElement,
    TypedefElement,
    TypeVariableElement;
import '../enqueue.dart' show
    ResolutionEnqueuer,
    WorldImpact;
import '../tree/tree.dart' show
    AsyncForIn,
    Send,
    TypeAnnotation;
import '../universe/universe.dart' show
    UniverseSelector;
import '../util/util.dart' show
    Setlet;
import 'registry.dart' show
    Registry;
import 'work.dart' show
    ItemCompilationContext,
    WorkItem;

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
class ResolutionWorkItem extends WorkItem {
  bool _isAnalyzed = false;

  ResolutionWorkItem(AstElement element,
                     ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  WorldImpact run(Compiler compiler, ResolutionEnqueuer world) {
    WorldImpact impact = compiler.analyze(this, world);
    _isAnalyzed = true;
    return impact;
  }

  bool get isAnalyzed => _isAnalyzed;
}

// TODO(johnniwinther): Rename this to something like  `BackendResolutionApi`
// and clean up the interface.
/// Backend callbacks function specific to the resolution phase.
class ResolutionCallbacks {
  /// Transform the [ResolutionImpact] into a [WorldImpact] adding the
  /// backend dependencies for features used in [worldImpact].
  WorldImpact transformImpact(ResolutionImpact worldImpact) => worldImpact;
}

class ResolutionImpact extends WorldImpact {
  const ResolutionImpact();

  // TODO(johnniwinther): Remove this.
  void registerDependency(Element element) {}

  Iterable<Feature> get features => const <Feature>[];
  Iterable<DartType> get requiredTypes => const <DartType>[];
  Iterable<MapLiteralUse> get mapLiterals => const <MapLiteralUse>[];
  Iterable<ListLiteralUse> get listLiterals => const <ListLiteralUse>[];
  Iterable<DartType> get typeLiterals => const <DartType>[];
  Iterable<String> get constSymbolNames => const <String>[];
}

/// A language feature seen during resolution.
// TODO(johnniwinther): Should mirror usage be part of this?
enum Feature {
  /// Invocation of a generative construction on an abstract class.
  ABSTRACT_CLASS_INSTANTIATION,
  /// An assert statement with no message.
  ASSERT,
  /// An assert statement with a message.
  ASSERT_WITH_MESSAGE,
  /// A method with an `async` body modifier.
  ASYNC,
  /// An asynchronous for in statement like `await for (var e in i) {}`.
  ASYNC_FOR_IN,
  /// A method with an `async*` body modifier.
  ASYNC_STAR,
  /// A catch statement.
  CATCH_STATEMENT,
  /// A compile time error.
  COMPILE_TIME_ERROR,
  /// A fall through in a switch case.
  FALL_THROUGH_ERROR,
  /// A ++/-- operation.
  INC_DEC_OPERATION,
  /// A field whose initialization is not a constant.
  LAZY_FIELD,
  /// A catch clause with a variable for the stack trace.
  STACK_TRACE_IN_CATCH,
  /// String interpolation.
  STRING_INTERPOLATION,
  /// An implicit call to `super.noSuchMethod`, like calling an unresolved
  /// super method.
  SUPER_NO_SUCH_METHOD,
  /// A redirection to the `Symbol` constructor.
  SYMBOL_CONSTRUCTOR,
  /// An synchronous for in statement, like `for (var e in i) {}`.
  SYNC_FOR_IN,
  /// A method with a `sync*` body modifier.
  SYNC_STAR,
  /// A throw expression.
  THROW_EXPRESSION,
  /// An implicit throw of a `NoSuchMethodError`, like calling an unresolved
  /// static method.
  THROW_NO_SUCH_METHOD,
  /// An implicit throw of a runtime error, like
  THROW_RUNTIME_ERROR,
  /// The need for a type variable bound check, like instantiation of a generic
  /// type whose type variable have non-trivial bounds.
  TYPE_VARIABLE_BOUNDS_CHECK,
}

/// A use of a map literal seen during resolution.
class MapLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  MapLiteralUse(this.type, {this.isConstant: false, this.isEmpty: false});

  int get hashCode {
    return
        type.hashCode * 13 +
        isConstant.hashCode * 17 +
        isEmpty.hashCode * 19;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MapLiteralUse) return false;
    return
        type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }
}

/// A use of a list literal seen during resolution.
class ListLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  ListLiteralUse(this.type, {this.isConstant: false, this.isEmpty: false});

  int get hashCode {
    return
        type.hashCode * 13 +
        isConstant.hashCode * 17 +
        isEmpty.hashCode * 19;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ListLiteralUse) return false;
    return
        type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }
}

/// Mutable implementation of [WorldImpact] used to transform
/// [ResolutionImpact] to [WorldImpact].
// TODO(johnniwinther): Remove [Registry] when dependency is tracked directly
// on [WorldImpact].
class TransformedWorldImpact extends WorldImpact {
  final ResolutionImpact worldImpact;

  Setlet<Element> _staticUses;
  Setlet<InterfaceType> _instantiatedTypes;
  Setlet<UniverseSelector> _dynamicGetters;
  Setlet<UniverseSelector> _dynamicInvocations;
  Setlet<UniverseSelector> _dynamicSetters;

  TransformedWorldImpact(this.worldImpact);

  @override
  Iterable<DartType> get asCasts => worldImpact.asCasts;

  @override
  Iterable<DartType> get checkedModeChecks => worldImpact.checkedModeChecks;

  @override
  Iterable<MethodElement> get closurizedFunctions {
    return worldImpact.closurizedFunctions;
  }

  @override
  Iterable<UniverseSelector> get dynamicGetters {
    return _dynamicGetters != null
        ? _dynamicGetters : worldImpact.dynamicGetters;
  }

  @override
  Iterable<UniverseSelector> get dynamicInvocations {
    return _dynamicInvocations != null
        ? _dynamicInvocations : worldImpact.dynamicInvocations;
  }

  @override
  Iterable<UniverseSelector> get dynamicSetters {
    return _dynamicSetters != null
        ? _dynamicSetters : worldImpact.dynamicSetters;
  }

  @override
  Iterable<DartType> get isChecks => worldImpact.isChecks;

  @override
  Iterable<Element> get staticUses {
    if (_staticUses == null) {
      return worldImpact.staticUses;
    }
    return _staticUses;
  }

  _unsupported(String message) => throw new UnsupportedError(message);

  void registerDynamicGetter(UniverseSelector selector) {
    if (_dynamicGetters == null) {
      _dynamicGetters = new Setlet<UniverseSelector>();
      _dynamicGetters.addAll(worldImpact.dynamicGetters);
    }
    _dynamicGetters.add(selector);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    if (_dynamicInvocations == null) {
      _dynamicInvocations = new Setlet<UniverseSelector>();
      _dynamicInvocations.addAll(worldImpact.dynamicInvocations);
    }
    _dynamicInvocations.add(selector);
  }

  void registerDynamicSetter(UniverseSelector selector) {
    if (_dynamicSetters == null) {
      _dynamicSetters = new Setlet<UniverseSelector>();
      _dynamicSetters.addAll(worldImpact.dynamicSetters);
    }
    _dynamicSetters.add(selector);
  }

  void registerInstantiatedType(InterfaceType type) {
    // TODO(johnniwinther): Remove this when dependency tracking is done on
    // the world impact itself.
    worldImpact.registerDependency(type.element);
    if (_instantiatedTypes == null) {
      _instantiatedTypes = new Setlet<InterfaceType>();
    }
    _instantiatedTypes.add(type);
  }

  @override
  Iterable<InterfaceType> get instantiatedTypes {
    return _instantiatedTypes != null
        ? _instantiatedTypes : const <InterfaceType>[];
  }

  @override
  Iterable<DartType> get typeLiterals {
    return worldImpact.typeLiterals;
  }

  void registerStaticUse(Element element) {
    // TODO(johnniwinther): Remove this when dependency tracking is done on
    // the world impact itself.
    worldImpact.registerDependency(element);
    if (_staticUses == null) {
      _staticUses = new Setlet<Element>();
    }
    _staticUses.add(element);
  }

  @override
  Iterable<LocalFunctionElement> get closures => worldImpact.closures;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('TransformedWorldImpact($worldImpact)');
    sb.write(super.toString());
    return sb.toString();
  }
}

// TODO(johnniwinther): Rename to `Resolver` or `ResolverContext`.
abstract class Resolution {
  Parsing get parsing;
  DiagnosticReporter get reporter;
  CoreTypes get coreTypes;

  void resolveTypedef(TypedefElement typdef);
  void resolveClass(ClassElement cls);
  void registerClass(ClassElement cls);
  void resolveMetadataAnnotation(MetadataAnnotation metadataAnnotation);
  FunctionSignature resolveSignature(FunctionElement function);
  DartType resolveTypeAnnotation(Element element, TypeAnnotation node);

  bool hasBeenResolved(Element element);
  WorldImpact getWorldImpact(Element element);
  WorldImpact computeWorldImpact(Element element);
}

// TODO(johnniwinther): Rename to `Parser` or `ParsingContext`.
abstract class Parsing {
  DiagnosticReporter get reporter;
  void parsePatchClass(ClassElement cls);
  measure(f());
}