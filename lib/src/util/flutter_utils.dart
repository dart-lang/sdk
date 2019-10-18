// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../util/dart_type_utilities.dart';

var _collectionInterfaces = <InterfaceTypeDefinition>[
  InterfaceTypeDefinition('List', 'dart.core'),
  InterfaceTypeDefinition('Map', 'dart.core'),
  InterfaceTypeDefinition('LinkedHashMap', 'dart.collection'),
  InterfaceTypeDefinition('Set', 'dart.core'),
  InterfaceTypeDefinition('LinkedHashSet', 'dart.collection'),
];

_Flutter _flutterInstance = _Flutter('flutter', 'package:flutter');

_Flutter get _flutter => _flutterInstance;

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

bool isWidgetType(DartType type) => _flutter.isWidgetType(type);

/// See: analysis_server/lib/src/utilities/flutter.dart
class _Flutter {
  static const _nameWidget = 'Widget';
  static const _nameContainer = 'Container';

  final String packageName;
  final String widgetsUri;

  final Uri _uriContainer;
  final Uri _uriFramework;

  _Flutter(this.packageName, String uriPrefix)
      : widgetsUri = '$uriPrefix/widgets.dart',
        _uriContainer = Uri.parse('$uriPrefix/src/widgets/container.dart'),
        _uriFramework = Uri.parse('$uriPrefix/src/widgets/framework.dart');

  bool isExactWidgetTypeContainer(DartType type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameContainer, _uriContainer);

  bool isWidget(ClassElement element) {
    if (element == null) {
      return false;
    }
    if (_isExactWidget(element, _nameWidget, _uriFramework)) {
      return true;
    }
    for (InterfaceType type in element.allSupertypes) {
      if (_isExactWidget(type.element, _nameWidget, _uriFramework)) {
        return true;
      }
    }
    return false;
  }

  bool isWidgetType(DartType type) =>
      type is InterfaceType && isWidget(type.element);

  bool _isExactWidget(ClassElement element, String type, Uri uri) =>
      element != null && element.name == type && element.source.uri == uri;
}
