// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_library_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

/// The context of a unit - the context of the bundle, and the unit tokens.
class LinkedUnitContext {
  final LinkedLibraryContext libraryContext;
  final int indexInLibrary;
  final String partUriStr;
  final String uriStr;
  final Reference reference;
  final bool isSynthetic;
  final CompilationUnit unit;
  final UnitReader unitReader;

  bool _hasDirectivesRead = false;

  LinkedUnitContext(this.libraryContext, this.indexInLibrary, this.partUriStr,
      this.uriStr, this.reference, this.isSynthetic,
      {@required this.unit, @required this.unitReader});

  CompilationUnitElementImpl get element {
    return reference.element;
  }

  LinkedElementFactory get elementFactory => libraryContext.elementFactory;

  bool get hasPartOfDirective {
    for (var directive in unit_withDirectives.directives) {
      if (directive is PartOfDirective) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if this unit is a part of a bundle that is being linked.
  bool get isLinking => unitReader == null;

  TypeProvider get typeProvider {
    var libraryReference = libraryContext.reference;
    var libraryElement = libraryReference.element as LibraryElementImpl;
    return libraryElement.typeProvider;
  }

  CompilationUnit get unit_withDeclarations {
    unitReader?.readDeclarations();
    return unit;
  }

  /// Ensure that [unit] has directives ready (because we are linking,
  /// and so always have full AST, or, if we are reading, we make sure
  /// that we have them read).
  CompilationUnit get unit_withDirectives {
    if (unitReader != null && !_hasDirectivesRead) {
      _hasDirectivesRead = true;
      unitReader.readDirectives();
      var libraryElement = libraryContext.reference.element;
      for (var directive in unit.directives) {
        if (directive is ExportDirective) {
          if (directive.element == null) {
            ExportElementImpl.forLinkedNode(libraryElement, directive);
          }
        } else if (directive is ImportDirective) {
          if (directive.element == null) {
            ImportElementImpl.forLinkedNode(libraryElement, directive);
          }
        }
      }
    }
    return unit;
  }

  void applyResolution(AstNode node) {
    if (node is VariableDeclaration) {
      node = node.parent.parent;
    }
    if (node is HasAstLinkedContext) {
      var astLinkedContext = (node as HasAstLinkedContext).linkedContext;
      astLinkedContext?.applyResolution(this);
    }
  }

  void createGenericFunctionTypeElement(int id, GenericFunctionTypeImpl node) {
    var containerRef = this.reference.getChild('@genericFunctionType');
    var reference = containerRef.getChild('$id');
    var element = GenericFunctionTypeElementImpl.forLinkedNode(
      this.reference.element,
      reference,
      node,
    );
    node.declaredElement = element;
  }

  int getCodeLength(AstNode node) {
    if (node is HasAstLinkedContext) {
      var linked = (node as HasAstLinkedContext).linkedContext;
      return linked != null ? linked.codeLength : node.length;
    }

    if (node is CompilationUnitImpl) {
      var data = node.summaryData as SummaryDataForCompilationUnit;
      if (data != null) {
        return data.codeLength;
      } else {
        return node.length;
      }
    } else if (node is EnumConstantDeclaration) {
      return node.length;
    } else if (node is FormalParameter) {
      return node.length;
    } else if (node is TypeParameter) {
      return node.length;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      var linked = (parent2 as HasAstLinkedContext).linkedContext;
      return linked.getVariableDeclarationCodeLength(node);
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  int getCodeOffset(AstNode node) {
    if (node is HasAstLinkedContext) {
      var linked = (node as HasAstLinkedContext).linkedContext;
      return linked != null ? linked.codeOffset : node.offset;
    }

    if (node is CompilationUnit) {
      return 0;
    } else if (node is EnumConstantDeclaration) {
      return node.offset;
    } else if (node is FormalParameter) {
      return node.offset;
    } else if (node is TypeParameter) {
      return node.offset;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      var linked = (parent2 as HasAstLinkedContext).linkedContext;
      return linked.getVariableDeclarationCodeOffset(node);
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  List<ConstructorInitializer> getConstructorInitializers(
    ConstructorDeclaration node,
  ) {
    return node.initializers;
  }

  ConstructorName getConstructorRedirected(ConstructorDeclaration node) {
    return node.redirectedConstructor;
  }

  List<ConstructorDeclaration> getConstructors(AstNode node) {
    if (node is ClassOrMixinDeclaration) {
      return _getClassOrExtensionOrMixinMembers(node)
          .whereType<ConstructorDeclaration>()
          .toList();
    }
    return const <ConstructorDeclaration>[];
  }

  int getDirectiveOffset(Directive node) {
    return node.keyword.offset;
  }

  Comment getDocumentationComment(AstNode node) {
    if (node is HasAstLinkedContext) {
      var linkedContext = (node as HasAstLinkedContext).linkedContext;
      linkedContext?.readDocumentationComment();
      return (node as AnnotatedNode).documentationComment;
    } else if (node is VariableDeclaration) {
      return getDocumentationComment(node.parent.parent);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  String getFieldFormalParameterName(AstNode node) {
    if (node is DefaultFormalParameter) {
      return getFieldFormalParameterName(node.parameter);
    } else if (node is FieldFormalParameter) {
      return node.identifier.name;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  List<VariableDeclaration> getFields(CompilationUnitMember node) {
    var fields = <VariableDeclaration>[];
    var members = _getClassOrExtensionOrMixinMembers(node);
    for (var member in members) {
      if (member is FieldDeclaration) {
        fields.addAll(member.fields.variables);
      }
    }
    return fields;
  }

  String getFormalParameterName(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return getFormalParameterName(node.parameter);
    } else if (node is NormalFormalParameter) {
      return node.identifier?.name ?? '';
    }
    return null;
  }

  List<FormalParameter> getFormalParameters(AstNode node) {
    if (node is ConstructorDeclaration) {
      return node.parameters.parameters;
    } else if (node is FunctionDeclaration) {
      return getFormalParameters(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.parameters?.parameters;
    } else if (node is FormalParameter) {
      if (node is DefaultFormalParameter) {
        return getFormalParameters(node.parameter);
      } else if (node is FieldFormalParameter) {
        return node.parameters?.parameters;
      } else if (node is FunctionTypedFormalParameter) {
        return node.parameters.parameters;
      } else {
        return null;
      }
    } else if (node is FunctionTypeAlias) {
      return node.parameters.parameters;
    } else if (node is GenericFunctionType) {
      return node.parameters.parameters;
    } else if (node is MethodDeclaration) {
      return node.parameters?.parameters;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  ImplementsClause getImplementsClause(AstNode node) {
    if (node is ClassDeclaration) {
      return node.implementsClause;
    } else if (node is ClassTypeAlias) {
      return node.implementsClause;
    } else if (node is MixinDeclaration) {
      return node.implementsClause;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  Expression getInitializer(AstNode node) {
    if (node is DefaultFormalParameter) {
      return node.defaultValue;
    } else if (node is VariableDeclaration) {
      return node.initializer;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  LibraryLanguageVersion getLanguageVersion(CompilationUnit node) {
    return (node as CompilationUnitImpl).languageVersion;
  }

  Comment getLibraryDocumentationComment() {
    for (var directive in unit_withDirectives.directives) {
      if (directive is LibraryDirectiveImpl) {
        var data = directive.summaryData as SummaryDataForLibraryDirective;
        data.readDocumentationComment();
        return directive.documentationComment;
      }
    }
    return null;
  }

  List<Annotation> getLibraryMetadata() {
    unit_withDirectives;
    unitReader.applyDirectivesResolution(this);
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        return directive.metadata;
      }
    }
    return const <Annotation>[];
  }

  List<Annotation> getMetadata(AstNode node) {
    if (node is ClassDeclaration) {
      return node.metadata;
    } else if (node is ClassTypeAlias) {
      return node.metadata;
    } else if (node is CompilationUnit) {
      assert(node == unit);
      if (indexInLibrary != 0) {
        return _getPartDirectiveAnnotation();
      } else {
        return const <Annotation>[];
      }
    } else if (node is ConstructorDeclaration) {
      return node.metadata;
    } else if (node is DefaultFormalParameter) {
      return getMetadata(node.parameter);
    } else if (node is Directive) {
      return node.metadata;
    } else if (node is EnumConstantDeclaration) {
      return node.metadata;
    } else if (node is EnumDeclaration) {
      return node.metadata;
    } else if (node is ExtensionDeclaration) {
      return node.metadata;
    } else if (node is FormalParameter) {
      return node.metadata;
    } else if (node is FunctionDeclaration) {
      return node.metadata;
    } else if (node is FunctionTypeAlias) {
      return node.metadata;
    } else if (node is GenericTypeAlias) {
      return node.metadata;
    } else if (node is MethodDeclaration) {
      return node.metadata;
    } else if (node is MixinDeclaration) {
      return node.metadata;
    } else if (node is TypeParameter) {
      return node.metadata;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      if (parent2 is FieldDeclaration) {
        return parent2.metadata;
      } else if (parent2 is TopLevelVariableDeclaration) {
        return parent2.metadata;
      }
    }
    return const <Annotation>[];
  }

  List<MethodDeclaration> getMethods(CompilationUnitMember node) {
    return _getClassOrExtensionOrMixinMembers(node)
        .whereType<MethodDeclaration>()
        .toList();
  }

  int getNameOffset(AstNode node) {
    if (node is ConstructorDeclaration) {
      if (node.name != null) {
        return node.name.offset;
      } else {
        return node.returnType.offset;
      }
    } else if (node is EnumConstantDeclaration) {
      return node.name.offset;
    } else if (node is ExtensionDeclaration) {
      return node.name?.offset ?? -1;
    } else if (node is FormalParameter) {
      return node.identifier?.offset ?? -1;
    } else if (node is MethodDeclaration) {
      return node.name.offset;
    } else if (node is NamedCompilationUnitMember) {
      return node.name.offset;
    } else if (node is TypeParameter) {
      return node.name.offset;
    } else if (node is VariableDeclaration) {
      return node.name.offset;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  /// Return the actual return type for the [node] - explicit or inferred.
  DartType getReturnType(AstNode node) {
    if (node is GenericFunctionType) {
      return node.returnType?.type ?? DynamicTypeImpl.instance;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  TypeName getSuperclass(AstNode node) {
    if (node is ClassDeclaration) {
      return node.extendsClause?.superclass;
    } else if (node is ClassTypeAlias) {
      return node.superclass;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  TypeParameterList getTypeParameters2(AstNode node) {
    if (node is ClassDeclaration) {
      return node.typeParameters;
    } else if (node is ClassTypeAlias) {
      return node.typeParameters;
    } else if (node is ConstructorDeclaration) {
      return null;
    } else if (node is DefaultFormalParameter) {
      return getTypeParameters2(node.parameter);
    } else if (node is ExtensionDeclaration) {
      return node.typeParameters;
    } else if (node is FieldFormalParameter) {
      return node.typeParameters;
    } else if (node is FunctionDeclaration) {
      return getTypeParameters2(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.typeParameters;
    } else if (node is FunctionTypedFormalParameter) {
      return node.typeParameters;
    } else if (node is FunctionTypeAlias) {
      return node.typeParameters;
    } else if (node is GenericFunctionType) {
      return node.typeParameters;
    } else if (node is GenericTypeAlias) {
      return node.typeParameters;
    } else if (node is MethodDeclaration) {
      return node.typeParameters;
    } else if (node is MixinDeclaration) {
      return node.typeParameters;
    } else if (node is SimpleFormalParameter) {
      return null;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  WithClause getWithClause(AstNode node) {
    if (node is ClassDeclaration) {
      return node.withClause;
    } else if (node is ClassTypeAlias) {
      return node.withClause;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool hasImplicitReturnType(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.returnType == null;
    }
    if (node is MethodDeclaration) {
      return node.returnType == null;
    }
    return false;
  }

  bool hasImplicitType(AstNode node) {
    if (node is DefaultFormalParameter) {
      return hasImplicitType(node.parameter);
    } else if (node is SimpleFormalParameter) {
      return node.type == null;
    } else if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.type == null;
    }
    return false;
  }

  bool hasInitializer(VariableDeclarationImpl node) {
    return node.initializer != null || node.hasInitializer;
  }

  bool isAbstract(AstNode node) {
    if (node is ClassDeclaration) {
      return node.isAbstract;
    } else if (node is ClassTypeAlias) {
      return node.isAbstract;
    } else if (node is ConstructorDeclaration) {
      return false;
    } else if (node is FunctionDeclaration) {
      return false;
    } else if (node is MethodDeclaration) {
      return node.isAbstract;
    } else if (node is VariableDeclaration) {
      var parent = node.parent;
      if (parent is VariableDeclarationList) {
        var grandParent = parent.parent;
        if (grandParent is FieldDeclaration) {
          return grandParent.abstractKeyword != null;
        } else {
          throw UnimplementedError('${grandParent.runtimeType}');
        }
      } else {
        throw UnimplementedError('${parent.runtimeType}');
      }
    } else if (node is EnumConstantDeclaration) {
      return false;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isAsynchronous(AstNode node) {
    if (node is ConstructorDeclaration) {
      return false;
    } else if (node is FunctionDeclaration) {
      return isAsynchronous(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.body.isAsynchronous;
    } else if (node is MethodDeclaration) {
      return node.body.isAsynchronous;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool isConst(AstNode node) {
    if (node is FormalParameter) {
      return node.isConst;
    }
    if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.isConst;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isExplicitlyCovariant(AstNode node) {
    if (node is DefaultFormalParameter) {
      return isExplicitlyCovariant(node.parameter);
    } else if (node is EnumConstantDeclaration) {
      return false;
    } else if (node is FormalParameter) {
      return node.covariantKeyword != null;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      return parent2 is FieldDeclaration && parent2.covariantKeyword != null;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  bool isExternal(AstNode node) {
    if (node is ConstructorDeclaration) {
      return node.externalKeyword != null;
    } else if (node is FunctionDeclaration) {
      return node.externalKeyword != null;
    } else if (node is MethodDeclaration) {
      return node.externalKeyword != null || node.body is NativeFunctionBody;
    } else if (node is VariableDeclaration) {
      var parent = node.parent;
      if (parent is VariableDeclarationList) {
        var grandParent = parent.parent;
        if (grandParent is FieldDeclaration) {
          return grandParent.externalKeyword != null;
        } else if (grandParent is TopLevelVariableDeclaration) {
          return grandParent.externalKeyword != null;
        } else {
          throw UnimplementedError('${grandParent.runtimeType}');
        }
      } else {
        throw UnimplementedError('${parent.runtimeType}');
      }
    } else if (node is EnumConstantDeclaration) {
      return false;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool isFinal(AstNode node) {
    if (node is EnumConstantDeclaration) {
      return false;
    }
    if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.isFinal;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isGenerator(AstNode node) {
    if (node is ConstructorDeclaration) {
      return false;
    } else if (node is FunctionDeclaration) {
      return isGenerator(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.body.isGenerator;
    } else if (node is MethodDeclaration) {
      return node.body.isGenerator;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool isGetter(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.isGetter;
    } else if (node is MethodDeclaration) {
      return node.isGetter;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  bool isLate(AstNode node) {
    if (node is VariableDeclaration) {
      return node.isLate;
    }
    if (node is EnumConstantDeclaration) {
      return false;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isNative(AstNode node) {
    if (node is MethodDeclaration) {
      return node.body is NativeFunctionBody;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool isSetter(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.isSetter;
    } else if (node is MethodDeclaration) {
      return node.isSetter;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  bool isStatic(AstNode node) {
    if (node is FunctionDeclaration) {
      return true;
    } else if (node is MethodDeclaration) {
      return node.modifierKeyword != null;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      return parent2 is FieldDeclaration && parent2.isStatic;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool shouldBeConstFieldElement(AstNode node) {
    if (node is VariableDeclaration) {
      VariableDeclarationList variableList = node.parent;
      if (variableList.isConst) return true;

      FieldDeclaration fieldDeclaration = variableList.parent;
      if (fieldDeclaration.staticKeyword != null) return false;

      if (variableList.isFinal) {
        var class_ = fieldDeclaration.parent;
        if (class_ is ClassDeclaration) {
          var hasLinkedContext = class_ as HasAstLinkedContext;
          var linkedContext = hasLinkedContext.linkedContext;
          // TODO(scheglov) Get rid of this check, exists only for linking.
          // Maybe we should pre-create all elements before linking.
          if (linkedContext != null) {
            return linkedContext.isClassWithConstConstructor;
          } else {
            for (var member in class_.members) {
              if (member is ConstructorDeclaration &&
                  member.constKeyword != null) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  List<VariableDeclaration> topLevelVariables(CompilationUnit unit) {
    var variables = <VariableDeclaration>[];
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        variables.addAll(declaration.variables.variables);
      }
    }
    return variables;
  }

  List<ClassMember> _getClassOrExtensionOrMixinMembers(
    CompilationUnitMember node,
  ) {
    var linkedContext = (node as HasAstLinkedContext).linkedContext;
    if (linkedContext != null) {
      return linkedContext.classMembers;
    } else {
      if (node is ClassDeclaration) {
        return node.members;
      } else if (node is ClassTypeAlias) {
        return <ClassMember>[];
      } else if (node is ExtensionDeclaration) {
        return node.members;
      } else if (node is MixinDeclaration) {
        return node.members;
      } else {
        throw StateError('${node.runtimeType}');
      }
    }
  }

  NodeList<Annotation> _getPartDirectiveAnnotation() {
    var definingContext = libraryContext.definingUnit;
    var definingUnit = definingContext.unit_withDirectives;
    var partDirectiveIndex = 0;
    for (var directive in definingUnit.directives) {
      if (directive is PartDirective) {
        partDirectiveIndex++;
        if (partDirectiveIndex == indexInLibrary) {
          return directive.metadata;
        }
      }
    }
    throw StateError('Expected to find $indexInLibrary part directive.');
  }
}
