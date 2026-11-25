// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// An empty static namespace: a type alias of a type that is not an interface
/// type, such as a function type, a record type, `dynamic`, or a type
/// variable, as in `typedef A<X> = X;`.
///
/// Every selector, as in `F.x` or `F.toString()`, is an invalid static
/// access; `(F).x` reads a member of the `Type` object.
final class EmptyStaticNamespace extends StaticNamespace {
  @override
  final TypeAliasElementImpl element;

  new(this.element);
}

/// The static members of an extension.
final class ExtensionStaticNamespace extends StaticNamespace {
  @override
  final ExtensionElementImpl element;

  new(this.element);
}

/// The static members and constructors of a class, enum, mixin, or extension
/// type, named directly or through a type alias.
final class InterfaceStaticNamespace extends StaticNamespace {
  /// The interface, or the type alias that denotes it.
  @override
  final ElementImpl element;

  /// The interface whose members are looked up.
  final InterfaceElementImpl interface;

  new({required this.element, required this.interface});
}

/// A type alias of an invalid type, such as `typedef A = Unknown;`, or a type
/// alias that references itself, such as `typedef A = List<A>;`.
///
/// The alias has no static members, but a selector is not reported, because
/// the error is already reported for the alias.
final class InvalidStaticNamespace extends StaticNamespace {
  @override
  final TypeAliasElementImpl element;

  new(this.element);
}

/// What a name followed by a selector denotes, when it is not a value, such
/// as `C` in `C.x`.
sealed class StaticNamespace {
  /// The declaration that the name denotes.
  ElementImpl get element;

  /// Returns the static namespace that [element] denotes when its name is
  /// followed by a selector, as `C` in `C.x`, or `null` if the name is then a
  /// value, such as a variable or a function.
  ///
  /// By the language specification, a selector on a type literal is a static
  /// access, and it is an error unless the type literal denotes a declaration
  /// with that static member (sections "Property Extraction" and "Member
  /// Invocations"; also "It is a compile-time error to invoke an instance
  /// method on a type literal that is immediately followed by the token `.`").
  /// A type alias gives access to static members only when it denotes a class
  /// (the generalized type aliases specification, 2.13). So an alias of a type
  /// that is not an interface type is an empty namespace, not a `Type` value:
  /// `R.hashCode` is an error, while `(R).hashCode` reads a member of `Type`.
  ///
  /// A type parameter is a type literal too, so the specification makes `T.x`
  /// a static access as well. But `T.toString()` is common in existing code,
  /// so a type parameter is deliberately a value, and `T.x` reads a member of
  /// the `Type` object.
  static StaticNamespace? of(Element? element) {
    switch (element) {
      case InterfaceElementImpl():
        return InterfaceStaticNamespace(element: element, interface: element);
      case ExtensionElementImpl():
        return ExtensionStaticNamespace(element);
      // Checked before the aliased type, which for `typedef A = List<A>;` is
      // still an interface type.
      case TypeAliasElementImpl(hasSelfReference: true):
        return InvalidStaticNamespace(element);
      case TypeAliasElementImpl(aliasedType: InterfaceTypeImpl type):
        return InterfaceStaticNamespace(
          element: element,
          interface: type.element,
        );
      case TypeAliasElementImpl(aliasedType: InvalidTypeImpl()):
        return InvalidStaticNamespace(element);
      case TypeAliasElementImpl():
        return EmptyStaticNamespace(element);
      default:
        return null;
    }
  }
}
