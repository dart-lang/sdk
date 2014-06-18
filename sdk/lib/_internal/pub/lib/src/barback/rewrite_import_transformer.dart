// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.rewrite_import_transformer;

import 'dart:async';

import 'package:barback/barback.dart';

import '../dart.dart';

/// A transformer used internally to rewrite "package:" imports so they point to
/// the barback server rather than to pub's package root.
class RewriteImportTransformer extends Transformer {
  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var directives = parseImportsAndExports(contents,
          name: transform.primaryInput.id.toString());

      var buffer = new StringBuffer();
      var index = 0;
      for (var directive in directives) {
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
