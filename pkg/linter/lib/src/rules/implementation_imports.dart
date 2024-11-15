// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r"Don't import implementation files from another package.";

bool isImplementation(Uri? uri) {
  var segments = uri?.pathSegments ?? const <String>[];
  if (segments.length > 2) {
    if (segments[1] == 'src') {
      return true;
    }
  }
  return false;
}

bool isPackage(Uri? uri) => uri?.scheme == 'package';

bool samePackage(Uri? uri1, Uri? uri2) {
  if (uri1 == null || uri2 == null) {
    return false;
  }
  var segments1 = uri1.pathSegments;
  var segments2 = uri2.pathSegments;
  if (segments1.isEmpty || segments2.isEmpty) {
    return false;
  }
  return segments1.first == segments2.first;
}

class ImplementationImports extends LintRule {
  ImplementationImports()
      : super(
          name: LintNames.implementation_imports,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.implementation_imports;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var libraryUri = context.libraryElement2?.uri;
    if (libraryUri == null) return;

    // If the source URI is not a `package` URI bail out.
    if (!isPackage(libraryUri)) return;

    var visitor = _Visitor(this, libraryUri);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final Uri sourceUri;

  _Visitor(this.rule, this.sourceUri);

  @override
  void visitImportDirective(ImportDirective node) {
    Uri? importUri;
    if (node.libraryImport?.uri case DirectiveUriWithSource importedLibrary) {
      importUri = importedLibrary.source.uri;
    }

    // Test for 'package:*/src/'.
    if (!isImplementation(importUri)) return;

    if (!samePackage(importUri, sourceUri)) {
      rule.reportLint(node.uri);
    }
  }
}
