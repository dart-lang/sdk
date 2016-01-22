// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.summarize_ast;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/public_namespace_computer.dart';
import 'package:analyzer/src/summary/summarize_const_expr.dart';

/**
 * Serialize all the declarations in [compilationUnit] to an unlinked summary.
 */
UnlinkedUnitBuilder serializeAstUnlinked(CompilationUnit compilationUnit) {
  return new _SummarizeAstVisitor().serializeCompilationUnit(compilationUnit);
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single constant [Expression].
 */
class _ConstExprSerializer extends AbstractConstExprSerializer {
  final _SummarizeAstVisitor visitor;

  _ConstExprSerializer(this.visitor);

  EntityRefBuilder serializeIdentifier(Identifier identifier) {
    EntityRefBuilder b = new EntityRefBuilder();
    if (identifier is SimpleIdentifier) {
      b.reference = visitor.serializeReference(null, identifier.name);
    } else if (identifier is PrefixedIdentifier) {
      int prefix = visitor.serializeReference(null, identifier.prefix.name);
      b.reference =
          visitor.serializeReference(prefix, identifier.identifier.name);
    } else {
      throw new StateError(
          'Unexpected identifier type: ${identifier.runtimeType}');
    }
    return b;
  }

  @override
  EntityRefBuilder serializeType(TypeName node) {
    return visitor.serializeTypeName(node);
  }
}

/**
 * An [_OtherScopedEntity] is a [_ScopedEntity] that does not refer to a type
 * parameter.  Since we don't need to track any special information about these
 * types of scoped entities, it is a singleton class.
 */
class _OtherScopedEntity extends _ScopedEntity {
  static final _OtherScopedEntity _instance = new _OtherScopedEntity._();

  factory _OtherScopedEntity() => _instance;

  _OtherScopedEntity._();
}

/**
 * A [_Scope] represents a set of name/value pairs defined locally within a
 * limited span of a compilation unit.  (Note that the spec also uses the term
 * "scope" to refer to the set of names defined at top level within a
 * compilation unit, but we do not use [_Scope] for that purpose).
 */
class _Scope {
  /**
   * Names defined in this scope, and their meanings.
   */
  Map<String, _ScopedEntity> _definedNames = <String, _ScopedEntity>{};

  /**
   * Look up the meaning associated with the given [name], and return it.  If
   * [name] is not defined in this scope, return `null`.
   */
  _ScopedEntity operator [](String name) => _definedNames[name];

  /**
   * Let the given [name] refer to [entity] within this scope.
   */
  void operator []=(String name, _ScopedEntity entity) {
    _definedNames[name] = entity;
  }
}

/**
 * Base class for entities that can live inside a scope.
 */
abstract class _ScopedEntity {}

/**
 * A [_ScopedTypeParameter] is a [_ScopedEntity] that refers to a type
 * parameter of a class, typedef, or executable.
 */
class _ScopedTypeParameter extends _ScopedEntity {
  /**
   * Index of the type parameter within this scope.  Since summaries use De
   * Bruijn indices to refer to type parameters, which count upwards from the
   * innermost bound name, the last type parameter in the scope has an index of
   * 1, and each preceding type parameter has the next higher index.
   */
  final int index;

  _ScopedTypeParameter(this.index);
}

/**
 * Visitor used to create a summary from an AST.
 */
class _SummarizeAstVisitor extends SimpleAstVisitor {
  /**
   * List of objects which should be written to [UnlinkedUnit.classes].
   */
  final List<UnlinkedClassBuilder> classes = <UnlinkedClassBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.enums].
   */
  final List<UnlinkedEnumBuilder> enums = <UnlinkedEnumBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.executables]
   * or [UnlinkedClass.executables].
   */
  List<UnlinkedExecutableBuilder> executables = <UnlinkedExecutableBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.exports].
   */
  final List<UnlinkedExportNonPublicBuilder> exports =
      <UnlinkedExportNonPublicBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.parts].
   */
  final List<UnlinkedPartBuilder> parts = <UnlinkedPartBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.typedefs].
   */
  final List<UnlinkedTypedefBuilder> typedefs = <UnlinkedTypedefBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.variables] or
   * [UnlinkedClass.fields].
   */
  List<UnlinkedVariableBuilder> variables = <UnlinkedVariableBuilder>[];

  /**
   * The unlinked portion of the "imports table".  This is the list of objects
   * which should be written to [UnlinkedUnit.imports].
   */
  final List<UnlinkedImportBuilder> unlinkedImports = <UnlinkedImportBuilder>[];

  /**
   * The unlinked portion of the "references table".  This is the list of
   * objects which should be written to [UnlinkedUnit.references].
   */
  final List<UnlinkedReferenceBuilder> unlinkedReferences =
      <UnlinkedReferenceBuilder>[new UnlinkedReferenceBuilder()];

  /**
   * The [ClassDeclaration] currently being summarized, or `null` if we are not
   * currently visiting a [ClassDeclaration].
   */
  ClassDeclaration currentClassDeclaration;

  /**
   * Map associating names used as prefixes in this compilation unit with their
   * associated indices into [UnlinkedUnit.references].
   */
  final Map<String, int> prefixIndices = <String, int>{};

  /**
   * List of [_Scope]s currently in effect.  This is used to resolve type names
   * to type parameters within classes, typedefs, and executables.
   */
  final List<_Scope> scopes = <_Scope>[];

  /**
   * True if 'dart:core' has been explicitly imported.
   */
  bool hasCoreBeenImported = false;

  /**
   * Names referenced by this compilation unit.  Structured as a map from
   * prefix index to (map from name to reference table index), where "prefix
   * index" means the index into [UnlinkedUnit.references] of the prefix (or
   * `null` if there is no prefix), and "reference table index" means the index
   * into [UnlinkedUnit.references] for the name itself.
   */
  final Map<int, Map<String, int>> nameToReference = <int, Map<String, int>>{};

  /**
   * If the library has a library directive, the library name derived from it.
   * Otherwise `null`.
   */
  String libraryName;

  /**
   * If the library has a library directive, the offset of the library name.
   * Otherwise `null`.
   */
  int libraryNameOffset;

  /**
   * If the library has a library directive, the length of the library name, as
   * it appears in the source file.  Otherwise `null`.
   */
  int libraryNameLength;

  /**
   * If the library has a library directive, the documentation comment for it
   * (if any).  Otherwise `null`.
   */
  UnlinkedDocumentationCommentBuilder libraryDocumentationComment;

  /**
   * The number of slot ids which have been assigned to this compilation unit.
   */
  int numSlots = 0;

  /**
   * Create a slot id for storing a propagated or inferred type.
   */
  int assignTypeSlot() => ++numSlots;

  /**
   * Build a [_Scope] object containing the names defined within the body of a
   * class declaration.
   */
  _Scope buildClassMemberScope(NodeList<ClassMember> members) {
    _Scope scope = new _Scope();
    for (ClassMember member in members) {
      // TODO(paulbery): consider replacing these if-tests with dynamic method
      // dispatch.
      if (member is MethodDeclaration) {
        if (member.isSetter || member.isOperator) {
          // We don't have to handle setters or operators because the only
          // thing we look up is type names.
        } else {
          scope[member.name.name] = new _OtherScopedEntity();
        }
      } else if (member is FieldDeclaration) {
        for (VariableDeclaration field in member.fields.variables) {
          // A field declaration introduces two names, one with a trailing `=`.
          // We don't have to worry about the one with a trailing `=` because
          // the only thing we look up is type names.
          scope[field.name.name] = new _OtherScopedEntity();
        }
      }
    }
    return scope;
  }

  /**
   * Try to find a field with the given [name] in the current class declaration
   * and return its type.  If no field is found, or there isn't a current
   * class declaration, return null.
   */
  TypeName getFieldType(String name) {
    if (currentClassDeclaration == null) {
      return null;
    }
    for (ClassMember member in currentClassDeclaration.members) {
      if (member is FieldDeclaration) {
        for (VariableDeclaration variable in member.fields.variables) {
          if (variable.name.name == name) {
            return member.fields.type;
          }
        }
      }
    }
    return null;
  }

  /**
   * Serialize a [ClassDeclaration] or [ClassTypeAlias] into an [UnlinkedClass]
   * and store the result in [classes].
   */
  void serializeClass(
      Token abstractKeyword,
      String name,
      int nameOffset,
      TypeParameterList typeParameters,
      TypeName superclass,
      WithClause withClause,
      ImplementsClause implementsClause,
      NodeList<ClassMember> members,
      bool isMixinApplication,
      Comment documentationComment) {
    int oldScopesLength = scopes.length;
    List<UnlinkedExecutableBuilder> oldExecutables = executables;
    executables = <UnlinkedExecutableBuilder>[];
    List<UnlinkedVariableBuilder> oldVariables = variables;
    variables = <UnlinkedVariableBuilder>[];
    _TypeParameterScope typeParameterScope = new _TypeParameterScope();
    scopes.add(typeParameterScope);
    UnlinkedClassBuilder b = new UnlinkedClassBuilder();
    b.name = name;
    b.nameOffset = nameOffset;
    b.isMixinApplication = isMixinApplication;
    b.typeParameters =
        serializeTypeParameters(typeParameters, typeParameterScope);
    if (superclass != null) {
      b.supertype = serializeTypeName(superclass);
    }
    if (withClause != null) {
      b.mixins = withClause.mixinTypes.map(serializeTypeName).toList();
    }
    if (implementsClause != null) {
      b.interfaces =
          implementsClause.interfaces.map(serializeTypeName).toList();
    }
    if (members != null) {
      scopes.add(buildClassMemberScope(members));
      for (ClassMember member in members) {
        member.accept(this);
      }
      scopes.removeLast();
    }
    b.executables = executables;
    b.fields = variables;
    b.isAbstract = abstractKeyword != null;
    b.documentationComment = serializeDocumentation(documentationComment);
    classes.add(b);
    scopes.removeLast();
    assert(scopes.length == oldScopesLength);
    executables = oldExecutables;
    variables = oldVariables;
  }

  /**
   * Serialize a [Combinator] into an [UnlinkedCombinator].
   */
  UnlinkedCombinatorBuilder serializeCombinator(Combinator combinator) {
    UnlinkedCombinatorBuilder b = new UnlinkedCombinatorBuilder();
    if (combinator is ShowCombinator) {
      b.shows =
          combinator.shownNames.map((SimpleIdentifier id) => id.name).toList();
    } else if (combinator is HideCombinator) {
      b.hides =
          combinator.hiddenNames.map((SimpleIdentifier id) => id.name).toList();
    } else {
      throw new StateError(
          'Unexpected combinator type: ${combinator.runtimeType}');
    }
    return b;
  }

  /**
   * Main entry point for serializing an AST.
   */
  UnlinkedUnitBuilder serializeCompilationUnit(
      CompilationUnit compilationUnit) {
    compilationUnit.directives.accept(this);
    if (!hasCoreBeenImported) {
      unlinkedImports.add(new UnlinkedImportBuilder(isImplicit: true));
    }
    compilationUnit.declarations.accept(this);
    UnlinkedUnitBuilder b = new UnlinkedUnitBuilder();
    b.libraryName = libraryName;
    b.libraryNameOffset = libraryNameOffset;
    b.libraryNameLength = libraryNameLength;
    b.libraryDocumentationComment = libraryDocumentationComment;
    b.classes = classes;
    b.enums = enums;
    b.executables = executables;
    b.exports = exports;
    b.imports = unlinkedImports;
    b.parts = parts;
    b.references = unlinkedReferences;
    b.typedefs = typedefs;
    b.variables = variables;
    b.publicNamespace = computePublicNamespace(compilationUnit);
    return b;
  }

  /**
   * Serialize the given [expression], creating an [UnlinkedConstBuilder].
   */
  UnlinkedConstBuilder serializeConstExpr(Expression expression) {
    _ConstExprSerializer serializer = new _ConstExprSerializer(this);
    serializer.serialize(expression);
    return serializer.toBuilder();
  }

  /**
   * Serialize a [Comment] node into an [UnlinkedDocumentationComment] object.
   */
  UnlinkedDocumentationCommentBuilder serializeDocumentation(
      Comment documentationComment) {
    if (documentationComment == null) {
      return null;
    }
    String text = documentationComment.tokens
        .map((Token t) => t.toString())
        .join()
        .replaceAll('\r\n', '\n');
    return new UnlinkedDocumentationCommentBuilder(
        text: text,
        offset: documentationComment.offset,
        length: documentationComment.length);
  }

  /**
   * Serialize a [FunctionDeclaration] or [MethodDeclaration] into an
   * [UnlinkedExecutable].
   */
  UnlinkedExecutableBuilder serializeExecutable(
      SimpleIdentifier name,
      bool isGetter,
      bool isSetter,
      TypeName returnType,
      FormalParameterList formalParameters,
      FunctionBody body,
      bool isTopLevel,
      bool isStatic,
      Comment documentationComment,
      TypeParameterList typeParameters,
      bool isExternal) {
    int oldScopesLength = scopes.length;
    _TypeParameterScope typeParameterScope = new _TypeParameterScope();
    scopes.add(typeParameterScope);
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder();
    String nameString = name.name;
    if (isGetter) {
      b.kind = UnlinkedExecutableKind.getter;
    } else if (isSetter) {
      b.kind = UnlinkedExecutableKind.setter;
      nameString = '$nameString=';
    } else {
      b.kind = UnlinkedExecutableKind.functionOrMethod;
    }
    b.isAbstract = body is EmptyFunctionBody;
    b.name = nameString;
    b.nameOffset = name.offset;
    b.typeParameters =
        serializeTypeParameters(typeParameters, typeParameterScope);
    if (!isTopLevel) {
      b.isStatic = isStatic;
    }
    b.returnType = serializeTypeName(returnType);
    b.hasImplicitReturnType = returnType == null;
    b.isExternal = isExternal;
    if (formalParameters != null) {
      b.parameters = formalParameters.parameters
          .map((FormalParameter p) => p.accept(this))
          .toList();
    }
    b.documentationComment = serializeDocumentation(documentationComment);
    scopes.removeLast();
    assert(scopes.length == oldScopesLength);
    return b;
  }

  /**
   * Serialize the return type and parameters of a function-typed formal
   * parameter and store them in [b].
   */
  void serializeFunctionTypedParameterDetails(UnlinkedParamBuilder b,
      TypeName returnType, FormalParameterList parameters) {
    EntityRefBuilder serializedReturnType = serializeTypeName(returnType);
    if (serializedReturnType != null) {
      b.type = serializedReturnType;
    }
    b.parameters = parameters.parameters
        .map((FormalParameter p) => p.accept(this))
        .toList();
  }

  /**
   * Serialize a [FieldFormalParameter], [FunctionTypedFormalParameter], or
   * [SimpleFormalParameter] into an [UnlinkedParam].
   */
  UnlinkedParamBuilder serializeParameter(NormalFormalParameter node) {
    UnlinkedParamBuilder b = new UnlinkedParamBuilder();
    b.name = node.identifier.name;
    b.nameOffset = node.identifier.offset;
    switch (node.kind) {
      case ParameterKind.REQUIRED:
        b.kind = UnlinkedParamKind.required;
        break;
      case ParameterKind.POSITIONAL:
        b.kind = UnlinkedParamKind.positional;
        break;
      case ParameterKind.NAMED:
        b.kind = UnlinkedParamKind.named;
        break;
      default:
        throw new StateError('Unexpected parameter kind: ${node.kind}');
    }
    return b;
  }

  /**
   * Serialize a reference to a top level name declared elsewhere, by adding an
   * entry to the references table if necessary.  If [prefixIndex] is not null,
   * the reference is associated with the prefix having the given index in the
   * references table.
   */
  int serializeReference(int prefixIndex, String name) => nameToReference
          .putIfAbsent(prefixIndex, () => <String, int>{})
          .putIfAbsent(name, () {
        int index = unlinkedReferences.length;
        unlinkedReferences.add(new UnlinkedReferenceBuilder(
            prefixReference: prefixIndex, name: name));
        return index;
      });

  /**
   * Serialize a type name (which might be defined in a nested scope, at top
   * level within this library, or at top level within an imported library) to
   * a [EntityRef].  Note that this method does the right thing if the
   * name doesn't refer to an entity other than a type (e.g. a class member).
   */
  EntityRefBuilder serializeTypeName(TypeName node) {
    EntityRefBuilder b = new EntityRefBuilder();
    if (node == null) {
      b.reference = serializeReference(null, 'dynamic');
    } else {
      Identifier identifier = node.name;
      if (identifier is SimpleIdentifier) {
        String name = identifier.name;
        int indexOffset = 0;
        for (int i = scopes.length - 1; i >= 0; i--) {
          _Scope scope = scopes[i];
          _ScopedEntity entity = scope[name];
          if (entity != null) {
            if (entity is _ScopedTypeParameter) {
              b.paramReference = indexOffset + entity.index;
              return b;
            } else {
              // None of the other things that can be declared in local scopes
              // are types, so this is an error and should be treated as a
              // reference to `dynamic`.
              b.reference = serializeReference(null, 'dynamic');
              return b;
            }
          }
          if (scope is _TypeParameterScope) {
            indexOffset += scope.length;
          }
        }
        b.reference = serializeReference(null, name);
      } else if (identifier is PrefixedIdentifier) {
        int prefixIndex = prefixIndices.putIfAbsent(identifier.prefix.name,
            () => serializeReference(null, identifier.prefix.name));
        b.reference =
            serializeReference(prefixIndex, identifier.identifier.name);
      } else {
        throw new StateError(
            'Unexpected identifier type: ${identifier.runtimeType}');
      }
      if (node.typeArguments != null) {
        // Trailing type arguments of type 'dynamic' should be omitted.
        NodeList<TypeName> args = node.typeArguments.arguments;
        int numArgsToSerialize = args.length;
        while (
            numArgsToSerialize > 0 && isDynamic(args[numArgsToSerialize - 1])) {
          --numArgsToSerialize;
        }
        if (numArgsToSerialize > 0) {
          List<EntityRefBuilder> serializedArguments = <EntityRefBuilder>[];
          for (int i = 0; i < numArgsToSerialize; i++) {
            serializedArguments.add(serializeTypeName(args[i]));
          }
          b.typeArguments = serializedArguments;
        }
      }
    }
    return b;
  }

  /**
   * Serialize the given [typeParameters] into a list of [UnlinkedTypeParam]s,
   * and also store them in [typeParameterScope].
   */
  List<UnlinkedTypeParamBuilder> serializeTypeParameters(
      TypeParameterList typeParameters,
      _TypeParameterScope typeParameterScope) {
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters.typeParameters.length; i++) {
        TypeParameter typeParameter = typeParameters.typeParameters[i];
        typeParameterScope[typeParameter.name.name] =
            new _ScopedTypeParameter(typeParameters.typeParameters.length - i);
      }
      return typeParameters.typeParameters.map(visitTypeParameter).toList();
    }
    return const <UnlinkedTypeParamBuilder>[];
  }

  /**
   * Serialize the given [variables] into [UnlinkedVariable]s, and store them
   * in [this.variables].
   */
  void serializeVariables(VariableDeclarationList variables, bool isStatic,
      Comment documentationComment) {
    for (VariableDeclaration variable in variables.variables) {
      UnlinkedVariableBuilder b = new UnlinkedVariableBuilder();
      b.isFinal = variables.isFinal;
      b.isConst = variables.isConst;
      b.isStatic = isStatic;
      b.name = variable.name.name;
      b.nameOffset = variable.name.offset;
      b.type = serializeTypeName(variables.type);
      b.hasImplicitType = variables.type == null;
      b.documentationComment = serializeDocumentation(documentationComment);
      if (variable.isConst) {
        Expression initializer = variable.initializer;
        if (initializer != null) {
          b.constExpr = serializeConstExpr(initializer);
        }
      }
      if (variable.initializer != null &&
          (variables.isFinal || variables.isConst)) {
        b.propagatedTypeSlot = assignTypeSlot();
      }
      this.variables.add(b);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    currentClassDeclaration = node;
    TypeName superclass =
        node.extendsClause == null ? null : node.extendsClause.superclass;
    serializeClass(
        node.abstractKeyword,
        node.name.name,
        node.name.offset,
        node.typeParameters,
        superclass,
        node.withClause,
        node.implementsClause,
        node.members,
        false,
        node.documentationComment);
    currentClassDeclaration = null;
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    serializeClass(
        node.abstractKeyword,
        node.name.name,
        node.name.offset,
        node.typeParameters,
        node.superclass,
        node.withClause,
        node.implementsClause,
        null,
        true,
        node.documentationComment);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder();
    if (node.name != null) {
      b.name = node.name.name;
      b.nameOffset = node.name.offset;
    } else {
      b.nameOffset = node.returnType.offset;
    }
    b.parameters = node.parameters.parameters
        .map((FormalParameter p) => p.accept(this))
        .toList();
    b.kind = UnlinkedExecutableKind.constructor;
    b.isFactory = node.factoryKeyword != null;
    b.isConst = node.constKeyword != null;
    b.isExternal = node.externalKeyword != null;
    b.documentationComment = serializeDocumentation(node.documentationComment);
    executables.add(b);
  }

  @override
  UnlinkedParamBuilder visitDefaultFormalParameter(
      DefaultFormalParameter node) {
    return node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    UnlinkedEnumBuilder b = new UnlinkedEnumBuilder();
    b.name = node.name.name;
    b.nameOffset = node.name.offset;
    b.values = node.constants
        .map((EnumConstantDeclaration value) => new UnlinkedEnumValueBuilder(
            name: value.name.name, nameOffset: value.name.offset))
        .toList();
    b.documentationComment = serializeDocumentation(node.documentationComment);
    enums.add(b);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    UnlinkedExportNonPublicBuilder b = new UnlinkedExportNonPublicBuilder(
        uriOffset: node.uri.offset, uriEnd: node.uri.end, offset: node.offset);
    exports.add(b);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    serializeVariables(
        node.fields, node.staticKeyword != null, node.documentationComment);
  }

  @override
  UnlinkedParamBuilder visitFieldFormalParameter(FieldFormalParameter node) {
    UnlinkedParamBuilder b = serializeParameter(node);
    b.isInitializingFormal = true;
    if (node.type == null && node.parameters == null) {
      b.hasImplicitType = true;
    } else {
      b.isFunctionTyped = node.parameters != null;
      if (node.parameters != null) {
        serializeFunctionTypedParameterDetails(b, node.type, node.parameters);
      } else {
        TypeName typeName = node.type;
        if (typeName == null) {
          typeName = getFieldType(node.identifier.name);
        }
        b.type = serializeTypeName(typeName);
      }
    }
    return b;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    executables.add(serializeExecutable(
        node.name,
        node.isGetter,
        node.isSetter,
        node.returnType,
        node.functionExpression.parameters,
        node.functionExpression.body,
        true,
        false,
        node.documentationComment,
        node.functionExpression.typeParameters,
        node.externalKeyword != null));
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    int oldScopesLength = scopes.length;
    _TypeParameterScope typeParameterScope = new _TypeParameterScope();
    scopes.add(typeParameterScope);
    UnlinkedTypedefBuilder b = new UnlinkedTypedefBuilder();
    b.name = node.name.name;
    b.nameOffset = node.name.offset;
    b.typeParameters =
        serializeTypeParameters(node.typeParameters, typeParameterScope);
    EntityRefBuilder serializedReturnType = serializeTypeName(node.returnType);
    if (serializedReturnType != null) {
      b.returnType = serializedReturnType;
    }
    b.parameters = node.parameters.parameters
        .map((FormalParameter p) => p.accept(this))
        .toList();
    b.documentationComment = serializeDocumentation(node.documentationComment);
    typedefs.add(b);
    scopes.removeLast();
    assert(scopes.length == oldScopesLength);
  }

  @override
  UnlinkedParamBuilder visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) {
    UnlinkedParamBuilder b = serializeParameter(node);
    b.isFunctionTyped = true;
    serializeFunctionTypedParameterDetails(b, node.returnType, node.parameters);
    return b;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    UnlinkedImportBuilder b = new UnlinkedImportBuilder();
    if (node.uri.stringValue == 'dart:core') {
      hasCoreBeenImported = true;
    }
    b.offset = node.offset;
    b.combinators = node.combinators.map(serializeCombinator).toList();
    if (node.prefix != null) {
      b.prefixReference = serializeReference(null, node.prefix.name);
      b.prefixOffset = node.prefix.offset;
    }
    b.isDeferred = node.deferredKeyword != null;
    b.uri = node.uri.stringValue;
    b.uriOffset = node.uri.offset;
    b.uriEnd = node.uri.end;
    unlinkedImports.add(b);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    libraryName =
        node.name.components.map((SimpleIdentifier id) => id.name).join('.');
    libraryNameOffset = node.name.offset;
    libraryNameLength = node.name.length;
    libraryDocumentationComment =
        serializeDocumentation(node.documentationComment);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    executables.add(serializeExecutable(
        node.name,
        node.isGetter,
        node.isSetter,
        node.returnType,
        node.parameters,
        node.body,
        false,
        node.isStatic,
        node.documentationComment,
        node.typeParameters,
        node.externalKeyword != null));
  }

  @override
  void visitPartDirective(PartDirective node) {
    parts.add(new UnlinkedPartBuilder(
        uriOffset: node.uri.offset, uriEnd: node.uri.end));
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {}

  @override
  UnlinkedParamBuilder visitSimpleFormalParameter(SimpleFormalParameter node) {
    UnlinkedParamBuilder b = serializeParameter(node);
    b.type = serializeTypeName(node.type);
    b.hasImplicitType = node.type == null;
    return b;
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    serializeVariables(node.variables, false, node.documentationComment);
  }

  @override
  UnlinkedTypeParamBuilder visitTypeParameter(TypeParameter node) {
    UnlinkedTypeParamBuilder b = new UnlinkedTypeParamBuilder();
    b.name = node.name.name;
    b.nameOffset = node.name.offset;
    if (node.bound != null) {
      b.bound = serializeTypeName(node.bound);
    }
    return b;
  }

  /**
   * Helper method to determine if a given [typeName] refers to `dynamic`.
   */
  static bool isDynamic(TypeName typeName) {
    Identifier name = typeName.name;
    return name is SimpleIdentifier && name.name == 'dynamic';
  }
}

/**
 * A [_TypeParameterScope] is a [_Scope] which defines [_ScopedTypeParameter]s.
 */
class _TypeParameterScope extends _Scope {
  /**
   * Get the number of [_ScopedTypeParameter]s defined in this
   * [_TypeParameterScope].
   */
  int get length => _definedNames.length;
}
