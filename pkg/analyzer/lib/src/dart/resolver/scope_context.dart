// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  Scope get nameScope => _nameScope;

  void visitClassDeclaration(
    ClassDeclarationImpl node, {
    required AstVisitor visitor,
    void Function(CommentImpl)? visitDocumentationComment,
    void Function()? enterBodyScope,
    void Function(ClassBodyImpl body)? visitBody,
  }) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.namePart.typeParameters?.accept(visitor);
      node.extendsClause?.accept(visitor);
      node.withClause?.accept(visitor);
      node.implementsClause?.accept(visitor);
      node.nativeClause?.accept(visitor);

      withInstanceScope(element, () {
        enterBodyScope?.call();
        node.documentationComment?.visitWithOverride(
          visitor,
          visitDocumentationComment,
        );
        node.namePart
            .tryCast<PrimaryConstructorDeclarationImpl>()
            ?.formalParameters
            .accept(visitor);
        node.body.visitWithOverride(visitor, visitBody);
      });
    });
  }

  void visitExtensionDeclaration(
    ExtensionDeclarationImpl node, {
    required AstVisitor visitor,
    void Function(CommentImpl)? visitDocumentationComment,
    void Function()? enterBodyScope,
    void Function(BlockClassBodyImpl body)? visitBody,
  }) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept(visitor);
      node.onClause?.accept(visitor);

      withExtensionScope(element, () {
        enterBodyScope?.call();
        node.documentationComment?.visitWithOverride(
          visitor,
          visitDocumentationComment,
        );
        node.body.visitWithOverride(visitor, visitBody);
      });
    });
  }

  void visitExtensionTypeDeclaration(
    ExtensionTypeDeclarationImpl node, {
    required AstVisitor visitor,
    void Function(CommentImpl)? visitDocumentationComment,
    void Function()? enterBodyScope,
    void Function(ClassBodyImpl body)? visitBody,
  }) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.primaryConstructor.typeParameters?.accept(visitor);
      node.implementsClause?.accept(visitor);

      withInstanceScope(element, () {
        enterBodyScope?.call();
        node.documentationComment?.visitWithOverride(
          visitor,
          visitDocumentationComment,
        );
        node.primaryConstructor.formalParameters.accept(visitor);
        node.body.visitWithOverride(visitor, visitBody);
      });
    });
  }

  void visitMixinDeclaration(
    MixinDeclarationImpl node, {
    required AstVisitor visitor,
    void Function(CommentImpl)? visitDocumentationComment,
    void Function()? enterBodyScope,
    void Function(BlockClassBodyImpl body)? visitBody,
  }) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept(visitor);

    withTypeParameterScope(element.typeParameters, () {
      node.nameScope = nameScope;
      node.typeParameters?.accept(visitor);
      node.onClause?.accept(visitor);
      node.implementsClause?.accept(visitor);

      withInstanceScope(element, () {
        enterBodyScope?.call();
        node.documentationComment?.visitWithOverride(
          visitor,
          visitDocumentationComment,
        );
        node.body.visitWithOverride(visitor, visitBody);
      });
    });
  }

  void withConstructorInitializerScope(
    ConstructorElementImpl element,
    void Function() operation,
  ) {
    withScope(ConstructorInitializerScope(nameScope, element), operation);
  }

  void withDocImportScope(CommentImpl node, void Function() operation) {
    var docImportInnerScope = _docImportScope.innerScope;
    _docImportScope.innerScope = nameScope;
    try {
      withScope(_docImportScope, () {
        node.nameScope = nameScope;
        operation();
      });
    } finally {
      _docImportScope.innerScope = docImportInnerScope;
    }
  }

  void withExtensionScope(
    ExtensionElementImpl element,
    void Function() operation,
  ) {
    withScope(ExtensionScope(nameScope, element), operation);
  }

  void withFormalParameterScope(
    List<FormalParameterElementImpl> elements,
    void Function() operation,
  ) {
    withScope(FormalParameterScope(nameScope, elements), operation);
  }

  void withInstanceScope(
    InstanceElementImpl element,
    void Function() operation,
  ) {
    withScope(InstanceScope(nameScope, element), operation);
  }

  /// Run [operation] with a new [LocalScope].
  void withLocalScope(void Function(LocalScope scope) operation) {
    var scope = LocalScope(nameScope);
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
      TypeParameterScope(
        nameScope,
        elements,
        featureSet: _libraryFragment.library.featureSet,
      ),
      operation,
    );
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
