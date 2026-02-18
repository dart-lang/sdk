// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Type aliases with dot shorthands.

typedef ClassAlias = A<int>;
typedef AliasAlias = ClassAlias;
typedef ExtensionAlias = AExt<int>;
typedef ExtensionAliasAlias = ExtensionAlias; 

class A<T> {
  static ClassAlias get alias => A(1);

  static const ClassAlias constAlias = const A._(1);

  static ClassAlias method() => A(1);

  final T t;

  A(this.t);

  const A._(this.t);

  ClassAlias get aliasGetter => A(1);
}

extension type AExt<T>(T t) {
  static ExtensionAlias get alias => AExt(1);

  static const ExtensionAlias constAlias = const AExt._(1);

  static ExtensionAlias method() => AExt(1);

  const AExt._(this.t);

  ExtensionAlias get aliasGetter => AExt(1);
}


void main() {
  // Class
  ClassAlias classAlias = .alias;
  ClassAlias classAlias2 = .new(1).aliasGetter;
  ClassAlias classAliasMethod = .method();
  const ClassAlias constClassAlias = .constAlias;

  // Extension type
  ExtensionAlias extensionAlias = .alias;
  ExtensionAlias extensionAliasCtor = .new(1).aliasGetter;
  ExtensionAlias extensionAliasMethod = .method();
  const ExtensionAlias constExtensionAlias = .constAlias;

  // Nested typedefs
  AliasAlias nestedAlias = .alias;
  AliasAlias nestedAlias2 = .new(1).aliasGetter;
  AliasAlias nestedAliasMethod = .method();
  const AliasAlias constNestedAlias = .constAlias;

  ExtensionAliasAlias nestedExtensionAlias = .alias;
  ExtensionAliasAlias nestedExtensionAliasCtor = .new(1).aliasGetter;
  ExtensionAliasAlias nestedExtensionAliasMethod = .method();
  const ExtensionAliasAlias constNestedExtensionExtensionAlias = .constAlias;
}
