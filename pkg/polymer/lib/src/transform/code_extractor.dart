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

        // TODO(sigmund): should we automatically include a library directive
        // if it doesn't have one?
        var filename = path.url.basename(inputId.path);
        // TODO(sigmund): ensure this filename is unique (dartbug.com/12618).
        tag.attributes['src'] = '$filename.$count.dart';
        var textContent = tag.nodes.first;
        var id = inputId.addExtension('.$count.dart');
        transform.addOutput(new Asset.fromString(id, textContent.value));
        textContent.remove();
        count++;
      }
      transform.addOutput(new Asset.fromString(inputId,
          htmlChanged ? document.outerHtml : content));
    });
  }
}
