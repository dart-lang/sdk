/// Encapsulates how to invoke the analyzer resolver and overrides how it
/// computes types on expressions to use our restricted set of types.
library ddc.src.checker.resolver;

import 'package:ddc_analyzer/analyzer.dart';
import 'package:ddc_analyzer/src/generated/ast.dart';
import 'package:ddc_analyzer/src/generated/element.dart';
import 'package:ddc_analyzer/src/generated/engine.dart';
import 'package:ddc_analyzer/src/generated/error.dart';
import 'package:ddc_analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:ddc_analyzer/src/generated/resolver.dart';
import 'package:ddc_analyzer/src/generated/static_type_analyzer.dart';
import 'package:ddc_analyzer/src/generated/sdk_io.dart'
    show DirectoryBasedDartSdk;
import 'package:ddc_analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:ddc_analyzer/src/generated/source.dart' show Source;
import 'package:ddc_analyzer/src/generated/source_io.dart';
import 'package:logging/logging.dart' as logger;

import 'package:ddc/src/options.dart';
import 'package:ddc/src/report.dart';
import 'dart_sdk.dart';
import 'multi_package_resolver.dart';

final _log = new logger.Logger('ddc.src.resolver');

/// Encapsulates a resolver from the analyzer package.
class TypeResolver {
  final InternalAnalysisContext context = _initContext();

  final Map<Uri, Source> _sources = <Uri, Source>{};

  TypeResolver(DartUriResolver sdkResolver,
      {List otherResolvers, ResolverOptions options}) {
    var resolvers = [sdkResolver];
    if (otherResolvers == null) {
      if (options == null) options = new ResolverOptions();
      resolvers.add(new FileUriResolver());
      resolvers.add(options.useMultiPackage
          ? new MultiPackageResolver(options.packagePaths)
          : new PackageUriResolver([new JavaFile(options.packageRoot)]));
    } else {
      resolvers.addAll(otherResolvers);
    }
    context.sourceFactory = new SourceFactory(resolvers);
  }

  /// Creates a [TypeResolver] that uses a mock 'dart:' library contents.
  TypeResolver.fromMock(Map<String, String> mockSources,
      {List otherResolvers, ResolverOptions options})
      : this(new MockDartSdk(mockSources, reportMissing: true).resolver,
          otherResolvers: otherResolvers, options: options);

  /// Creates a [TypeResolver] that uses the SDK at the given [sdkPath].
  TypeResolver.fromDir(String sdkPath,
      {List otherResolvers, ResolverOptions options})
      : this(
          new DartUriResolver(new DirectoryBasedDartSdk(new JavaFile(sdkPath))),
          otherResolvers: otherResolvers, options: options);

  /// Find the corresponding [Source] for [uri].
  Source findSource(Uri uri) {
    var source = _sources[uri];
    if (source != null) return source;
    return _sources[uri] = context.sourceFactory.forUri('$uri');
  }

  /// Log any errors encountered when resolving [source] and return whether any
  /// errors were found.
  bool logErrors(Source source, CheckerReporter reporter) {
    List<AnalysisError> errors = context.getErrors(source).errors;
    bool failure = false;
    if (errors.isNotEmpty) {
      for (var error in errors) {
        var severity = error.errorCode.errorSeverity;
        var isError = severity == ErrorSeverity.ERROR;
        if (isError) failure = true;
        var level = isError ? logger.Level.SEVERE : logger.Level.WARNING;
        reporter.logAnalyzerError(
            error.message, level, error.offset, error.offset + error.length);
      }
    }
    return failure;
  }
}

/// Creates an analysis context that contains our restricted typing rules.
InternalAnalysisContext _initContext() {
  var options = new AnalysisOptionsImpl()..cacheSize = 512;
  InternalAnalysisContext res = AnalysisEngine.instance.createAnalysisContext();
  return res
    ..analysisOptions = options
    ..resolverVisitorFactory = RestrictedResolverVisitor.constructor;
}

/// Overrides the default [ResolverVisitor] to comply with DDC's restricted
/// type rules. This changes how types are promoted in conditional expressions
/// and statements, and how types are computed on expressions.
class RestrictedResolverVisitor extends ResolverVisitor {
  final TypeProvider _typeProvider;

  RestrictedResolverVisitor(
      Library library, Source source, TypeProvider typeProvider)
      : _typeProvider = typeProvider,
        super.con1(library, source, typeProvider,
            typeAnalyzerFactory: (r) => new RestrictedStaticTypeAnalyzer(r));

  static ResolverVisitor constructor(
          Library library, Source source, TypeProvider typeProvider) =>
      new RestrictedResolverVisitor(library, source, typeProvider);

  @override
  visitCatchClause(CatchClause node) {
    var stack = node.stackTraceParameter;
    if (stack != null) {
      // TODO(jmesserly): analyzer does not correctly associate StackTrace type.
      // It happens too late in TypeResolverVisitor visitCatchClause.
      var element = stack.staticElement;
      if (element is VariableElementImpl && element.type == null) {
        // From the language spec:
        // The static type of p1 is T and the static type of p2 is StackTrace.
        element.type = _typeProvider.stackTraceType;
      }
    }
    return super.visitCatchClause(node);
  }

  @override // removes type promotion
  void promoteTypes(Expression condition) {
    // TODO(sigmund, vsm): add this back, but use strict meaning of is checks.
  }
}

/// Overrides the default [StaticTypeAnalyzer] to adjust rules that are stricter
/// in the restricted type system and to infer types for untyped local
/// variables.
class RestrictedStaticTypeAnalyzer extends StaticTypeAnalyzer {
  final TypeProvider _typeProvider;

  RestrictedStaticTypeAnalyzer(ResolverVisitor r)
      : _typeProvider = r.typeProvider,
        super(r);

  @override // to infer type from initializers
  visitVariableDeclaration(VariableDeclaration node) {
    _inferType(node);
    return super.visitVariableDeclaration(node);
  }

  /// Infer the type of a variable based on the initializer's type.
  void _inferType(VariableDeclaration node) {
    if (node.element is! LocalVariableElement) return;
    Expression initializer = node.initializer;
    if (initializer == null) return;

    var declaredType = (node.parent as VariableDeclarationList).type;
    if (declaredType != null) return;
    VariableElementImpl element = node.element;
    if (element.type != dynamicType) return;
    var type = getStaticType(initializer);
    if (type == _typeProvider.bottomType) return;
    element.type = type;
  }

  @override // to propagate types to identifiers
  visitMethodInvocation(MethodInvocation node) {
    // TODO(sigmund): follow up with analyzer team - why is this needed?
    visitSimpleIdentifier(node.methodName);
    return super.visitMethodInvocation(node);
  }

  // Review note: no longer need to override visitFunctionExpression, this is
  // handled by the analyzer internally.
  // TODO(vsm): in visitbinaryExpression: check computeStaticReturnType result?
  // TODO(vsm): in visitConditionalExpression: check... LUB in rules?
  // TODO(vsm): in visitFunctionDeclaration: Should we ever use the expression
  // type in a (...) => expr or just the written type?

}
