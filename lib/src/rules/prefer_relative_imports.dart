// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../rules/implementation_imports.dart';

const _desc = r'Prefer relative imports for files in `lib/`.';

const _details = r'''Prefer relative imports for files in `lib/`.

When mixing relative and absolute imports it's possible to create confusion
where the same member gets imported in two different ways. One way to avoid
that is to ensure you consistently use relative imports for files withing the
`lib/` directory.

**GOOD:**

```
import 'bar.dart';
```

**BAD:**

```
import 'package:my_package/bar.dart';
```

''';

YamlMap _parseYaml(String content) {
  if (content == null) {
    return YamlMap();
  }
  try {
    YamlNode doc = loadYamlNode(content);
    if (doc is YamlMap) {
      return doc;
    }
    return YamlMap();
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return YamlMap();
  }
}

class PreferRelativeImports extends LintRule implements NodeLintRule {
  PreferRelativeImports()
      : super(
            name: 'prefer_relative_imports',
            description: _desc,
            details: _details,
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
  final PreferRelativeImports rule;

  bool isInLibFolder;
  File pubspecFile;
  YamlMap parsedPubspec;

  _Visitor(this.rule);

  bool isPackageSelfReference(ImportDirective node) {
    // Ignore this compilation unit if it's not in the lib/ folder.
    if (!isInLibFolder) return false;

    // Is it a package: import?
    String importUri = node?.uri?.stringValue;
    if (importUri == null) return false;

    Uri uri;
    try {
      uri = Uri.parse(importUri);
      if (!isPackage(uri)) return false;
    } on FormatException catch (_) {
      return false;
    }

    // Is the package: import referencing the current package?
    var segments = uri.pathSegments;
    if (segments.isEmpty) return false;

    if (parsedPubspec == null) {
      String content;
      try {
        content = pubspecFile.readAsStringSync();
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
      parsedPubspec = _parseYaml(content);
    }

    return parsedPubspec['name'] == segments[0];
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    isInLibFolder = isDefinedInLib(node);

    pubspecFile = locatePubspecFile(node);
    parsedPubspec = null;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (pubspecFile == null) return;

    if (isPackageSelfReference(node)) {
      rule.reportLint(node.uri);
    }
  }
}
