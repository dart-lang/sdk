// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// The concrete implementation of [CodeStyleOptions].
class CodeStyleOptionsImpl implements CodeStyleOptions {
  /// The analysis options that owns this instance.
  final AnalysisOptions _options;

  @override
  final bool useFormatter;

  CodeStyleOptionsImpl(this._options, {required this.useFormatter});

  @override
  bool get addTrailingCommas => _isLintEnabled('require_trailing_commas');

  @override
  bool get makeLocalsFinal => _isLintEnabled('prefer_final_locals');

  @override
  bool get preferIntLiterals => _isLintEnabled('prefer_int_literals');

  @override
  String get preferredQuoteForStrings => _lintQuote() ?? "'";

  @override
  bool get sortConstructorsFirst => _isLintEnabled('sort_constructors_first');

  @override
  bool get specifyTypes => _isLintEnabled('always_specify_types');

  @override
  bool get usePackageUris => _isLintEnabled('always_use_package_imports');

  @override
  bool get useRelativeUris => _isLintEnabled('prefer_relative_imports');

  @override
  String preferredQuoteForUris(Iterable<NamespaceDirective> directives) {
    var lintQuote = _lintQuote();
    if (lintQuote != null) {
      return lintQuote;
    }
    var singleCount = 0;
    var doubleCount = 0;

    void add(SimpleStringLiteral literal) {
      var lexeme = literal.literal.lexeme;
      if (lexeme.startsWith('"')) {
        doubleCount++;
      } else {
        singleCount++;
      }
    }

    for (var directive in directives) {
      var uri = directive.uri;
      if (uri is SimpleStringLiteral) {
        add(uri);
      } else if (uri is AdjacentStrings) {
        for (var string in uri.strings) {
          if (string is SimpleStringLiteral) {
            add(string);
          }
        }
      }
    }
    return doubleCount > singleCount ? '"' : "'";
  }

  /// Returns whether the lint rule with the given [name] is enabled.
  bool _isLintEnabled(String name) => _options.isLintEnabled(name);

  /// Returns the preferred lint quote, otherwise `null`.
  String? _lintQuote() => _isLintEnabled('prefer_single_quotes')
      ? "'"
      : _isLintEnabled('prefer_double_quotes')
          ? '"'
          : null;
}
