// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class ScopeContext {
  final LibraryFragmentImpl _libraryFragment;
  final DocumentationCommentScope _docImportScope;

  Scope _nameScope;
  InstanceElementImpl? _enclosingInstanceElement;

  ScopeContext({
    required LibraryFragmentImpl libraryFragment,
    required Scope nameScope,
    List<LibraryElement> docImportLibraries = const [],
  }) : _libraryFragment = libraryFragment,
       _docImportScope = DocumentationCommentScope(
         nameScope,
         docImportLibraries,
       ),
       _nameScope = nameScope;

  InstanceElementImpl? get enclosingInstanceElement {
    return _enclosingInstanceElement;
  }

  Scope get nameScope => _nameScope;

  FeatureSet get _featureSet => _libraryFragment.library.featureSet;

  void visitClassDeclaration(
    ClassDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.namePart.typeParameters?.accept(visitor);
      node.extendsClause?.accept(visitor);
      node.withClause?.accept(visitor);
      node.implementsClause?.accept(visitor);
      node.nativeClause?.accept(visitor);

      withInstanceScope(element, () {
        node.bodyScope = nameScope;
        visitDocumentationComment(node.documentationComment, visitor);
        node.namePart
            .tryCast<PrimaryConstructorDeclarationImpl>()
            ?.formalParameters
            .accept(visitor);
        node.body.accept(visitor);
      });
    });
  }

  void visitClassTypeAlias(
    ClassTypeAliasImpl node, {
    required AstVisitor visitor,
    void Function(NamedTypeImpl)? visitSuperclass,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.typeParameterScope = nameScope;
      node.typeParameters?.accept(visitor);
      node.superclass.visitWithOverride(visitor, visitSuperclass);
      node.withClause.accept(visitor);
      node.implementsClause?.accept(visitor);

      withInstanceScope(element, () {
        visitDocumentationComment(node.documentationComment, visitor);
      });
    });
  }

  void visitDocumentationComment(CommentImpl? node, AstVisitor visitor) {
    if (node != null) {
      var docImportInnerScope = _docImportScope.innerScope;
      _docImportScope.innerScope = nameScope;
      try {
        withScope(_docImportScope, () {
          node.nameScope = nameScope;
          node.accept(visitor);
        });
      } finally {
        _docImportScope.innerScope = docImportInnerScope;
      }
    }
  }

  void visitEnumDeclaration(
    EnumDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.namePart.typeParameters?.accept(visitor);
      node.withClause?.accept(visitor);
      node.implementsClause?.accept(visitor);

      withInstanceScope(element, () {
        node.bodyScope = nameScope;
        visitDocumentationComment(node.documentationComment, visitor);
        node.namePart
            .tryCast<PrimaryConstructorDeclarationImpl>()
            ?.formalParameters
            .accept(visitor);
        node.body.accept(visitor);
      });
    });
  }

  void visitExtensionDeclaration(
    ExtensionDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept(visitor);
      node.onClause?.accept(visitor);

      withExtensionScope(element, () {
        node.bodyScope = nameScope;
        visitDocumentationComment(node.documentationComment, visitor);
        node.body.accept(visitor);
      });
    });
  }

  void visitExtensionTypeDeclaration(
    ExtensionTypeDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.primaryConstructor.typeParameters?.accept(visitor);
      node.implementsClause?.accept(visitor);

      if (_featureSet.isEnabled(Feature.primary_constructors)) {
        withInstanceScope(element, () {
          node.bodyScope = nameScope;
          visitDocumentationComment(node.documentationComment, visitor);
          node.primaryConstructor.formalParameters.accept(visitor);
          node.body.accept(visitor);
        });
      } else {
        node.primaryConstructor.formalParameters.accept(visitor);
        withInstanceScope(element, () {
          node.bodyScope = nameScope;
          visitDocumentationComment(node.documentationComment, visitor);
          node.body.accept(visitor);
        });
      }
    });
  }

  void visitFieldFormalParameter(
    FieldFormalParameterImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.type?.accept(visitor);
      node.typeParameters?.accept(visitor);
      node.parameters?.accept(visitor);
    });
  }

  void visitFunctionDeclaration(
    FunctionDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.returnType?.accept(visitor);

      var functionExpression = node.functionExpression;
      functionExpression.typeParameters?.accept(visitor);
      functionExpression.parameters?.accept(visitor);

      withFormalParameterScope(element.formalParameters, () {
        visitDocumentationComment(node.documentationComment, visitor);
        functionExpression.body.accept(visitor);
      });
    });
  }

  void visitFunctionExpression(
    FunctionExpressionImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    withTypeParameterList(node.typeParameters, () {
      node.typeParameters?.accept(visitor);
      node.parameters?.accept(visitor);

      withFormalParameterScope(element.formalParameters, () {
        node.body.accept(visitor);
      });
    });
  }

  void visitFunctionTypeAlias(
    FunctionTypeAliasImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.returnType?.accept(visitor);
      node.typeParameters?.accept(visitor);
      node.parameters.accept(visitor);

      withLocalScope((scope) {
        scope.addFormalParameterList(node.parameters);
        visitDocumentationComment(node.documentationComment, visitor);
      });
    });
  }

  void visitFunctionTypedFormalParameter(
    FunctionTypedFormalParameterImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.returnType?.accept(visitor);
      node.typeParameters?.accept(visitor);
      node.parameters.accept(visitor);
    });
  }

  void visitGenericFunctionType(
    GenericFunctionTypeImpl node, {
    required AstVisitor visitor,
  }) {
    withTypeParameterList(node.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept(visitor);
      node.parameters.accept(visitor);
      node.returnType?.accept(visitor);
    });
  }

  void visitGenericTypeAlias(
    GenericTypeAliasImpl node, {
    required AstVisitor visitor,
    void Function()? enterTypeParameterScope,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      if (enterTypeParameterScope != null) {
        enterTypeParameterScope();
      }
      node.typeParameters?.accept(visitor);
      node.type.accept(visitor);

      if (node.type case GenericFunctionTypeImpl functionTypeNode) {
        withTypeParameterList(functionTypeNode.typeParameters, () {
          withLocalScope((scope) {
            scope.addFormalParameterList(functionTypeNode.parameters);
            visitDocumentationComment(node.documentationComment, visitor);
          });
        });
      } else {
        visitDocumentationComment(node.documentationComment, visitor);
      }
    });
  }

  void visitMethodDeclaration(
    MethodDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameterScope = nameScope;
      node.returnType?.accept(visitor);
      node.typeParameters?.accept(visitor);
      node.parameters?.accept(visitor);

      withFormalParameterScope(element.formalParameters, () {
        visitDocumentationComment(node.documentationComment, visitor);
        node.body.accept(visitor);
      });
    });
  }

  void visitMixinDeclaration(
    MixinDeclarationImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept(visitor);
      node.onClause?.accept(visitor);
      node.implementsClause?.accept(visitor);

      withInstanceScope(element, () {
        node.bodyScope = nameScope;
        visitDocumentationComment(node.documentationComment, visitor);
        node.body.accept(visitor);
      });
    });
  }

  void visitSuperFormalParameter(
    SuperFormalParameterImpl node, {
    required AstVisitor visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.type?.accept(visitor);
      node.typeParameters?.accept(visitor);
      node.parameters?.accept(visitor);
    });
  }

  void visitVariableDeclarationList(
    VariableDeclarationListImpl node, {
    required AstVisitor visitor,
  }) {
    node.metadata.accept(visitor);
    node.type?.accept(visitor);

    var variablesScope = nameScope;

    // Use different scope for instance non-late field initializers.
    if (node.parent case FieldDeclarationImpl fieldDeclaration) {
      if (!fieldDeclaration.isStatic) {
        if (node.lateKeyword == null) {
          var primaryConstructor = _enclosingInstanceElement
              .tryCast<InterfaceElementImpl>()
              ?.primaryConstructor;
          if (primaryConstructor != null) {
            variablesScope = ConstructorInitializerScope(
              nameScope,
              primaryConstructor,
            );
          }
        }
      }
    }

    withScope(variablesScope, () {
      node.variables.accept(visitor);
    });
  }

  void withConstructorInitializerScope(
    ConstructorElementImpl element,
    void Function() operation,
  ) {
    withScope(ConstructorInitializerScope(nameScope, element), operation);
  }

  void withExtensionScope(
    ExtensionElementImpl element,
    void Function() operation,
  ) {
    withScope(ExtensionScope(nameScope, element), () {
      _withEnclosingInstanceElement(element, operation);
    });
  }

  void withFormalParameterScope(
    List<FormalParameterElementImpl> elements,
    void Function() operation,
  ) {
    withScope(
      FormalParameterScope(nameScope, elements, featureSet: _featureSet),
      operation,
    );
  }

  void withInstanceScope(
    InstanceElementImpl element,
    void Function() operation,
  ) {
    withScope(InstanceScope(nameScope, element), () {
      _withEnclosingInstanceElement(element, operation);
    });
  }

  /// Run [operation] with a new [LocalScope].
  void withLocalScope(void Function(LocalScope scope) operation) {
    var scope = LocalScope(nameScope, featureSet: _featureSet);
    withScope(scope, () => operation(scope));
  }

  void withPrimaryParameterScope(
    ConstructorElementImpl element,
    void Function() operation,
  ) {
    withScope(PrimaryParameterScope(nameScope, element), operation);
  }

  void withScope(Scope scope, void Function() operation) {
    var outerScope = _nameScope;
    try {
      _nameScope = scope;
      operation();
    } finally {
      _nameScope = outerScope;
    }
  }

  void withTypeParameterList(
    TypeParameterListImpl? typeParameterList,
    void Function() operation,
  ) {
    if (typeParameterList != null) {
      var elements = typeParameterList.typeParameters
          .map((node) => node.declaredFragment!.element)
          .toList();
      withTypeParameterScope(elements, operation);
    } else {
      operation();
    }
  }

  void withTypeParameterScope(
    List<TypeParameterElementImpl> elements,
    void Function() operation,
  ) {
    withScope(
      TypeParameterScope(nameScope, elements, featureSet: _featureSet),
      operation,
    );
  }

  void _withEnclosingInstanceElement(
    InstanceElementImpl element,
    void Function() operation,
  ) {
    _enclosingInstanceElement = element;
    try {
      operation();
    } finally {
      _enclosingInstanceElement = null;
    }
  }
}

extension<T extends AstNode> on T {
  void visitWithOverride(AstVisitor visitor, void Function(T)? visitOverride) {
    if (visitOverride != null) {
      visitOverride(this);
    } else {
      accept(visitor);
    }
  }
}

extension LocalScopeExtension on LocalScope {
  void addFormalParameterList(FormalParameterList node) {
    for (var formalParameter in node.parameters) {
      add(formalParameter.declaredFragment!.element);
    }
  }
}
