// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc =
    r'Avoid using web-only libraries outside Flutter web plugin packages.';

// TODO(pq): consider making a utility and sharing w/ `prefer_relative_imports`
YamlMap _parseYaml(String content) {
  try {
    var doc = loadYamlNode(content);
    if (doc is YamlMap) {
      return doc;
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    // Fall-through.
  }
  return YamlMap();
}

class AvoidWebLibrariesInFlutter extends LintRule {
  /// Cache of most recent analysis root to parsed "hasFlutter" state.
  static final Map<String, bool> _rootHasFlutterCache = {};

  AvoidWebLibrariesInFlutter()
    : super(name: LintNames.avoid_web_libraries_in_flutter, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidWebLibrariesInFlutter;

  bool hasFlutterDep(File? pubspec) {
    if (pubspec == null) {
      return false;
    }

    YamlMap parsedPubspec;
    try {
      var content = pubspec.readAsStringSync();
      parsedPubspec = _parseYaml(content);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }

    // If it has Flutter as a dependency, continue checking.
    if (parsedPubspec['dependencies'] case {'flutter': var _?}) {
      if (parsedPubspec['flutter'] case {
        'plugin': {'platforms': {'web': _?}},
      }) {
        // Is a Flutter web plugin; allow web libraries.
        return false;
      } else {
        // Is a non-web Flutter package; don't allow web libraries.
        return true;
      }
    }

    // Is not a Flutter package; allow web libraries.
    return false;
  }

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    bool hasFlutter(String root) {
      var hasFlutter = _rootHasFlutterCache[root];
      if (hasFlutter == null) {
        // Clear the previous cache.
        clearCache();
        var pubspecFile = locatePubspecFile(context.definingUnit.unit);
        hasFlutter = hasFlutterDep(pubspecFile);
        _rootHasFlutterCache[root] = hasFlutter;
      }
      return hasFlutter;
    }

    var root = context.package?.root;
    if (root != null) {
      if (hasFlutter(root.path)) {
        var visitor = _Visitor(this);
        registry.addImportDirective(this, visitor);
      }
    }
  }

  @visibleForTesting
  static void clearCache() => _rootHasFlutterCache.clear();
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isWebUri(String uri) {
    var uriLength = uri.length;
    return (uriLength == 9 && uri == 'dart:html') ||
        (uriLength == 7 && uri == 'dart:js') ||
        (uriLength == 12 && uri == 'dart:js_util');
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var uriString = node.uri.stringValue;
    if (uriString != null && isWebUri(uriString)) {
      rule.reportAtNode(node);
    }
  }
}
