// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.declaration;

import '../problems.dart' show unsupported;

abstract class Builder {
  /// Used when multiple things with the same name are declared within the same
  /// parent. Only used for top-level and class-member declarations, not for
  /// block scopes.
  Builder next;

  Builder get parent;

  Uri get fileUri;

  int get charOffset;

  Builder get origin;

  String get fullNameForErrors;

  bool get hasProblem;

  bool get isConst;

  bool get isConstructor;

  bool get isFactory;

  bool get isField;

  bool get isFinal;

  bool get isGetter;

  /// Returns `true` if this builder is an extension declaration.
  ///
  /// For instance `B` in:
  ///
  ///    class A {}
  ///    extension B on A {}
  ///
  bool get isExtension;

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
  bool get isExtensionMember;

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

  bool get isLocal;

  bool get isPatch;

  bool get isRegularMethod;

  bool get isOperator;

  bool get isSetter;

  bool get isStatic;

  bool get isSynthetic;

  bool get isTopLevel;

  bool get isTypeDeclaration;

  bool get isTypeVariable;

  /// Applies [patch] to this declaration.
  void applyPatch(Builder patch);

  /// Returns the number of patches that was finished.
  int finishPatch();

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors(covariant Builder parent);

  /// Return `true` if this builder is a duplicate of another with the same
  /// name. This is `false` for the builder first declared amongst duplicates.
  bool get isDuplicate;
}

abstract class BuilderImpl implements Builder {
  @override
  Builder next;

  BuilderImpl();

  @override
  Builder get origin => this;

  bool get hasProblem => false;

  @override
  bool get isConst => false;

  @override
  bool get isConstructor => false;

  @override
  bool get isFactory => false;

  @override
  bool get isField => false;

  @override
  bool get isFinal => false;

  @override
  bool get isGetter => false;

  @override
  bool get isExtension => false;

  @override
  bool get isDeclarationMember => false;

  @override
  bool get isClassMember => false;

  @override
  bool get isExtensionMember => false;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  bool get isClassInstanceMember => false;

  @override
  bool get isExtensionInstanceMember => false;

  @override
  bool get isLocal => false;

  @override
  bool get isPatch => this != origin;

  @override
  bool get isRegularMethod => false;

  @override
  bool get isOperator => false;

  @override
  bool get isSetter => false;

  @override
  bool get isStatic => false;

  @override
  bool get isSynthetic => false;

  @override
  bool get isTopLevel => false;

  @override
  bool get isTypeDeclaration => false;

  @override
  bool get isTypeVariable => false;

  @override
  void applyPatch(Builder patch) {
    unsupported("${runtimeType}.applyPatch", charOffset, fileUri);
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;
    unsupported("${runtimeType}.finishPatch", charOffset, fileUri);
    return 0;
  }

  @override
  int resolveConstructors(covariant Builder parent) => 0;

  @override
  bool get isDuplicate => next != null;
}
