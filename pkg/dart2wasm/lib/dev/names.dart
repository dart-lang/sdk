// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;

/// Returns [member]'s label.
///
/// Example: `package:foo/foo.dart::Foo.bar`
String memberLabel(ast.Member member) {
  final libraryUri = member.enclosingLibrary.importUri;
  final className = member.enclosingClass?.name;
  final isUnnamedConstructor =
      member is ast.Constructor && member.name.text.isEmpty;
  final name = isUnnamedConstructor ? 'new' : member.name.text;
  if (className != null) {
    return '$libraryUri::$className.$name';
  }
  return '$libraryUri::$name';
}

/// Returns [cls]'s label.
///
/// Example: `package:foo/foo.dart::Foo`
String classLabel(ast.Class cls) =>
    '${cls.enclosingLibrary.importUri}::${cls.name}';

/// Returns instance [member]'s name.
///
/// Example: `mem` or `_mem@package:foo/foo.dart` if private.
String instanceMemberName(ast.Member member) {
  final name = member.name;
  return name.isPrivate ? '${name.text}@${name.library!.importUri}' : name.text;
}

/// Returns [function]'s shape label: its positional parameter count, then its
/// named parameters' names (sorted).
///
/// Example: `1,a,b` for `foo(x, {b, a})`.
String shapeLabel(ast.FunctionNode function) {
  final names = [
    for (final parameter in function.namedParameters) parameter.parameterName,
  ]..sort();
  return [function.positionalParameters.length, ...names].join(',');
}
