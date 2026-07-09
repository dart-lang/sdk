// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'arguments.dart';
import 'expressions.dart';
import 'references.dart';
import 'scope.dart';
import 'type_annotations.dart';
import 'util.dart';

/// A [Proto] represents a parsed substructure before it can be determined
/// whether is is an expression, a type annotation, or something else.
///
/// For instance when parsing `Foo` we cannot determine what it means before
/// we have parsed what comes after `Foo`. If it is followed by `.bar` it could
/// be the class name prefix of a static field access `Foo.bar` and if it is
/// followed by `,` then it could be a type literal `Foo` as an expression.
sealed class Proto {
  /// Creates the [Proto] corresponding to this [Proto] followed by [send].
  ///
  /// If [send] is `null`, this corresponds to this [Proto] on its own.
  /// Otherwise this corresponds to this [Proto] followed by `.` or `?.`, an
  /// identifier, and optionally type arguments and/or arguments.
  Proto apply(IdentifierProto? send, {bool isNullAware = false}) {
    if (send == null) {
      return this;
    } else if (isNullAware) {
      return new InstanceAccessProto(
        this,
        send.text,
        isNullAware: true,
      ).instantiate(send.typeArguments).invoke(send.arguments);
    } else {
      return access(
        send.text,
      ).instantiate(send.typeArguments).invoke(send.arguments);
    }
  }

  /// Returns the [Proto] corresponding to accessing the property [name].
  ///
  /// If [name] is `null`, the [Proto] itself is returned. This functionality
  /// is supported for ease of use.
  Proto access(String? name);

  /// Returns the [Proto] corresponding applying [typeArguments] to it.
  ///
  /// If [typeArguments] is `null`, the [Proto] itself is returned. This
  /// functionality is supported for ease of use.
  Proto instantiate(List<TypeAnnotation>? typeArguments);

  /// Returns the [Proto] corresponding invoke it with [arguments].
  ///
  /// If [arguments] is `null`, the [Proto] itself is returned. This
  /// functionality is supported for ease of use.
  Proto invoke(List<Argument>? arguments);

  /// Creates the [Expression] corresponding to this [Proto].
  ///
  /// This corresponding to this [Proto] occurring in an expression context
  /// on its own.
  Expression toExpression();

  /// Creates the [TypeAnnotation] corresponding to this [Proto].
  ///
  /// This corresponding to this [Proto] occurring in a type annotation context
  /// on its own.
  TypeAnnotation toTypeAnnotation();

  /// Returns the [Proto] corresponding to this [Proto] in which all
  /// [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [Proto], `null` is returned.
  Proto? resolve();
}

/// An unresolved part of a proto, expression or type annotation.
sealed class Unresolved {
  /// Returns this unresolved part as an [Expression] if it can be resolved.
  Expression? resolveAsExpression();

  /// Returns this unresolved part as a [TypeAnnotation] if it can be resolved.
  TypeAnnotation? resolveAsTypeAnnotation();
}

/// The unresolved identifier [name] occurring in [scope].
class UnresolvedIdentifier extends Proto implements Unresolved {
  final Scope scope;
  final String name;

  UnresolvedIdentifier(this.scope, this.name);

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    return new UnresolvedAccess(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    if (typeArguments == null) {
      return this;
    }
    return new UnresolvedInstantiate(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    if (arguments == null) {
      return this;
    }
    return new UnresolvedInvoke(this, arguments);
  }

  @override
  Expression toExpression() {
    return new UnresolvedExpression(this);
  }

  @override
  TypeAnnotation toTypeAnnotation() {
    return new UnresolvedTypeAnnotation(this);
  }

  @override
  String toString() => 'UnresolvedIdentifier($name)';

  @override
  Expression? resolveAsExpression() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toExpression();
  }

  @override
  TypeAnnotation? resolveAsTypeAnnotation() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toTypeAnnotation();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnresolvedIdentifier &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  Proto? resolve() {
    Proto resolved = scope.lookup(name);
    return this == resolved ? null : resolved;
  }
}

/// The unresolved access to [name] on [prefix].
class UnresolvedAccess extends Proto implements Unresolved {
  final Proto prefix;
  final String name;

  UnresolvedAccess(this.prefix, this.name);

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    return new UnresolvedAccess(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    if (typeArguments == null) {
      return this;
    }
    return new UnresolvedInstantiate(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    if (arguments == null) {
      return this;
    }
    return new UnresolvedInvoke(this, arguments);
  }

  @override
  Expression toExpression() {
    return new UnresolvedExpression(this);
  }

  @override
  TypeAnnotation toTypeAnnotation() {
    return new UnresolvedTypeAnnotation(this);
  }

  @override
  String toString() => 'UnresolvedAccess($prefix,$name)';

  @override
  Expression? resolveAsExpression() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toExpression();
  }

  @override
  TypeAnnotation? resolveAsTypeAnnotation() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toTypeAnnotation();
  }

  @override
  Proto? resolve() {
    Proto? newPrefix = prefix.resolve();
    return newPrefix == null ? null : newPrefix.access(name);
  }
}

/// The application of [typeArguments] on [prefix].
///
/// The [prefix] is (partially) unresolved, so it cannot yet determined what
/// the application of [typeArguments] means. For instance `unresolved<int>`
/// could be instantiation of the generic class `unresolved` or the
/// instantiation of the generic method `unresolved`.
class UnresolvedInstantiate extends Proto implements Unresolved {
  final Proto prefix;
  final List<TypeAnnotation> typeArguments;

  UnresolvedInstantiate(this.prefix, this.typeArguments);

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    return new UnresolvedAccess(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    if (typeArguments == null) {
      return this;
    }
    return new UnresolvedInstantiate(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    if (arguments == null) {
      return this;
    }
    return new UnresolvedInvoke(this, arguments);
  }

  @override
  Expression toExpression() {
    return new UnresolvedExpression(this);
  }

  @override
  TypeAnnotation toTypeAnnotation() {
    return new UnresolvedTypeAnnotation(this);
  }

  @override
  String toString() => 'UnresolvedInstantiate($prefix,$typeArguments)';

  @override
  Expression? resolveAsExpression() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toExpression();
  }

  @override
  TypeAnnotation? resolveAsTypeAnnotation() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toTypeAnnotation();
  }

  @override
  Proto? resolve() {
    Proto? newPrefix = prefix.resolve();
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );

    return newPrefix == null && newTypeArguments == null
        ? null
        : (newPrefix ?? prefix).instantiate(newTypeArguments ?? typeArguments);
  }
}

/// The invocation of [arguments] on [prefix].
///
/// The [prefix] is (partially) unresolved, so it cannot yet determined what
/// the invocation of [arguments] means. For instance `unresolved(0)`
/// could be the constructor invocation of the unnamed constructor of the class
/// `unresolved` or the invocation of the method `unresolved`.
class UnresolvedInvoke extends Proto implements Unresolved {
  final Proto prefix;
  final List<Argument> arguments;

  UnresolvedInvoke(this.prefix, this.arguments);

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    return new UnresolvedAccess(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    if (typeArguments == null) {
      return this;
    }
    return new UnresolvedInstantiate(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    if (arguments == null) {
      return this;
    }
    return new UnresolvedInvoke(this, arguments);
  }

  @override
  Expression toExpression() {
    return new UnresolvedExpression(this);
  }

  @override
  TypeAnnotation toTypeAnnotation() {
    return new UnresolvedTypeAnnotation(this);
  }

  @override
  String toString() => 'UnresolvedInvoke($prefix,$arguments)';

  @override
  Expression? resolveAsExpression() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toExpression();
  }

  @override
  TypeAnnotation? resolveAsTypeAnnotation() {
    Proto? resolved = resolve();
    return resolved == null ? null : resolved.toTypeAnnotation();
  }

  @override
  Proto? resolve() {
    Proto? newPrefix = prefix.resolve();
    List<Argument>? newArguments = arguments.resolve((a) => a.resolve());
    return newPrefix == null && newArguments == null
        ? null
        : (newPrefix ?? prefix).invoke(newArguments ?? arguments);
  }
}

/// A [reference] to a class.
///
/// The [Proto] includes the [scope] of the class, which is used to resolve
/// access to constructors and static members on the class.
class ClassProto extends Proto {
  final ClassReference reference;
  final TypeDeclarationScope scope;

  ClassProto(this.reference, this.scope);

  @override
  String toString() => 'ClassProto($reference)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new GenericClassProto(reference, scope, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new NamedTypeAnnotation(reference);

  @override
  Proto? resolve() => null;
}

/// A [reference] to a class instantiated with [typeArguments].
///
/// The [Proto] includes the [scope] of the class, which is used to resolve
/// access to constructors on the class.
class GenericClassProto extends Proto {
  final ClassReference reference;
  final TypeDeclarationScope scope;
  final List<TypeAnnotation> typeArguments;

  GenericClassProto(this.reference, this.scope, this.typeArguments);

  @override
  String toString() => 'GenericClassProto($reference,$typeArguments)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name, typeArguments);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? throw new UnimplementedError('GenericClassProto.instantiate')
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() =>
      new NamedTypeAnnotation(reference, typeArguments);

  @override
  Proto? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (a) => a.resolve(),
    );
    return newTypeArguments == null
        ? null
        : new GenericClassProto(reference, scope, newTypeArguments);
  }
}

/// A [reference] to an extension
///
/// The [Proto] includes the [scope] of the extension, which is used to resolve
/// access to static members on the extension.
class ExtensionProto extends Proto {
  final ExtensionReference reference;
  final TypeDeclarationScope scope;

  ExtensionProto(this.reference, this.scope);

  @override
  String toString() => 'ExtensionProto($reference)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new InvalidInstantiationProto(this, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new InvalidInvocationProto(this, const [], arguments)
        : this;
  }

  @override
  Expression toExpression() {
    return new InvalidExpression();
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  Proto? resolve() => null;
}

/// A [reference] to an enum
///
/// The [Proto] includes the [scope] of the enum, which is used to resolve
/// access to static members on the enum.
class EnumProto extends Proto {
  final EnumReference reference;
  final TypeDeclarationScope scope;

  EnumProto(this.reference, this.scope);

  @override
  String toString() => 'EnumProto($reference)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new GenericEnumProto(reference, scope, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new InvalidInvocationProto(this, const [], arguments)
        : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new NamedTypeAnnotation(reference);

  @override
  Proto? resolve() => null;
}

/// A [reference] to an enum instantiated with [typeArguments].
///
/// The [Proto] includes the [scope] of the enum, which is used to resolve
/// access to constructors on the enum.
class GenericEnumProto extends Proto {
  final EnumReference reference;
  final TypeDeclarationScope scope;
  final List<TypeAnnotation> typeArguments;

  GenericEnumProto(this.reference, this.scope, this.typeArguments);

  @override
  String toString() => 'GenericEnumProto($reference,$typeArguments)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name, typeArguments);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? throw new UnimplementedError('$this.instantiate')
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() =>
      new NamedTypeAnnotation(reference, typeArguments);

  @override
  Proto? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (a) => a.resolve(),
    );
    return newTypeArguments == null
        ? null
        : new GenericEnumProto(reference, scope, newTypeArguments);
  }
}

/// A [reference] to a mixin
///
/// The [Proto] includes the [scope] of the mixin, which is used to resolve
/// access to static members on the mixin.
class MixinProto extends Proto {
  final MixinReference reference;
  final TypeDeclarationScope scope;

  MixinProto(this.reference, this.scope);

  @override
  String toString() => 'MixinProto($reference)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new GenericMixinProto(reference, scope, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new InvalidInvocationProto(this, const [], arguments)
        : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new NamedTypeAnnotation(reference);

  @override
  Proto? resolve() => null;
}

/// A [reference] to an enum instantiated with [typeArguments].
///
/// The [Proto] includes the [scope] of the enum, which is used to resolve
/// access to constructors on the enum.
class GenericMixinProto extends Proto {
  final MixinReference reference;
  final TypeDeclarationScope scope;
  final List<TypeAnnotation> typeArguments;

  GenericMixinProto(this.reference, this.scope, this.typeArguments);

  @override
  String toString() => 'GenericMixinProto($reference,$typeArguments)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name, typeArguments);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? throw new UnimplementedError('$this.instantiate')
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() =>
      new NamedTypeAnnotation(reference, typeArguments);

  @override
  Proto? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (a) => a.resolve(),
    );
    return newTypeArguments == null
        ? null
        : new GenericMixinProto(reference, scope, newTypeArguments);
  }
}

/// A [reference] to an extension type.
///
/// The [Proto] includes the [scope] of the extension type, which is used to
/// resolve access to constructors and static members on the extension type.
class ExtensionTypeProto extends Proto {
  final ExtensionTypeReference reference;
  final TypeDeclarationScope scope;

  ExtensionTypeProto(this.reference, this.scope);

  @override
  String toString() => 'ExtensionTypeProto($reference)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new GenericExtensionTypeProto(reference, scope, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new NamedTypeAnnotation(reference);

  @override
  Proto? resolve() => null;
}

/// A [reference] to an extension type instantiated with [typeArguments].
///
/// The [Proto] includes the [scope] of the extension type, which is used to
/// resolve access to constructors on the class.
class GenericExtensionTypeProto extends Proto {
  final ExtensionTypeReference reference;
  final TypeDeclarationScope scope;
  final List<TypeAnnotation> typeArguments;

  GenericExtensionTypeProto(this.reference, this.scope, this.typeArguments);

  @override
  String toString() => 'GenericExtensionTypeProto($reference,$typeArguments)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name, typeArguments);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? throw new UnimplementedError('GenericExtensionTypeProto.instantiate')
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() =>
      new NamedTypeAnnotation(reference, typeArguments);

  @override
  Proto? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (a) => a.resolve(),
    );
    return newTypeArguments == null
        ? null
        : new GenericExtensionTypeProto(reference, scope, newTypeArguments);
  }
}

/// A [reference] to a typedef.
///
/// The [Proto] includes the [scope] of the typedef, which is used to resolve
/// access to constructors through the typedef.
class TypedefProto extends Proto {
  final TypedefReference reference;
  final TypeDeclarationScope scope;

  TypedefProto(this.reference, this.scope);

  @override
  String toString() => 'TypedefProto($reference)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new GenericTypedefProto(reference, scope, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new NamedTypeAnnotation(reference);

  @override
  Proto? resolve() => null;
}

/// A [reference] to a typedef instantiated with [typeArguments].
///
/// The [Proto] includes the [scope] of the typedef, which is used to resolve
/// access to constructors through the typedef.
class GenericTypedefProto extends Proto {
  final TypedefReference reference;
  final TypeDeclarationScope scope;
  final List<TypeAnnotation> typeArguments;

  GenericTypedefProto(this.reference, this.scope, this.typeArguments);

  @override
  String toString() => 'GenericTypedefProto($reference,$typeArguments)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    if (name == 'new') {
      name = '';
    }
    return scope.lookup(name, typeArguments);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? throw new UnimplementedError('GenericTypedefProto.instantiate')
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null ? access('new').invoke(arguments) : this;
  }

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() =>
      new NamedTypeAnnotation(reference, typeArguments);

  @override
  Proto? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (a) => a.resolve(),
    );
    return newTypeArguments == null
        ? null
        : new GenericTypedefProto(reference, scope, newTypeArguments);
  }
}

/// A [reference] to a `void`.
class VoidProto extends Proto {
  final Reference reference;

  VoidProto(this.reference);

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new VoidTypeAnnotation(reference);

  @override
  Proto access(String? name) {
    return name == null ? this : new InvalidAccessProto(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments == null
        ? this
        : new InvalidInstantiationProto(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments == null
        ? this
        : new InvalidInvocationProto(this, const [], arguments);
  }

  @override
  String toString() => 'VoidProto()';

  @override
  Proto? resolve() => null;
}

/// A [reference] to a `dynamic`.
class DynamicProto extends Proto {
  final Reference reference;

  DynamicProto(this.reference);

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() => new DynamicTypeAnnotation(reference);

  @override
  Proto access(String? name) {
    return name == null ? this : new InvalidAccessProto(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments == null
        ? this
        : new InvalidInstantiationProto(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments == null
        ? this
        : new InvalidInvocationProto(this, const [], arguments);
  }

  @override
  String toString() => 'DynamicProto()';

  @override
  Proto? resolve() => null;
}

/// A [reference] to a constructor, including a reference to the [type] on which
/// it was accessed, as well as the [typeArguments] applied to [type].
class ConstructorProto extends Proto {
  final Reference type;
  final List<TypeAnnotation> typeArguments;
  final ConstructorReference reference;

  ConstructorProto(this.type, this.typeArguments, this.reference);

  @override
  String toString() => 'ConstructorProto($type,$typeArguments,$reference)';

  @override
  Proto access(String? name) {
    return name != null ? new InvalidAccessProto(this, name) : this;
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new ExpressionInstantiationProto(this, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new ExpressionProto(
            new ConstructorInvocation(
              new NamedTypeAnnotation(type, typeArguments),
              reference,
              arguments,
            ),
          )
        : this;
  }

  @override
  Expression toExpression() {
    return new ConstructorTearOff(
      new NamedTypeAnnotation(type, typeArguments),
      reference,
    );
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  Proto? resolve() => null;
}

/// A [reference] to a static or top level field.
class FieldProto extends Proto {
  final FieldReference reference;

  FieldProto(this.reference);

  @override
  String toString() => 'FieldProto($reference)';

  @override
  Proto access(String? name) {
    return name != null ? new InstanceAccessProto(this, name) : this;
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new ExpressionInstantiationProto(this, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new InstanceInvocationProto(this, const [], arguments)
        : this;
  }

  @override
  Expression toExpression() {
    return new StaticGet(reference);
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  Proto? resolve() => null;
}

/// A [reference] to a static or top level method.
class FunctionProto extends Proto {
  final FunctionReference reference;

  FunctionProto(this.reference);

  @override
  String toString() => 'FunctionProto($reference)';

  @override
  Proto access(String? name) {
    return name != null ? new InstanceAccessProto(this, name) : this;
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new FunctionInstantiationProto(reference, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new ExpressionProto(
            new StaticInvocation(reference, const [], arguments),
          )
        : this;
  }

  @override
  Expression toExpression() {
    return new FunctionTearOff(reference);
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  Proto? resolve() => null;
}

/// A [reference] to a static or top level method instantiated with
/// [typeArguments].
class FunctionInstantiationProto extends Proto {
  final FunctionReference reference;
  final List<TypeAnnotation> typeArguments;

  FunctionInstantiationProto(this.reference, this.typeArguments);

  @override
  String toString() => 'FunctionInstantiationProto($reference,$typeArguments)';

  @override
  Proto access(String? name) {
    return name != null ? new InstanceAccessProto(this, name) : this;
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new ExpressionInstantiationProto(this, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new ExpressionProto(
            new StaticInvocation(reference, typeArguments, arguments),
          )
        : this;
  }

  @override
  Expression toExpression() {
    return new Instantiation(new FunctionTearOff(reference), typeArguments);
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  Proto? resolve() => null;
}

/// A reference to the [prefix].
///
/// The [Proto] includes the [scope] of the prefix, which is used to resolve
/// access to imported members and types through the prefix.
class PrefixProto extends Proto {
  final String prefix;
  final Scope scope;

  PrefixProto(this.prefix, this.scope);

  @override
  String toString() => 'PrefixProto($prefix)';

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    return scope.lookup(name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new InvalidInstantiationProto(this, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new InvalidInvocationProto(this, const [], arguments)
        : this;
  }

  @override
  Expression toExpression() {
    return new InvalidExpression();
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  Proto? resolve() => null;
}

/// The suffix of an access to the property [text] including applied
/// [typeArguments] and [arguments], if any.
///
/// This is not really a [Proto] but just a sequence of information needed to
/// call [Proto.access], [Proto.instantiate], and [Proto.invoke]. Unfortunately
/// the parser currently provides these as a "send" which is not the ideal model
/// for parsing Dart.
class IdentifierProto extends Proto {
  final String text;
  final List<TypeAnnotation>? typeArguments;
  final List<Argument>? arguments;

  IdentifierProto(String text) : this._(text, null, null);

  IdentifierProto._(this.text, this.typeArguments, this.arguments);

  @override
  Proto access(String? name) {
    return name == null
        ? this
        : throw new UnimplementedError('IdentifierProto.access');
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments == null
        ? this
        : new IdentifierProto._(text, typeArguments, null);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments == null
        ? this
        : new IdentifierProto._(text, typeArguments, arguments);
  }

  @override
  Expression toExpression() {
    throw new UnimplementedError('IdentifierProto.toExpression');
  }

  @override
  TypeAnnotation toTypeAnnotation() {
    throw new UnimplementedError('IdentifierProto.toTypeAnnotation');
  }

  @override
  String toString() => 'IdentifierProto($text)';

  @override
  Proto? resolve() => null;
}

/// An access to the [text] property on [receiver].
///
/// If [isNullAware] is `true`, this is a `?.` access, otherwise it is a '.'
/// access.
///
/// This is used for the when the [text] property is known to be an instance
/// member of [receiver]. Either because the [receiver] cannot be the prefix
/// of a static access or if [isNullAware] is `true`.
class InstanceAccessProto extends Proto {
  final Proto receiver;
  final String text;
  final bool isNullAware;

  InstanceAccessProto(this.receiver, this.text, {this.isNullAware = false});

  @override
  Proto access(String? name) {
    if (name == null) {
      return this;
    }
    throw new UnimplementedError('$this.access');
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    if (typeArguments == null) {
      return this;
    }
    throw new UnimplementedError('$this.instantiate');
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    if (arguments == null) {
      return this;
    }
    throw new UnimplementedError('$this.invoke');
  }

  @override
  Expression toExpression() {
    return isNullAware
        ? new NullAwarePropertyGet(receiver.toExpression(), text)
        : new PropertyGet(receiver.toExpression(), text);
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() => 'InstanceAccessProto($receiver,$text)';

  @override
  Proto? resolve() => null;
}

/// The application of [typeArguments] on [receiver] which is known to be an
/// expression.
class ExpressionInstantiationProto extends Proto {
  final Proto receiver;
  final List<TypeAnnotation> typeArguments;

  ExpressionInstantiationProto(this.receiver, this.typeArguments);

  @override
  Proto access(String? name) {
    return name != null
        ? new ExpressionProto(new PropertyGet(receiver.toExpression(), name))
        : this;
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    throw new UnimplementedError('InstanceInstantiationProto.instantiate');
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new ExpressionProto(
            new ImplicitInvocation(
              receiver.toExpression(),
              const [],
              arguments,
            ),
          )
        : this;
  }

  @override
  Expression toExpression() {
    return new Instantiation(receiver.toExpression(), typeArguments);
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() => 'InstanceInstantiationProto($receiver,$typeArguments)';

  @override
  Proto? resolve() => null;
}

/// The application of [typeArguments] and [arguments] on [receiver] which is
/// known to be an expression.
class InstanceInvocationProto extends Proto {
  final Proto receiver;
  final List<TypeAnnotation> typeArguments;
  final List<Argument> arguments;

  InstanceInvocationProto(this.receiver, this.typeArguments, this.arguments);

  @override
  Proto access(String? name) {
    throw new UnimplementedError('InstanceInvocationProto.access');
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    throw new UnimplementedError('InstanceInvocationProto.instantiate');
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    throw new UnimplementedError('InstanceInvocationProto.invoke');
  }

  @override
  Expression toExpression() {
    return new ImplicitInvocation(
      receiver.toExpression(),
      typeArguments,
      arguments,
    );
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() =>
      'InstanceInvocationProto($receiver,$typeArguments,$arguments)';

  @override
  Proto? resolve() => null;
}

/// The access of [text] on [receiver] when this is known to be an invalid
/// construct.
// TODO(johnniwinther): This is not valid for non-const expressions. Expand
// this if used for non-const expressions.
class InvalidAccessProto extends Proto {
  final Proto receiver;
  final String text;

  InvalidAccessProto(this.receiver, this.text);

  @override
  Proto access(String? name) {
    throw new UnimplementedError('InvalidAccessProto.access');
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    throw new UnimplementedError('InvalidAccessProto.instantiate');
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    throw new UnimplementedError('InvalidAccessProto.invoke');
  }

  @override
  Expression toExpression() {
    return new InvalidExpression();
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() => 'InvalidAccessProto($receiver,$text)';

  @override
  Proto? resolve() => null;
}

/// The application of [typeArguments] on [receiver] when this is known to be an
/// invalid construct.
// TODO(johnniwinther): This might not be valid for non-const expressions.
//  Expand this if used for non-const expressions.
class InvalidInstantiationProto extends Proto {
  final Proto receiver;
  final List<TypeAnnotation> typeArguments;

  InvalidInstantiationProto(this.receiver, this.typeArguments);

  @override
  Proto access(String? name) {
    throw new UnimplementedError('InvalidInstantiationProto.access');
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    throw new UnimplementedError('InvalidInstantiationProto.instantiate');
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    throw new UnimplementedError('InvalidInstantiationProto.invoke');
  }

  @override
  Expression toExpression() {
    return new InvalidExpression();
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() => 'InvalidInstantiationProto($receiver,$typeArguments)';

  @override
  Proto? resolve() => null;
}

/// The application of [typeArguments] and [arguments] on [receiver] when this
/// is known to be an invalid construct.
// TODO(johnniwinther): This might not be valid for non-const expressions.
//  Expand this if used for non-const expressions.
class InvalidInvocationProto extends Proto {
  final Proto receiver;
  final List<TypeAnnotation> typeArguments;
  final List<Argument> arguments;

  InvalidInvocationProto(this.receiver, this.typeArguments, this.arguments);

  @override
  Proto access(String? name) {
    throw new UnimplementedError('InvalidInvocationProto.access');
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    throw new UnimplementedError('InvalidInvocationProto.instantiate');
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    throw new UnimplementedError('InvalidInvocationProto.invoke');
  }

  @override
  Expression toExpression() {
    return new InvalidExpression();
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() =>
      'InvalidInvocationProto($receiver,$typeArguments,$arguments)';

  @override
  Proto? resolve() => null;
}

/// An [expression] occurring as a [Proto].
class ExpressionProto extends Proto {
  final Expression expression;

  ExpressionProto(this.expression);

  @override
  Proto access(String? name) {
    return name != null ? new InstanceAccessProto(this, name) : this;
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments != null
        ? new ExpressionInstantiationProto(this, typeArguments)
        : this;
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new ExpressionProto(
            new ImplicitInvocation(expression, const [], arguments),
          )
        : this;
  }

  @override
  Expression toExpression() {
    return expression;
  }

  @override
  TypeAnnotation toTypeAnnotation() => new InvalidTypeAnnotation();

  @override
  String toString() => 'ExpressionProto($expression)';

  @override
  Proto? resolve() => null;
}

/// A reference to a [functionTypeParameter].
class FunctionTypeParameterProto extends Proto {
  final FunctionTypeParameter functionTypeParameter;

  FunctionTypeParameterProto(this.functionTypeParameter);

  @override
  Proto access(String? name) {
    return name == null ? this : new InvalidAccessProto(this, name);
  }

  @override
  Proto instantiate(List<TypeAnnotation>? typeArguments) {
    return typeArguments == null
        ? this
        : new ExpressionInstantiationProto(this, typeArguments);
  }

  @override
  Proto invoke(List<Argument>? arguments) {
    return arguments != null
        ? new ExpressionProto(
            new ImplicitInvocation(toExpression(), const [], arguments),
          )
        : this;
  }

  @override
  Proto? resolve() => null;

  @override
  Expression toExpression() {
    return new TypeLiteral(toTypeAnnotation());
  }

  @override
  TypeAnnotation toTypeAnnotation() {
    return new FunctionTypeParameterType(functionTypeParameter);
  }
}
