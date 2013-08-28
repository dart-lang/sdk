// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that inlines polymer-element definitions from html imports. */
library polymer.src.transform.import_inliner;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show Document, Node, DocumentFragment;
import 'common.dart';

/** Recursively inlines polymer-element definitions from html imports. */
// TODO(sigmund): make sure we match semantics of html-imports for tags other
// than polymer-element (see dartbug.com/12613).
class ImportedElementInliner extends Transformer {
  Future<bool> isPrimary(Asset input) =>
      new Future.value(input.id.extension == ".html");

  Future apply(Transform transform) {
    var seen = new Set<AssetId>();
    var elements = [];
    var id = transform.primaryInput.id;
    seen.add(id);
    return transform.primaryInput.readAsString().then((content) {
      var document = parseHtml(content, id.path, transform.logger);
      var future = _visitImports(document, id, transform, seen, elements);
      return future.then((importsFound) {
        if (!importsFound) {
          transform.addOutput(new Asset.fromString(id, content));
          return;
        }

        for (var tag in document.queryAll('link')) {
          if (tag.attributes['rel'] == 'import') {
            tag.remove();
          }
        }
        var fragment = new DocumentFragment()..nodes.addAll(elements);
        document.body.insertBefore(fragment,
            //TODO(jmesserly): add Node.firstChild to html5lib
            document.body.nodes.length == 0 ? null : document.body.nodes[0]);
        transform.addOutput(new Asset.fromString(id, document.outerHtml));
      });
    });
  }

  /**
   * Visits imports in [document] and add their polymer-element definitions to
   * [elements], unless they have already been [seen]. Elements are added in the
   * order they appear, transitive imports are added first.
   */
  Future<bool> _visitImports(Document document, AssetId sourceId,
      Transform transform, Set<AssetId> seen, List<Node> elements) {
    var importIds = [];
    bool hasImports = false;
    for (var tag in document.queryAll('link')) {
      if (tag.attributes['rel'] != 'import') continue;
      var href = tag.attributes['href'];
      var id = resolve(sourceId, href, transform.logger, tag.sourceSpan);
      hasImports = true;
      if (id == null || seen.contains(id)) continue;
      importIds.add(id);
    }

    if (importIds.isEmpty) return new Future.value(hasImports);

    // Note: we need to preserve the import order in the generated output.
    return Future.forEach(importIds, (id) {
      if (seen.contains(id)) return new Future.value(null);
      seen.add(id);
      return _collectPolymerElements(id, transform, seen, elements);
    }).then((_) => true);
  }

  /**
   * Loads an asset identified by [id], visits its imports and collects it's
   * polymer-element definitions.
   */
  Future _collectPolymerElements(
      AssetId id, Transform transform, Set<AssetId> seen, List elements) {
    return transform.readInputAsString(id)
        .then((content) => parseHtml(
              content, id.path, transform.logger, checkDocType: false))
        .then((document) {
          return _visitImports(document, id, transform, seen, elements)
            .then((_) => elements.addAll(document.queryAll('polymer-element')));
        });
  }
}
