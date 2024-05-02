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
///
/// This type is not intended to be extended and will be marked as `final`
/// in a future release of `package:meta`.
@Target({TargetKind.classType})
class Target {
  /// The kinds of declarations with which the annotated annotation can be
  /// associated.
  final Set<TargetKind> kinds;

  /// Create a new instance of [Target] to be used as an annotation
  /// on a class intended to be used as an annotation, with the
  /// specified target [kinds] that it can be applied to.
  const Target(this.kinds);
}

/// An enumeration of the kinds of targets to which an annotation can be
/// applied.
///
/// This type is not intended to be extended and will be marked as `final`
/// in a future release of `package:meta`.
class TargetKind {
  /// Indicates that an annotation is valid on any class declaration.
  static const classType = TargetKind._('classes', 'classType');

  /// Indicates that an annotation is valid on any constructor declaration, both
  /// factory and generative constructors, whether it's in a class, enum, or
  /// extension type. Extension type primary constructors are not supported,
  /// because there is no way to annotate a primary constructor.
  static const constructor = TargetKind._('constructors', 'constructor');

  /// Indicates that an annotation is valid on any directive in a library or
  /// part file, whether it's a `library`, `import`, `export`, `part`, or
  /// `part of` directive.
  static const directive = TargetKind._('directives', 'directive');

  /// Indicates that an annotation is valid on any enum declaration.
  static const enumType = TargetKind._('enums', 'enumType');

  /// Indicates that an annotation is valid on any enum value declaration.
  static const enumValue = TargetKind._('enum values', 'enumValue');

  /// Indicates that an annotation is valid on any extension declaration.
  static const extension = TargetKind._('extensions', 'extension');

  /// Indicates that an annotation is valid on any extension type declaration.
  static const extensionType = TargetKind._('extension types', 'extensionType');

  /// Indicates that an annotation is valid on any field declaration, both
  /// instance and static fields, whether it's in a class, enum, mixin, or
  /// extension.
  static const field = TargetKind._('fields', 'field');

  /// Indicates that an annotation is valid on any top-level function
  /// declaration.
  static const function = TargetKind._('top-level functions', 'function');

  /// Indicates that an annotation is valid on any overridable instance member
  /// declaration, whether it's in a class, enum, extension type, or mixin. This
  /// includes instance fields, getters, setters, methods, and operators.
  static const overridableMember =
      TargetKind._('overridable members', 'overridableMember');

  /// Indicates that an annotation is valid on the first directive in a library,
  /// whether that's a `library`, `import`, `export` or `part` directive. This
  /// doesn't include the `part of` directive in a part file.
  static const library = TargetKind._('libraries', 'library');

  /// Indicates that an annotation is valid on any getter declaration, both
  /// instance or static getters, whether it's in a class, enum, mixin,
  /// extension, extension type, or at the top-level of a library.
  static const getter = TargetKind._('getters', 'getter');

  /// Indicates that an annotation is valid on any method declaration, both
  /// instance and static methods, whether it's in a class, enum, mixin,
  /// extension, or extension type.
  static const method = TargetKind._('methods', 'method');

  /// Indicates that an annotation is valid on any mixin declaration.
  static const mixinType = TargetKind._('mixins', 'mixinType');

  /// Indicates that an annotation is valid on any optional formal parameter
  /// declaration, whether it's in a constructor, function (named or anonymous),
  /// function type, function-typed formal parameter, or method.
  static const optionalParameter =
      TargetKind._('optional parameters', 'optionalParameter');

  /// Indicates that an annotation is valid on any formal parameter declaration,
  /// whether it's in a constructor, function (named or anonymous), function
  /// type, function-typed formal parameter, or method.
  static const parameter = TargetKind._('parameters', 'parameter');

  /// Indicates that an annotation is valid on any setter declaration, both
  /// instance or static setters, whether it's in a class, enum, mixin,
  /// extension, extension type, or at the top-level of a library.
  static const setter = TargetKind._('setters', 'setter');

  /// Indicates that an annotation is valid on any top-level variable
  /// declaration.
  static const topLevelVariable =
      TargetKind._('top-level variables', 'topLevelVariable');

  /// Indicates that an annotation is valid on any declaration that introduces a
  /// type. This includes classes, enums, mixins, and typedefs, but does not
  /// include extensions because extensions don't introduce a type.
  // TODO(srawlins): This should include extension types.
  static const type =
      TargetKind._('types (classes, enums, mixins, or typedefs)', 'type');

  /// Indicates that an annotation is valid on any typedef declaration.
  static const typedefType = TargetKind._('typedefs', 'typedefType');

  /// Indicates that an annotation is valid on any type parameter declaration,
  /// whether it's on a class, enum, function type, function, mixin, extension,
  /// extension type, or typedef.
  static const typeParameter = TargetKind._('type parameters', 'typeParameter');

  /// All current [TargetKind] values of targets to
  /// which an annotation can be applied.
  static const values = [
    classType,
    constructor,
    directive,
    enumType,
    enumValue,
    extension,
    extensionType,
    field,
    function,
    overridableMember,
    library,
    getter,
    method,
    mixinType,
    optionalParameter,
    parameter,
    setter,
    topLevelVariable,
    type,
    typedefType,
    typeParameter,
  ];

  /// A user visible string used to describe this target kind.
  final String displayString;

  /// The name of the [TargetKind] value.
  ///
  /// The name is a string containing the source identifier used
  /// to declare the [TargetKind] value. For example,
  /// the result of `TargetKind.classType.name`is the string "classType".
  final String name;

  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  const TargetKind._(this.displayString, this.name);

  /// A numeric identifier for the enumerated value.
  int get index => values.indexOf(this);

  @override
  String toString() => 'TargetKind.$name';
}
