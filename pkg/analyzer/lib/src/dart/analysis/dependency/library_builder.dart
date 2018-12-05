// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/summary/api_signature.dart';

/// Build [Library] that describes nodes and dependencies of the library
/// with the given [uri] and [units].
///
/// If the [units] are just parsed, then only token signatures and referenced
/// names of nodes can be computed. If the [units] are fully resolved, then
/// also class member references can be recorded.
Library buildLibrary(
  Uri uri,
  List<CompilationUnit> units,
  ReferenceCollector referenceCollector,
) {
  return _LibraryBuilder(uri, units, referenceCollector).build();
}

/// The `show` or `hide` namespace combinator.
class Combinator {
  final bool isShow;
  final List<String> names;

  Combinator(this.isShow, this.names);

  @override
  String toString() {
    if (isShow) {
      return 'show ' + names.join(', ');
    } else {
      return 'hide ' + names.join(', ');
    }
  }
}

/// The `export` directive.
class Export {
  /// The absolute URI of the exported library.
  final Uri uri;

  /// The list of namespace combinators to apply, not `null`.
  final List<Combinator> combinators;

  Export(this.uri, this.combinators);

  @override
  String toString() {
    return 'Export(uri: $uri, combinators: $combinators)';
  }
}

/// The `import` directive.
class Import {
  /// The absolute URI of the imported library.
  final Uri uri;

  /// The import prefix, or `null` if not specified.
  final String prefix;

  /// The list of namespace combinators to apply, not `null`.
  final List<Combinator> combinators;

  Import(this.uri, this.prefix, this.combinators);

  @override
  String toString() {
    return 'Import(uri: $uri, prefix: $prefix, combinators: $combinators)';
  }
}

/// The collection of imports, exports, and top-level nodes.
class Library {
  /// The absolute URI of the library.
  final Uri uri;

  /// The list of imports in this library.
  final List<Import> imports;

  /// The list of exports in this library.
  final List<Export> exports;

  /// The list of libraries that correspond to the [imports].
  List<Library> importedLibraries;

  /// The list of top-level nodes defined in the library.
  ///
  /// This list is sorted.
  final List<DependencyNode> declaredNodes;

  /// The map of [declaredNodes], used for fast search.
  /// TODO(scheglov) consider using binary search instead.
  final Map<DependencyName, DependencyNode> declaredNodeMap = {};

  /// The list of nodes exported from this library, either using `export`
  /// directives, or declared in this library.
  ///
  /// This list is sorted.
  List<DependencyNode> exportedNodes;

  /// The map of nodes that are visible in the library, either imported,
  /// or declared in this library.
  ///
  /// TODO(scheglov) support for imports with prefixes
  Map<String, DependencyNode> libraryScope;

  Library(this.uri, this.imports, this.exports, this.declaredNodes) {
    for (var node in declaredNodes) {
      declaredNodeMap[node.name] = node;
    }
  }

  @override
  String toString() => '$uri';
}

/// The interface for a class that collects information about external nodes
/// referenced by a node.
///
/// The workflow for using it is that the library builder creates a new
/// instance, fills it with names of import prefixes using [addImportPrefix].
/// Then for each node defined in the library, methods `appendXyz` called
/// zero or more times to record references to external names to record API or
/// implementation dependencies. When all dependencies of a node are appended,
/// [finish] is invoked to construct the full [DependencyNodeDependencies].
/// TODO(scheglov) In following CLs we will provide single implementation.
abstract class ReferenceCollector {
  final Uri libraryUri;

  ReferenceCollector(this.libraryUri);

  /// Record that the [name] is a name of an import prefix.
  ///
  /// So, when we see code like `prefix.foo` we know that `foo` should be
  /// resolved in the import scope that corresponds to `prefix` (unless the
  /// name `prefix` is shadowed by a local declaration).
  void addImportPrefix(String name);

  /// Collect external nodes referenced from the given [node].
  void appendExpression(Expression node);

  /// Collect external nodes referenced from the given [node].
  void appendFormalParameters(FormalParameterList node);

  /// Collect external nodes referenced from the given [node].
  void appendFunctionBody(FunctionBody node);

  /// Collect external nodes referenced from the given [node].
  void appendTypeAnnotation(TypeAnnotation node);

  /// Construct and return a new [DependencyNodeDependencies] with the given
  /// [tokenSignature] and all recorded references to external nodes. Clear
  /// data structures with recorded references and be ready to start recording
  /// references for a new node.
  DependencyNodeDependencies finish(List<int> tokenSignature);
}

class _LibraryBuilder {
  /// The URI of the library.
  final Uri uri;

  /// The units of the library, parsed or fully resolved.
  final List<CompilationUnit> units;

  /// The instance of the referenced names, class members collector.
  final ReferenceCollector referenceCollector;

  /// The list of imports in the library.
  final List<Import> imports = [];

  /// The list of exports in the library.
  final List<Export> exports = [];

  /// The top-level nodes declared in the library.
  final List<DependencyNode> declaredNodes = [];

  _LibraryBuilder(this.uri, this.units, this.referenceCollector);

  Library build() {
    _addImports();
    _addExports();

    // TODO(scheglov) import prefixes are shadowed by class members

    for (var unit in units) {
      _addUnit(unit);
    }
    declaredNodes.sort(DependencyNode.compare);

    return Library(uri, imports, exports, declaredNodes);
  }

  void _addClassOrMixin(ClassOrMixinDeclaration node) {
    var hasConstConstructor = node.members.any(
      (m) => m is ConstructorDeclaration && m.constKeyword != null,
    );

    List<DependencyNode> classTypeParameters;
    if (node.typeParameters != null) {
      classTypeParameters = <DependencyNode>[];
      for (var typeParameter in node.typeParameters.typeParameters) {
        classTypeParameters.add(DependencyNode(
          DependencyName(uri, typeParameter.name.name),
          DependencyNodeKind.TYPE_PARAMETER,
          _computeApiDependencies(
            _computeNodeTokenSignature(typeParameter),
            typeParameter,
          ),
          DependencyNodeDependencies.none,
        ));
      }
      classTypeParameters.sort(DependencyNode.compare);
    }

    var classMembers = <DependencyNode>[];
    var hasConstructor = false;
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        hasConstructor = true;
        _addConstructor(classMembers, member);
      } else if (member is FieldDeclaration) {
        _addVariables(
          classMembers,
          member.metadata,
          member.fields,
          hasConstConstructor,
        );
      } else if (member is MethodDeclaration) {
        _addMethod(classMembers, member);
      } else {
        throw UnimplementedError('(${member.runtimeType}) $member');
      }
    }

    if (!hasConstructor && node is ClassDeclaration) {
      classMembers.add(DependencyNode(
        DependencyName(uri, ''),
        DependencyNodeKind.CONSTRUCTOR,
        DependencyNodeDependencies.none,
        DependencyNodeDependencies.none,
      ));
    }

    var classTokenSignature = _computeTokenSignature(
      node.beginToken,
      node.leftBracket,
    );
    // TODO(scheglov) add library URI

    var classNode = DependencyNode(
      DependencyName(uri, node.name.name),
      node is MixinDeclaration
          ? DependencyNodeKind.MIXIN
          : DependencyNodeKind.CLASS,
      _computeApiDependencies(classTokenSignature, node),
      DependencyNodeDependencies.none,
      classTypeParameters: classTypeParameters,
    );

    classMembers.sort(DependencyNode.compare);
    classNode.setClassMembers(classMembers);

    declaredNodes.add(classNode);
  }

  void _addClassTypeAlias(ClassTypeAlias node) {
    var tokenSignature = _computeNodeTokenSignature(node);
    declaredNodes.add(DependencyNode(
      DependencyName(uri, node.name.name),
      DependencyNodeKind.CLASS_TYPE_ALIAS,
      _computeApiDependencies(tokenSignature, node),
      DependencyNodeDependencies.none,
    ));
  }

  void _addConstructor(
      List<DependencyNode> classMembers, ConstructorDeclaration node) {
    var signature = ApiSignature();
    _appendMetadataTokens(signature, node.metadata);
    _appendFormalParametersTokens(signature, node.parameters);
    var tokenSignature = signature.toByteList();

    classMembers.add(DependencyNode(
      DependencyName(uri, node.name?.name ?? ''),
      DependencyNodeKind.CONSTRUCTOR,
      _computeApiDependencies(tokenSignature, node),
      DependencyNodeDependencies.none,
    ));
  }

  void _addEnum(EnumDeclaration node) {
    var classMembers = <DependencyNode>[];
    for (var constant in node.constants) {
      classMembers.add(DependencyNode(
        DependencyName(uri, constant.name.name),
        DependencyNodeKind.GETTER,
        DependencyNodeDependencies.none,
        DependencyNodeDependencies.none,
      ));
    }
    classMembers.add(DependencyNode(
      DependencyName(uri, 'index'),
      DependencyNodeKind.GETTER,
      DependencyNodeDependencies.none,
      DependencyNodeDependencies.none,
    ));
    classMembers.add(DependencyNode(
      DependencyName(uri, 'values'),
      DependencyNodeKind.GETTER,
      DependencyNodeDependencies.none,
      DependencyNodeDependencies.none,
    ));
    classMembers.sort(DependencyNode.compare);

    var enumNode = DependencyNode(
      DependencyName(uri, node.name.name),
      DependencyNodeKind.ENUM,
      DependencyNodeDependencies.none,
      DependencyNodeDependencies.none,
    );
    enumNode.setClassMembers(classMembers);

    declaredNodes.add(enumNode);
  }

  /// Fill [exports] with information about exports.
  void _addExports() {
    for (var directive in units.first.directives) {
      if (directive is ExportDirective) {
        var refUri = directive.uri.stringValue;
        var importUri = uri.resolve(refUri);
        var combinators = _getCombinators(directive);
        exports.add(Export(importUri, combinators));
      }
    }
  }

  void _addFunction(FunctionDeclaration node) {
    var functionExpression = node.functionExpression;

    var signature = ApiSignature();
    _appendMetadataTokens(signature, node.metadata);
    _appendNodeTokens(signature, node.returnType);
    _appendNodeTokens(signature, functionExpression.typeParameters);
    _appendFormalParametersTokens(signature, functionExpression.parameters);
    var tokenSignature = signature.toByteList();

    var rawName = node.name.name;
    var name = DependencyName(uri, node.isSetter ? '$rawName=' : rawName);

    DependencyNodeKind kind;
    if (node.isGetter) {
      kind = DependencyNodeKind.GETTER;
    } else if (node.isSetter) {
      kind = DependencyNodeKind.SETTER;
    } else {
      kind = DependencyNodeKind.FUNCTION;
    }

    referenceCollector.appendTypeAnnotation(node.returnType);
    referenceCollector.appendFormalParameters(
      node.functionExpression.parameters,
    );
    var api = referenceCollector.finish(tokenSignature);

    var bodyNode = node.functionExpression.body;
    var implTokenSignature = _computeNodeTokenSignature(bodyNode);
    referenceCollector.appendFunctionBody(bodyNode);
    var impl = referenceCollector.finish(implTokenSignature);

    declaredNodes.add(DependencyNode(name, kind, api, impl));
  }

  void _addFunctionTypeAlias(FunctionTypeAlias node) {
    var signature = ApiSignature();
    _appendMetadataTokens(signature, node.metadata);
    _appendNodeTokens(signature, node.typeParameters);
    _appendNodeTokens(signature, node.returnType);
    _appendFormalParametersTokens(signature, node.parameters);
    var tokenSignature = signature.toByteList();

    declaredNodes.add(DependencyNode(
      DependencyName(uri, node.name.name),
      DependencyNodeKind.FUNCTION_TYPE_ALIAS,
      _computeApiDependencies(tokenSignature, node),
      DependencyNodeDependencies.none,
    ));
  }

  void _addGenericTypeAlias(GenericTypeAlias node) {
    var functionType = node.functionType;

    var signature = ApiSignature();
    _appendMetadataTokens(signature, node.metadata);
    _appendNodeTokens(signature, node.typeParameters);
    _appendNodeTokens(signature, functionType.returnType);
    _appendNodeTokens(signature, functionType.typeParameters);
    _appendFormalParametersTokens(signature, functionType.parameters);
    var tokenSignature = signature.toByteList();

    declaredNodes.add(DependencyNode(
      DependencyName(uri, node.name.name),
      DependencyNodeKind.GENERIC_TYPE_ALIAS,
      _computeApiDependencies(tokenSignature, node),
      DependencyNodeDependencies.none,
    ));
  }

  /// Fill [imports] with information about imports.
  void _addImports() {
    var hasDartCoreImport = false;
    for (var directive in units.first.directives) {
      if (directive is ImportDirective) {
        var refUri = directive.uri.stringValue;
        var importUri = uri.resolve(refUri);

        if (importUri.toString() == 'dart:core') {
          hasDartCoreImport = true;
        }

        var combinators = _getCombinators(directive);

        imports.add(Import(importUri, directive.prefix?.name, combinators));

        if (directive.prefix != null) {
          referenceCollector.addImportPrefix(directive.prefix.name);
        }
      }
    }

    if (!hasDartCoreImport) {
      imports.add(Import(Uri.parse('dart:core'), null, []));
    }
  }

  void _addMethod(List<DependencyNode> classMembers, MethodDeclaration node) {
    var signature = ApiSignature();
    _appendMetadataTokens(signature, node.metadata);
    _appendNodeTokens(signature, node.returnType);
    _appendNodeTokens(signature, node.typeParameters);
    _appendFormalParametersTokens(signature, node.parameters);
    var tokenSignature = signature.toByteList();

    DependencyNodeKind kind;
    if (node.isGetter) {
      kind = DependencyNodeKind.GETTER;
    } else if (node.isSetter) {
      kind = DependencyNodeKind.SETTER;
    } else {
      kind = DependencyNodeKind.METHOD;
    }

    referenceCollector.appendTypeAnnotation(node.returnType);
    referenceCollector.appendFormalParameters(node.parameters);
    var api = referenceCollector.finish(tokenSignature);

    var implTokenSignature = _computeNodeTokenSignature(node.body);
    referenceCollector.appendFunctionBody(node.body);
    var impl = referenceCollector.finish(implTokenSignature);

    classMembers.add(
        DependencyNode(DependencyName(uri, node.name.name), kind, api, impl));
  }

  void _addUnit(CompilationUnit unit) {
    for (var declaration in unit.declarations) {
      if (declaration is ClassOrMixinDeclaration) {
        _addClassOrMixin(declaration);
      } else if (declaration is ClassTypeAlias) {
        _addClassTypeAlias(declaration);
      } else if (declaration is EnumDeclaration) {
        _addEnum(declaration);
      } else if (declaration is FunctionDeclaration) {
        _addFunction(declaration);
      } else if (declaration is FunctionTypeAlias) {
        _addFunctionTypeAlias(declaration);
      } else if (declaration is GenericTypeAlias) {
        _addGenericTypeAlias(declaration);
      } else if (declaration is TopLevelVariableDeclaration) {
        _addVariables(
          declaredNodes,
          declaration.metadata,
          declaration.variables,
          false,
        );
      } else {
        throw UnimplementedError('(${declaration.runtimeType}) $declaration');
      }
    }
  }

  void _addVariables(
      List<DependencyNode> variableNodes,
      List<Annotation> metadata,
      VariableDeclarationList variables,
      bool appendInitializerToApi) {
    if (variables.isConst || variables.type == null) {
      appendInitializerToApi = true;
    }

    for (var variable in variables.variables) {
      var signature = ApiSignature();
      signature.addInt(variables.isConst ? 1 : 0); // const flag
      _appendMetadataTokens(signature, metadata);

      _appendNodeTokens(signature, variables.type);
      referenceCollector.appendTypeAnnotation(variables.type);

      if (appendInitializerToApi) {
        _appendNodeTokens(signature, variable.initializer);
        referenceCollector.appendExpression(variable.initializer);
      }

      var tokenSignature = signature.toByteList();
      var api = referenceCollector.finish(tokenSignature);

      var rawName = variable.name.name;
      variableNodes.add(
        DependencyNode(
          DependencyName(uri, rawName),
          DependencyNodeKind.GETTER,
          api,
          DependencyNodeDependencies.none,
        ),
      );
      if (!variables.isConst && !variables.isFinal) {
        variableNodes.add(
          DependencyNode(
            DependencyName(uri, '$rawName='),
            DependencyNodeKind.SETTER,
            api,
            DependencyNodeDependencies.none,
          ),
        );
      }
    }
  }

  /// Append tokens of the given [parameters] to the [signature].
  static void _appendFormalParametersTokens(
      ApiSignature signature, FormalParameterList parameters) {
    if (parameters == null) return;

    for (var parameter in parameters.parameters) {
      if (parameter.isRequired) {
        signature.addInt(1);
      } else if (parameter.isOptionalPositional) {
        signature.addInt(2);
      } else {
        signature.addInt(3);
      }

      // If a simple not named parameter, we don't need its name.
      // We should be careful to include also annotations.
      if (parameter is SimpleFormalParameter && parameter.type != null) {
        _appendTokens(
          signature,
          parameter.beginToken,
          parameter.type.endToken,
        );
        continue;
      }

      // We don't know anything better than adding the whole parameter.
      _appendNodeTokens(signature, parameter);
    }
  }

  static void _appendMetadataTokens(
      ApiSignature signature, List<Annotation> metadata) {
    if (metadata != null) {
      for (var annotation in metadata) {
        _appendNodeTokens(signature, annotation);
      }
    }
  }

  /// Append tokens of the given [node] to the [signature].
  static void _appendNodeTokens(ApiSignature signature, AstNode node) {
    if (node != null) {
      _appendTokens(signature, node.beginToken, node.endToken);
    }
  }

  /// Append tokens from [begin] to [end] (both including) to the [signature].
  static void _appendTokens(ApiSignature signature, Token begin, Token end) {
    if (begin is CommentToken) {
      begin = (begin as CommentToken).parent;
    }

    Token token = begin;
    while (token != null) {
      signature.addString(token.lexeme);

      if (token == end) {
        break;
      }

      var nextToken = token.next;
      if (nextToken == token) {
        break;
      }

      token = nextToken;
    }
  }

  /// TODO(scheglov) Replace all uses with [referenceCollector].
  static DependencyNodeDependencies _computeApiDependencies(
      List<int> tokenSignature, AstNode node,
      [AstNode node2]) {
    List<String> importPrefixes = [];
    List<String> unprefixedReferencedNames = [];
    List<List<String>> importPrefixedReferencedNames = [];
    return DependencyNodeDependencies(
      tokenSignature,
      unprefixedReferencedNames,
      importPrefixes,
      importPrefixedReferencedNames,
      const [],
    );
  }

  /// Return the signature for all tokens of the [node].
  static List<int> _computeNodeTokenSignature(AstNode node) {
    if (node == null) {
      return const <int>[];
    }
    return _computeTokenSignature(node.beginToken, node.endToken);
  }

  /// Return the signature for tokens from [begin] to [end] (both including).
  static List<int> _computeTokenSignature(Token begin, Token end) {
    var signature = ApiSignature();
    _appendTokens(signature, begin, end);
    return signature.toByteList();
  }

  /// Return [Combinator]s for the given import or export [directive].
  static List<Combinator> _getCombinators(NamespaceDirective directive) {
    var combinators = <Combinator>[];
    for (var combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        combinators.add(
          Combinator(
            true,
            combinator.shownNames.map((id) => id.name).toList(),
          ),
        );
      }
      if (combinator is HideCombinator) {
        combinators.add(
          Combinator(
            false,
            combinator.hiddenNames.map((id) => id.name).toList(),
          ),
        );
      }
    }
    return combinators;
  }
}
