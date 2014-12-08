/// Encapsulates how to invoke the analyzer resolver and overrides how it
/// computes types on expressions to use our restricted set of types.
library ddc.src.resolver;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:logging/logging.dart' as logger;

import 'dart_sdk.dart';
import 'utils.dart';

final _log = new logger.Logger('ddc.src.resolver');

/// Encapsulates a resolver from the analyzer package.
class TypeResolver {
  final InternalAnalysisContext context = _initContext();

  final Map<Uri, Source> _sources = <Uri, Source>{};

  TypeResolver(DartUriResolver sdkResolver, [List otherResolvers]) {
    var resolvers = [sdkResolver];
    if (otherResolvers == null)  {
      resolvers.add(new FileUriResolver());
      resolvers.add(new PackageUriResolver([new JavaFile('packages/')]));
    } else {
      resolvers.addAll(otherResolvers);
    }
    context.sourceFactory = new SourceFactory(resolvers);
  }

  /// Find the corresponding [Source] for [uri].
  Source findSource(Uri uri) {
    var source = _sources[uri];
    if (source != null) return source;
    return _sources[uri] = context.sourceFactory.forUri('$uri');
  }

  /// Log any errors encountered when resolving [source] and return whether any
  /// errors were found.
  bool logErrors(Source source) {
    List<AnalysisError> errors = context.getErrors(source).errors;
    bool failure = false;
    if (errors.isNotEmpty) {
      _log.info('analyzer found a total of ${errors.length} errors:');
      for (var error in errors) {
        var offset = error.offset;
        var span = spanFor(error.source, offset, offset + error.length);
        var severity = error.errorCode.errorSeverity;
        var isError = severity == ErrorSeverity.ERROR;
        if (isError) failure = true;
        var level = isError ? logger.Level.SEVERE : logger.Level.WARNING;
        _log.log(level,
            span.message(error.message, color: colorOf(severity.name)));
      }
    }
    return failure;
  }

  /// Creates a [DartUriResolver] that uses the SDK at the given [sdkPath].
  static DartUriResolver sdkResolverFromDir(String sdkPath) =>
      new DartUriResolver(new DirectoryBasedDartSdk(new JavaFile(sdkPath)));

  /// Creates a [DartUriResolver] that uses a mock 'dart:' library contents.
  static DartUriResolver sdkResolverFromMock(
      Map<String, String> mockSdkSources) {
    return new MockDartSdk(mockSdkSources, reportMissing: true).resolver;
  }
}

/// Creates an analysis context that contains our restricted typing rules.
InternalAnalysisContext _initContext() {
  InternalAnalysisContext res = AnalysisEngine.instance.createAnalysisContext();
  return res..resolverVisitorFactory = RestrictedResolverVisitor.constructor;
}

/// Overrides the default [ResolverVisitor] to comply with DDC's restricted
/// type rules. This changes how types are promoted in conditional expressions
/// and statements, and how types are computed on expressions.
class RestrictedResolverVisitor extends ResolverVisitor {

  RestrictedResolverVisitor(
      Library library, Source source, TypeProvider typeProvider)
      : super.con1(library, source, typeProvider,
          typeAnalyzerFactory: (r) => new RestrictedStaticTypeAnalyzer(r));

  static ResolverVisitor constructor(
      Library library, Source source, TypeProvider typeProvider) =>
      new RestrictedResolverVisitor(library, source, typeProvider);


  @override // removes type promotion
  void promoteTypes(Expression condition) {
    // TODO(sigmund, vsm): add this back, but use strict meaning of is checks.
  }
}

/// Overrides the default [StaticTypeAnalyzer] to adjust rules that are stricter
/// in the restricted type system and to infer types for untyped local
/// variables.
class RestrictedStaticTypeAnalyzer extends StaticTypeAnalyzer {

  RestrictedStaticTypeAnalyzer(ResolverVisitor r) : super(r);

  @override // to infer type from initializers
  Object visitVariableDeclaration(VariableDeclaration node) {
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
    element.type = getStaticType(initializer);
    return;
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

  @override
  void recordStaticType(Expression expression, DartType type) {
    // TODO(vsm, sigmund): get rid of _dynamize, no more erasure!
    super.recordStaticType(expression, _dynamize(type));
  }

  // TODO(vsm, sigmund): get rid of _dynamize, no more erasure!
  DartType _dynamize(DartType type) {
    if (type is ParameterizedType) {
      int len = type.typeParameters.length;
      if (len > 0) {
        var params = new List.filled(len, dynamicType);
        return type.substitute2(params, type.typeArguments);
      }
    }
    // Erasure
    if (type is TypeParameterElement) type = dynamicType;
    return type;
  }
}
