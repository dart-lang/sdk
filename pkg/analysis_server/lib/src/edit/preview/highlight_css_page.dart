// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/edit/nnbd_migration/resources/resources.g.dart'
    as resources;
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';

/// The page that contains the CSS used to style the semantic highlighting
/// within a Dart file.
class HighlightCssPage extends PreviewPage {
  /// Initialize a newly created CSS page within the given [site].
  HighlightCssPage(PreviewSite site)
      : super(site, PreviewSite.highlightCssPath.substring(1));

  @override
  void generateBody(Map<String, String> params) {
    throw UnimplementedError();
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    buf.write(resources.highlight_css);
  }
}
