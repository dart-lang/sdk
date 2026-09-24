// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';

class CommentReferenceResolver {
  final ResolverVisitor _resolver;

  CommentReferenceResolver(this._resolver);

  /// Resolves [commentReference].
  void resolve(CommentReferenceImpl commentReference) {
    _resolver.diagnosticReporter.lockLevel++;
    try {
      var components = commentReference.components;
      if (components.length == 1) {
        components.single.element = _resolveUnqualified(components.single);
      } else if (components.length == 2) {
        _resolveTwoComponents(components[0], components[1]);
      } else if (components.length == 3) {
        _resolveThreeComponents(components[0], components[1], components[2]);
      }
    } finally {
      _resolver.diagnosticReporter.lockLevel--;
    }
  }

  /// Resolves [name] as a member of [container]: declared members first, then
  /// inherited ones. Constructors are members only for qualified references,
  /// because a bare name never refers to a constructor.
  Element? _resolveInstanceMember(
    InstanceElement container,
    String name, {
    required bool allowConstructors,
  }) {
    var declaredElement =
        container.getMethod(name) ??
        container.getGetter(name) ??
        container.getSetter(name);
    if (declaredElement != null) {
      return declaredElement;
    }

    if (container is InterfaceElement) {
      if (allowConstructors) {
        var constructor = container.getNamedConstructor(name);
        if (constructor != null) {
          return constructor;
        }
      }
      var memberName = Name(container.library.uri, name);
      return _resolver.inheritance.getMember(container, memberName) ??
          _resolver.inheritance.getMember(container, memberName.forSetter);
    }

    return null;
  }

  void _resolveThreeComponents(
    CommentReferenceComponentImpl first,
    CommentReferenceComponentImpl second,
    CommentReferenceComponentImpl third,
  ) {
    var firstElement = _resolveUnqualified(first);
    first.element = firstElement;

    // The only valid firstElement is a PrefixElement.
    if (firstElement is! PrefixElement) {
      return;
    }

    var prefixScope = firstElement.scope;
    var secondLookupResult = prefixScope.lookup(second.name.lexeme);
    var secondElement = secondLookupResult.getter ?? secondLookupResult.setter;
    second.element = secondElement;

    // When resolving `third`, use the aliased element.
    if (secondElement is TypeAliasElement) {
      secondElement = secondElement.aliasedType.element;
    }

    if (secondElement is InstanceElement) {
      third.element = _resolveInstanceMember(
        secondElement,
        third.name.lexeme,
        allowConstructors: true,
      );
    }
  }

  void _resolveTwoComponents(
    CommentReferenceComponentImpl first,
    CommentReferenceComponentImpl second,
  ) {
    var firstElement = _resolveUnqualified(first);
    first.element = firstElement;

    if (firstElement == null) {
      return;
    }

    // When resolving `second`, use the aliased element.
    if (firstElement is TypeAliasElement) {
      firstElement = firstElement.aliasedType.element;
    }

    switch (firstElement) {
      case PrefixElement():
        var prefixScope = firstElement.scope;
        var lookupResult = prefixScope.lookup(second.name.lexeme);
        var element = lookupResult.getter ?? lookupResult.setter;
        second.element = element;
      case InstanceElement():
        second.element = _resolveInstanceMember(
          firstElement,
          second.name.lexeme,
          allowConstructors: true,
        );
    }
  }

  /// Resolves the unqualified [component] if possible.
  ///
  /// Returns the resolved element, or `null` if the component could not be
  /// resolved. This does not record the results of the resolution.
  Element? _resolveUnqualified(CommentReferenceComponentImpl component) {
    var scopeLookupResult = component.scopeLookupResult!;
    var scopeElement = scopeLookupResult.getter ?? scopeLookupResult.setter;

    // Import usage is tracked by lookups in the prefix scope, which `[math]`
    // alone does not do; without this, the import would be reported unused.
    if (scopeElement is PrefixElementImpl) {
      scopeElement.scope.notifyPrefixUsedInCommentReference();
    }

    if (scopeElement != null) {
      return scopeElement;
    }

    var enclosingInstanceElement = _resolver.enclosingInstanceElement;
    if (enclosingInstanceElement == null) {
      return null;
    }

    var name = component.name.lexeme;
    var receiverType = _resolver.typeSystem.resolveToBound(
      enclosingInstanceElement.thisType,
    );

    // The instance scope yields nothing for instance members, so look them up.
    if (receiverType is InterfaceTypeImpl) {
      var member = _resolveInstanceMember(
        receiverType.element,
        name,
        allowConstructors: false,
      );
      if (member != null) {
        return member;
      }
    }

    var extensionResult = _resolver.extensionResolver.findExtension(
      receiverType,
      component,
      Name(_resolver.definingLibrary.uri, name),
    );
    return extensionResult.getter2 ?? extensionResult.setter2;
  }
}
