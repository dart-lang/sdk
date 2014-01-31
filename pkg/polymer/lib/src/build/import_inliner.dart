// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer that inlines polymer-element definitions from html imports. */
library polymer.src.build.import_inliner;

import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:html5lib/dom.dart' show
    Document, DocumentFragment, Element, Node;
import 'package:html5lib/dom_parsing.dart' show TreeVisitor;
import 'package:source_maps/span.dart' show Span;

import 'code_extractor.dart'; // import just for documentation.
import 'common.dart';

/**
 * Recursively inlines the contents of HTML imports. Produces as output a single
 * HTML file that inlines the polymer-element definitions, and a text file that
 * contains, in order, the URIs to each library that sourced in a script tag.
 *
 * This transformer assumes that all script tags point to external files. To
 * support script tags with inlined code, use this transformer after running
 * [InlineCodeExtractor] on an earlier phase.
 */
class ImportInliner extends Transformer with PolymerTransformer {
  final TransformOptions options;

  ImportInliner(this.options);

  /** Only run on entry point .html files. */
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) {
    var logger = transform.logger;
    var seen = new Set<AssetId>();
    var documents = [];
    var id = transform.primaryInput.id;
    seen.add(id);
    return readPrimaryAsHtml(transform).then((document) {
      var future = _visitImports(document, id, transform, seen, documents);
      return future.then((importsFound) {
        // We produce a secondary asset with extra information for later phases.
        var secondaryId = id.addExtension('.scriptUrls');
        if (!importsFound) {
          transform.addOutput(transform.primaryInput);
          transform.addOutput(new Asset.fromString(secondaryId, '[]'));
          return;
        }

        // Split Dart script tags from all the other elements. Now that Dartium
        // only allows a single script tag per page, we can't inline script
        // tags. Instead, we collect the urls of each script tag so we import
        // them directly from the Dart bootstrap code.
        var scripts = [];

        var fragment = new DocumentFragment();
        for (var importedDoc in documents) {
          bool first = true;
          for (var e in importedDoc.queryAll('script')) {
            if (e.attributes['type'] == 'application/dart') {
              e.remove();

              // only one Dart script per document is supported in Dartium.
              if (first) {
                first = false;
                scripts.add(e);
              } else {
                // TODO(jmesserly): remove this when we are running linter.
                logger.warning('more than one Dart script per HTML document is '
                    'not supported. Script will be ignored.',
                    span: e.sourceSpan);
              }
            }
          }

          // TODO(jmesserly): should we merge the head too?
          fragment.nodes.addAll(importedDoc.body.nodes);
        }

        document.body.insertBefore(fragment, document.body.firstChild);

        for (var tag in document.queryAll('link')) {
          if (tag.attributes['rel'] == 'import') tag.remove();
        }

        transform.addOutput(new Asset.fromString(id, document.outerHtml));

        var scriptIds = [];
        for (var script in scripts) {
          var src = script.attributes['src'];
          if (src == null) {
            logger.warning('unexpected script without a src url. The '
              'ImportInliner transformer should run after running the '
              'InlineCodeExtractor', span: script.sourceSpan);
            continue;
          }
          scriptIds.add(resolve(id, src, logger, script.sourceSpan));
        }
        transform.addOutput(new Asset.fromString(secondaryId,
            JSON.encode(scriptIds, toEncodable: (id) => id.serialize())));
      });
    });
  }

  /**
   * Visits imports in [document] and add their polymer-element and script tags
   * to [elements], unless they have already been [seen]. Elements are added in
   * the order they appear, transitive imports are added first.
   */
  Future<bool> _visitImports(Document document, AssetId sourceId,
      Transform transform, Set<AssetId> seen, List<Document> documents) {
    var importIds = [];
    bool hasImports = false;
    for (var tag in document.queryAll('link')) {
      if (tag.attributes['rel'] != 'import') continue;
      var href = tag.attributes['href'];
      var id = resolve(sourceId, href, transform.logger, tag.sourceSpan);
      hasImports = true;
      if (id == null || seen.contains(id) ||
         (id.package == 'polymer' && id.path == 'lib/init.html')) continue;
      importIds.add(id);
    }

    if (importIds.isEmpty) return new Future.value(hasImports);

    // Note: we need to preserve the import order in the generated output.
    return Future.forEach(importIds, (id) {
      if (seen.contains(id)) return new Future.value(null);
      seen.add(id);
      return _collectImportedDocuments(id, transform, seen, documents);
    }).then((_) => true);
  }

  /**
   * Loads an asset identified by [id], visits its imports and collects it's
   * polymer-element definitions and script tags.
   */
  Future _collectImportedDocuments(AssetId id, Transform transform,
      Set<AssetId> seen, List documents) {
    return readAsHtml(id, transform).then((document) {
      return _visitImports(document, id, transform, seen, documents).then((_) {
        new _UrlNormalizer(transform, id).visit(document);
        documents.add(document);
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
        if (url != null && url != '' && !url.startsWith('{{')) {
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
    if (id == null) return href;
    var primaryId = transform.primaryInput.id;

    if (id.path.startsWith('lib/')) {
      return 'packages/${id.package}/${id.path.substring(4)}';
    }

    if (id.path.startsWith('asset/')) {
      return 'assets/${id.package}/${id.path.substring(6)}';
    }

    if (primaryId.package != id.package) {
      // Techincally we shouldn't get there
      transform.logger.error("don't know how to include $id from $primaryId",
          span: span);
      return href;
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
