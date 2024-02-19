// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import '../executor.dart';

/// Meta information for a span of text in a generated augmentation library.
///
/// These are collected during generation of augmentation libraries and are used
/// to compute relation between offsets in the intermediate augmentation
/// libraries and the merged augmented library.
class Span {
  /// Key that defines the semantics of the content of this span.
  ///
  /// This must be unique within the spans generated from a single
  /// augmentation library.
  final Key key;

  /// The offset in the generated augmentation library source code where this
  /// span occurs.
  final int offset;

  /// The source code of this span.
  final String text;

  Span(this.key, this.offset, this.text);
}

/// Object that defines the semantics of a [Span] in a generated augmentation
/// library.
///
/// This is used to identify corresponding parts of generated augmentation
/// libraries when converting offsets from the intermediate augmentation
/// libraries to the merged augmentation library.
///
/// For instance we might have two intermediate both containing an import
/// of the same library with potentially different prefixes:
///
///     // intermediate augmentation library #0
///     ...
///     import 'dart:core' as prefix1;
///     ...
///     prefix1.String method1() => '42';
///     ...
///
///     // intermediate augmentation library #1
///     ...
///     import 'dart:core' as prefix2;
///     ...
///     prefix2.String method2() => '87';
///     ...
///
/// and the merged augmentation library:
///
///     ...
///     import 'dart:core' as prefix4;
///     ...
///     prefix4.String method1() => '42';
///     ...
///     prefix4.String method2() => '87';
///     ...
///
/// Here the same key is used for the 'prefix1', 'prefix2' and 'prefix4' in the
/// import directives. The same key is used for 'prefix1' in
/// 'prefix1.String' in intermediate augmentation library #0 and the 'prefix4'
/// in the first occurrence of 'prefix4.String' in the merged augmentation
/// library. Similarly for 'prefix2' and 'prefix4' for 'method2'.
sealed class Key {
  Key? get parent;
}

enum _ContentKind {
  Code,
  String,
  ImplicitThis,
  PrefixDot,
  StaticScope,
  IdentifierName,
  LibraryAugmentation,
  LibraryAugmentationSeparator,
}

/// Content defined by its [kind] and [index] within the [parent] key.
class ContentKey implements Key {
  @override
  final Key parent;
  final int index;
  final _ContentKind kind;

  ContentKey._(this.parent, this.index, this.kind);

  /// Create the key for a [Code] object occurring as the [index]th part of
  /// [parent].
  ContentKey.code(Key parent, int index)
      : this._(parent, index, _ContentKind.Code);

  /// Create the key for a [String] occurring as the [index]th part of [parent].
  ContentKey.string(Key parent, int index)
      : this._(parent, index, _ContentKind.String);

  /// Create the key for a `this.` occurring as the [index]th part of [parent].
  ContentKey.implicitThis(Key parent, int index)
      : this._(parent, index, _ContentKind.ImplicitThis);

  /// Create the key for a `.` after a prefix occurring as the [index]th part
  /// of [parent].
  ContentKey.prefixDot(Key parent, int index)
      : this._(parent, index, _ContentKind.PrefixDot);

  /// Create the key for a static qualifier `Foo.` of a static member access in
  /// `Foo` occurring as the [index]th part of [parent].
  ContentKey.staticScope(Key parent, int index)
      : this._(parent, index, _ContentKind.StaticScope);

  /// Create the key for an [Identifier] after a prefix occurring as the
  /// [index]th part of [parent].
  ContentKey.identifierName(Key parent, int index)
      : this._(parent, index, _ContentKind.IdentifierName);

  /// Create the key the [index]th library augmentation in [parent].
  ContentKey.libraryAugmentation(Key parent, int index)
      : this._(parent, index, _ContentKind.LibraryAugmentation);

  /// Create the key the separator text after the [index]th library augmentation
  /// in [parent].
  ContentKey.libraryAugmentationSeparator(Key parent, int index)
      : this._(parent, index, _ContentKind.LibraryAugmentationSeparator);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentKey &&
          runtimeType == other.runtimeType &&
          parent == other.parent &&
          index == other.index &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(parent, index, kind);
}

enum _UriKind {
  Prefix,
  ImportPrefix,
  ImportSuffix,
}

/// Use of a [Uri] defined by the [uri] and the [kind] of use.
class UriKey implements Key {
  final Uri uri;

  final _UriKind kind;

  UriKey._(this.uri, this.kind);

  /// Creates a key for the definition of the prefix for [uri], that is,
  /// "prefix" in `import 'foo.dart' as prefix;`.
  UriKey.prefixDefinition(Uri uri) : this._(uri, _UriKind.Prefix);

  /// Creates a key for the prefix of the import of [uri], that is,
  /// "import 'foo.dart' as" in `import 'foo.dart' as prefix;`.
  UriKey.importPrefix(Uri uri) : this._(uri, _UriKind.ImportPrefix);

  /// Creates a key for the suffix of the import of [uri], that is,
  /// ";\n" in
  ///
  ///     import 'foo.dart' as prefix;
  ///
  UriKey.importSuffix(Uri uri) : this._(uri, _UriKind.ImportSuffix);

  @override
  Key? get parent => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UriKey &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(uri, kind);
}

/// A reference to the prefix of [uri] occurring as the [index]th part of
/// [parent].
class PrefixUseKey implements Key {
  @override
  final Key parent;

  final int index;

  final Uri uri;

  PrefixUseKey(this.parent, this.index, this.uri);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefixUseKey &&
          runtimeType == other.runtimeType &&
          parent == other.parent &&
          uri == other.uri &&
          index == other.index;

  @override
  int get hashCode => Object.hash(parent, uri, index);
}

/// The use of [omittedTypeAnnotation] occurring as the [index]th part of
/// [parent].
class OmittedTypeAnnotationKey implements Key {
  @override
  final Key parent;

  final int index;

  final OmittedTypeAnnotation omittedTypeAnnotation;

  OmittedTypeAnnotationKey(this.parent, this.index, this.omittedTypeAnnotation);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OmittedTypeAnnotationKey &&
          runtimeType == other.runtimeType &&
          parent == other.parent &&
          index == other.index &&
          omittedTypeAnnotation == other.omittedTypeAnnotation;

  @override
  int get hashCode => Object.hash(parent, index, omittedTypeAnnotation);
}

/// The content defined by [result].
///
/// This is used as the root key for content specific to [result].
class MacroExecutionResultKey implements Key {
  final MacroExecutionResult result;

  MacroExecutionResultKey(this.result);

  @override
  Key? get parent => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroExecutionResultKey &&
          runtimeType == other.runtimeType &&
          result == other.result;

  @override
  int get hashCode => result.hashCode;
}

/// The root key for content of [typeDeclaration].
///
/// This is used as the root key for the parts of the declaration of
/// [typeDeclaration] that can be shared amongst members.
///
/// For instance when to intermediate augmentation libraries generate members
/// for the same class we have
///
///     // intermediate augmentation library #0
///     ...
///     augment class Foo {
///       method1() {}
///     }
///     ...
///
///     // intermediate augmentation library #1
///     ...
///     augment class Foo {
///       method2() {}
///     }
///     ...
///
/// and the merged augmentation library merges these to same the class
/// declaration:
///
///     ...
///     augment class Foo {
///       method1() {}
///       method2() {}
///     }
///     ...
///
/// In this case the declaration "augment class Foo ", the body start "{\n" and
/// the body end "}\n" use keys with the same [TypeDeclarationKey] as parent.
class TypeDeclarationKey implements Key {
  final TypeDeclaration typeDeclaration;

  TypeDeclarationKey(this.typeDeclaration);

  @override
  Key? get parent => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeDeclarationKey &&
          runtimeType == other.runtimeType &&
          typeDeclaration == other.typeDeclaration;

  @override
  int get hashCode => typeDeclaration.hashCode;
}

enum _TypeDeclarationContentKind {
  Declaration,
  Mixins,
  Interfaces,
  BodyStart,
  EnumValueEnd,
  DeclarationSeparator,
  BodyEnd,
}

/// Content of a [TypeDeclaration].
class TypeDeclarationContentKey implements Key {
  @override
  final Key parent;

  final _TypeDeclarationContentKind kind;

  TypeDeclarationContentKey._(this.parent, this.kind);

  /// The declaration of the type declaration, that is, "augment class Foo " in
  /// `augment class Foo { }`.
  TypeDeclarationContentKey.declaration(Key parent)
      : this._(parent, _TypeDeclarationContentKind.Declaration);

  /// The fixed parts of a with-clause, that is, "with " and ", " in
  /// `augment class Foo with Bar, Baz { }`.
  TypeDeclarationContentKey.mixins(Key parent)
      : this._(parent, _TypeDeclarationContentKind.Mixins);

  /// The fixed parts of an implements-clause, that is, "implements " and ", "
  /// in `augment class Foo implements Bar, Baz { }`.
  TypeDeclarationContentKey.interfaces(Key parent)
      : this._(parent, _TypeDeclarationContentKind.Interfaces);

  /// The start of the declaration body, that is, "{\n" in
  ///
  ///     augment class Foo implements Bar, Baz {
  ///     }
  ///
  TypeDeclarationContentKey.bodyStart(Key parent)
      : this._(parent, _TypeDeclarationContentKind.BodyStart);

  /// The end of element values, that is, ";\n"
  ///
  ///     augment enum Foo {
  ///       a,
  ///       b,
  ///       ;
  ///       method() {}
  ///     }
  ///
  TypeDeclarationContentKey.enumValueEnd(Key parent)
      : this._(parent, _TypeDeclarationContentKind.EnumValueEnd);

  /// The space between member declarations.
  TypeDeclarationContentKey.declarationSeparator(Key parent)
      : this._(parent, _TypeDeclarationContentKind.DeclarationSeparator);

  /// The end of the declaration body, that is, "}\n" in
  ///
  ///     augment class Foo implements Bar, Baz {
  ///     }
  ///
  TypeDeclarationContentKey.bodyEnd(Key parent)
      : this._(parent, _TypeDeclarationContentKind.BodyEnd);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeDeclarationContentKey &&
          runtimeType == other.runtimeType &&
          parent == other.parent &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(parent, kind);
}

enum _IdentifierKind {
  Enum,
  Mixin,
  Interface,
  Type,
}

/// Key defined be the [identifier] its use [kind] occurring as the [index]th
/// part of [parent].
class IdentifierKey implements Key {
  @override
  final Key parent;
  final Identifier identifier;
  final int index;
  final _IdentifierKind kind;

  IdentifierKey._(this.parent, this.index, this.identifier, this.kind);

  /// Identifier for an enum value.
  IdentifierKey.enum_(Key parent, int index, Identifier identifier)
      : this._(parent, index, identifier, _IdentifierKind.Enum);

  /// Identifier for a mixed in type.
  IdentifierKey.mixin(Key parent, int index, Identifier identifier)
      : this._(parent, index, identifier, _IdentifierKind.Mixin);

  /// Identifier for an implemented type.
  IdentifierKey.interface(Key parent, int index, Identifier identifier)
      : this._(parent, index, identifier, _IdentifierKind.Interface);

  /// Identifier for an augmented member.
  IdentifierKey.member(Key parent, int index, Identifier identifier)
      : this._(parent, index, identifier, _IdentifierKind.Type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentifierKey &&
          runtimeType == other.runtimeType &&
          parent == other.parent &&
          index == other.index &&
          identifier == other.identifier &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(parent, index, identifier, kind);
}

/// Key for the separation between imports and declarations.
class ImportDeclarationSeparatorKey implements Key {
  const ImportDeclarationSeparatorKey();

  @override
  Key? get parent => null;
}

/// Key for the end-of-file.
class EndOfFileKey implements Key {
  const EndOfFileKey();

  @override
  Key? get parent => null;
}
