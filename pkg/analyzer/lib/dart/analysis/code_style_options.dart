// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// A set of options related to coding style that apply to the code within a
/// single analysis context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CodeStyleOptions {
  /// Whether the `require_trailing_commas` is enabled and trailing commas
  /// should be inserted in function calls and declarations.
  bool get addTrailingCommas;

  /// Whether local variables should be `final` inside a for-loop.
  bool get finalInForEach;

  /// Whether local variables should be `final` whenever possible.
  bool get makeLocalsFinal;

  /// Whether `prefer_const_declarations` is enabled.
  bool get preferConstDeclarations;

  /// Whether `prefer_int_literals` is enabled.
  bool get preferIntLiterals;

  /// The preferred quote based on the enabled lints, otherwise a single quote.
  String get preferredQuoteForStrings;

  /// Whether constructors should be sorted first, before other class members.
  bool get sortConstructorsFirst;

  /// Whether types should be specified whenever possible.
  bool get specifyTypes;

  /// Whether the formatter should be used on code changes in this context.
  bool get useFormatter;

  /// Whether URIs should be always added with a package scheme.
  bool get usePackageUris;

  /// Whether URIs should be "relative", meaning without a scheme, whenever
  /// possible.
  bool get useRelativeUris;

  /// The preferred quote character, based on the enabled lints, otherwise
  /// based on the most common quote, otherwise a single quote.
  String preferredQuoteForUris(Iterable<NamespaceDirective> directives);
}
