// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that combines multiple dart script tags into a single one. */
library polymer.src.transform.script_compactor;

import 'dart:async';

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
 * invoke the main method on each of these libraries and register any polymer
 * elements annotated with `@CustomTag`.
 */
class ScriptCompactor extends Transformer {
  /** Only run on entry point .html files. */
  Future<bool> isPrimary(Asset input) => isPrimaryHtml(input.id);

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    var logger = transform.logger;
    return transform.primaryInput.readAsString().then((content) {
      var document = parseHtml(content, id.path, logger,
          checkDocType: false);
      var libraries = [];
      bool changed = false;
      var dartLoaderTag = null;
      for (var tag in document.queryAll('script')) {
        var src = tag.attributes['src'];
        if (src != null) {
          if (src == 'packages/polymer/boot.js') {
            tag.remove();
            continue;
          }
          var last = src.split('/').last;
          if (last == 'dart.js' || last == 'testing.js') {
            dartLoaderTag = tag;
          }
        }
        if (tag.attributes['type'] != 'application/dart') continue;
        tag.remove();
        changed = true;
        if (src == null) {
          logger.warning('unexpected script without a src url. The '
            'ScriptCompactor transformer should run after running the '
            'InlineCodeExtractor', tag.sourceSpan);
          continue;
        }
        var libraryId = resolve(id, src, logger, tag.sourceSpan);

        // TODO(sigmund): should we detect/remove duplicates?
        if (libraryId == null) continue;
        libraries.add(libraryId);
      }

      if (!changed) {
        transform.addOutput(new Asset.fromString(id, content));
        return;
      }

      var bootstrapId = id.addExtension('_bootstrap.dart');
      var filename = path.url.basename(bootstrapId.path);

      var bootstrapScript = parseFragment(
            '<script type="application/dart" src="$filename"></script>');
      if (dartLoaderTag == null) {
        document.body.nodes.add(bootstrapScript);
        document.body.nodes.add(parseFragment(
            '<script src="packages/browser/dart.js"></script>'));
      } else if (dartLoaderTag.parent != document.body) {
        document.body.nodes.add(bootstrapScript);
      } else {
        document.body.insertBefore(bootstrapScript, dartLoaderTag);
      }

      var urls = libraries.map((id) => importUrlFor(id, bootstrapId, logger))
          .where((url) => url != null).toList();
      var buffer = new StringBuffer()..write(_header);
      for (int i = 0; i < urls.length; i++) {
        buffer.writeln("import '${urls[i]}' as i$i;");
      }
      buffer..write(_mainPrefix)
          ..writeAll(urls.map((url) => "      '$url',\n"))
          ..write(_mainSuffix);

      transform.addOutput(new Asset.fromString(bootstrapId, buffer.toString()));
      transform.addOutput(new Asset.fromString(id, document.outerHtml));
    });
  }

  /**
   * Generate the import url for a file described by [id], referenced by a file
   * with [sourceId].
   */
  String importUrlFor(AssetId id, AssetId sourceId, TransformLogger logger) {
    // use package: urls if possible
    if (id.path.startsWith('lib/')) {
      return 'package:${id.package}/${id.path.substring(4)}';
    }

    // Use relative urls only if it's possible.
    if (id.package != sourceId.package) {
      logger.error("don't know how to import $id from $sourceId");
      return null;
    }

    var builder = path.url;
    return builder.relative(builder.join('/', id.path),
        from: builder.join('/', builder.dirname(sourceId.path)));
  }
}

const _header = """
library app_bootstrap;

import 'package:polymer/polymer.dart';
import 'dart:mirrors' show currentMirrorSystem;

""";

const _mainPrefix = """

void main() {
  initPolymer([
""";

// TODO(sigmund): investigate alternative to get the baseUri (dartbug.com/12612)
const _mainSuffix = """
    ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
}
""";
