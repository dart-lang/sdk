// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations that describe the intended use of other annotations.
library meta_meta;

/// An annotation used on classes that are intended to be used as annotations
/// to indicate the kinds of declarations and directives for which the
/// annotation is appropriate.
///
/// The kinds are represented by the constants defined in [TargetKind].
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a class, where the
///   class must be usable as an annotation (that is, contain at least one
///   `const` constructor).
/// * the annotated annotation is associated with anything other than the kinds
///   of declarations listed as valid targets.
@Target({TargetKind.classType})
class Target {
  /// The kinds of declarations with which the annotated annotation can be
  /// associated.
  final Set<TargetKind> kinds;

  const Target(this.kinds);
}

/// An enumeration of the kinds of targets to which an annotation can be
/// applied.
class TargetKind {
  /// Indicates that an annotation is valid on any class declaration.
  static const classType = TargetKind._('classes', 'classType');

  /// Indicates that an annotation is valid on any enum declaration.
  static const enumType = TargetKind._('enums', 'enumType');

  /// Indicates that an annotation is valid on any extension declaration.
  static const extension = TargetKind._('extensions', 'extension');

  /// Indicates that an annotation is valid on any extension type declaration.
  static const extensionType = TargetKind._('extension types', 'extensionType');

  /// Indicates that an annotation is valid on any field declaration, both
  /// instance and static fields, whether it's in a class, mixin or extension.
  static const field = TargetKind._('fields', 'field');

  /// Indicates that an annotation is valid on any top-level function
  /// declaration.
  static const function = TargetKind._('top-level functions', 'function');

  /// Indicates that an annotation is valid on the first directive in a library,
  /// whether that's a `library`, `import`, `export` or `part` directive. This
  /// doesn't include the `part of` directive in a part file.
  static const library = TargetKind._('libraries', 'library');

  /// Indicates that an annotation is valid on any getter declaration, both
  /// instance or static getters, whether it's in a class, mixin, extension, or
  /// at the top-level of a library.
  static const getter = TargetKind._('getters', 'getter');

  /// Indicates that an annotation is valid on any method declaration, both
  /// instance and static methods, whether it's in a class, mixin or extension.
  static const method = TargetKind._('methods', 'method');

  /// Indicates that an annotation is valid on any mixin declaration.
  static const mixinType = TargetKind._('mixins', 'mixinType');

  /// Indicates that an annotation is valid on any formal parameter declaration,
  /// whether it's in a function, method, constructor, or closure.
  static const parameter = TargetKind._('parameters', 'parameter');

  /// Indicates that an annotation is valid on any setter declaration, both
  /// instance or static setters, whether it's in a class, mixin, extension, or
  /// at the top-level of a library.
  static const setter = TargetKind._('setters', 'setter');

  /// Indicates that an annotation is valid on any top-level variable
  /// declaration.
  static const topLevelVariable =
      TargetKind._('top-level variables', 'topLevelVariable');

  /// Indicates that an annotation is valid on any declaration that introduces a
  /// type. This includes classes, enums, mixins and typedefs, but does not
  /// include extensions because extensions don't introduce a type.
  static const type =
      TargetKind._('types (classes, enums, mixins, or typedefs)', 'type');

  /// Indicates that an annotation is valid on any typedef declaration.`
  static const typedefType = TargetKind._('typedefs', 'typedefType');

  static const values = [
    classType,
    enumType,
    extension,
    extensionType,
    field,
    function,
    library,
    getter,
    method,
    mixinType,
    parameter,
    setter,
    topLevelVariable,
    type,
    typedefType,
  ];

  /// A user visible string used to describe this target kind.
  final String displayString;

  /// The name of the [TargetKind] value.
  ///
  /// The name is a string containing the source identifier used to declare the [TargetKind] value.
  /// For example, the result of `TargetKind.classType.name` is the string "classType".
  final String name;

  // This class isnot meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  const TargetKind._(this.displayString, this.name);

  /// A numeric identifier for the enumerated value.
  int get index => values.indexOf(this);

  @override
  String toString() => 'TargetKind.$name';
}
