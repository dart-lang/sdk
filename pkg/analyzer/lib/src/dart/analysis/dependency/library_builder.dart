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
  final List<Node> declaredNodes;

  /// The map of [declaredNodes], used for fast search.
  /// TODO(scheglov) consider using binary search instead.
  final Map<LibraryQualifiedName, Node> declaredNodeMap = {};

  /// The list of nodes exported from this library, either using `export`
  /// directives, or declared in this library.
  ///
  /// This list is sorted.
  List<Node> exportedNodes;

  /// The map of nodes that are visible in the library, either imported,
  /// or declared in this library.
  ///
  /// TODO(scheglov) support for imports with prefixes
  Map<String, Node> libraryScope;

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
/// [finish] is invoked to construct the full [Dependencies].
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

  /// Construct and return a new [Dependencies] with the given
  /// [tokenSignature] and all recorded references to external nodes. Clear
  /// data structures with recorded references and be ready to start recording
  /// references for a new node.
  Dependencies finish(List<int> tokenSignature);
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
  final List<Node> declaredNodes = [];

  /// The precomputed signature of the [uri].
  ///
  /// It is mixed into every API token signature, because for example even
  /// though types of two functions might be the same, their locations
  /// are different.
  List<int> uriSignature;

  /// The precomputed signature of the enclosing class name, or `null` if
  /// outside a class.
  ///
  /// It is mixed into every API token signature of every class member, because
  /// for example even though types of two methods might be the same, their
  /// locations are different.
  List<int> enclosingClassNameSignature;

  _LibraryBuilder(this.uri, this.units, this.referenceCollector);

  Library build() {
    uriSignature = (ApiSignature()..addString(uri.toString())).toByteList();

    _addImports();
    _addExports();

    // TODO(scheglov) import prefixes are shadowed by class members

    for (var unit in units) {
      _addUnit(unit);
    }
    declaredNodes.sort(Node.compare);

    return Library(uri, imports, exports, declaredNodes);
  }

  void _addClassOrMixin(ClassOrMixinDeclaration node) {
    enclosingClassNameSignature =
        (ApiSignature()..addString(node.name.name)).toByteList();

    var hasConstConstructor = node.members.any(
      (m) => m is ConstructorDeclaration && m.constKeyword != null,
    );

    List<Node> classTypeParameters;
    if (node.typeParameters != null) {
      classTypeParameters = <Node>[];
      for (var typeParameter in node.typeParameters.typeParameters) {
        classTypeParameters.add(Node(
          LibraryQualifiedName(uri, typeParameter.name.name),
          NodeKind.TYPE_PARAMETER,
          _computeApiDependencies(
            _computeNodeTokenSignature(typeParameter),
            typeParameter,
          ),
          Dependencies.none,
        ));
      }
      classTypeParameters.sort(Node.compare);
    }

    var classMembers = <Node>[];
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
      classMembers.add(Node(
        LibraryQualifiedName(uri, ''),
        NodeKind.CONSTRUCTOR,
        Dependencies.none,
        Dependencies.none,
      ));
    }

    var apiTokenSignature = _computeTokenSignature(
      node.beginToken,
      node.leftBracket,
    );

    var classNode = Node(
      LibraryQualifiedName(uri, node.name.name),
      node is MixinDeclaration ? NodeKind.MIXIN : NodeKind.CLASS,
      _computeApiDependencies(apiTokenSignature, node),
      Dependencies.none,
      classTypeParameters: classTypeParameters,
    );

    classMembers.sort(Node.compare);
    classNode.setClassMembers(classMembers);

    declaredNodes.add(classNode);
    enclosingClassNameSignature = null;
  }

  void _addClassTypeAlias(ClassTypeAlias node) {
    var apiTokenSignature = _computeNodeTokenSignature(node);
    declaredNodes.add(Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.CLASS_TYPE_ALIAS,
      _computeApiDependencies(apiTokenSignature, node),
      Dependencies.none,
    ));
  }

  void _addConstructor(List<Node> classMembers, ConstructorDeclaration node) {
    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendFormalParametersTokens(builder, node.parameters);
    var apiTokenSignature = builder.toByteList();

    classMembers.add(Node(
      LibraryQualifiedName(uri, node.name?.name ?? ''),
      NodeKind.CONSTRUCTOR,
      _computeApiDependencies(apiTokenSignature, node),
      Dependencies.none,
    ));
  }

  void _addEnum(EnumDeclaration node) {
    var enumTokenSignature = _newApiSignatureBuilder().toByteList();

    Dependencies fieldDependencies;
    {
      var builder = _newApiSignatureBuilder();
      builder.addString(node.name.name);
      _appendTokens(builder, node.leftBracket, node.rightBracket);
      fieldDependencies = Dependencies(builder.toByteList(), [], [], [], []);
    }

    var members = <Node>[];
    for (var constant in node.constants) {
      members.add(Node(
        LibraryQualifiedName(uri, constant.name.name),
        NodeKind.GETTER,
        fieldDependencies,
        Dependencies.none,
      ));
    }

    members.add(Node(
      LibraryQualifiedName(uri, 'index'),
      NodeKind.GETTER,
      fieldDependencies,
      Dependencies.none,
    ));

    members.add(Node(
      LibraryQualifiedName(uri, 'values'),
      NodeKind.GETTER,
      fieldDependencies,
      Dependencies.none,
    ));
    members.sort(Node.compare);

    var enumNode = Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.ENUM,
      Dependencies(enumTokenSignature, [], [], [], []),
      Dependencies.none,
    );
    enumNode.setClassMembers(members);

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

    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.returnType);
    _appendNodeTokens(builder, functionExpression.typeParameters);
    _appendFormalParametersTokens(builder, functionExpression.parameters);
    var apiTokenSignature = builder.toByteList();

    var rawName = node.name.name;
    var name = LibraryQualifiedName(uri, node.isSetter ? '$rawName=' : rawName);

    NodeKind kind;
    if (node.isGetter) {
      kind = NodeKind.GETTER;
    } else if (node.isSetter) {
      kind = NodeKind.SETTER;
    } else {
      kind = NodeKind.FUNCTION;
    }

    referenceCollector.appendTypeAnnotation(node.returnType);
    // TODO(scheglov) type parameters (their bounds)
    referenceCollector.appendFormalParameters(
      node.functionExpression.parameters,
    );
    var api = referenceCollector.finish(apiTokenSignature);

    var bodyNode = node.functionExpression.body;
    var implTokenSignature = _computeNodeTokenSignature(bodyNode);
    referenceCollector.appendFunctionBody(bodyNode);
    var impl = referenceCollector.finish(implTokenSignature);

    declaredNodes.add(Node(name, kind, api, impl));
  }

  void _addFunctionTypeAlias(FunctionTypeAlias node) {
    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.typeParameters);
    _appendNodeTokens(builder, node.returnType);
    _appendFormalParametersTokens(builder, node.parameters);
    var apiTokenSignature = builder.toByteList();

    declaredNodes.add(Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.FUNCTION_TYPE_ALIAS,
      _computeApiDependencies(apiTokenSignature, node),
      Dependencies.none,
    ));
  }

  void _addGenericTypeAlias(GenericTypeAlias node) {
    var functionType = node.functionType;

    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.typeParameters);
    _appendNodeTokens(builder, functionType.returnType);
    _appendNodeTokens(builder, functionType.typeParameters);
    _appendFormalParametersTokens(builder, functionType.parameters);
    var apiTokenSignature = builder.toByteList();

    declaredNodes.add(Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.GENERIC_TYPE_ALIAS,
      _computeApiDependencies(apiTokenSignature, node),
      Dependencies.none,
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

  void _addMethod(List<Node> classMembers, MethodDeclaration node) {
    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.returnType);
    _appendNodeTokens(builder, node.typeParameters);
    _appendFormalParametersTokens(builder, node.parameters);
    var apiTokenSignature = builder.toByteList();

    NodeKind kind;
    if (node.isGetter) {
      kind = NodeKind.GETTER;
    } else if (node.isSetter) {
      kind = NodeKind.SETTER;
    } else {
      kind = NodeKind.METHOD;
    }

    referenceCollector.appendTypeAnnotation(node.returnType);
    // TODO(scheglov) type parameters (their bounds)
    referenceCollector.appendFormalParameters(node.parameters);
    var api = referenceCollector.finish(apiTokenSignature);

    var implTokenSignature = _computeNodeTokenSignature(node.body);
    referenceCollector.appendFunctionBody(node.body);
    var impl = referenceCollector.finish(implTokenSignature);

    classMembers
        .add(Node(LibraryQualifiedName(uri, node.name.name), kind, api, impl));
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

  void _addVariables(List<Node> variableNodes, List<Annotation> metadata,
      VariableDeclarationList variables, bool appendInitializerToApi) {
    if (variables.isConst || variables.type == null) {
      appendInitializerToApi = true;
    }

    for (var variable in variables.variables) {
      var builder = _newApiSignatureBuilder();
      builder.addInt(variables.isConst ? 1 : 0); // const flag
      _appendMetadataTokens(builder, metadata);

      _appendNodeTokens(builder, variables.type);
      referenceCollector.appendTypeAnnotation(variables.type);

      if (appendInitializerToApi) {
        _appendNodeTokens(builder, variable.initializer);
        referenceCollector.appendExpression(variable.initializer);
      }

      var apiTokenSignature = builder.toByteList();
      var api = referenceCollector.finish(apiTokenSignature);

      var rawName = variable.name.name;
      variableNodes.add(
        Node(
          LibraryQualifiedName(uri, rawName),
          NodeKind.GETTER,
          api,
          Dependencies.none,
        ),
      );
      if (!variables.isConst && !variables.isFinal) {
        variableNodes.add(
          Node(
            LibraryQualifiedName(uri, '$rawName='),
            NodeKind.SETTER,
            api,
            Dependencies.none,
          ),
        );
      }
    }
  }

  /// Return the signature for all tokens of the [node].
  List<int> _computeNodeTokenSignature(AstNode node) {
    if (node == null) {
      return const <int>[];
    }
    return _computeTokenSignature(node.beginToken, node.endToken);
  }

  /// Return the signature for tokens from [begin] to [end] (both including).
  List<int> _computeTokenSignature(Token begin, Token end) {
    var signature = _newApiSignatureBuilder();
    _appendTokens(signature, begin, end);
    return signature.toByteList();
  }

  /// Return a new signature builder, primed with the current context salts.
  ApiSignature _newApiSignatureBuilder() {
    var builder = ApiSignature();
    builder.addBytes(uriSignature);
    if (enclosingClassNameSignature != null) {
      builder.addBytes(enclosingClassNameSignature);
    }
    return builder;
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
  static Dependencies _computeApiDependencies(
      List<int> tokenSignature, AstNode node,
      [AstNode node2]) {
    List<String> importPrefixes = [];
    List<String> unprefixedReferencedNames = [];
    List<List<String>> importPrefixedReferencedNames = [];
    return Dependencies(
      tokenSignature,
      unprefixedReferencedNames,
      importPrefixes,
      importPrefixedReferencedNames,
      const [],
    );
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
