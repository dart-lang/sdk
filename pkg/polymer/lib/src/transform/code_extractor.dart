// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that extracts inlined script code into separate assets. */
library polymer.src.transformers;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

/**
 * Transformer that extracts Dart code inlined in HTML script tags and outputs a
 * separate file for each.
 */
class InlineCodeExtractor extends Transformer {
  Future<bool> isPrimary(Asset input) =>
      new Future.value(input.id.extension == ".html");

  Future apply(Transform transform) {
    var inputId = transform.primaryId;
    return getPrimaryContent(transform).then((content) {
      var document = parseHtml(content, inputId.path, transform.logger);
      int count = 0;
      for (var tag in document.queryAll('script')) {
        if (tag.attributes['type'] == 'application/dart' &&
            !tag.attributes.containsKey('src')) {
          // TODO(sigmund): should we automatically include a library directive
          // if it doesn't have one?
          var filename = path.basename(inputId.path);
          tag.attributes['src'] = '$filename.$count.dart';
          var textContent = tag.nodes.first;
          var id = inputId.addExtension('.$count.dart');
          transform.addOutput(new Asset.fromString(id, textContent.value));
          textContent.remove();
          count++;
        }
      }
      transform.addOutput(new Asset.fromString(inputId,
          count == 0 ? content : document.outerHtml));
    });
  }
}
