// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../extensions.dart';
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

bool hasWidgetAsAscendant(ClassElement element) =>
    _flutter.hasWidgetAsAscendant(element);

bool isBuildContext(DartType? type, {bool skipNullable = false}) =>
    _flutter.isBuildContext(type, skipNullable: skipNullable);

bool isExactWidget(ClassElement element) => _flutter.isExactWidget(element);

bool isExactWidgetTypeContainer(DartType? type) =>
    _flutter.isExactWidgetTypeContainer(type);

bool isExactWidgetTypeSizedBox(DartType? type) =>
    _flutter.isExactWidgetTypeSizedBox(type);

bool isKDebugMode(Element2? element) => _flutter.isKDebugMode(element);

bool isState(InterfaceElement element) => _flutter.isState(element);

bool isStatefulWidget(ClassElement2? element) =>
    element != null && _flutter.isStatefulWidget(element);

bool isWidgetProperty(DartType? type) {
  if (isWidgetType(type)) {
    return true;
  }
  if (type is InterfaceType &&
      type.implementsAnyInterface(_collectionInterfaces)) {
    return type.element.typeParameters.length == 1 &&
        isWidgetProperty(type.typeArguments.first);
  }
  return false;
}

bool isWidgetType(DartType? type) => _flutter.isWidgetType(type);

/// A utility class for determining whether a given element is an expected
/// Flutter element.
///
/// See pkg/analysis_server/lib/src/utilities/flutter.dart.
class _Flutter {
  static const _nameBuildContext = 'BuildContext';
  static const _nameContainer = 'Container';
  static const _nameSizedBox = 'SizedBox';
  static const _nameState = 'State';
  static const _nameStatefulWidget = 'StatefulWidget';
  static const _nameWidget = 'Widget';

  final String packageName;
  final String widgetsUri;

  final Uri _uriBasic;
  final Uri _uriContainer;
  final Uri _uriFramework;
  final Uri _uriFoundation;

  _Flutter(this.packageName, String uriPrefix)
      : widgetsUri = '$uriPrefix/widgets.dart',
        _uriBasic = Uri.parse('$uriPrefix/src/widgets/basic.dart'),
        _uriContainer = Uri.parse('$uriPrefix/src/widgets/container.dart'),
        _uriFramework = Uri.parse('$uriPrefix/src/widgets/framework.dart'),
        _uriFoundation = Uri.parse('$uriPrefix/src/foundation/constants.dart');

  bool hasWidgetAsAscendant(InterfaceElement? element,
      [Set<InterfaceElement>? alreadySeen]) {
    if (element == null) return false;

    if (isExactly(element, _nameWidget, _uriFramework)) return true;

    alreadySeen ??= {};
    if (!alreadySeen.add(element)) return false;

    var type =
        element.isAugmentation ? element.augmented.thisType : element.supertype;
    return hasWidgetAsAscendant(type?.element, alreadySeen);
  }

  bool isBuildContext(DartType? type, {bool skipNullable = false}) {
    if (type is! InterfaceType) {
      return false;
    }
    if (skipNullable && type.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    }
    return isExactly(type.element, _nameBuildContext, _uriFramework);
  }

  /// Whether [element] is exactly the element named [type], from Flutter.
  bool isExactly(InterfaceElement element, String type, Uri uri) =>
      element.name == type && element.source.uri == uri;

  /// Whether [element] is exactly the element named [type], from Flutter.
  bool isExactly2(InterfaceElement2 element, String type, Uri uri) =>
      element.name3 == type &&
      element.firstFragment.libraryFragment.source.uri == uri;

  bool isExactWidget(ClassElement element) =>
      isExactly(element, _nameWidget, _uriFramework);

  bool isExactWidgetTypeContainer(DartType? type) =>
      type is InterfaceType &&
      isExactly(type.element, _nameContainer, _uriContainer);

  bool isExactWidgetTypeSizedBox(DartType? type) =>
      type is InterfaceType &&
      isExactly(type.element, _nameSizedBox, _uriBasic);

  bool isKDebugMode(Element2? element) =>
      element != null &&
      element.name3 == 'kDebugMode' &&
      element.library2.uri == _uriFoundation;

  bool isState(InterfaceElement element) =>
      isExactly(element, _nameState, _uriFramework) ||
      element.allSupertypes
          .any((type) => isExactly(type.element, _nameState, _uriFramework));

  bool isStatefulWidget(ClassElement2 element) =>
      isExactly2(element, _nameStatefulWidget, _uriFramework) ||
      element.allSupertypes.any((type) =>
          isExactly(type.element, _nameStatefulWidget, _uriFramework));

  bool isWidget(InterfaceElement element) {
    if (isExactly(element, _nameWidget, _uriFramework)) {
      return true;
    }
    for (var type in element.allSupertypes) {
      if (isExactly(type.element, _nameWidget, _uriFramework)) {
        return true;
      }
    }
    return false;
  }

  bool isWidgetType(DartType? type) =>
      type is InterfaceType && isWidget(type.element);
}
