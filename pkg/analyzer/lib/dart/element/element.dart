// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the element model. The element model describes the semantic (as
/// opposed to syntactic) structure of Dart code. The syntactic structure of the
/// code is modeled by the [AST
/// structure](../dart_ast_ast/dart_ast_ast-library.html).
///
/// The element model consists of two closely related kinds of objects: elements
/// (instances of a subclass of `Element`) and types. This library defines the
/// elements, the types are defined in
/// [type.dart](../dart_element_type/dart_element_type-library.html).
///
/// Generally speaking, an element represents something that is declared in the
/// code, such as a class, method, or variable. Elements are organized in a tree
/// structure in which the children of an element are the elements that are
/// logically (and often syntactically) part of the declaration of the parent.
/// For example, the elements representing the methods and fields in a class are
/// children of the element representing the class.
///
/// Every complete element structure is rooted by an instance of the class
/// `LibraryElement`. A library element represents a single Dart library. Every
/// library is defined by one or more compilation units (the library and all of
/// its parts). The compilation units are represented by the class
/// `CompilationUnitElement` and are children of the library that is defined by
/// them. Each compilation unit can contain zero or more top-level declarations,
/// such as classes, functions, and variables. Each of these is in turn
/// represented as an element that is a child of the compilation unit. Classes
/// contain methods and fields, methods can contain local variables, etc.
///
/// The element model does not contain everything in the code, only those things
/// that are declared by the code. For example, it does not include any
/// representation of the statements in a method body, but if one of those
/// statements declares a local variable then the local variable will be
/// represented by an element.
library;

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart'
    show elementModelDeprecationMsg;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
// ignore: deprecated_member_use_from_same_package
import 'package:analyzer/src/task/api/model.dart' show AnalysisTarget;
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// Meaning of a URI referenced in a directive.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUri {}

/// [DirectiveUriWithSource] that references a [LibraryElement2].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithLibrary extends DirectiveUriWithSource {
  /// The library referenced by the [source].
  LibraryElement2 get library2;
}

/// [DirectiveUriWithRelativeUriString] that can be parsed into a relative URI.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithRelativeUri
    extends DirectiveUriWithRelativeUriString {
  /// The relative URI, parsed from [relativeUriString].
  Uri get relativeUri;
}

/// [DirectiveUri] for which we can get its relative URI string.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithRelativeUriString extends DirectiveUri {
  /// The relative URI string specified in code.
  String get relativeUriString;
}

/// [DirectiveUriWithRelativeUri] that resolves to a [Source].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithSource extends DirectiveUriWithRelativeUri {
  /// The result of resolving [relativeUri] against the enclosing URI.
  Source get source;
}

/// [DirectiveUriWithSource] that references a [LibraryFragment].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithUnit extends DirectiveUriWithSource {
  /// The library fragment referenced by the [source].
  @experimental
  LibraryFragment get libraryFragment;
}

/// The base class for all of the elements in the element model. Generally
/// speaking, the element model is a semantic model of the program that
/// represents things that are declared with a name and hence can be referenced
/// elsewhere in the code.
///
/// There are two exceptions to the general case. First, there are elements in
/// the element model that are created for the convenience of various kinds of
/// analysis but that do not have any corresponding declaration within the
/// source code. Such elements are marked as being <i>synthetic</i>. Examples of
/// synthetic elements include
/// * default constructors in classes that do not define any explicit
///   constructors,
/// * getters and setters that are induced by explicit field declarations,
/// * fields that are induced by explicit declarations of getters and setters,
///   and
/// * functions representing the initialization expression for a variable.
///
/// Second, there are elements in the element model that do not have a name.
/// These correspond to unnamed functions and exist in order to more accurately
/// represent the semantic structure of the program.
///
/// Clients may not extend, implement or mix-in this class.
@Deprecated(elementModelDeprecationMsg)
abstract class Element implements AnalysisTarget {
  /// The analysis context in which this element is defined.
  AnalysisContext get context;

  /// The declaration of this element.
  ///
  /// If the element is a view on an element, e.g. a method from an interface
  /// type, with substituted type parameters, return the corresponding element
  /// from the class, without any substitutions. If this element is already a
  /// declaration (or a synthetic element, e.g. a synthetic property accessor),
  /// return itself.
  @Deprecated(elementModelDeprecationMsg)
  Element? get declaration;

  /// The display name of this element, possibly the empty string if the
  /// element does not have a name.
  ///
  /// In most cases the name and the display name are the same. Differences
  /// though are cases such as setters where the name of some setter `set f(x)`
  /// is `f=`, instead of `f`.
  String get displayName;

  /// The content of the documentation comment (including delimiters) for this
  /// element, or `null` if this element does not or cannot have documentation.
  String? get documentationComment;

  /// The element that either physically or logically encloses this element.
  ///
  /// For [LibraryElement] returns `null`, because libraries are the top-level
  /// elements in the model.
  ///
  /// For [CompilationUnitElement] returns the [CompilationUnitElement] that
  /// uses `part` directive to include this element, or `null` if this element
  /// is the defining unit of the library.
  @Deprecated('Use Element2.enclosingElement2 instead or '
      'Fragment.enclosingFragment instead')
  Element? get enclosingElement3;

  /// Whether the element has an annotation of the form `@alwaysThrows`.
  bool get hasAlwaysThrows;

  /// Whether the element has an annotation of the form `@deprecated`
  /// or `@Deprecated('..')`.
  bool get hasDeprecated;

  /// Whether the element has an annotation of the form `@doNotStore`.
  bool get hasDoNotStore;

  /// Whether the element has an annotation of the form `@doNotSubmit`.
  bool get hasDoNotSubmit;

  /// Whether the element has an annotation of the form `@factory`.
  bool get hasFactory;

  /// Whether the element has an annotation of the form `@immutable`.
  bool get hasImmutable;

  /// Whether the element has an annotation of the form `@internal`.
  bool get hasInternal;

  /// Whether the element has an annotation of the form `@isTest`.
  bool get hasIsTest;

  /// Whether the element has an annotation of the form `@isTestGroup`.
  bool get hasIsTestGroup;

  /// Whether the element has an annotation of the form `@JS(..)`.
  bool get hasJS;

  /// Whether the element has an annotation of the form `@literal`.
  bool get hasLiteral;

  /// Whether the element has an annotation of the form `@mustBeConst`.
  bool get hasMustBeConst;

  /// Whether the element has an annotation of the form `@mustBeOverridden`.
  bool get hasMustBeOverridden;

  /// Whether the element has an annotation of the form `@mustCallSuper`.
  bool get hasMustCallSuper;

  /// Whether the element has an annotation of the form `@nonVirtual`.
  bool get hasNonVirtual;

  /// Whether the element has an annotation of the form `@optionalTypeArgs`.
  bool get hasOptionalTypeArgs;

  /// Whether the element has an annotation of the form `@override`.
  bool get hasOverride;

  /// Whether the element has an annotation of the form `@protected`.
  bool get hasProtected;

  /// Whether the element has an annotation of the form `@redeclare`.
  bool get hasRedeclare;

  /// Whether the element has an annotation of the form `@reopen`.
  bool get hasReopen;

  /// Whether the element has an annotation of the form `@required`.
  bool get hasRequired;

  /// Whether the element has an annotation of the form `@sealed`.
  bool get hasSealed;

  /// Whether the element has an annotation of the form `@useResult`
  /// or `@UseResult('..')`.
  bool get hasUseResult;

  /// Whether the element has an annotation of the form `@visibleForOverriding`.
  bool get hasVisibleForOverriding;

  /// Whether the element has an annotation of the form `@visibleForTemplate`.
  bool get hasVisibleForTemplate;

  /// Whether the element has an annotation of the form `@visibleForTesting`.
  bool get hasVisibleForTesting;

  /// Whether the element has an annotation of the form
  /// `@visibleOutsideTemplate`.
  bool get hasVisibleOutsideTemplate;

  /// The unique integer identifier of this element.
  int get id;

  /// Whether the element is private.
  ///
  /// Private elements are visible only within the library in which they are
  /// declared.
  bool get isPrivate;

  /// Whether the element is public.
  ///
  /// Public elements are visible within any library that imports the library
  /// in which they are declared.
  bool get isPublic;

  /// Whether the element is synthetic.
  ///
  /// A synthetic element is an element that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  bool get isSynthetic;

  /// The kind of element that this is.
  ElementKind get kind;

  /// The location of this element in the element model.
  ///
  /// The object can be used to locate this element at a later time.
  ElementLocation? get location;

  /// All of the metadata associated with this element.
  ///
  /// The array will be empty if the element does not have any metadata or if
  /// the library containing this element has not yet been resolved.
  List<ElementAnnotation> get metadata;

  /// The name of this element, or `null` if this element does not have a name.
  String? get name;

  /// The length of the name of this element in the file that contains the
  /// declaration of this element, or `0` if this element does not have a name.
  int get nameLength;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element, or `-1` if this element is synthetic, does
  /// not have a name, or otherwise does not have an offset.
  int get nameOffset;

  /// The non-synthetic element that caused this element to be created.
  ///
  /// If this element is not synthetic, then the element itself is returned.
  ///
  /// If this element is synthetic, then the corresponding non-synthetic
  /// element is returned. For example, for a synthetic getter of a
  /// non-synthetic field the field is returned; for a synthetic constructor
  /// the enclosing class is returned.
  @Deprecated(elementModelDeprecationMsg)
  Element get nonSynthetic;

  /// The analysis session in which this element is defined.
  AnalysisSession? get session;

  /// The version where this SDK API was added.
  ///
  /// A `@Since()` annotation can be applied to a library declaration,
  /// any public declaration in a library, or in a class, or to an optional
  /// parameter, etc.
  ///
  /// The returned version is "effective", so that if a library is annotated
  /// then all elements of the library inherit it; or if a class is annotated
  /// then all members and constructors of the class inherit it.
  ///
  /// If multiple `@Since()` annotations apply to the same element, the latest
  /// version takes precedence.
  ///
  /// Returns `null` if the element is not declared in SDK, or does not have
  /// a `@Since()` annotation applicable to it.
  Version? get sinceSdkVersion;

  @override
  Source? get source;

  /// Returns the presentation of this element as it should appear when
  /// presented to users.
  ///
  /// If [withNullability] is `true`, then [NullabilitySuffix.question] and
  /// [NullabilitySuffix.star] in types will be represented as `?` and `*`.
  /// [NullabilitySuffix.none] does not have any explicit presentation.
  ///
  /// If [withNullability] is `false`, nullability suffixes will not be
  /// included into the presentation.
  ///
  /// If [multiline] is `true`, the string may be wrapped over multiple lines
  /// with newlines to improve formatting. For example function signatures may
  /// be formatted as if they had trailing commas.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString({
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
    bool multiline = false,
  });

  /// Returns a display name for the given element that includes the path to the
  /// compilation unit in which the type is defined. If [shortName] is `null`
  /// then [displayName] will be used as the name of this element. Otherwise
  /// the provided name will be used.
  // TODO(brianwilkerson): Make the parameter optional.
  String getExtendedDisplayName(String? shortName);

  /// Returns either this element or the most immediate ancestor of this element
  /// for which the [predicate] returns `true`, or `null` if there is no such
  /// element.
  @Deprecated('Use Element2.thisOrAncestorMatching2() instead')
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  );

  /// Returns either this element or the most immediate ancestor of this element
  /// for which the [predicate] returns `true`, or `null` if there is no such
  /// element.
  @Deprecated('Use Element2.thisOrAncestorMatching2() instead')
  E? thisOrAncestorMatching3<E extends Element>(
    bool Function(Element) predicate,
  );

  /// Returns either this element or the most immediate ancestor of this element
  /// that has the given type, or `null` if there is no such element.
  @Deprecated('Use Element2.thisOrAncestorMatching2() instead')
  E? thisOrAncestorOfType<E extends Element>();

  /// Returns either this element or the most immediate ancestor of this element
  /// that has the given type, or `null` if there is no such element.
  @Deprecated('Use Element2.thisOrAncestorMatching2() instead')
  E? thisOrAncestorOfType3<E extends Element>();
}

/// A single annotation associated with an element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ElementAnnotation implements ConstantEvaluationTarget {
  /// The errors that were produced while computing a value for this
  /// annotation, or `null` if no value has been computed.
  ///
  /// If a value has been produced but no errors were generated, then the
  /// list will be empty.
  List<AnalysisError>? get constantEvaluationErrors;

  /// Returns the element referenced by this annotation.
  ///
  /// In valid code this element can be a [GetterElement] of a constant
  /// top-level variable, or a constant static field of a class; or a
  /// constant [ConstructorElement2].
  ///
  /// In invalid code this element can be `null`, or a reference to any
  /// other element.
  Element2? get element2;

  /// Whether the annotation marks the associated function as always throwing.
  bool get isAlwaysThrows;

  /// Whether the annotation marks the associated element as being deprecated.
  bool get isDeprecated;

  /// Whether the annotation marks the associated element as not to be stored.
  bool get isDoNotStore;

  /// Whether the annotation marks the associated member as not to be used.
  bool get isDoNotSubmit;

  /// Whether the annotation marks the associated member as a factory.
  bool get isFactory;

  /// Whether the annotation marks the associated class and its subclasses as
  /// being immutable.
  bool get isImmutable;

  /// Whether the annotation marks the associated element as being internal to
  /// its package.
  bool get isInternal;

  /// Whether the annotation marks the associated member as running a single
  /// test.
  bool get isIsTest;

  /// Whether the annotation marks the associated member as running a test
  /// group.
  bool get isIsTestGroup;

  /// Whether the annotation marks the associated element with the `JS`
  /// annotation.
  bool get isJS;

  /// Whether the annotation marks the associated constructor as being literal.
  bool get isLiteral;

  /// Whether the annotation marks the associated returned element as
  /// requiring a constant argument.
  bool get isMustBeConst;

  /// Whether the annotation marks the associated member as requiring
  /// subclasses to override this member.
  bool get isMustBeOverridden;

  /// Whether the annotation marks the associated member as requiring
  /// overriding methods to call super.
  bool get isMustCallSuper;

  /// Whether the annotation marks the associated member as being non-virtual.
  bool get isNonVirtual;

  /// Whether the annotation marks the associated type as having "optional"
  /// type arguments.
  bool get isOptionalTypeArgs;

  /// Whether the annotation marks the associated method as being expected to
  /// override an inherited method.
  bool get isOverride;

  /// Whether the annotation marks the associated member as being protected.
  bool get isProtected;

  /// Whether the annotation marks the associated class as implementing a proxy
  /// object.
  bool get isProxy;

  /// Whether the annotation marks the associated member as redeclaring.
  bool get isRedeclare;

  /// Whether the annotation marks the associated member as being reopened.
  bool get isReopen;

  /// Whether the annotation marks the associated member as being required.
  bool get isRequired;

  /// Whether the annotation marks the associated class as being sealed.
  bool get isSealed;

  /// Whether the annotation marks the associated class as being intended to
  /// be used as an annotation.
  bool get isTarget;

  /// Whether the annotation marks the associated returned element as
  /// requiring use.
  bool get isUseResult;

  /// Whether the annotation marks the associated member as being visible for
  /// overriding only.
  bool get isVisibleForOverriding;

  /// Whether the annotation marks the associated member as being visible for
  /// template files.
  bool get isVisibleForTemplate;

  /// Whether the annotation marks the associated member as being visible for
  /// testing.
  bool get isVisibleForTesting;

  /// Whether the annotation marks the associated member as being visible
  /// outside of template files.
  bool get isVisibleOutsideTemplate;

  /// Whether the annotation marks the associated member as being a widget
  /// factory.
  bool get isWidgetFactory;

  /// Returns a representation of the value of this annotation, forcing the
  /// value to be computed if it had not previously been computed, or `null`
  /// if the value of this annotation could not be computed because of errors.
  DartObject? computeConstantValue();

  /// Returns a textual description of this annotation in a form approximating
  /// valid source.
  ///
  /// The returned string will not be valid source primarily in the case where
  /// the annotation itself is not well-formed.
  String toSource();
}

/// The kind of elements in the element model.
///
/// Clients may not extend, implement or mix-in this class.
class ElementKind implements Comparable<ElementKind> {
  static const ElementKind AUGMENTATION_IMPORT =
      ElementKind('AUGMENTATION_IMPORT', 0, "augmentation import");

  static const ElementKind CLASS = ElementKind('CLASS', 1, "class");

  static const ElementKind CLASS_AUGMENTATION =
      ElementKind('CLASS_AUGMENTATION', 2, "class augmentation");

  static const ElementKind COMPILATION_UNIT =
      ElementKind('COMPILATION_UNIT', 3, "compilation unit");

  static const ElementKind CONSTRUCTOR =
      ElementKind('CONSTRUCTOR', 4, "constructor");

  static const ElementKind DYNAMIC = ElementKind('DYNAMIC', 5, "<dynamic>");

  static const ElementKind ENUM = ElementKind('ENUM', 6, "enum");

  static const ElementKind ERROR = ElementKind('ERROR', 7, "<error>");

  static const ElementKind EXPORT =
      ElementKind('EXPORT', 8, "export directive");

  static const ElementKind EXTENSION = ElementKind('EXTENSION', 9, "extension");

  static const ElementKind EXTENSION_TYPE =
      ElementKind('EXTENSION_TYPE', 10, "extension type");

  static const ElementKind FIELD = ElementKind('FIELD', 11, "field");

  static const ElementKind FUNCTION = ElementKind('FUNCTION', 12, "function");

  static const ElementKind GENERIC_FUNCTION_TYPE =
      ElementKind('GENERIC_FUNCTION_TYPE', 13, 'generic function type');

  static const ElementKind GETTER = ElementKind('GETTER', 14, "getter");

  static const ElementKind IMPORT =
      ElementKind('IMPORT', 15, "import directive");

  static const ElementKind LABEL = ElementKind('LABEL', 16, "label");

  static const ElementKind LIBRARY = ElementKind('LIBRARY', 17, "library");

  static const ElementKind LIBRARY_AUGMENTATION =
      ElementKind('LIBRARY_AUGMENTATION', 18, "library augmentation");

  static const ElementKind LOCAL_VARIABLE =
      ElementKind('LOCAL_VARIABLE', 19, "local variable");

  static const ElementKind METHOD = ElementKind('METHOD', 20, "method");

  static const ElementKind MIXIN = ElementKind('MIXIN', 21, "mixin");

  static const ElementKind NAME = ElementKind('NAME', 22, "<name>");

  static const ElementKind NEVER = ElementKind('NEVER', 23, "<never>");

  static const ElementKind PARAMETER =
      ElementKind('PARAMETER', 24, "parameter");

  static const ElementKind PART = ElementKind('PART', 25, "part");

  static const ElementKind PREFIX = ElementKind('PREFIX', 26, "import prefix");

  static const ElementKind RECORD = ElementKind('RECORD', 27, "record");

  static const ElementKind SETTER = ElementKind('SETTER', 28, "setter");

  static const ElementKind TOP_LEVEL_VARIABLE =
      ElementKind('TOP_LEVEL_VARIABLE', 29, "top level variable");

  static const ElementKind FUNCTION_TYPE_ALIAS =
      ElementKind('FUNCTION_TYPE_ALIAS', 30, "function type alias");

  static const ElementKind TYPE_PARAMETER =
      ElementKind('TYPE_PARAMETER', 31, "type parameter");

  static const ElementKind TYPE_ALIAS =
      ElementKind('TYPE_ALIAS', 32, "type alias");

  static const ElementKind UNIVERSE = ElementKind('UNIVERSE', 33, "<universe>");

  static const List<ElementKind> values = [
    CLASS,
    CLASS_AUGMENTATION,
    COMPILATION_UNIT,
    CONSTRUCTOR,
    DYNAMIC,
    ENUM,
    ERROR,
    EXPORT,
    EXTENSION,
    EXTENSION_TYPE,
    FIELD,
    FUNCTION,
    GENERIC_FUNCTION_TYPE,
    GETTER,
    IMPORT,
    LABEL,
    LIBRARY,
    LOCAL_VARIABLE,
    METHOD,
    MIXIN,
    NAME,
    NEVER,
    PARAMETER,
    PART,
    PREFIX,
    RECORD,
    SETTER,
    TOP_LEVEL_VARIABLE,
    FUNCTION_TYPE_ALIAS,
    TYPE_PARAMETER,
    UNIVERSE
  ];

  /// The name of this element kind.
  final String name;

  /// The ordinal value of the element kind.
  final int ordinal;

  /// The name displayed in the UI for this kind of element.
  final String displayName;

  /// Initialize a newly created element kind to have the given [displayName].
  const ElementKind(this.name, this.ordinal, this.displayName);

  @override
  int compareTo(ElementKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// The location of an element within the element model.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ElementLocation {
  /// The path to the element whose location is represented by this object.
  ///
  /// Clients must not modify the returned array.
  List<String> get components;

  /// The encoded representation of this location that can be used to create a
  /// location that is equal to this location.
  String get encoding;
}

/// A combinator that causes some of the names in a namespace to be hidden when
/// being imported.
///
/// Clients may not extend, implement or mix-in this class.
abstract class HideElementCombinator implements NamespaceCombinator {
  /// The names that are not to be made visible in the importing library even
  /// if they are defined in the imported library.
  List<String> get hiddenNames;
}

class LibraryLanguageVersion {
  /// The version for the whole package that contains this library.
  final Version package;

  /// The version specified using `@dart` override, `null` if absent or invalid.
  final Version? override;

  LibraryLanguageVersion({
    required this.package,
    required this.override,
  });

  /// The effective language version for the library.
  Version get effective {
    return override ?? package;
  }
}

/// An object that controls how namespaces are combined.
///
/// Clients may not extend, implement or mix-in this class.
sealed class NamespaceCombinator {
  /// The offset of the character immediately following the last character of
  /// this node.
  int get end;

  /// The offset of the first character of this node.
  int get offset;
}

/// A combinator that cause some of the names in a namespace to be visible (and
/// the rest hidden) when being imported.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ShowElementCombinator implements NamespaceCombinator {
  /// The names that are to be made visible in the importing library if they
  /// are defined in the imported library.
  List<String> get shownNames;
}
