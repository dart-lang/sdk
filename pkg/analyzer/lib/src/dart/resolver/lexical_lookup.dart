// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

class LexicalLookup {
  final ResolverVisitor _resolver;

  LexicalLookup(this._resolver);

  LexicalLookupResult perform({
    @required SimpleIdentifier node,
    @required bool setter,
  }) {
    var id = node.name;
    var scopeResult = _resolver.nameScope.lookup(id);
    var scopeGetter = scopeResult.getter;
    var scopeSetter = scopeResult.setter;
    if (scopeGetter != null || scopeSetter != null) {
      if (scopeGetter is VariableElement) {
        return LexicalLookupResult(requested: scopeGetter);
      }
      if (setter) {
        if (scopeSetter != null) {
          return LexicalLookupResult(
            requested: _resolver.toLegacyElement(scopeSetter),
          );
        }
        if (!scopeGetter.isInstanceMember) {
          return LexicalLookupResult(
            recovery: _resolver.toLegacyElement(scopeGetter),
          );
        }
      } else {
        if (scopeGetter != null) {
          return LexicalLookupResult(
            requested: _resolver.toLegacyElement(scopeGetter),
          );
        }
      }
    }

    var thisType = _resolver.thisType;
    if (thisType == null) {
      var recoveryElement = setter ? scopeGetter : scopeGetter;
      return LexicalLookupResult(
        recovery: _resolver.toLegacyElement(recoveryElement),
      );
    }

    var propertyResult = _resolver.typePropertyResolver.resolve(
      receiver: null,
      receiverType: thisType,
      name: id,
      receiverErrorNode: node,
      nameErrorEntity: node,
    );

    if (setter) {
      var setterElement = propertyResult.setter;
      if (setterElement != null) {
        return LexicalLookupResult(
          requested: _resolver.toLegacyElement(setterElement),
        );
      } else {
        var recoveryElement = scopeGetter ?? propertyResult.getter;
        return LexicalLookupResult(
          recovery: _resolver.toLegacyElement(recoveryElement),
        );
      }
    } else {
      var getterElement = propertyResult.getter;
      if (getterElement != null) {
        return LexicalLookupResult(
          requested: _resolver.toLegacyElement(getterElement),
        );
      } else {
        var recoveryElement = scopeSetter ?? propertyResult.setter;
        return LexicalLookupResult(
          recovery: _resolver.toLegacyElement(recoveryElement),
        );
      }
    }
  }
}

class LexicalLookupResult {
  final Element requested;
  final Element recovery;

  LexicalLookupResult({this.requested, this.recovery});
}
