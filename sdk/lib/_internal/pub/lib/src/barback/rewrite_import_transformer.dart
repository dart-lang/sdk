// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.rewrite_import_transformer;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:analyzer/analyzer.dart';

/// A transformer used internally to rewrite "package:" imports so they point to
/// the barback server rather than to pub's package root.
class RewriteImportTransformer extends Transformer {
  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var collector = new _DirectiveCollector();
      parseCompilationUnit(contents, name: transform.primaryInput.id.toString())
          .accept(collector);

      var buffer = new StringBuffer();
      var index = 0;
      for (var directive in collector.directives) {
        var uri = Uri.parse(directive.uri.stringValue);
        if (uri.scheme != 'package') continue;

        buffer
          ..write(contents.substring(index, directive.uri.literal.offset))
          ..write('"/packages/${uri.path}"');
        index = directive.uri.literal.end;
      }
      buffer.write(contents.substring(index, contents.length));

      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, buffer.toString()));
    });
  }
}

/// A simple visitor that collects import and export nodes.
class _DirectiveCollector extends GeneralizingAstVisitor {
  final directives = <UriBasedDirective>[];

  visitUriBasedDirective(UriBasedDirective node) => directives.add(node);
}
