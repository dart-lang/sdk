// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

import 'shims.dart';

enum EntryPointRole {
  // Dart_New (constructors) / Dart_Allocate (classes)
  allocation,
  // Dart_Invoke (invocable methods as well as invocable (function-valued)
  // fields and getters)
  call,
  // Dart_GetField (non-getter methods)
  closure,
  // Dart_GetClass (default type arguments for parameterized types)
  class_,
  // Dart_GetField (getter methods and fields)
  getter,
  // Dart_InvokeConstructor
  initialization,
  // Dart_SetField (setter methods and fields)
  setter,
  // Dart_NonNullableType
  nonNullableType,
  // Dart_NullableType
  nullableType,
}

class EntryPointShimCollector {
  final CoreTypes _coreTypes;
  final bool _errorOnUnhandledEntryPoints;
  final roles = <Reference, Set<EntryPointFunctionShim>>{};

  EntryPointShimCollector(this._coreTypes, this._errorOnUnhandledEntryPoints);

  bool _hasUnhandledFeatures(NamedNode node, FunctionType type) {
    if (type.namedParameters.isNotEmpty) {
      if (_errorOnUnhandledEntryPoints) {
        throw ArgumentError("$node: named parameters are not handled");
      }
      return true;
    }
    if (type.positionalParameters.length !=
        type.requiredPositionalParameterCount) {
      if (_errorOnUnhandledEntryPoints) {
        throw ArgumentError("$node: optional parameters are not handled");
      }
      return true;
    }
    if (type.typeParameters.isNotEmpty) {
      if (_errorOnUnhandledEntryPoints) {
        throw ArgumentError("$node: generic methods are not handled");
      }
      return true;
    }
    return false;
  }

  void add(Reference reference, EntryPointRole role) {
    final node = reference.node;
    late final EntryPointFunctionShim shim;
    switch (role) {
      case EntryPointRole.class_:
        shim = EntryPointClassShim.fromClass(node as Class, _coreTypes);
        break;
      case EntryPointRole.nonNullableType:
        shim = EntryPointNonNullableTypeShim.fromClass(
          node as Class,
          _coreTypes,
        );
        break;
      case EntryPointRole.nullableType:
        shim = EntryPointNullableTypeShim.fromClass(node as Class, _coreTypes);
        break;
      case EntryPointRole.allocation:
        if (node is Constructor) {
          if (_hasUnhandledFeatures(
            node,
            EntryPointNewShim.functionType(node),
          )) {
            return;
          }
          shim = EntryPointNewShim.fromConstructor(node, _coreTypes);
        } else {
          shim = EntryPointAllocationShim.fromClass(node as Class, _coreTypes);
        }
        break;
      case EntryPointRole.call:
        final member = node as Member;
        if (_hasUnhandledFeatures(
          member,
          EntryPointCallShim.functionType(member),
        )) {
          return;
        }
        shim = EntryPointCallShim.fromMember(member, _coreTypes);
        break;
      case EntryPointRole.closure:
        shim = EntryPointClosureShim.fromProcedure(
          node as Procedure,
          _coreTypes,
        );
        break;
      case EntryPointRole.getter:
        shim = EntryPointGetterShim.fromMember(node as Member, _coreTypes);
        break;
      case EntryPointRole.initialization:
        final c = node as Constructor;
        if (_hasUnhandledFeatures(
          c,
          EntryPointInitializationShim.functionType(c),
        )) {
          return;
        }
        shim = EntryPointInitializationShim.fromConstructor(c, _coreTypes);
        break;
      case EntryPointRole.setter:
        shim = EntryPointSetterShim.fromMember(node as Member, _coreTypes);
        break;
    }
    roles.putIfAbsent(reference, () => {}).add(shim);
  }

  void addAll(Reference reference, Iterable<EntryPointRole> it) =>
      it.forEach((role) => add(reference, role));

  Iterable<Reference> get keys => roles.keys;
  Iterable<MapEntry<Reference, Set<EntryPointFunctionShim>>> get entries =>
      roles.entries;
  Set<EntryPointFunctionShim>? operator [](Reference reference) =>
      roles[reference];
  bool containsKey(Reference reference) => roles.containsKey(reference);
}
