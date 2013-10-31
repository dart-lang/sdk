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
// TODO(sigmund): currently we just inline polymer-element and script tags, we
// need to make sure we match semantics of html-imports for other tags too.
// (see dartbug.com/12613).
class ImportInliner extends Transformer with PolymerTransformer {
  final TransformOptions options;

  ImportInliner(this.options);

  /** Only run on entry point .html files. */
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) {
    var logger = transform.logger;
    var seen = new Set<AssetId>();
    var elements = [];
    var id = transform.primaryInput.id;
    seen.add(id);
    return readPrimaryAsHtml(transform).then((document) {
      var future = _visitImports(document, id, transform, seen, elements);
      return future.then((importsFound) {
        // We produce a secondary asset with extra information for later phases.
        var secondaryId = id.addExtension('.scriptUrls');
        if (!importsFound) {
          transform.addOutput(transform.primaryInput);
          transform.addOutput(new Asset.fromString(secondaryId, '[]'));
          return;
        }

        for (var tag in document.queryAll('link')) {
          if (tag.attributes['rel'] == 'import') {
            tag.remove();
          }
        }

        // Split Dart script tags from all the other elements. Now that Dartium
        // only allows a single script tag per page, we can't inline script
        // tags. Instead, we collect the urls of each script tag so we import
        // them directly from the Dart bootstrap code.
        var scripts = [];
        var rest = [];
        for (var e in elements) {
          if (e.tagName == 'script' &&
              e.attributes['type'] == 'application/dart') {
            scripts.add(e);
          } else if (e.tagName == 'polymer-element') {
            rest.add(e);
            var script = e.query('script');
            if (script != null &&
                script.attributes['type'] == 'application/dart') {
              script.remove();
              scripts.add(script);
            }
          } else {
            rest.add(e);
          }
        }

        var fragment = new DocumentFragment()..nodes.addAll(rest);
        document.body.insertBefore(fragment,
            //TODO(jmesserly): add Node.firstChild to html5lib
            document.body.nodes.length == 0 ? null : document.body.nodes[0]);
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
      Transform transform, Set<AssetId> seen, List<Node> elements) {
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
      return _collectElements(id, transform, seen, elements);
    }).then((_) => true);
  }

  /**
   * Loads an asset identified by [id], visits its imports and collects it's
   * polymer-element definitions and script tags.
   */
  Future _collectElements(AssetId id, Transform transform,
      Set<AssetId> seen, List elements) {
    return readAsHtml(id, transform).then((document) {
      return _visitImports(document, id, transform, seen, elements).then((_) {
        new _UrlNormalizer(transform, id).visit(document);
        new _InlineQuery(elements).visit(document);
      });
    });
  }
}

/** Implements document.queryAll('polymer-element,script'). */
// TODO(sigmund): delete this (dartbug.com/14135)
class _InlineQuery extends TreeVisitor {
  final List<Element> elements;
  _InlineQuery(this.elements);

  visitElement(Element node) {
    if (node.tagName == 'polymer-element' || node.tagName == 'script') {
      elements.add(node);
    } else {
      super.visitElement(node);
    }
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
