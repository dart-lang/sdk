// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that extracts inlined script code into separate assets. */
library polymer.src.transformers;

import 'dart:async';

import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

/**
 * Transformer that extracts Dart code inlined in HTML script tags and outputs a
 * separate file for each.
 */
class InlineCodeExtractor extends Transformer {
  /** Only run this transformer on .html files. */
  final String allowedExtensions = ".html";


  Future apply(Transform transform) {
    var inputId = transform.primaryInput.id;
    return transform.primaryInput.readAsString().then((content) {
      var document = parseHtml(content, inputId.path, transform.logger);
      int count = 0;
      bool htmlChanged = false;
      for (var tag in document.queryAll('script')) {
        // Only process tags that have inline Dart code
        if (tag.attributes['type'] != 'application/dart' ||
          tag.attributes.containsKey('src')) {
          continue;
        }
        htmlChanged = true;

        // Remove empty tags
        if (tag.nodes.length == 0) {
          tag.remove();
          continue;
        }

        var filename = path.url.basename(inputId.path);
        // TODO(sigmund): ensure this filename is unique (dartbug.com/12618).
        tag.attributes['src'] = '$filename.$count.dart';
        var textContent = tag.nodes.first;
        var code = textContent.value;
        var id = inputId.addExtension('.$count.dart');
        if (!_hasLibraryDirective(code)) {
          var libname = path.withoutExtension(id.path)
              .replaceAll(new RegExp('[-./]'), '_');
          code = "library $libname;\n$code";
        }
        transform.addOutput(new Asset.fromString(id, code));
        textContent.remove();
        count++;
      }
      transform.addOutput(new Asset.fromString(inputId,
          htmlChanged ? document.outerHtml : content));
    });
  }
}

/** Parse [code] and determine whether it has a library directive. */
bool _hasLibraryDirective(String code) {
  var errorListener = new _ErrorCollector();
  var token = new StringScanner(null, code, errorListener).tokenize();
  var unit = new Parser(null, errorListener).parseCompilationUnit(token);
  return unit.directives.any((d) => d is LibraryDirective);
}

class _ErrorCollector extends AnalysisErrorListener {
  final errors = <AnalysisError>[];
  onError(error) => errors.add(error);
}
