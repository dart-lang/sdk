// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class ScopeContext {
  final LibraryFragmentImpl _libraryFragment;
  final DocumentationCommentScope _docImportScope;

  Scope _nameScope;
  InstanceElementImpl? _enclosingInstanceElement;
  bool _isInStaticMember = false;

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

  TypeImpl instantiateTypeParameter({
    required TypeParameterElementImpl element,
    required NullabilitySuffix nullability,
  }) {
    if (_isInStaticMember && element.enclosingElement is InstanceElement) {
      return InvalidTypeImpl.instance;
    }
    return element.instantiate(nullabilitySuffix: nullability);
  }

  void visitClassDeclaration(
    ClassDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.namePart.typeParameters?.accept2(visitor);
      node.extendsClause?.accept2(visitor);
      node.withClause?.accept2(visitor);
      node.implementsClause?.accept2(visitor);
      node.nativeClause?.accept2(visitor);

      withInstanceScope(element, () {
        node.bodyScope = nameScope;
        node.documentationComment?.accept2(visitor);
        node.namePart
            .tryCast<PrimaryConstructorDeclarationImpl>()
            ?.formalParameters
            .accept2(visitor);
        node.body.accept2(visitor);
      });
    });
  }

  void visitClassTypeAlias(
    ClassTypeAliasImpl node, {
    required AstVisitor2 visitor,
    void Function(NamedTypeImpl)? visitSuperclass,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.typeParameterScope = nameScope;
      node.typeParameters?.accept2(visitor);
      node.superclass.visitWithOverride(visitor, visitSuperclass);
      node.withClause.accept2(visitor);
      node.implementsClause?.accept2(visitor);

      withInstanceScope(element, () {
        node.documentationComment?.accept2(visitor);
      });
    });
  }

  void visitConstructorDeclaration(
    ConstructorDeclarationImpl node, {
    required AstVisitor2 visitor,
    void Function(SimpleIdentifierImpl)? visitTypeName,
    void Function(NodeList<ConstructorInitializer>)? visitInitializers,
    void Function(ConstructorNameImpl)? visitRedirectedConstructor,
  }) {
    var fragment = node.declaredFragment!;

    node.metadata.accept2(visitor);
    node.typeName?.visitWithOverride(visitor, visitTypeName);
    node.parameters.accept2(visitor);

    withScope(_constructorInitializerScope(fragment), () {
      node.formalParameterInitializerScope = nameScope;
      node.initializers.visitWithOverride(visitor, visitInitializers);
      node.documentationComment?.accept2(visitor);
    });

    node.redirectedConstructor?.visitWithOverride(
      visitor,
      visitRedirectedConstructor,
    );

    withFormalParameterScope(fragment.formalParameters, () {
      node.body.accept2(visitor);
    });
  }

  void visitDocumentationComment(CommentImpl node, AstVisitor2 visitor) {
    var docImportInnerScope = _docImportScope.innerScope;
    _docImportScope.innerScope = nameScope;
    try {
      withScope(_docImportScope, () {
        node.nameScope = nameScope;
        node.visitChildren2(visitor);
      });
    } finally {
      _docImportScope.innerScope = docImportInnerScope;
    }
  }

  void visitEnumDeclaration(
    EnumDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.namePart.typeParameters?.accept2(visitor);
      node.withClause?.accept2(visitor);
      node.implementsClause?.accept2(visitor);

      withInstanceScope(element, () {
        node.bodyScope = nameScope;
        node.documentationComment?.accept2(visitor);
        node.namePart
            .tryCast<PrimaryConstructorDeclarationImpl>()
            ?.formalParameters
            .accept2(visitor);
        node.body.accept2(visitor);
      });
    });
  }

  void visitExtensionDeclaration(
    ExtensionDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept2(visitor);
      node.onClause?.accept2(visitor);

      withExtensionScope(element, () {
        node.bodyScope = nameScope;
        node.documentationComment?.accept2(visitor);
        node.body.accept2(visitor);
      });
    });
  }

  void visitExtensionTypeDeclaration(
    ExtensionTypeDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.namePart.typeParameters?.accept2(visitor);
      node.implementsClause?.accept2(visitor);

      if (_featureSet.isEnabled(Feature.primary_constructors)) {
        withInstanceScope(element, () {
          node.bodyScope = nameScope;
          node.documentationComment?.accept2(visitor);
          node.namePart
              .tryCast<PrimaryConstructorDeclarationImpl>()
              ?.formalParameters
              .accept2(visitor);
          node.body.accept2(visitor);
        });
      } else {
        node.namePart
            .tryCast<PrimaryConstructorDeclarationImpl>()
            ?.formalParameters
            .accept2(visitor);
        withInstanceScope(element, () {
          node.bodyScope = nameScope;
          node.documentationComment?.accept2(visitor);
          node.body.accept2(visitor);
        });
      }
    });
  }

  void visitFieldDeclaration(
    FieldDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    withInStaticMember(node.isStatic, () {
      node.visitChildren2(visitor);
    });
  }

  void visitFormalParameter(
    FormalParameterImpl node, {
    required AstVisitor2 visitor,
  }) {
    node.scope = nameScope;

    node.metadata.accept2(visitor);
    node.documentationComment?.accept2(visitor);

    var functionTypedSuffix = node.functionTypedSuffix;
    if (functionTypedSuffix == null) {
      node.type?.accept2(visitor);
    } else {
      withTypeParameterList(functionTypedSuffix.typeParameters, () {
        node.type?.accept2(visitor);
        functionTypedSuffix.typeParameters?.accept2(visitor);
        functionTypedSuffix.formalParameters.accept2(visitor);
      });
    }

    node.defaultClause?.accept2(visitor);
  }

  void visitFunctionDeclaration(
    FunctionDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.returnType?.accept2(visitor);

      var functionExpression = node.functionExpression;
      functionExpression.typeParameters?.accept2(visitor);
      functionExpression.parameters?.accept2(visitor);

      withFormalParameterScope(fragment.formalParameters, () {
        node.documentationComment?.accept2(visitor);
        functionExpression.body.accept2(visitor);
      });
    });
  }

  void visitFunctionExpression(
    FunctionExpressionImpl node, {
    required AstVisitor2 visitor,
  }) {
    var fragment = node.declaredFragment!;

    withTypeParameterList(node.typeParameters, () {
      node.typeParameters?.accept2(visitor);
      node.parameters?.accept2(visitor);

      withFormalParameterScope(fragment.formalParameters, () {
        node.body.accept2(visitor);
      });
    });
  }

  void visitFunctionTypeAlias(
    FunctionTypeAliasImpl node, {
    required AstVisitor2 visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.returnType?.accept2(visitor);
      node.typeParameters?.accept2(visitor);
      node.parameters.accept2(visitor);

      withLocalScope((scope) {
        scope.addFormalParameterList(node.parameters);
        node.documentationComment?.accept2(visitor);
      });
    });
  }

  void visitGenericFunctionType(
    GenericFunctionTypeImpl node, {
    required AstVisitor2 visitor,
  }) {
    withTypeParameterList(node.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept2(visitor);
      node.parameters.accept2(visitor);
      node.returnType?.accept2(visitor);
    });
  }

  void visitGenericTypeAlias(
    GenericTypeAliasImpl node, {
    required AstVisitor2 visitor,
    void Function()? enterTypeParameterScope,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      if (enterTypeParameterScope != null) {
        enterTypeParameterScope();
      }
      node.typeParameters?.accept2(visitor);
      node.type.accept2(visitor);

      if (node.type case GenericFunctionTypeImpl functionTypeNode) {
        withTypeParameterList(functionTypeNode.typeParameters, () {
          withLocalScope((scope) {
            scope.addFormalParameterList(functionTypeNode.parameters);
            node.documentationComment?.accept2(visitor);
          });
        });
      } else {
        node.documentationComment?.accept2(visitor);
      }
    });
  }

  void visitMethodDeclaration(
    MethodDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept2(visitor);

    withInStaticMember(node.isStatic, () {
      withTypeParameterScope(element.typeParameters, () {
        node.nameScope = nameScope;
        node.typeParameterScope = nameScope;
        node.returnType?.accept2(visitor);
        node.typeParameters?.accept2(visitor);
        node.parameters?.accept2(visitor);

        withFormalParameterScope(fragment.formalParameters, () {
          node.documentationComment?.accept2(visitor);
          node.body.accept2(visitor);
        });
      });
    });
  }

  void visitMixinDeclaration(
    MixinDeclarationImpl node, {
    required AstVisitor2 visitor,
  }) {
    var element = node.declaredFragment!.element;

    node.metadata.accept2(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept2(visitor);
      node.onClause?.accept2(visitor);
      node.implementsClause?.accept2(visitor);

      withInstanceScope(element, () {
        node.bodyScope = nameScope;
        node.documentationComment?.accept2(visitor);
        node.body.accept2(visitor);
      });
    });
  }

  void visitPrimaryConstructorBody(
    PrimaryConstructorBodyImpl node, {
    required AstVisitor2 visitor,
    void Function(NodeList<ConstructorInitializer>)? visitInitializers,
  }) {
    var fragment = node.declaration?.declaredFragment;

    node.metadata.accept2(visitor);

    withScope(
      fragment != null ? _constructorInitializerScope(fragment) : nameScope,
      () {
        node.formalParameterInitializerScope = nameScope;
        node.initializers.visitWithOverride(visitor, visitInitializers);
      },
    );

    withScope(
      fragment != null
          ? PrimaryParameterScope(
              nameScope,
              fragment.element,
              fragment.formalParameters,
            )
          : nameScope,
      () {
        node.documentationComment?.accept2(visitor);
        node.body.accept2(visitor);
      },
    );
  }

  void visitVariableDeclarationList(
    VariableDeclarationListImpl node, {
    required AstVisitor2 visitor,
  }) {
    node.metadata.accept2(visitor);
    node.type?.accept2(visitor);

    var variablesScope = nameScope;

    // Use different scope for instance non-late field initializers.
    if (node.parent case FieldDeclarationImpl fieldDeclaration) {
      if (!fieldDeclaration.isStatic && node.lateKeyword == null) {
        var primaryConstructor = fieldDeclaration.enclosingPrimaryConstructor;
        if (primaryConstructor != null) {
          variablesScope = _constructorInitializerScope(
            primaryConstructor.declaredFragment!,
          );
        }
      }
    }

    withScope(variablesScope, () {
      node.variables.accept2(visitor);
    });
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
    List<FormalParameterFragmentImpl> fragments,
    void Function() operation,
  ) {
    withScope(
      FormalParameterScope(nameScope, fragments, featureSet: _featureSet),
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

  void withInStaticMember(bool isInStaticMember, void Function() operation) {
    var outer = _isInStaticMember;
    try {
      _isInStaticMember = isInStaticMember;
      operation();
    } finally {
      _isInStaticMember = outer;
    }
  }

  /// Run [operation] with a new [LocalScope].
  void withLocalScope(void Function(LocalScope scope) operation) {
    var scope = LocalScope(nameScope, featureSet: _featureSet);
    withScope(scope, () => operation(scope));
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

  Scope _constructorInitializerScope(ConstructorFragmentImpl fragment) {
    return ConstructorInitializerScope(
      nameScope,
      fragment.element,
      fragment.formalParameters,
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
  void visitWithOverride(AstVisitor2 visitor, void Function(T)? visitOverride) {
    if (visitOverride != null) {
      visitOverride(this);
    } else {
      accept2(visitor);
    }
  }
}

extension<E extends AstNode> on NodeList<E> {
  void visitWithOverride(
    AstVisitor2 visitor,
    void Function(NodeList<E>)? visitOverride,
  ) {
    if (visitOverride != null) {
      visitOverride(this);
    } else {
      accept2(visitor);
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

extension _FieldDeclarationExtension on FieldDeclaration {
  PrimaryConstructorDeclarationImpl? get enclosingPrimaryConstructor {
    return switch (parent?.parent) {
      ClassDeclarationImpl(:var namePart) => namePart.tryCast(),
      EnumDeclarationImpl(:var namePart) => namePart.tryCast(),
      ExtensionTypeDeclarationImpl(:var namePart) => namePart.tryCast(),
      _ => null,
    };
  }
}
