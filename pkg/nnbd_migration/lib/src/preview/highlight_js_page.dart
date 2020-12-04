// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/front_end/resources/resources.g.dart'
    as resources;
import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// The page that contains the JavaScript used to apply semantic highlighting
/// styles to a Dart file.
class HighlightJSPage extends PreviewPage {
  /// Initialize a newly created JS page within the given [site].
  HighlightJSPage(PreviewSite site)
      : super(site, PreviewSite.highlightJsPath.substring(1));

  @override
  bool get requiresAuth => false;

  @override
  void generateBody(Map<String, String> params) {
    throw UnimplementedError();
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    buf.write(resources.highlight_pack_js);
  }
}
