// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:yaml/yaml.dart';

const _desc = r'Avoid using web-only libraries outside Flutter web packages';

const _details = r'''Avoid using web packages, `dart:html`, `dart:js` and 
`dart:js_util` in non-web Flutter packages.  These packages are not supported
outside a web context and functionality that depends on them will fail at
runtime.

Web package access is allowed in:

* packages meant to run on the web (e.g., have a `web/` directory)
* plugin packages that declare `web` as a supported context

otherwise, imports of `dart:html`, `dart:js` and  `dart:js_util` are flagged.
''';

const _webLibs = [
  'dart:html',
  'dart:js',
  'dart:js_util',
];

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

class FlutterHtml extends LintRule implements NodeLintRule {
  FlutterHtml()
      : super(
            name: 'flutter_html',
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
  bool isInFlutterApp = true;
  bool isInFlutterWebContext = false;

  final rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // todo (pq): consider caching for library?
    final pubspecFile = locatePubspecFile(node);
    if (pubspecFile == null) {
      return;
    }

    var parsedPubspec;
    try {
      final content = pubspecFile.readAsStringSync();
      parsedPubspec = _parseYaml(content);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return;
    }

    if ((parsedPubspec['dependencies'] ?? const {})['flutter'] == null) {
      isInFlutterApp = false;
      return;
    }

    isInFlutterWebContext = pubspecFile.parent.getChild('web').exists ||
        ((parsedPubspec['flutter'] ?? const {})['plugin'] ?? const {})['web'] !=
            null;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (!isInFlutterApp || isInFlutterWebContext) return;

    if (_webLibs.contains(node.uri.stringValue)) {
      rule.reportLint(node);
    }
  }
}
