// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that inlines polymer-element definitions from html imports. */
library polymer.src.build.import_inliner;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:html5lib/dom.dart' show Document, Node, DocumentFragment;
import 'package:html5lib/dom_parsing.dart' show TreeVisitor;
import 'common.dart';

/** Recursively inlines polymer-element definitions from html imports. */
// TODO(sigmund): make sure we match semantics of html-imports for tags other
// than polymer-element (see dartbug.com/12613).
class ImportedElementInliner extends Transformer with PolymerTransformer {
  final TransformOptions options;

  ImportedElementInliner(this.options);

  /** Only run on entry point .html files. */
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) {
    var seen = new Set<AssetId>();
    var elements = [];
    var id = transform.primaryInput.id;
    seen.add(id);
    return readPrimaryAsHtml(transform).then((document) {
      var future = _visitImports(document, id, transform, seen, elements);
      return future.then((importsFound) {
        if (!importsFound) {
          transform.addOutput(transform.primaryInput);
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
  Future _collectPolymerElements(AssetId id, Transform transform,
      Set<AssetId> seen, List elements) {
    return readAsHtml(id, transform).then((document) {
      return _visitImports(document, id, transform, seen, elements).then((_) {
        var normalizer = new _UrlNormalizer(transform, id);
        for (var element in document.queryAll('polymer-element')) {
          normalizer.visit(document);
          elements.add(element);
        }
      });
    });
  }
}

/** Internally adjusts urls in the html that we are about to inline. */
class _UrlNormalizer extends TreeVisitor {
  final Transform transform;

  /** Asset where the original content (and original url) was found. */
  final AssetId sourceId;

  _UrlNormalizer(this.transform, this.sourceId);

  visitElement(Element node) {
    for (var key in node.attributes.keys) {
      if (_urlAttributes.contains(key)) {
        var url = node.attributes[key];
        if (url != null && url != '') {
          node.attributes[key] = _newUrl(url, node.sourceSpan);
        }
      }
    }
    super.visitElement(node);
  }

  _newUrl(String href, Span span) {
    var uri = Uri.parse(href);
    if (uri.isAbsolute) return href;
    if (!uri.scheme.isEmpty) return href;
    if (!uri.host.isEmpty) return href;
    if (uri.path.isEmpty) return href;  // Implies standalone ? or # in URI.
    if (path.isAbsolute(href)) return href;

    var id = resolve(sourceId, href, transform.logger, span);
    var primaryId = transform.primaryInput.id;

    if (id.path.startsWith('lib/')) {
      return 'packages/${id.package}/${id.path.substring(4)}';
    }

    if (id.path.startsWith('asset/')) {
      return 'assets/${id.package}/${id.path.substring(6)}';
    }

    if (primaryId.package != id.package) {
      // Techincally we shouldn't get there
      logger.error("don't know how to include $id from $primaryId", span);
      return null;
    }
    
    var builder = path.url;
    return builder.relative(builder.join('/', id.path),
        from: builder.join('/', builder.dirname(primaryId.path)));
  }
}

/**
 * HTML attributes that expect a URL value.
 * <http://dev.w3.org/html5/spec/section-index.html#attributes-1>
 *
 * Every one of these attributes is a URL in every context where it is used in
 * the DOM. The comments show every DOM element where an attribute can be used.
 */
const _urlAttributes = const [
  'action',     // in form
  'background', // in body
  'cite',       // in blockquote, del, ins, q
  'data',       // in object
  'formaction', // in button, input
  'href',       // in a, area, link, base, command
  'icon',       // in command
  'manifest',   // in html
  'poster',     // in video
  'src',        // in audio, embed, iframe, img, input, script, source, track,
                //    video
];
