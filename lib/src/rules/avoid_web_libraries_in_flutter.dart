// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc =
    r'Avoid using web-only libraries outside Flutter web plugin packages.';

const _details = r'''Avoid using web libraries, `dart:html`, `dart:js` and 
`dart:js_util` in Flutter packages that are not web plugins. These libraries are 
not supported outside a web context; functionality that depends on them will
fail at runtime in Flutter mobile, and their use is generally discouraged in
Flutter web.

Web library access *is* allowed in:

* plugin packages that declare `web` as a supported context

otherwise, imports of `dart:html`, `dart:js` and  `dart:js_util` are disallowed.
''';

/// todo (pq): consider making a utility and sharing w/ `prefer_relative_imports`
YamlMap _parseYaml(String content) {
  try {
    final doc = loadYamlNode(content);
    if (doc is YamlMap) {
      return doc;
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    // Fall-through.
  }
  return YamlMap();
}

class AvoidWebLibrariesInFlutter extends LintRule implements NodeLintRule {
  AvoidWebLibrariesInFlutter()
      : super(
            name: 'avoid_web_libraries_in_flutter',
            description: _desc,
            details: _details,
            maturity: Maturity.experimental,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  File pubspecFile;

  final rule;
  bool _shouldValidateUri;

  _Visitor(this.rule);

  bool get shouldValidateUri => _shouldValidateUri ??= checkForValidation();

  bool checkForValidation() {
    if (pubspecFile == null) {
      return false;
    }

    var parsedPubspec;
    try {
      final content = pubspecFile.readAsStringSync();
      parsedPubspec = _parseYaml(content);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }

    // Check for Flutter.
    if ((parsedPubspec['dependencies'] ?? const {})['flutter'] == null) {
      return false;
    }

    // Check for a web plugin context declaration.
    return (((parsedPubspec['flutter'] ?? const {})['plugin'] ??
                const {})['platforms'] ??
            const {})['web'] ==
        null;
  }

  bool isWebUri(String uri) {
    final uriLength = uri.length;
    return (uriLength == 9 && uri == 'dart:html') ||
        (uriLength == 7 && uri == 'dart:js') ||
        (uriLength == 12 && uri == 'dart:js_util');
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    pubspecFile = locatePubspecFile(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (isWebUri(node.uri.stringValue) && shouldValidateUri) {
      rule.reportLint(node);
    }
  }
}
