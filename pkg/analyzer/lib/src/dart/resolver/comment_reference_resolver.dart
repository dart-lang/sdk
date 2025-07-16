// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/generated/resolver.dart';

class CommentReferenceResolver {
  final TypeProviderImpl _typeProvider;

  final ResolverVisitor _resolver;

  /// Helper for resolving properties on types.
  final TypePropertyResolver _typePropertyResolver;

  CommentReferenceResolver(this._typeProvider, this._resolver)
    : _typePropertyResolver = _resolver.typePropertyResolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Resolves [commentReference].
  void resolve(CommentReference commentReference) {
    _resolver.diagnosticReporter.lockLevel++;
    try {
      var expression = commentReference.expression;
      if (expression is SimpleIdentifierImpl) {
        _resolveSimpleIdentifierReference(
          expression,
          hasNewKeyword: commentReference.newKeyword != null,
        );
      } else if (expression is PrefixedIdentifierImpl) {
        _resolvePrefixedIdentifierReference(
          expression,
          hasNewKeyword: commentReference.newKeyword != null,
        );
      } else if (expression is PropertyAccessImpl) {
        _resolvePropertyAccessReference(
          expression,
          hasNewKeyword: commentReference.newKeyword != null,
        );
      }
    } finally {
      _resolver.diagnosticReporter.lockLevel--;
    }
  }

  void _resolvePrefixedIdentifierReference(
    PrefixedIdentifierImpl expression, {
    required bool hasNewKeyword,
  }) {
    var prefix = expression.prefix;
    var prefixElement = _resolveSimpleIdentifier(prefix);
    prefix.element = prefixElement;

    if (prefixElement == null) {
      return;
    }

    var name = expression.identifier;

    if (prefixElement is TypeAliasElement) {
      // When resolving `name`, use the aliased element.
      prefixElement = prefixElement.aliasedType.element;
    }

    if (prefixElement is PrefixElement) {
      var prefixScope = prefixElement.scope;
      var lookupResult = prefixScope.lookup(name.name);
      var element = lookupResult.getter ?? lookupResult.setter;
      name.element = element;
      return;
    }

    if (!hasNewKeyword) {
      if (prefixElement is InterfaceElement) {
        name.element =
            _resolver.inheritance.getMember(
              prefixElement,
              Name(prefixElement.library.uri, name.name),
            ) ??
            prefixElement.getMethod(name.name) ??
            prefixElement.getGetter(name.name) ??
            prefixElement.getSetter(name.name) ??
            prefixElement.getNamedConstructor(name.name);
      } else if (prefixElement is ExtensionElement) {
        name.element =
            prefixElement.getMethod(name.name) ??
            prefixElement.getGetter(name.name) ??
            prefixElement.getSetter(name.name);
      } else {
        // TODO(brianwilkerson): Report this error.
      }
    } else if (prefixElement is InterfaceElement) {
      var constructor = prefixElement.getNamedConstructor(name.name);
      if (constructor == null) {
        // TODO(brianwilkerson): Report this error.
      } else {
        name.element = constructor;
      }
    } else {
      // TODO(brianwilkerson): Report this error.
    }
  }

  void _resolvePropertyAccessReference(
    PropertyAccessImpl expression, {
    required bool hasNewKeyword,
  }) {
    var target = expression.target;
    if (target is! PrefixedIdentifierImpl) {
      // A PropertyAccess with a target more complex than a
      // [PrefixedIdentifier] is not a valid comment reference.
      return;
    }

    var prefix = target.prefix;
    var prefixElement = _resolveSimpleIdentifier(prefix);
    prefix.element = prefixElement;

    if (prefixElement is! PrefixElement) {
      // The only valid prefixElement is a PrefixElement; otherwise, this is
      // not a comment reference.
      return;
    }

    var name = target.identifier;
    var prefixScope = prefixElement.scope;
    var lookupResult = prefixScope.lookup(name.name);
    var element = lookupResult.getter ?? lookupResult.setter;
    name.element = element;

    var propertyName = expression.propertyName;

    if (element is TypeAliasElement) {
      // When resolving `propertyName`, use the aliased element.
      element = element.aliasedType.element;
    }

    if (element is InterfaceElement) {
      propertyName.element =
          element.getMethod(propertyName.name) ??
          element.getGetter(propertyName.name) ??
          element.getSetter(propertyName.name) ??
          element.getNamedConstructor(propertyName.name);
    } else if (element is ExtensionElement) {
      propertyName.element =
          element.getMethod(propertyName.name) ??
          element.getGetter(propertyName.name) ??
          element.getSetter(propertyName.name);
    }
  }

  /// Resolves the given simple [identifier] if possible.
  ///
  /// Returns the resolved element, or `null` if the identifier could not be
  /// resolved. This does not record the results of the resolution.
  Element? _resolveSimpleIdentifier(SimpleIdentifierImpl identifier) {
    var lookupResult = identifier.scopeLookupResult!;
    var element = lookupResult.getter ?? lookupResult.setter;

    // Usually referencing just an import prefix is an error.
    // But we allow this in documentation comments.
    if (element is PrefixElementImpl) {
      element.scope.notifyPrefixUsedInCommentReference();
    }

    if (element == null) {
      InterfaceTypeImpl enclosingType;
      var enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        enclosingType = enclosingClass.thisType;
      } else {
        var enclosingExtension = _resolver.enclosingExtension;
        if (enclosingExtension == null) {
          return null;
        }
        var extendedType = _typeSystem.resolveToBound(
          enclosingExtension.extendedType,
        );
        if (extendedType is InterfaceTypeImpl) {
          enclosingType = extendedType;
        } else if (extendedType is FunctionType) {
          enclosingType = _typeProvider.functionType;
        } else {
          return null;
        }
      }
      var result = _typePropertyResolver.resolve(
        receiver: null,
        receiverType: enclosingType,
        name: identifier.name,
        hasRead: true,
        hasWrite: true,
        propertyErrorEntity: identifier,
        nameErrorEntity: identifier,
      );
      element = result.getter2 ?? result.setter2;
    }
    return element;
  }

  void _resolveSimpleIdentifierReference(
    SimpleIdentifierImpl expression, {
    required bool hasNewKeyword,
  }) {
    var element = _resolveSimpleIdentifier(expression);
    if (element == null) {
      return;
    }
    expression.element = element;
    if (hasNewKeyword) {
      if (element is InterfaceElement) {
        var constructor = element.unnamedConstructor;
        if (constructor == null) {
          // TODO(brianwilkerson): Report this error.
        } else {
          expression.element = constructor;
        }
      } else {
        // TODO(brianwilkerson): Report this error.
      }
    }
  }
}
