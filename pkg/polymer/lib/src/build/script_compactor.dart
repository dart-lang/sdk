// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that combines multiple dart script tags into a single one. */
library polymer.src.build.script_compactor;

import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:html5lib/parser.dart' show parseFragment;
import 'package:path/path.dart' as path;

import 'code_extractor.dart'; // import just for documentation.
import 'common.dart';

/**
 * Combines Dart script tags into a single script tag, and creates a new Dart
 * file that calls the main function of each of the original script tags.
 *
 * This transformer assumes that all script tags point to external files. To
 * support script tags with inlined code, use this transformer after running
 * [InlineCodeExtractor] on an earlier phase.
 *
 * Internally, this transformer will convert each script tag into an import
 * statement to a library, and then uses `initPolymer` (see polymer.dart)  to
 * process `@initMethod` and `@CustomTag` annotations in those libraries.
 */
class ScriptCompactor extends Transformer with PolymerTransformer {
  final TransformOptions options;

  ScriptCompactor(this.options);

  /** Only run on entry point .html files. */
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    var secondaryId = id.addExtension('.scriptUrls');
    var logger = transform.logger;
    return readPrimaryAsHtml(transform).then((document) {
      return transform.readInputAsString(secondaryId).then((libraryIds) {
        var libraries = (JSON.decode(libraryIds) as Iterable).map(
          (data) => new AssetId.deserialize(data)).toList();
        var mainLibraryId;
        var mainScriptTag;
        bool changed = false;

        for (var tag in document.queryAll('script')) {
          var src = tag.attributes['src'];
          if (src == 'packages/polymer/boot.js') {
            tag.remove();
            continue;
          }
          if (tag.attributes['type'] != 'application/dart') continue;
          if (src == null) {
            logger.warning('unexpected script without a src url. The '
              'ScriptCompactor transformer should run after running the '
              'InlineCodeExtractor', span: tag.sourceSpan);
            continue;
          }
          if (mainLibraryId != null) {
            logger.warning('unexpected script. Only one Dart script tag '
              'per document is allowed.', span: tag.sourceSpan);
            tag.remove();
            continue;
          }
          mainLibraryId = resolve(id, src, logger, tag.sourceSpan);
          mainScriptTag = tag;
        }

        if (mainScriptTag == null) {
          // We didn't find any main library, nothing to do.
          transform.addOutput(transform.primaryInput);
          return null;
        }

        var bootstrapId = id.addExtension('_bootstrap.dart');
        mainScriptTag.attributes['src'] =
            path.url.basename(bootstrapId.path);

        libraries.add(mainLibraryId);
        var urls = libraries.map((id) => assetUrlFor(id, bootstrapId, logger))
            .where((url) => url != null).toList();
        var buffer = new StringBuffer()..writeln(MAIN_HEADER);
        int i = 0;
        for (; i < urls.length; i++) {
          buffer.writeln("import '${urls[i]}' as i$i;");
        }

        buffer..write('\n')
            ..writeln('void main() {')
            ..writeln('  configureForDeployment([')
            ..writeAll(urls.map((url) => "      '$url',\n"))
            ..writeln('    ]);')
            ..writeln('  i${i - 1}.main();')
            ..writeln('}');

        transform.addOutput(new Asset.fromString(
              bootstrapId, buffer.toString()));
        transform.addOutput(new Asset.fromString(id, document.outerHtml));
      });
    });
  }
}

const MAIN_HEADER = """
library app_bootstrap;

import 'package:polymer/polymer.dart';
""";
