// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Builder {
  Builder? get parent;

  Uri? get fileUri;

  int get fileOffset;

  String get fullNameForErrors;

  /// Returns `true` if this builder is a member of a class, mixin, or extension
  /// declaration.
  ///
  /// For instance `A.constructor`, `method1a`, `method1b`, `method2a`,
  /// `method2b`, `method3a`, and `method3b` in:
  ///
  ///     class A {
  ///       A.constructor();
  ///       method1a() {}
  ///       static method1b() {}
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {}
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {}
  ///     }
  ///
  /// Unused in interface; left in on purpose.
  bool get isDeclarationMember;

  /// Returns `true` if this builder is a member of a class or mixin
  /// declaration.
  ///
  /// For instance `A.constructor`, `method1a`, `method1b`, `method2a` and
  /// `method2b` in:
  ///
  ///     class A {
  ///       A.constructor();
  ///       method1a() {}
  ///       static method1b() {}
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {}
  ///     }
  ///     extends C on A {
  ///       method3a() {}        // Not a class member.
  ///       static method3b() {} // Not a class member.
  ///     }
  ///
  /// Unused in interface; left in on purpose.
  bool get isClassMember;

  /// Returns `true` if this builder is a member of an extension declaration.
  ///
  /// For instance `method3a` and `method3b` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an extension member.
  ///       method1a() {}        // Not an extension member.
  ///       static method1b() {} // Not an extension member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an extension member.
  ///       static method2b() {} // Not an extension member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {}
  ///     }
  ///
  /// Unused in interface; left in on purpose.
  bool get isExtensionMember;

  /// Returns `true` if this builder is a member of an extension type
  /// declaration.
  ///
  /// For instance `method3a` and `method3b` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an extension type member.
  ///       method1a() {}        // Not an extension type member.
  ///       static method1b() {} // Not an extension type member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an extension type member.
  ///       static method2b() {} // Not an extension type member.
  ///     }
  ///     extension type C(A it) {
  ///       method3a() {}
  ///       static method3b() {}
  ///     }
  ///
  bool get isExtensionTypeMember;

  /// Returns `true` if this builder is an instance member of a class, mixin, or
  /// extension declaration.
  ///
  /// For instance `method1a`, `method2a`, and `method3a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not a declaration instance member.
  ///       method1a() {}
  ///       static method1b() {} // Not a declaration instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {} // Not a declaration instance member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {} // Not a declaration instance member.
  ///     }
  ///
  bool get isDeclarationInstanceMember;

  /// Returns `true` if this builder is an instance member of a class or mixin
  /// extension declaration.
  ///
  /// For instance `method1a` and `method2a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not a class instance member.
  ///       method1a() {}
  ///       static method1b() {} // Not a class instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {} // Not a class instance member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}        // Not a class instance member.
  ///       static method3b() {} // Not a class instance member.
  ///     }
  ///
  bool get isClassInstanceMember;

  /// Returns `true` if this builder is an instance member of an extension
  /// declaration.
  ///
  /// For instance `method3a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an extension instance member.
  ///       method1a() {}        // Not an extension instance member.
  ///       static method1b() {} // Not an extension instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an extension instance member.
  ///       static method2b() {} // Not an extension instance member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {} // Not an extension instance member.
  ///     }
  ///
  bool get isExtensionInstanceMember;

  /// Returns `true` if this builder is an instance member of an extension type
  /// declaration.
  ///
  /// For instance `method3a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an extension type instance member.
  ///       method1a() {}        // Not an extension type instance member.
  ///       static method1b() {} // Not an extension type instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an extension type instance member.
  ///       static method2b() {} // Not an extension type instance member.
  ///     }
  ///     extension type C(A it) {
  ///       C.named(this.it);    // Not an extension type instance member.
  ///       method3a() {}
  ///       static method3b() {} // Not an extension type instance member.
  ///     }
  ///
  bool get isExtensionTypeInstanceMember;

  bool get isStatic;

  bool get isSynthetic;

  bool get isTopLevel;

  bool get isTypeParameter;
}

abstract class NamedBuilder implements Builder {
  String get name;

  /// Used when multiple things with the same name are declared within the same
  /// parent. Only used for top-level and class-member declarations, not for
  /// block scopes.
  NamedBuilder? next;

  /// Return `true` if this builder is a duplicate of another with the same
  /// name. This is `false` for the builder first declared amongst duplicates.
  bool get isDuplicate;
}

abstract class BuilderImpl implements Builder {
  BuilderImpl();

  @override
  // Coverage-ignore(suite): Not run.
  bool get isDeclarationMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isClassMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeMember => false;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isClassInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isStatic => false;

  @override
  bool get isSynthetic => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isTopLevel => false;

  @override
  bool get isTypeParameter => false;
}

abstract class NamedBuilderImpl extends BuilderImpl implements NamedBuilder {
  @override
  NamedBuilder? next;

  @override
  bool get isDuplicate => next != null;
}

extension BuilderExtension on NamedBuilder {
  /// Returns the 'duplicate index' for this builder, which is the number of
  /// builders declared prior this.
  ///
  /// For a non-duplicate builder, this is 0.
  int get duplicateIndex {
    if (next != null) {
      int count = 0;
      NamedBuilder? current = next;
      while (current != null) {
        count++;
        current = current.next;
      }
      return count;
    }
    return 0;
  }
}
