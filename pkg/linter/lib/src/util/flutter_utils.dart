// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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

extension FlutterDartTypeExtension on DartType? {
  bool get isWidgetProperty {
    var self = this;
    if (self.isWidgetType) return true;

    if (self is InterfaceType &&
        self.implementsAnyInterface(_collectionInterfaces)) {
      return self.element.typeParameters.length == 1 &&
          self.typeArguments.first.isWidgetProperty;
    }
    return false;
  }

  bool get isWidgetType {
    var self = this;
    return self is InterfaceType && self.element.isWidget;
  }

  bool isBuildContext({bool skipNullable = false}) {
    var self = this;
    if (self is! InterfaceType) return false;
    if (skipNullable && self.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    }
    return self.element._isExactly(_nameBuildContext, _uriFramework);
  }
}

extension FlutterElementExtension on Element? {
  bool get isKDebugMode {
    var self = this;
    return self != null &&
        self.name == 'kDebugMode' &&
        self.library?.uri == _uriFoundation;
  }
}

extension FlutterInstanceCreationExpressionExtension
    on InstanceCreationExpression {
  bool get isWidgetTypeContainer {
    var type = staticType;
    return type is InterfaceType &&
        type.element._isExactly(_nameContainer, _uriContainer);
  }

  bool get isWidgetTypeSizedBox {
    var type = staticType;
    return type is InterfaceType &&
        type.element._isExactly(_nameSizedBox, _uriBasic);
  }
}

// TODO(pq): based on similar extension in server. (Move and reuse.)
extension InterfaceElementExtension on InterfaceElement {
  bool get extendsWidget => _hasWidgetAsAscendant(this, {});

  bool get isExactlyWidget => _isExactly(_nameWidget, _uriFramework);

  bool get isState =>
      _isExactly(_nameState, _uriFramework) ||
      allSupertypes.any(
        (type) => type.element._isExactly(_nameState, _uriFramework),
      );

  bool get isStatefulWidget =>
      _isExactly(_nameStatefulWidget, _uriFramework) ||
      allSupertypes.any(
        (type) => type.element._isExactly(_nameStatefulWidget, _uriFramework),
      );

  /// Whether this is the Flutter class `Widget`, or a subtype.
  bool get isWidget {
    if (isExactlyWidget) return true;

    return allSupertypes.any(
      (type) => type.element._isExactly(_nameWidget, _uriFramework),
    );
  }

  /// Whether this is exactly the element named [type], from Flutter.
  bool _isExactly(String type, Uri uri) => name == type && library.uri == uri;

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
