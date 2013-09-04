// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common methods used by transfomers. */
library polymer.src.transform.common;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show Document;
import 'package:html5lib/parser.dart' show HtmlParser;
import 'package:path/path.dart' as path;
import 'package:source_maps/span.dart' show Span;

/**
 * Parses an HTML file [contents] and returns a DOM-like tree. Adds emitted
 * error/warning to [logger].
 */
Document parseHtml(String contents, String sourcePath, TransformLogger logger,
    {bool checkDocType: true}) {
  // TODO(jmesserly): make HTTP encoding configurable
  var parser = new HtmlParser(contents, encoding: 'utf8', generateSpans: true,
      sourceUrl: sourcePath);
  var document = parser.parse();

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in parser.errors) {
    if (checkDocType || e.errorCode != 'expected-doctype-but-got-start-tag') {
      logger.warning(e.message, e.span);
    }
  }
  return document;
}

/** Create an [AssetId] for a [url] seen in the [source] asset. */
// TODO(sigmund): delete once this is part of barback (dartbug.com/12610)
AssetId resolve(AssetId source, String url, TransformLogger logger, Span span) {
  if (url == null || url == '') return null;
  var uri = Uri.parse(url);
  var urlBuilder = path.url;
  if (uri.host != '' || uri.scheme != '' || urlBuilder.isAbsolute(url)) {
    logger.error('absolute paths not allowed: "$url"', span);
    return null;
  }

  var package;
  var targetPath;
  var segments = urlBuilder.split(url);
  if (segments[0] == 'packages') {
    if (segments.length < 3) {
      logger.error("incomplete packages/ path. It should have at least 3 "
          "segments packages/name/path-from-name's-lib-dir", span);
      return null;
    }
    package = segments[1];
    targetPath = urlBuilder.join('lib',
        urlBuilder.joinAll(segments.sublist(2)));
  } else if (segments[0] == 'assets') {
    if (segments.length < 3) {
      logger.error("incomplete assets/ path. It should have at least 3 "
          "segments assets/name/path-from-name's-asset-dir", span);
    }
    package = segments[1];
    targetPath = urlBuilder.join('asset',
        urlBuilder.joinAll(segments.sublist(2)));
  } else {
    package = source.package;
    targetPath = urlBuilder.normalize(
        urlBuilder.join(urlBuilder.dirname(source.path), url));
  }
  return new AssetId(package, targetPath);
}

/** Whether an asset with [id] is considered a primary entry point HTML file. */
Future<bool> isPrimaryHtml(AssetId id) =>
    new Future.value(id.extension == '.html' &&
        // Note: [id.path] is a relative path from the root of a package.
        (id.path.startsWith('web/') || id.path.startsWith('test/')));
