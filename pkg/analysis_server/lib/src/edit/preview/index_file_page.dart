// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';

/// The page that is displayed when the root of the included path is requested.
class IndexFilePage extends PreviewPage {
  /// Initialize a newly created index file page within the given [site].
  IndexFilePage(PreviewSite site)
      : super(site, site.migrationInfo.includedRoot);

  @override
  bool get requiresAuth => true;

  @override
  void generateBody(Map<String, String> params) {
    throw UnsupportedError('generateBody');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    var renderer = InstrumentationRenderer(site.migrationInfo, site.pathMapper,
        site.migrationState.hasBeenApplied, site.migrationState.needsRerun);
    buf.write(renderer.render());
  }
}
