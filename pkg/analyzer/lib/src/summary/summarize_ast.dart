// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.summarize_ast;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
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

  /**
   * If a constructor initializer expression is being serialized, the names of
   * the constructor parameters.  Otherwise `null`.
   */
  final Set<String> constructorParameterNames;

  _ConstExprSerializer(this.visitor, this.constructorParameterNames);

  @override
  bool isConstructorParameterName(String name) {
    return constructorParameterNames?.contains(name) ?? false;
  }

  @override
  void serializeAnnotation(Annotation annotation) {
    if (annotation.arguments == null) {
      assert(annotation.constructorName == null);
      serialize(annotation.name);
    } else {
      Identifier name = annotation.name;
      EntityRefBuilder constructor;
      if (name is PrefixedIdentifier && annotation.constructorName == null) {
        constructor = serializeConstructorName(
            new TypeName(name.prefix, null), name.identifier);
      } else {
        constructor = serializeConstructorName(
            new TypeName(annotation.name, null), annotation.constructorName);
      }
      serializeInstanceCreation(constructor, annotation.arguments);
    }
  }

  @override
  EntityRefBuilder serializeConstructorName(
      TypeName type, SimpleIdentifier name) {
    EntityRefBuilder typeBuilder = serializeType(type);
    if (name == null) {
      return typeBuilder;
    } else {
      int nameRef =
          visitor.serializeReference(typeBuilder.reference, name.name);
      return new EntityRefBuilder(
          reference: nameRef, typeArguments: typeBuilder.typeArguments);
    }
  }

  EntityRefBuilder serializeIdentifier(Identifier identifier) {
    EntityRefBuilder b = new EntityRefBuilder();
    if (identifier is SimpleIdentifier) {
      b.reference = visitor.serializeSimpleReference(identifier.name);
    } else if (identifier is PrefixedIdentifier) {
      int prefix = visitor.serializeSimpleReference(identifier.prefix.name);
      b.reference =
          visitor.serializeReference(prefix, identifier.identifier.name);
    } else {
      throw new StateError(
          'Unexpected identifier type: ${identifier.runtimeType}');
    }
    return b;
  }

  @override
  EntityRefBuilder serializePropertyAccess(PropertyAccess access) {
    Expression target = access.target;
    if (target is Identifier) {
      EntityRefBuilder targetRef = serializeIdentifier(target);
      return new EntityRefBuilder(
          reference: visitor.serializeReference(
              targetRef.reference, access.propertyName.name));
    } else {
      // TODO(scheglov) should we handle other targets in malformed constants?
      throw new StateError('Unexpected target type: ${target.runtimeType}');
    }
  }

  @override
  EntityRefBuilder serializeType(TypeName node) {
    return visitor.serializeTypeName(node);
  }
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
 * A [_ScopedClassMember] is a [_ScopedEntity] refers to a member of a class.
 */
class _ScopedClassMember extends _ScopedEntity {
  /**
   * The name of the class.
   */
  final String className;

  _ScopedClassMember(this.className);
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
class _SummarizeAstVisitor extends RecursiveAstVisitor {
  /**
   * List of objects which should be written to [UnlinkedUnit.classes].
   */
  final List<UnlinkedClassBuilder> classes = <UnlinkedClassBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.enums].
   */
  final List<UnlinkedEnumBuilder> enums = <UnlinkedEnumBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.executables],
   * [UnlinkedClass.executables] or [UnlinkedExecutable.localFunctions].
   */
  List<UnlinkedExecutableBuilder> executables = <UnlinkedExecutableBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.exports].
   */
  final List<UnlinkedExportNonPublicBuilder> exports =
      <UnlinkedExportNonPublicBuilder>[];

  /**
   * List of objects which should be written to
   * [UnlinkedExecutable.localLabels].
   */
  List<UnlinkedLabelBuilder> labels = <UnlinkedLabelBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.parts].
   */
  final List<UnlinkedPartBuilder> parts = <UnlinkedPartBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.typedefs].
   */
  final List<UnlinkedTypedefBuilder> typedefs = <UnlinkedTypedefBuilder>[];

  /**
   * List of objects which should be written to [UnlinkedUnit.variables],
   * [UnlinkedClass.fields] or [UnlinkedExecutable.localVariables].
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
   * Map associating names used as prefixes in this compilation unit with their
   * associated indices into [UnlinkedUnit.references].
   */
  final Map<String, int> prefixIndices = <String, int>{};

  /**
   * List of [_Scope]s currently in effect.  This is used to resolve type names
   * to type parameters within classes, typedefs, and executables, as well as
   * references to class members.
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
   * If the library has a library directive, the annotations for it (if any).
   * Otherwise `null`.
   */
  List<UnlinkedConst> libraryAnnotations = const <UnlinkedConstBuilder>[];

  /**
   * The number of slot ids which have been assigned to this compilation unit.
   */
  int numSlots = 0;

  /**
   * The [Block] that is being visited now, or `null` for non-local contexts.
   */
  Block enclosingBlock = null;

  /**
   * Create a slot id for storing a propagated or inferred type or const cycle
   * info.
   */
  int assignSlot() => ++numSlots;

  /**
   * Build a [_Scope] object containing the names defined within the body of a
   * class declaration.
   */
  _Scope buildClassMemberScope(
      String className, NodeList<ClassMember> members) {
    _Scope scope = new _Scope();
    for (ClassMember member in members) {
      if (member is MethodDeclaration) {
        if (member.isSetter || member.isOperator) {
          // We don't have to handle setters or operators because the only
          // things we look up are type names and identifiers.
        } else {
          scope[member.name.name] = new _ScopedClassMember(className);
        }
      } else if (member is FieldDeclaration) {
        for (VariableDeclaration field in member.fields.variables) {
          // A field declaration introduces two names, one with a trailing `=`.
          // We don't have to worry about the one with a trailing `=` because
          // the only things we look up are type names and identifiers.
          scope[field.name.name] = new _ScopedClassMember(className);
        }
      }
    }
    return scope;
  }

  /**
   * Serialize the given list of [annotations].  If there are no annotations,
   * the empty list is returned.
   */
  List<UnlinkedConstBuilder> serializeAnnotations(
      NodeList<Annotation> annotations) {
    if (annotations == null || annotations.isEmpty) {
      return const <UnlinkedConstBuilder>[];
    }
    return annotations.map((Annotation a) {
      _ConstExprSerializer serializer = new _ConstExprSerializer(this, null);
      serializer.serializeAnnotation(a);
      return serializer.toBuilder();
    }).toList();
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
      Comment documentationComment,
      NodeList<Annotation> annotations) {
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
      scopes.add(buildClassMemberScope(name, members));
      for (ClassMember member in members) {
        member.accept(this);
      }
      scopes.removeLast();
    }
    b.executables = executables;
    b.fields = variables;
    b.isAbstract = abstractKeyword != null;
    b.documentationComment = serializeDocumentation(documentationComment);
    b.annotations = serializeAnnotations(annotations);
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
      b.offset = combinator.offset;
      b.end = combinator.end;
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
    b.libraryAnnotations = libraryAnnotations;
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
  UnlinkedConstBuilder serializeConstExpr(Expression expression,
      [Set<String> constructorParameterNames]) {
    _ConstExprSerializer serializer =
        new _ConstExprSerializer(this, constructorParameterNames);
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
      String name,
      int nameOffset,
      bool isGetter,
      bool isSetter,
      TypeName returnType,
      FormalParameterList formalParameters,
      FunctionBody body,
      bool isTopLevel,
      bool isDeclaredStatic,
      Comment documentationComment,
      NodeList<Annotation> annotations,
      TypeParameterList typeParameters,
      bool isExternal) {
    int oldScopesLength = scopes.length;
    _TypeParameterScope typeParameterScope = new _TypeParameterScope();
    scopes.add(typeParameterScope);
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder();
    String nameString = name;
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
    b.nameOffset = nameOffset;
    b.typeParameters =
        serializeTypeParameters(typeParameters, typeParameterScope);
    if (!isTopLevel) {
      b.isStatic = isDeclaredStatic;
    }
    b.returnType = serializeTypeName(returnType);
    b.isExternal = isExternal;
    bool isSemanticallyStatic = isTopLevel || isDeclaredStatic;
    if (formalParameters != null) {
      b.parameters = formalParameters.parameters
          .map((FormalParameter p) => p.accept(this))
          .toList();
      if (!isSemanticallyStatic) {
        for (int i = 0; i < formalParameters.parameters.length; i++) {
          if (!b.parameters[i].isFunctionTyped &&
              b.parameters[i].type == null) {
            b.parameters[i].inferredTypeSlot = assignSlot();
          }
        }
      }
    }
    b.documentationComment = serializeDocumentation(documentationComment);
    b.annotations = serializeAnnotations(annotations);
    if (returnType == null && !isSemanticallyStatic) {
      b.inferredReturnTypeSlot = assignSlot();
    }
    b.visibleOffset = enclosingBlock?.offset;
    b.visibleLength = enclosingBlock?.length;
    serializeFunctionBody(b, body);
    scopes.removeLast();
    assert(scopes.length == oldScopesLength);
    return b;
  }

  /**
   * Record local functions and variables into the given executable. The given
   * [body] is usually an actual [FunctionBody], but may be an [Expression]
   * when we process a synthetic variable initializer function.
   */
  void serializeFunctionBody(UnlinkedExecutableBuilder b, AstNode body) {
    if (body is BlockFunctionBody || body is ExpressionFunctionBody) {
      for (UnlinkedParamBuilder parameter in b.parameters) {
        parameter.visibleOffset = body.offset;
        parameter.visibleLength = body.length;
      }
    }
    List<UnlinkedExecutableBuilder> oldExecutables = executables;
    List<UnlinkedLabelBuilder> oldLabels = labels;
    List<UnlinkedVariableBuilder> oldVariables = variables;
    executables = <UnlinkedExecutableBuilder>[];
    labels = <UnlinkedLabelBuilder>[];
    variables = <UnlinkedVariableBuilder>[];
    body.accept(this);
    b.localFunctions = executables;
    b.localLabels = labels;
    b.localVariables = variables;
    executables = oldExecutables;
    labels = oldLabels;
    variables = oldVariables;
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
   * If the given [expression] is not `null`, serialize it as an
   * [UnlinkedExecutableBuilder], otherwise return `null`.
   */
  UnlinkedExecutableBuilder serializeInitializerFunction(
      Expression expression) {
    if (expression == null) {
      return null;
    }
    UnlinkedExecutableBuilder initializer =
        new UnlinkedExecutableBuilder(nameOffset: expression.offset);
    serializeFunctionBody(initializer, expression);
    initializer.inferredReturnTypeSlot = assignSlot();
    return initializer;
  }

  /**
   * Serialize a [FieldFormalParameter], [FunctionTypedFormalParameter], or
   * [SimpleFormalParameter] into an [UnlinkedParam].
   */
  UnlinkedParamBuilder serializeParameter(NormalFormalParameter node) {
    UnlinkedParamBuilder b = new UnlinkedParamBuilder();
    b.name = node.identifier.name;
    b.nameOffset = node.identifier.offset;
    b.annotations = serializeAnnotations(node.metadata);
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
   * Serialize a reference to a name declared either at top level or in a
   * nested scope.
   */
  int serializeSimpleReference(String name) {
    for (int i = scopes.length - 1; i >= 0; i--) {
      _Scope scope = scopes[i];
      _ScopedEntity entity = scope[name];
      if (entity != null) {
        if (entity is _ScopedClassMember) {
          return serializeReference(
              serializeReference(null, entity.className), name);
        } else {
          // Invalid reference to a type parameter.  Should never happen in
          // legal Dart code.
          // TODO(paulberry): could this exception ever be uncaught in illegal
          // code?
          throw new StateError('Invalid identifier reference');
        }
      }
    }
    return serializeReference(null, name);
  }

  /**
   * Serialize a type name (which might be defined in a nested scope, at top
   * level within this library, or at top level within an imported library) to
   * a [EntityRef].  Note that this method does the right thing if the
   * name doesn't refer to an entity other than a type (e.g. a class member).
   */
  EntityRefBuilder serializeTypeName(TypeName node) {
    if (node == null) {
      return null;
    } else {
      EntityRefBuilder b = new EntityRefBuilder();
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
            () => serializeSimpleReference(identifier.prefix.name));
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
      return b;
    }
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
  void serializeVariables(
      VariableDeclarationList variables,
      bool isDeclaredStatic,
      Comment documentationComment,
      NodeList<Annotation> annotations,
      bool isField) {
    for (VariableDeclaration variable in variables.variables) {
      UnlinkedVariableBuilder b = new UnlinkedVariableBuilder();
      b.isFinal = variables.isFinal;
      b.isConst = variables.isConst;
      b.isStatic = isDeclaredStatic;
      b.name = variable.name.name;
      b.nameOffset = variable.name.offset;
      b.type = serializeTypeName(variables.type);
      b.documentationComment = serializeDocumentation(documentationComment);
      b.annotations = serializeAnnotations(annotations);
      if (variable.isConst ||
          variable.isFinal && isField && !isDeclaredStatic) {
        Expression initializer = variable.initializer;
        if (initializer != null) {
          b.constExpr = serializeConstExpr(initializer);
        }
      }
      if (variable.initializer != null &&
          (variables.isFinal || variables.isConst)) {
        b.propagatedTypeSlot = assignSlot();
      }
      bool isSemanticallyStatic = !isField || isDeclaredStatic;
      if (variables.type == null &&
          (variable.initializer != null || !isSemanticallyStatic)) {
        b.inferredTypeSlot = assignSlot();
      }
      b.visibleOffset = enclosingBlock?.offset;
      b.visibleLength = enclosingBlock?.length;
      b.initializer = serializeInitializerFunction(variable.initializer);
      this.variables.add(b);
    }
  }

  @override
  void visitBlock(Block node) {
    Block oldBlock = enclosingBlock;
    enclosingBlock = node;
    super.visitBlock(node);
    enclosingBlock = oldBlock;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
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
        node.documentationComment,
        node.metadata);
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
        node.documentationComment,
        node.metadata);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder();
    if (node.name != null) {
      b.name = node.name.name;
      b.nameOffset = node.name.offset;
      b.periodOffset = node.period.offset;
      b.nameEnd = node.name.end;
    } else {
      b.nameOffset = node.returnType.offset;
    }
    b.parameters = node.parameters.parameters
        .map((FormalParameter p) => p.accept(this))
        .toList();
    b.kind = UnlinkedExecutableKind.constructor;
    if (node.factoryKeyword != null) {
      b.isFactory = true;
      if (node.redirectedConstructor != null) {
        b.isRedirectedConstructor = true;
        b.redirectedConstructor = new _ConstExprSerializer(this, null)
            .serializeConstructorName(node.redirectedConstructor.type,
                node.redirectedConstructor.name);
      }
    } else {
      for (ConstructorInitializer initializer in node.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          b.isRedirectedConstructor = true;
          b.redirectedConstructorName = initializer.constructorName?.name;
        }
      }
    }
    if (node.constKeyword != null) {
      b.isConst = true;
      b.constCycleSlot = assignSlot();
    }
    b.isExternal = node.externalKeyword != null;
    b.documentationComment = serializeDocumentation(node.documentationComment);
    b.annotations = serializeAnnotations(node.metadata);
    if (node.constKeyword != null) {
      Set<String> constructorParameterNames =
          node.parameters.parameters.map((p) => p.identifier.name).toSet();
      b.constantInitializers = node.initializers
          .map((ConstructorInitializer initializer) =>
              serializeConstructorInitializer(initializer, (Expression expr) {
                return serializeConstExpr(expr, constructorParameterNames);
              }))
          .toList();
    }
    serializeFunctionBody(b, node.body);
    executables.add(b);
  }

  @override
  UnlinkedParamBuilder visitDefaultFormalParameter(
      DefaultFormalParameter node) {
    UnlinkedParamBuilder b = node.parameter.accept(this);
    if (node.defaultValue != null) {
      b.defaultValue = serializeConstExpr(node.defaultValue);
      b.defaultValueCode = node.defaultValue.toSource();
    }
    b.initializer = serializeInitializerFunction(node.defaultValue);
    return b;
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    UnlinkedEnumBuilder b = new UnlinkedEnumBuilder();
    b.name = node.name.name;
    b.nameOffset = node.name.offset;
    b.values = node.constants
        .map((EnumConstantDeclaration value) => new UnlinkedEnumValueBuilder(
            documentationComment:
                serializeDocumentation(value.documentationComment),
            name: value.name.name,
            nameOffset: value.name.offset))
        .toList();
    b.documentationComment = serializeDocumentation(node.documentationComment);
    b.annotations = serializeAnnotations(node.metadata);
    enums.add(b);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    UnlinkedExportNonPublicBuilder b = new UnlinkedExportNonPublicBuilder(
        uriOffset: node.uri.offset, uriEnd: node.uri.end, offset: node.offset);
    b.annotations = serializeAnnotations(node.metadata);
    exports.add(b);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    serializeVariables(node.fields, node.staticKeyword != null,
        node.documentationComment, node.metadata, true);
  }

  @override
  UnlinkedParamBuilder visitFieldFormalParameter(FieldFormalParameter node) {
    UnlinkedParamBuilder b = serializeParameter(node);
    b.isInitializingFormal = true;
    if (node.type != null || node.parameters != null) {
      b.isFunctionTyped = node.parameters != null;
      if (node.parameters != null) {
        serializeFunctionTypedParameterDetails(b, node.type, node.parameters);
      } else {
        b.type = serializeTypeName(node.type);
      }
    }
    return b;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    executables.add(serializeExecutable(
        node.name.name,
        node.name.offset,
        node.isGetter,
        node.isSetter,
        node.returnType,
        node.functionExpression.parameters,
        node.functionExpression.body,
        true,
        false,
        node.documentationComment,
        node.metadata,
        node.functionExpression.typeParameters,
        node.externalKeyword != null));
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      executables.add(serializeExecutable(
          null,
          node.offset,
          false,
          false,
          null,
          node.parameters,
          node.body,
          false,
          false,
          null,
          null,
          node.typeParameters,
          false));
    }
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
    b.annotations = serializeAnnotations(node.metadata);
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
    b.annotations = serializeAnnotations(node.metadata);
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
  void visitLabel(Label node) {
    AstNode parent = node.parent;
    labels.add(new UnlinkedLabelBuilder(
        name: node.label.name,
        nameOffset: node.offset,
        isOnSwitchMember: parent is SwitchMember,
        isOnSwitchStatement:
            parent is LabeledStatement && parent.statement is SwitchStatement));
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    libraryName =
        node.name.components.map((SimpleIdentifier id) => id.name).join('.');
    libraryNameOffset = node.name.offset;
    libraryNameLength = node.name.length;
    libraryDocumentationComment =
        serializeDocumentation(node.documentationComment);
    libraryAnnotations = serializeAnnotations(node.metadata);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    executables.add(serializeExecutable(
        node.name.name,
        node.name.offset,
        node.isGetter,
        node.isSetter,
        node.returnType,
        node.parameters,
        node.body,
        false,
        node.isStatic,
        node.documentationComment,
        node.metadata,
        node.typeParameters,
        node.externalKeyword != null));
  }

  @override
  void visitPartDirective(PartDirective node) {
    parts.add(new UnlinkedPartBuilder(
        uriOffset: node.uri.offset,
        uriEnd: node.uri.end,
        annotations: serializeAnnotations(node.metadata)));
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {}

  @override
  UnlinkedParamBuilder visitSimpleFormalParameter(SimpleFormalParameter node) {
    UnlinkedParamBuilder b = serializeParameter(node);
    b.type = serializeTypeName(node.type);
    return b;
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    serializeVariables(
        node.variables, false, node.documentationComment, node.metadata, false);
  }

  @override
  UnlinkedTypeParamBuilder visitTypeParameter(TypeParameter node) {
    UnlinkedTypeParamBuilder b = new UnlinkedTypeParamBuilder();
    b.name = node.name.name;
    b.nameOffset = node.name.offset;
    if (node.bound != null) {
      b.bound = serializeTypeName(node.bound);
    }
    b.annotations = serializeAnnotations(node.metadata);
    return b;
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    serializeVariables(node.variables, false, null, null, false);
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
