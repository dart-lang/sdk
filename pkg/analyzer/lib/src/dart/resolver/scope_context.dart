// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:meta/meta.dart';

class ScopeContext {
  final LibraryFragmentImpl libraryFragment;
  Scope nameScope;

  ScopeContext({required this.libraryFragment, required this.nameScope});

  void walkMixinDeclarationScopes(
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

  void withInstanceScope(InstanceElementImpl element, void Function() f) {
    withScope(InstanceScope(nameScope, element), f);
  }

  /// Run [f] with a new [LocalScope].
  void withLocalScope(void Function() f) {
    withScope(LocalScope(nameScope), f);
  }

  @nonVirtual
  void withScope(Scope scope, void Function() f) {
    var outerScope = nameScope;
    try {
      nameScope = scope;
      f();
    } finally {
      nameScope = outerScope;
    }
  }

  void withTypeParameterScope(
    List<TypeParameterElementImpl> elements,
    void Function() f,
  ) {
    withScope(
      TypeParameterScope(
        nameScope,
        elements,
        featureSet: libraryFragment.library.featureSet,
      ),
      f,
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
