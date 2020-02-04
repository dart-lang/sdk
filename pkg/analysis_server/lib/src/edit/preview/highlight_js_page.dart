// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/edit/nnbd_migration/resources/resources.g.dart'
    as resources;
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';

/// The page that contains the JavaScript used to apply semantic highlighting
/// styles to a Dart file.
class HighlightJSPage extends PreviewPage {
  /// The decoded content of the page. Use [pageContent] to access this field so
  /// that it is initialized on first read.
  static String _pageContent;

  /// Initialize a newly created JS page within the given [site].
  HighlightJSPage(PreviewSite site)
      : super(site, PreviewSite.highlightJsPath.substring(1));

  @override
  void generateBody(Map<String, String> params) {
    throw UnimplementedError();
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    buf.write(pageContent());
  }

  /// Return the content of the page.
  String pageContent() {
    return _pageContent ??= resources.highlight_pack_js;
  }
}
