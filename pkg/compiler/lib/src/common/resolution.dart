// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.resolution;

import '../common.dart';
import '../compile_time_constants.dart';
import '../compiler.dart' show Compiler;
import '../constants/expressions.dart' show ConstantExpression;
import '../constants/values.dart' show ConstantValue;
import '../core_types.dart' show CoreClasses, CoreTypes, CommonElements;
import '../dart_types.dart' show DartType, Types;
import '../elements/elements.dart'
    show
        AstElement,
        ClassElement,
        ConstructorElement,
        Element,
        ExecutableElement,
        FunctionElement,
        FunctionSignature,
        LibraryElement,
        MetadataAnnotation,
        MethodElement,
        ResolvedAst,
        TypedefElement;
import '../enqueue.dart' show ResolutionEnqueuer;
import '../id_generator.dart';
import '../mirrors_used.dart';
import '../options.dart' show CompilerOptions;
import '../parser/element_listener.dart' show ScannerOptions;
import '../parser/parser_task.dart';
import '../patch_parser.dart';
import '../resolution/resolution.dart';
import '../tree/tree.dart' show Send, TypeAnnotation;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/world_impact.dart' show WorldImpact;
import '../universe/feature.dart';
import 'backend_api.dart';
import 'work.dart' show WorkItem;

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
abstract class ResolutionWorkItem implements WorkItem {
  factory ResolutionWorkItem(Resolution resolution, AstElement element) =
      _ResolutionWorkItem;
}

class _ResolutionWorkItem extends WorkItem implements ResolutionWorkItem {
  bool _isAnalyzed = false;
  final Resolution resolution;

  _ResolutionWorkItem(this.resolution, AstElement element) : super(element);

  WorldImpact run() {
    assert(invariant(element, !_isAnalyzed,
        message: 'Element ${element} has already been analyzed'));
    WorldImpact impact = resolution.computeWorldImpact(element);
    _isAnalyzed = true;
    return impact;
  }
}

class ResolutionImpact extends WorldImpact {
  const ResolutionImpact();

  Iterable<Feature> get features => const <Feature>[];
  Iterable<MapLiteralUse> get mapLiterals => const <MapLiteralUse>[];
  Iterable<ListLiteralUse> get listLiterals => const <ListLiteralUse>[];
  Iterable<String> get constSymbolNames => const <String>[];
  Iterable<ConstantExpression> get constantLiterals =>
      const <ConstantExpression>[];

  Iterable<dynamic> get nativeData => const <dynamic>[];
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

  /// Resolve target specific information for [element] and register it with
  /// [registry].
  void resolveNativeElement(Element element, NativeRegistry registry) {}

  /// Processes [element] for resolution and returns the [MethodElement] that
  /// defines the implementation of [element].
  MethodElement resolveExternalFunction(MethodElement element) => element;

  /// Called when resolving a call to a foreign function. If a non-null value
  /// is returned, this is stored as native data for [node] in the resolved
  /// AST.
  dynamic resolveForeignCall(Send node, Element element,
      CallStructure callStructure, ForeignResolver resolver) {
    return null;
  }

  /// Returns `true` if [element] is a default implementation of `noSuchMethod`
  /// used by the target.
  bool isDefaultNoSuchMethod(MethodElement element);

  /// Returns the default superclass for the given [element] in this target.
  ClassElement defaultSuperclass(ClassElement element);

  /// Returns `true` if [element] is a native element, that is, that the
  /// corresponding entity already exists in the target language.
  bool isNative(Element element) => false;

  /// Returns `true` if [element] is a foreign element, that is, that the
  /// backend has specialized handling for the element.
  bool isForeign(Element element) => false;

  /// Returns `true` if this target supports async/await.
  bool get supportsAsyncAwait => true;
}

// TODO(johnniwinther): Rename to `Resolver` or `ResolverContext`.
abstract class Resolution implements Frontend {
  ParsingContext get parsingContext;
  DiagnosticReporter get reporter;
  CoreClasses get coreClasses;
  CoreTypes get coreTypes;
  CommonElements get commonElements;
  Types get types;
  Target get target;
  ResolverTask get resolver;
  ResolutionEnqueuer get enqueuer;
  CompilerOptions get options;
  IdGenerator get idGenerator;
  ConstantEnvironment get constants;
  MirrorUsageAnalyzerTask get mirrorUsageAnalyzerTask;

  /// Whether internally we computed the constant for the [proxy] variable
  /// defined in dart:core (used only for testing).
  // TODO(sigmund): delete, we need a better way to test this.
  bool get wasProxyConstantComputedTestingOnly;

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

  /// Ensure the resolution of all members of [element].
  void ensureClassMembers(ClassElement element);

  /// Registers that [element] has a compile time error.
  ///
  /// The error itself is given in [message].
  void registerCompileTimeError(Element element, DiagnosticMessage message);

  ResolutionWorkItem createWorkItem(Element element);

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

  WorldImpact transformResolutionImpact(
      Element element, ResolutionImpact resolutionImpact);

  /// Removes the [WorldImpact] for [element] from the resolution cache. Later
  /// calls to [getWorldImpact] or [computeWorldImpact] returns an empty impact.
  void uncacheWorldImpact(Element element);

  /// Removes the [WorldImpact]s for all [Element]s in the resolution cache. ,
  /// Later calls to [getWorldImpact] or [computeWorldImpact] returns an empty
  /// impact.
  void emptyCache();

  void forgetElement(Element element);

  /// Returns `true` if [value] is the top-level [proxy] annotation from the
  /// core library.
  bool isProxyConstant(ConstantValue value);
}

/// A container of commonly used dependencies for tasks that involve parsing.
abstract class ParsingContext {
  factory ParsingContext(DiagnosticReporter reporter, ParserTask parser,
      PatchParserTask patchParser, Backend backend) = _ParsingContext;

  DiagnosticReporter get reporter;
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
  final ParserTask parser;
  final PatchParserTask patchParser;
  final Backend backend;

  _ParsingContext(this.reporter, this.parser, this.patchParser, this.backend);

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
