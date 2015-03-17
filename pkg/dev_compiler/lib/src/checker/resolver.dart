// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Encapsulates how to invoke the analyzer resolver and overrides how it
/// computes types on expressions to use our restricted set of types.
library dev_compiler.src.checker.resolver;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart' as analyzer;
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:logging/logging.dart' as logger;

import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:dev_compiler/src/utils.dart';
import 'dart_sdk.dart';
import 'multi_package_resolver.dart';

final _log = new logger.Logger('dev_compiler.src.resolver');

/// Encapsulates a resolver from the analyzer package.
class TypeResolver {
  final InternalAnalysisContext context;

  final Map<Uri, Source> _sources = <Uri, Source>{};

  TypeResolver(DartUriResolver sdkResolver, ResolverOptions options,
      {List otherResolvers})
      : context = _initContext(options) {
    var resolvers = [sdkResolver];
    if (otherResolvers == null) {
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
  TypeResolver.fromMock(
      Map<String, String> mockSources, ResolverOptions options,
      {List otherResolvers})
      : this(
          new MockDartSdk(mockSources, reportMissing: true).resolver, options,
          otherResolvers: otherResolvers);

  /// Creates a [TypeResolver] that uses the SDK at the given [sdkPath].
  TypeResolver.fromDir(String sdkPath, ResolverOptions options,
      {List otherResolvers})
      : this(
          new DartUriResolver(new DirectoryBasedDartSdk(new JavaFile(sdkPath))),
          options, otherResolvers: otherResolvers);

  /// Find the corresponding [Source] for [uri].
  Source findSource(Uri uri) {
    var source = _sources[uri];
    if (source != null) return source;
    return _sources[uri] = context.sourceFactory.forUri('$uri');
  }

  /// Log any errors encountered when resolving [source] and return whether any
  /// errors were found.
  bool logErrors(Source source, CheckerReporter reporter) {
    List<analyzer.AnalysisError> errors = context.getErrors(source).errors;
    bool failure = false;
    if (errors.isNotEmpty) {
      for (var error in errors) {
        var message = new AnalyzerError.from(error);
        if (message.level == logger.Level.SEVERE) failure = true;
        reporter.log(message);
      }
    }
    return failure;
  }
}

class AnalyzerError extends Message {
  factory AnalyzerError.from(analyzer.AnalysisError error) {
    var severity = error.errorCode.errorSeverity;
    var isError = severity == analyzer.ErrorSeverity.ERROR;
    var level = isError ? logger.Level.SEVERE : logger.Level.WARNING;
    int begin = error.offset;
    int end = begin + error.length;
    return new AnalyzerError(error.message, level, begin, end);
  }

  const AnalyzerError(String message, logger.Level level, int begin, int end)
      : super('[from analyzer]: $message', level, begin, end);
}

/// Creates an analysis context that contains our restricted typing rules.
InternalAnalysisContext _initContext(ResolverOptions options) {
  var analysisOptions = new AnalysisOptionsImpl()..cacheSize = 512;
  AnalysisContextImpl res = AnalysisEngine.instance.createAnalysisContext();
  res.analysisOptions = analysisOptions;
  res.libraryResolverFactory =
      (context) => new LibraryResolverWithInference(context, options);
  return res;
}

/// A [LibraryResolver] that performs inference on top-levels and fields based
/// on the value of the initializer, and on fields and methods based on
/// overridden members in super classes.
class LibraryResolverWithInference extends LibraryResolver {
  final ResolverOptions _options;

  LibraryResolverWithInference(context, this._options) : super(context);

  @override
  void resolveReferencesAndTypes() {
    _resolveVariableReferences();

    // Skip inference in the core libraries (note: resolvedLibraries are the
    // libraries in the current strongly connected component).
    if (resolvedLibraries.any((l) => l.librarySource.isInSystemLibrary)) {
      _resolveReferencesAndTypes(false);
      return;
    }

    // Run resolution in two stages, skipping method bodies first, so we can run
    // type-inference before we fully analyze methods.
    _resolveReferencesAndTypes(true);
    _runInference();
    _resolveReferencesAndTypes(false);
  }

  // Note: this was split from _resolveReferencesAndTypesInLibrary so we do it
  // only once.
  void _resolveVariableReferences() {
    for (Library library in resolvedLibraries) {
      for (Source source in library.compilationUnitSources) {
        library.getAST(source).accept(
            new VariableResolverVisitor.con1(library, source, typeProvider));
      }
    }
  }

  // Note: this was split from _resolveReferencesAndTypesInLibrary so we can do
  // resolution in pieces.
  void _resolveReferencesAndTypes(bool skipMethods) {
    for (Library library in resolvedLibraries) {
      for (Source source in library.compilationUnitSources) {
        library.getAST(source).accept(new RestrictedResolverVisitor(
            library, source, typeProvider, _options, skipMethods));
      }
    }
  }

  _runInference() {
    var consts = [];
    var statics = [];
    var classes = [];

    // Extract top-level members that are const, statics, or classes.
    for (Library library in resolvedLibraries) {
      for (Source source in library.compilationUnitSources) {
        CompilationUnit ast = library.getAST(source);
        for (var declaration in ast.declarations) {
          if (declaration is TopLevelVariableDeclaration) {
            if (declaration.variables.isConst) {
              consts.addAll(declaration.variables.variables);
            } else {
              statics.addAll(declaration.variables.variables);
            }
          } else if (declaration is ClassDeclaration) {
            classes.add(declaration);
            for (var member in declaration.members) {
              if (member is! FieldDeclaration) continue;
              if (member.fields.isConst) {
                consts.addAll(member.fields.variables);
              } else if (member.isStatic) {
                statics.addAll(member.fields.variables);
              }
            }
          }
        }
      }
    }

    // TODO(sigmund): consider propagating const types after this layer of
    // inference, so their types can be used to initialize other members below.
    _inferVariableFromInitializer(consts);
    _inferVariableFromInitializer(statics);

    // Track types in this strongly connected component, ensure we visit
    // supertypes before subtypes.
    var typeToDeclaration = <InterfaceType, ClassDeclaration>{};
    classes.forEach((c) => typeToDeclaration[c.element.type] = c);
    var seen = new Set<InterfaceType>();
    visit(ClassDeclaration cls) {
      var element = cls.element;
      var type = element.type;
      if (seen.contains(type)) return;
      for (var supertype in element.allSupertypes) {
        var supertypeClass = typeToDeclaration[supertype];
        if (supertypeClass != null) visit(supertypeClass);
      }
      seen.add(type);

      _isInstanceField(f) =>
          f is FieldDeclaration && !f.isStatic && !f.fields.isConst;

      if (_options.inferFromOverrides) {
        // Infer field types from overrides first, otherwise from initializers.
        var pending = new Set<VariableDeclaration>();
        cls.members
            .where(_isInstanceField)
            .forEach((f) => _inferFieldTypeFromOverride(f, pending));
        if (pending.isNotEmpty) _inferVariableFromInitializer(pending);

        // Infer return-types from overrides
        cls.members
            .where((m) => m is MethodDeclaration && !m.isStatic)
            .forEach(_inferMethodReturnTypeFromOverride);
      } else {
        _inferVariableFromInitializer(cls.members
            .where(_isInstanceField)
            .expand((f) => f.fields.variables));
      }
    }
    classes.forEach(visit);
  }

  /// Attempts to infer the type on [field] from overridden fields or getters if
  /// a type was not specified. If no type could be inferred, but it contains an
  /// initializer, we add it to [pending] so we can try to infer it using the
  /// initializer type instead.
  void _inferFieldTypeFromOverride(
      FieldDeclaration field, Set<VariableDeclaration> pending) {
    var variables = field.fields;
    for (var variable in variables.variables) {
      var varElement = variable.element;
      if (!varElement.type.isDynamic || variables.type != null) continue;
      var getter = varElement.getter;
      // Note: type will be null only when there are no overrides. When some
      // override's type was not specified and couldn't be inferred, the type
      // here will be dynamic.
      var type = searchTypeFor(varElement.enclosingElement.type, getter);

      // Infer from the RHS when there are no overrides.
      if (type == null) {
        if (variable.initializer != null) pending.add(variable);
        continue;
      }

      // When field is final and overriden getter is dynamic, we can infer from
      // the RHS without breaking subtyping rules (return type is covariant).
      if (type.returnType.isDynamic) {
        if (variables.isFinal && variable.initializer != null) {
          pending.add(variable);
        }
        continue;
      }

      // Use type from the override.
      var newType = type.returnType;
      varElement.type = newType;
      varElement.getter.returnType = newType;
      if (!varElement.isFinal) varElement.setter.parameters[0].type = newType;
    }
  }

  void _inferMethodReturnTypeFromOverride(MethodDeclaration method) {
    var methodElement = method.element;
    if ((methodElement is MethodElement ||
            methodElement is PropertyAccessorElement) &&
        methodElement.returnType.isDynamic &&
        method.returnType == null) {
      var type =
          searchTypeFor(methodElement.enclosingElement.type, methodElement);
      if (type != null && !type.returnType.isDynamic) {
        methodElement.returnType = type.returnType;
      }
    }
  }

  void _inferVariableFromInitializer(Iterable<VariableDeclaration> variables) {
    for (var variable in variables) {
      var declaration = variable.parent;
      // Only infer on variables that don't have any declared type.
      if (declaration.type != null) continue;
      if (_options.onlyInferConstsAndFinalFields &&
          !declaration.isFinal &&
          !declaration.isConst) {
        return;
      }
      var initializer = variable.initializer;
      if (initializer == null) continue;
      var type = initializer.staticType;
      if (type == null || type.isDynamic || type.isBottom) continue;
      if (!_canInferFrom(initializer)) continue;
      var element = variable.element;
      // Note: it's ok to update the type here, since initializer.staticType
      // is already computed for all declarations in the library cycle. The
      // new types will only be propagated on a second run of the
      // ResolverVisitor.
      element.type = type;
      element.getter.returnType = type;
      if (!element.isFinal && !element.isConst) {
        element.setter.parameters[0].type = type;
      }
    }
  }

  bool _canInferFrom(Expression expression) {
    if (expression is Literal) return true;
    if (expression is InstanceCreationExpression) return true;
    if (expression is FunctionExpression) return true;
    if (expression is AsExpression) return true;
    if (expression is CascadeExpression) {
      return _canInferFrom(expression.target);
    }
    if (expression is SimpleIdentifier || expression is PropertyAccess) {
      return _options.inferTransitively;
    }
    if (expression is PrefixedIdentifier) {
      if (expression.staticElement is PropertyAccessorElement) {
        return _options.inferTransitively;
      }
      return _canInferFrom(expression.identifier);
    }
    if (expression is MethodInvocation) {
      return _canInferFrom(expression.target);
    }
    if (expression is BinaryExpression) {
      return _canInferFrom(expression.leftOperand);
    }
    if (expression is ConditionalExpression) {
      return _canInferFrom(expression.thenExpression) &&
          _canInferFrom(expression.elseExpression);
    }
    if (expression is PrefixExpression) {
      return _canInferFrom(expression.operand);
    }
    if (expression is PostfixExpression) {
      return _canInferFrom(expression.operand);
    }
    return false;
  }
}

/// Overrides the default [ResolverVisitor] to support type inference in
/// [LibraryResolverWithInference] above.
///
/// Before inference, this visitor is used to resolve top-levels, classes, and
/// fields, but nothing withihn method bodies. After inference, this visitor is
/// used again to step into method bodies and complete resolution as a second
/// phase.
class RestrictedResolverVisitor extends ResolverVisitor {
  final TypeProvider _typeProvider;

  /// Whether to skip resolution within method bodies.
  final bool skipMethodBodies;

  RestrictedResolverVisitor(Library library, Source source,
      TypeProvider typeProvider, ResolverOptions options, this.skipMethodBodies)
      : _typeProvider = typeProvider,
        super.con1(library, source, typeProvider,
            typeAnalyzerFactory: RestrictedStaticTypeAnalyzer.constructor);

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

  @override
  Object visitNode(AstNode node) {
    if (skipMethodBodies &&
        (node is FunctionBody ||
            node is FunctionExpression ||
            node is FunctionExpressionInvocation ||
            node is SuperConstructorInvocation ||
            node is RedirectingConstructorInvocation ||
            node is Annotation ||
            node is Comment)) {
      return null;
    }
    assert(node is! Statement || !skipMethodBodies);
    return super.visitNode(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    if (skipMethodBodies) {
      node.accept(elementResolver_J2DAccessor);
      node.accept(typeAnalyzer_J2DAccessor);
      return null;
    } else {
      return super.visitMethodDeclaration(node);
    }
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    if (skipMethodBodies) {
      node.accept(elementResolver_J2DAccessor);
      node.accept(typeAnalyzer_J2DAccessor);
      return null;
    } else {
      return super.visitFunctionDeclaration(node);
    }
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (skipMethodBodies) {
      node.accept(elementResolver_J2DAccessor);
      node.accept(typeAnalyzer_J2DAccessor);
      return null;
    } else {
      return super.visitConstructorDeclaration(node);
    }
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

  static constructor(ResolverVisitor r) => new RestrictedStaticTypeAnalyzer(r);

  @override // to infer type from initializers
  visitVariableDeclaration(VariableDeclaration node) {
    _inferType(node);
    return super.visitVariableDeclaration(node);
  }

  /// Infer the type of a variable based on the initializer's type.
  void _inferType(VariableDeclaration node) {
    var initializer = node.initializer;
    if (initializer == null) return;

    var declaredType = (node.parent as VariableDeclarationList).type;
    if (declaredType != null) return;
    var element = node.element;
    if (element is! LocalVariableElement) return;
    if (element.type != _typeProvider.dynamicType) return;

    var type = initializer.staticType;
    if (type == null || type == _typeProvider.bottomType) return;
    element.type = type;
    if (element is PropertyInducingElement) {
      element.getter.returnType = type;
      if (!element.isFinal && !element.isConst) {
        element.setter.parameters[0].type = type;
      }
    }
  }

  @override // to propagate types to identifiers
  visitMethodInvocation(MethodInvocation node) {
    // TODO(sigmund): follow up with analyzer team - why is this needed?
    visitSimpleIdentifier(node.methodName);
    super.visitMethodInvocation(node);

    var e = node.methodName.staticElement;
    if (e is FunctionElement &&
        e.library.name == '_foreign_helper' &&
        e.name == 'JS') {
      // Fix types for JS builtin calls.
      //
      // This code was taken from analyzer. It's not super sophisticated:
      // only looks for the type name in dart:core, so we just copy it here.
      //
      // TODO(jmesserly): we'll likely need something that can handle a wider
      // variety of types, especially when we get to JS interop.
      var args = node.argumentList.arguments;
      if (args.isNotEmpty && args.first is SimpleStringLiteral) {
        var coreLib = _typeProvider.objectType.element.library;
        var classElem = coreLib.getType(args.first.stringValue);
        if (classElem != null) node.staticType = classElem.type;
      }
    }
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    // TODO(vsm): The static type of a conditional should be the LUB of the
    // then and else expressions.  The analyzer appears to compute dynamic when
    // one or the other is the null literal.  Remove this fix once the
    // corresponding analyzer bug is fixed:
    // https://code.google.com/p/dart/issues/detail?id=22854
    super.visitConditionalExpression(node);
    if (node.staticType.isDynamic) {
      var thenExpr = node.thenExpression;
      var elseExpr = node.elseExpression;
      if (thenExpr.staticType.isBottom) {
        node.staticType = elseExpr.staticType;
      } else if (elseExpr.staticType.isBottom) {
        node.staticType = thenExpr.staticType;
      }
    }
  }

  // Review note: no longer need to override visitFunctionExpression, this is
  // handled by the analyzer internally.
  // TODO(vsm): in visitbinaryExpression: check computeStaticReturnType result?
  // TODO(vsm): in visitFunctionDeclaration: Should we ever use the expression
  // type in a (...) => expr or just the written type?

}
