// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.declaration;

import '../problems.dart' show unsupported;

/// Dummy class to help deprecate [Builder.target].
abstract class UnrelatedTarget {}

abstract class Builder {
  /// Used when multiple things with the same name are declared within the same
  /// parent. Only used for top-level and class-member declarations, not for
  /// block scopes.
  Builder next;

  Builder();

  Builder get parent;

  Uri get fileUri;

  int get charOffset;

  get target => unsupported("${runtimeType}.target", charOffset, fileUri);

  Builder get origin => this;

  String get fullNameForErrors;

  bool get hasProblem => false;

  bool get isConst => false;

  bool get isConstructor => false;

  bool get isFactory => false;

  bool get isField => false;

  bool get isFinal => false;

  bool get isGetter => false;

  /// Returns `true` if this builder is an extension declaration.
  ///
  /// For instance `B` in:
  ///
  ///    class A {}
  ///    extension B on A {}
  ///
  bool get isExtension => false;

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
  bool get isDeclarationMember => false;

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
  bool get isClassMember => false;

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
  bool get isExtensionMember => false;

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
  bool get isDeclarationInstanceMember => false;

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
  bool get isClassInstanceMember => false;

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
  bool get isExtensionInstanceMember => false;

  bool get isLocal => false;

  bool get isPatch => this != origin;

  bool get isRegularMethod => false;

  bool get isSetter => false;

  bool get isStatic => false;

  bool get isSynthetic => false;

  bool get isTopLevel => false;

  bool get isTypeDeclaration => false;

  bool get isTypeVariable => false;

  bool get isMixinApplication => false;

  bool get isNamedMixinApplication => false;

  bool get isAnonymousMixinApplication {
    return isMixinApplication && !isNamedMixinApplication;
  }

  /// Applies [patch] to this declaration.
  void applyPatch(Builder patch) {
    unsupported("${runtimeType}.applyPatch", charOffset, fileUri);
  }

  /// Returns the number of patches that was finished.
  int finishPatch() {
    if (!isPatch) return 0;
    unsupported("${runtimeType}.finishPatch", charOffset, fileUri);
    return 0;
  }

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors(covariant Builder parent) => 0;

  /// Return `true` if this builder is a duplicate of another with the same
  /// name. This is `false` for the builder first declared amongst duplicates.
  bool get isDuplicate => next != null;
}
