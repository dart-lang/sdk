// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../extensions.dart';
import '../util/dart_type_utilities.dart';

const _nameBuildContext = 'BuildContext';
const _nameContainer = 'Container';
const _nameSizedBox = 'SizedBox';
const _nameState = 'State';
const _nameStatefulWidget = 'StatefulWidget';
const _nameWidget = 'Widget';

var _collectionInterfaces = [
  InterfaceTypeDefinition('List', 'dart.core'),
  InterfaceTypeDefinition('Map', 'dart.core'),
  InterfaceTypeDefinition('LinkedHashMap', 'dart.collection'),
  InterfaceTypeDefinition('Set', 'dart.core'),
  InterfaceTypeDefinition('LinkedHashSet', 'dart.collection'),
];

final _uriBasic = Uri.parse('package:flutter/src/widgets/basic.dart');
final _uriContainer = Uri.parse('package:flutter/src/widgets/container.dart');
final _uriFoundation = Uri.parse(
  'package:flutter/src/foundation/constants.dart',
);
final _uriFramework = Uri.parse('package:flutter/src/widgets/framework.dart');

bool isBuildContext(DartType? type, {bool skipNullable = false}) {
  if (type is! InterfaceType) return false;
  if (skipNullable && type.nullabilitySuffix == NullabilitySuffix.question) {
    return false;
  }
  return _isExactly(type.element, _nameBuildContext, _uriFramework);
}

bool isExactWidgetTypeContainer(DartType? type) =>
    type is InterfaceType &&
    _isExactly(type.element, _nameContainer, _uriContainer);

bool isExactWidgetTypeSizedBox(DartType? type) =>
    type is InterfaceType && _isExactly(type.element, _nameSizedBox, _uriBasic);

bool isKDebugMode(Element? element) =>
    element != null &&
    element.name == 'kDebugMode' &&
    element.library?.uri == _uriFoundation;

bool isState(InterfaceElement element) =>
    _isExactly(element, _nameState, _uriFramework) ||
    element.allSupertypes.any(
      (type) => _isExactly(type.element, _nameState, _uriFramework),
    );

bool isStatefulWidget(ClassElement element) =>
    _isExactly(element, _nameStatefulWidget, _uriFramework) ||
    element.allSupertypes.any(
      (type) => _isExactly(type.element, _nameStatefulWidget, _uriFramework),
    );

bool isWidgetProperty(DartType? type) {
  if (isWidgetType(type)) return true;

  if (type is InterfaceType &&
      type.implementsAnyInterface(_collectionInterfaces)) {
    return type.element.typeParameters.length == 1 &&
        isWidgetProperty(type.typeArguments.first);
  }
  return false;
}

bool isWidgetType(DartType? type) =>
    type is InterfaceType && _isWidget(type.element);

/// Whether [element] is exactly the element named [type], from Flutter.
bool _isExactly(InterfaceElement element, String type, Uri uri) =>
    element.name == type && element.library.uri == uri;

/// Whether [element] is or subclasses `Widget`, from Flutter.
bool _isWidget(InterfaceElement element) {
  if (_isExactly(element, _nameWidget, _uriFramework)) return true;

  for (var type in element.allSupertypes) {
    if (_isExactly(type.element, _nameWidget, _uriFramework)) return true;
  }
  return false;
}

// TODO(pq): based on similar extension in server. (Move and reuse.)
extension InterfaceElementExtension2 on InterfaceElement? {
  bool get extendsWidget => _hasWidgetAsAscendant(this, {});

  bool get isExactlyWidget => _isExactly(_nameWidget, _uriFramework);

  /// Whether this is the Flutter class `Widget`, or a subtype.
  bool get isWidget {
    var self = this;
    if (self is! ClassElement) return false;

    if (isExactlyWidget) return true;

    return self.allSupertypes.any(
      (type) => type.element._isExactly(_nameWidget, _uriFramework),
    );
  }

  /// Whether this is the exact [type] defined in the file with the given [uri].
  bool _isExactly(String type, Uri uri) {
    var self = this;
    return self is ClassElement && self.name == type && self.library.uri == uri;
  }

  static bool _hasWidgetAsAscendant(
    InterfaceElement? element,
    Set<InterfaceElement> alreadySeen,
  ) {
    if (element == null) return false;
    if (element.isExactlyWidget) return true;

    if (!alreadySeen.add(element)) return false;

    return _hasWidgetAsAscendant(element.supertype?.element, alreadySeen);
  }
}
