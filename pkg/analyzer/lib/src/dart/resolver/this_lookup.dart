// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Class containing static methods for resolving identifiers as implicit
/// property gets/sets on the type of `this`.
class ThisLookup {
  /// Do not construct
  ThisLookup._() {
    assert(false, 'Do not construct instances of LexicalLookup');
  }

  /// Attempts to resolve an identifier with name, `node.name`, via implicit
  /// `this.`, assuming we are trying to look up a getter.
  ///
  /// If a matching element is found, a [LexicalLookupResult] is returned.
  /// Otherwise `null` is returned.
  static LexicalLookupResult? lookupGetter(
    ResolverVisitor resolver,
    SimpleIdentifier node,
  ) {
    var id = node.name;
    var thisType = resolver.thisType;
    if (thisType == null) {
      return null;
    }

    var propertyResult = resolver.typePropertyResolver.resolve(
      receiver: null,
      receiverType: thisType,
      name: id,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node,
      nameErrorEntity: node,
    );

    var callFunctionType = propertyResult.callFunctionType;
    if (callFunctionType != null) {
      return LexicalLookupResult(callFunctionType: callFunctionType);
    }

    var recordField = propertyResult.recordField;
    if (recordField != null) {
      return LexicalLookupResult(recordField: recordField);
    }

    var getterElement = propertyResult.getter2;
    if (getterElement != null) {
      return LexicalLookupResult(requested: getterElement);
    } else {
      return LexicalLookupResult(recovery: propertyResult.setter2);
    }
  }

  /// Attempts to resolve an identifier with name, `node.name`, via implicit
  /// `this.`, assuming we are trying to look up a setter.
  ///
  /// If a matching element is found, a [LexicalLookupResult] is returned.
  /// Otherwise `null` is returned.
  static LexicalLookupResult? lookupSetter(
    ResolverVisitor resolver,
    SimpleIdentifier node,
  ) {
    var id = node.name;
    var thisType = resolver.thisType;
    if (thisType == null) {
      return null;
    }

    var propertyResult = resolver.typePropertyResolver.resolve(
      receiver: null,
      receiverType: thisType,
      name: id,
      hasRead: false,
      hasWrite: true,
      propertyErrorEntity: node,
      nameErrorEntity: node,
    );

    var setterElement = propertyResult.setter2;
    if (setterElement != null) {
      return LexicalLookupResult(requested: setterElement);
    } else {
      return LexicalLookupResult(recovery: propertyResult.getter2);
    }
  }
}
