// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:macros/macros.dart' as macro;

final class AliasedTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  AliasedTypeLocation(this.parent);
}

final class ElementTypeLocation extends TypeAnnotationLocation {
  @override
  final Element element;

  ElementTypeLocation(this.element);
}

final class ExtendsClauseTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  ExtendsClauseTypeLocation(this.parent);
}

final class ExtensionElementOnTypeLocation extends TypeAnnotationLocation {
  @override
  final ExtensionElement element;

  ExtensionElementOnTypeLocation(this.element);
}

final class ExtensionTypeElementRepresentationTypeLocation
    extends TypeAnnotationLocation {
  @override
  final ExtensionTypeElement element;

  ExtensionTypeElementRepresentationTypeLocation(this.element);
}

final class FormalParameterTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;
  final int index;

  FormalParameterTypeLocation(this.parent, this.index);

  @override
  Element? get element {
    var parentElement = parent.element;
    parentElement as ExecutableElement;
    return parentElement.parameters[index];
  }
}

final class ImplementsClauseTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  ImplementsClauseTypeLocation(this.parent);
}

final class ListIndexTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;
  final int index;

  ListIndexTypeLocation(this.parent, this.index);
}

final class OnClauseTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  OnClauseTypeLocation(this.parent);
}

final class RecordNamedFieldTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;
  final int index;

  RecordNamedFieldTypeLocation(this.parent, this.index);
}

final class RecordPositionalFieldTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;
  final int index;

  RecordPositionalFieldTypeLocation(this.parent, this.index);
}

final class ReturnTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  ReturnTypeLocation(this.parent);

  @override
  Element? get element {
    return parent.element;
  }
}

/// Description of a [macro.TypeAnnotation] location, in a way that can be
/// stored into summaries. Specifically, it cannot use offsets, but can use
/// references to [Element]s.
sealed class TypeAnnotationLocation {
  /// The enclosing element.
  Element? get element => null;
}

final class TypeParameterBoundLocation extends TypeAnnotationLocation {}

final class VariableTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  VariableTypeLocation(this.parent);

  @override
  Element? get element {
    return parent.element;
  }
}

final class WithClauseTypeLocation extends TypeAnnotationLocation {
  final TypeAnnotationLocation parent;

  WithClauseTypeLocation(this.parent);
}
