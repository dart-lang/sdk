// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/navigation_tree_renderer.dart';
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';

/// The JSON that is displayed for the navigation tree.
class NavigationTreePage extends PreviewPage {
  /// Initialize a newly created navigation tree page within the given [site].
  NavigationTreePage(PreviewSite site)
      : super(site, site.migrationInfo.includedRoot);

  @override
  // TODO(srawlins): Refactor JSON-returning pages like this to not inherit all
  //  of the HTML logic from  [PreviewPage].
  void generateBody(Map<String, String> params) {
    throw UnsupportedError('generateBody');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    var renderer = NavigationTreeRenderer(site.migrationInfo, site.pathMapper);
    buf.write(renderer.render());
  }
}
