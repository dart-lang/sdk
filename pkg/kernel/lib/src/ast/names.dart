// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                                NAMES
// ------------------------------------------------------------------------

/// A public name, or a private name qualified by a library.
///
/// Names are only used for expressions with dynamic dispatch, as all
/// statically resolved references are represented in nameless form.
///
/// [Name]s are immutable and compare based on structural equality, and they
/// are not AST nodes.
///
/// The [toString] method returns a human-readable string that includes the
/// library name for private names; uniqueness is not guaranteed.
abstract class Name extends Node {
  @override
  final int hashCode;

  final String text;
  Reference? get libraryReference;
  Library? get library;
  bool get isPrivate;

  Name._internal(this.hashCode, this.text);

  factory Name(String text, [Library? library]) =>
      new Name.byReference(text, library?.reference);

  factory Name.byReference(String text, Reference? libraryName) {
    /// Use separate subclasses for the public and private case to save memory
    /// for public names.
    if (text.startsWith('_')) {
      assert(libraryName != null);
      return new _PrivateName(text, libraryName!);
    } else {
      return new _PublicName(text);
    }
  }

  @override
  bool operator ==(other) {
    return other is Name && text == other.text && library == other.library;
  }

  @override
  R accept<R>(Visitor<R> v) => v.visitName(this);

  @override
  R accept1<R, A>(Visitor1<R, A> v, A arg) => v.visitName(this, arg);

  @override
  void visitChildren(Visitor v) {
    // DESIGN TODO: Should we visit the library as a library reference?
  }

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// Note that this adds some nodes to a static map to ensure consistent
  /// naming, but that it thus also leaks memory.
  @override
  String leakingDebugToString() => astToText.debugNodeToString(this);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeName(this);
  }

  /// The name of the `call` method on a function.
  static final Name callName = new _PublicName('call');

  /// The name of the `==` operator.
  static final Name equalsName = new _PublicName('==');
}

class _PrivateName extends Name {
  @override
  final Reference libraryReference;

  @override
  bool get isPrivate => true;

  _PrivateName(String text, Reference libraryReference)
      : this.libraryReference = libraryReference,
        super._internal(_computeHashCode(text, libraryReference), text);

  @override
  String toString() => toStringInternal();

  @override
  String toStringInternal() => '$library::$text';

  @override
  Library get library => libraryReference.asLibrary;

  static int _computeHashCode(String name, Reference libraryReference) {
    // TODO(cstefantsova): Factor in [libraryReference] in a non-deterministic
    // way into the result.  Note, the previous code here was the following:
    //     return 131 * name.hashCode + 17 *
    //         libraryReference.asLibrary._libraryId;
    return name.hashCode;
  }
}

class _PublicName extends Name {
  @override
  Reference? get libraryReference => null;

  @override
  Library? get library => null;

  @override
  bool get isPrivate => false;

  _PublicName(String text) : super._internal(text.hashCode, text);

  @override
  String toString() => toStringInternal();
}
