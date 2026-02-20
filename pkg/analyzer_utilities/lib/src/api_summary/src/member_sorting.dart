// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

/// Element categorization used by [MemberSortKey].
enum MemberCategory {
  constructor,
  propertyAccessor,
  topLevelFunctionOrMethod,
  interface,
  extension,
  typeAlias,
}

/// Sort key used to sort elements in the output.
class MemberSortKey implements Comparable<MemberSortKey> {
  final bool _isInstanceMember;
  final MemberCategory _category;
  final String _name;

  MemberSortKey(Element element)
    : _isInstanceMember = _computeIsInstanceMember(element),
      _category = _computeCategory(element),
      _name = element.name!;

  @override
  int compareTo(MemberSortKey other) {
    if ((_isInstanceMember ? 1 : 0).compareTo(other._isInstanceMember ? 1 : 0)
        case var value when value != 0) {
      return value;
    }
    if (_category.index.compareTo(other._category.index) case var value
        when value != 0) {
      return value;
    }
    return _name.compareTo(other._name);
  }

  static MemberCategory _computeCategory(Element element) => switch (element) {
    ConstructorElement() => MemberCategory.constructor,
    PropertyAccessorElement() => MemberCategory.propertyAccessor,
    TopLevelFunctionElement() => MemberCategory.topLevelFunctionOrMethod,
    MethodElement() => MemberCategory.topLevelFunctionOrMethod,
    InterfaceElement() => MemberCategory.interface,
    ExtensionElement() => MemberCategory.extension,
    TypeAliasElement() => MemberCategory.typeAlias,
    dynamic(:var runtimeType) => throw UnimplementedError(
      'Unexpected element: $runtimeType',
    ),
  };

  static bool _computeIsInstanceMember(Element element) =>
      element.enclosingElement is InstanceElement &&
      switch (element) {
        ExecutableElement(:var isStatic) => !isStatic,
        dynamic(:var runtimeType) => throw UnimplementedError(
          'Unexpected element: $runtimeType',
        ),
      };
}
