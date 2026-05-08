// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;

/// Prefix for the getter names.
const String getterPrefix = 'get:';

/// Prefix for the setter names.
const String setterPrefix = 'set:';

/// Prefix for the selectors in the dynamic calls.
const String dynamicPrefix = 'dyn:';

/// Identifier in the Dart program, in the VM conventions.
///
/// Public names are represented with [String] objects, while
/// private names are represented with [PrivateName] objects.
extension type Name._(Object /*String|PrivateName*/ raw) implements Object {
  /// If [library] is not null, create a private name.
  /// Otherwise, create a public name.
  factory Name(String text, ast.Library? library) =>
      Name._((library != null) ? PrivateName(text, library) : text);

  factory Name.interfaceCallSelector(CFunction interfaceTarget) {
    final simpleName = interfaceTarget.member.name.text;
    return Name(switch (interfaceTarget) {
      GetterFunction() => '$getterPrefix$simpleName',
      SetterFunction() => '$setterPrefix$simpleName',
      _ => simpleName,
    }, interfaceTarget.member.name.library);
  }

  factory Name.dynamicCallSelector(DynamicCallKind kind, ast.Name selector) {
    return Name(switch (kind) {
      .method => '$dynamicPrefix${selector.text}',
      .getter => '$dynamicPrefix$getterPrefix${selector.text}',
      .setter => '$dynamicPrefix$setterPrefix${selector.text}',
    }, selector.library);
  }
}

/// Private name in a [library].
/// VM mangles such names with a library key (`@nnnn`).
final class PrivateName {
  final String text;
  final ast.Library library;
  PrivateName(this.text, this.library);

  @override
  bool operator ==(Object other) =>
      other is PrivateName && text == other.text && library == other.library;

  @override
  int get hashCode =>
      finalizeHash(combineHash(text.hashCode, library.hashCode));
}
