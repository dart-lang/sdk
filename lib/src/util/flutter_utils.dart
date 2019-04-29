// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

var _collectionInterfaces = <InterfaceTypeDefinition>[
  new InterfaceTypeDefinition('List', 'dart.core'),
  new InterfaceTypeDefinition('Map', 'dart.core'),
  new InterfaceTypeDefinition('LinkedHashMap', 'dart.collection'),
  new InterfaceTypeDefinition('Set', 'dart.core'),
  new InterfaceTypeDefinition('LinkedHashSet', 'dart.collection'),
];

// todo (pq): consider caching lookups
bool isWidgetType(DartType type) =>
    DartTypeUtilities.implementsInterface(type, 'Widget', '');

bool isWidgetProperty(DartType type) {
  if (isWidgetType(type)) {
    return true;
  }
  if (type is ParameterizedType &&
      DartTypeUtilities.implementsAnyInterface(type, _collectionInterfaces)) {
    return type.typeParameters.length == 1 &&
        isWidgetProperty(type.typeArguments.first);
  }
  return false;
}
