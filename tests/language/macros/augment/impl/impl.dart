// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:macros/macros.dart';

extension TypePhaseIntrospecterExtension on TypePhaseIntrospector {
  /// Converts [string] into `Code`.
  ///
  /// Identifiers to resolve must be marked with backticks, for example:
  ///
  /// ```
  ///   `int` get x => 3;
  /// ```
  ///
  /// They will be resolved in the context of `dart:core`.
  ///
  /// If [string] is `null`, just return `null`; or throw if `T` is not
  /// nullable.
  Future<T> code<T extends Code>(String string) async {
    final parts = <Object>[];
    final chunks = string.split('`');
    var isIdentifier = false;
    for (final chunk in chunks) {
      if (isIdentifier) {
        parts.add(await this.resolveIdentifier(Uri.parse('dart:core'), chunk));
      } else {
        parts.add(chunk);
      }
      isIdentifier = !isIdentifier;
    }

    if (T == CommentCode) {
      return CommentCode.fromParts(parts) as T;
    } else if (T == DeclarationCode) {
      return DeclarationCode.fromParts(parts) as T;
    } else if (T == ExpressionCode) {
      return ExpressionCode.fromParts(parts) as T;
    } else if (T == FunctionBodyCode) {
      return FunctionBodyCode.fromParts(parts) as T;
    } else {
      throw UnsupportedError(T.runtimeType.toString());
    }
  }

  /// As [code] but returns `null` for `null` input
  Future<T?> maybeCode<T extends Code>(String? string) async {
    if (string == null) return null;
    return await code<T>(string);
  }
}
