// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.resolution;

import '../common.dart';
import '../compiler.dart' show Compiler;
import '../constants/expressions.dart' show ConstantExpression;
import '../core_types.dart' show CoreClasses, CoreTypes;
import '../dart_types.dart' show DartType, InterfaceType, Types;
import '../elements/elements.dart'
    show
        AstElement,
        ClassElement,
        Element,
        ExecutableElement,
        FunctionElement,
        FunctionSignature,
        LibraryElement,
        MetadataAnnotation,
        ResolvedAst,
        TypedefElement;
import '../enqueue.dart' show ResolutionEnqueuer;
import '../options.dart' show ParserOptions;
import '../parser/element_listener.dart' show ScannerOptions;
import '../parser/parser_task.dart';
import '../patch_parser.dart';
import '../tree/tree.dart' show TypeAnnotation;
import '../universe/world_impact.dart' show WorldImpact;
import 'backend_api.dart';
import 'work.dart' show ItemCompilationContext, WorkItem;

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
class ResolutionWorkItem extends WorkItem {
  bool _isAnalyzed = false;

  ResolutionWorkItem(
      AstElement element, ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  WorldImpact run(Compiler compiler, ResolutionEnqueuer world) {
    WorldImpact impact = compiler.analyze(this, world);
    _isAnalyzed = true;
    return impact;
  }

  bool get isAnalyzed => _isAnalyzed;
}

class ResolutionImpact extends WorldImpact {
  const ResolutionImpact();

  Iterable<Feature> get features => const <Feature>[];
  Iterable<MapLiteralUse> get mapLiterals => const <MapLiteralUse>[];
  Iterable<ListLiteralUse> get listLiterals => const <ListLiteralUse>[];
  Iterable<String> get constSymbolNames => const <String>[];
  Iterable<ConstantExpression> get constantLiterals {
    return const <ConstantExpression>[];
  }

  Iterable<dynamic> get nativeData => const <dynamic>[];
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

  /// String juxtaposition.
  STRING_JUXTAPOSITION,

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
    return type.hashCode * 13 +
        isConstant.hashCode * 17 +
        isEmpty.hashCode * 19;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MapLiteralUse) return false;
    return type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }

  String toString() {
    return 'MapLiteralUse($type,isConstant:$isConstant,isEmpty:$isEmpty)';
  }
}

/// A use of a list literal seen during resolution.
class ListLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  ListLiteralUse(this.type, {this.isConstant: false, this.isEmpty: false});

  int get hashCode {
    return type.hashCode * 13 +
        isConstant.hashCode * 17 +
        isEmpty.hashCode * 19;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ListLiteralUse) return false;
    return type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }

  String toString() {
    return 'ListLiteralUse($type,isConstant:$isConstant,isEmpty:$isEmpty)';
  }
}

/// Interface for the accessing the front-end analysis.
// TODO(johnniwinther): Find a better name for this.
abstract class Frontend {
  /// Returns the [ResolutionImpact] for [element].
  ResolutionImpact getResolutionImpact(Element element);
}

/// Interface defining target-specific behavior for resolution.
abstract class Target {
  /// Returns `true` if [library] is a target specific library whose members
  /// have special treatment, such as being allowed to extends blacklisted
  /// classes or members being eagerly resolved.
  bool isTargetSpecificLibrary(LibraryElement element);
}

// TODO(johnniwinther): Rename to `Resolver` or `ResolverContext`.
abstract class Resolution implements Frontend {
  ParsingContext get parsingContext;
  DiagnosticReporter get reporter;
  CoreClasses get coreClasses;
  CoreTypes get coreTypes;
  Types get types;
  Target get target;

  /// If set to `true` resolution caches will not be cleared. Use this only for
  /// testing.
  bool retainCachesForTesting;

  void resolveTypedef(TypedefElement typdef);
  void resolveClass(ClassElement cls);
  void registerClass(ClassElement cls);
  void resolveMetadataAnnotation(MetadataAnnotation metadataAnnotation);
  FunctionSignature resolveSignature(FunctionElement function);
  DartType resolveTypeAnnotation(Element element, TypeAnnotation node);

  /// Returns `true` if [element] has been resolved.
  // TODO(johnniwinther): Normalize semantics between normal and deserialized
  // elements; deserialized elements are always resolved but the method will
  // return `false`.
  bool hasBeenResolved(Element element);

  /// Resolve [element] if it has not already been resolved.
  void ensureResolved(Element element);

  ResolutionWorkItem createWorkItem(
      Element element, ItemCompilationContext compilationContext);

  /// Returns `true` if [element] as a fully computed [ResolvedAst].
  bool hasResolvedAst(ExecutableElement element);

  /// Returns the `ResolvedAst` for the [element].
  ResolvedAst getResolvedAst(ExecutableElement element);

  /// Returns `true` if the [ResolutionImpact] for [element] is cached.
  bool hasResolutionImpact(Element element);

  /// Returns the precomputed [ResolutionImpact] for [element].
  ResolutionImpact getResolutionImpact(Element element);

  /// Returns the [ResolvedAst] for [element], computing it if necessary.
  ResolvedAst computeResolvedAst(Element element);

  /// Returns the precomputed [WorldImpact] for [element].
  WorldImpact getWorldImpact(Element element);

  /// Computes the [WorldImpact] for [element].
  WorldImpact computeWorldImpact(Element element);

  /// Removes the [WorldImpact] for [element] from the resolution cache. Later
  /// calls to [getWorldImpact] or [computeWorldImpact] returns an empty impact.
  void uncacheWorldImpact(Element element);

  /// Removes the [WorldImpact]s for all [Element]s in the resolution cache. ,
  /// Later calls to [getWorldImpact] or [computeWorldImpact] returns an empty
  /// impact.
  void emptyCache();

  void forgetElement(Element element);
}

/// A container of commonly used dependencies for tasks that involve parsing.
abstract class ParsingContext {
  factory ParsingContext(
      DiagnosticReporter reporter,
      ParserOptions parserOptions,
      ParserTask parser,
      PatchParserTask patchParser,
      Backend backend) = _ParsingContext;

  DiagnosticReporter get reporter;
  ParserOptions get parserOptions;
  ParserTask get parser;
  PatchParserTask get patchParser;

  /// Use [patchParser] directly instead.
  @deprecated
  void parsePatchClass(ClassElement cls);

  /// Use [parser] and measure directly instead.
  @deprecated
  measure(f());

  /// Get the [ScannerOptions] to scan the given [element].
  ScannerOptions getScannerOptionsFor(Element element);
}

class _ParsingContext implements ParsingContext {
  final DiagnosticReporter reporter;
  final ParserOptions parserOptions;
  final ParserTask parser;
  final PatchParserTask patchParser;
  final Backend backend;

  _ParsingContext(this.reporter, this.parserOptions, this.parser,
      this.patchParser, this.backend);

  @override
  measure(f()) => parser.measure(f);

  @override
  void parsePatchClass(ClassElement cls) {
    patchParser.measure(() {
      if (cls.isPatch) {
        patchParser.parsePatchClassNode(cls);
      }
    });
  }

  @override
  ScannerOptions getScannerOptionsFor(Element element) => new ScannerOptions(
      canUseNative: backend.canLibraryUseNative(element.library));
}
