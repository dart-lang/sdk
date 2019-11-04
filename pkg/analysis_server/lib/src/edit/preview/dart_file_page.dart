// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';

/// The page that is displayed when a preview of a valid Dart file is requested.
class DartFilePage extends PreviewPage {
  /// The information about the file being previewed.
  final UnitInfo unitInfo;

  /// Initialize a newly created Dart file page within the given [site]. The
  /// [unitInfo] provides the information needed to render the page.
  DartFilePage(PreviewSite site, this.unitInfo)
      // TODO(brianwilkerson) The path needs to be converted to use '/' if that
      //  isn't already done as part of building the unitInfo.
      : super(site, unitInfo.path.substring(1));

  @override
  void generateBody(Map<String, String> params) {
    buf.write('''
Not yet implemented.
''');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    // TODO(brianwilkerson) Implement this method, preferably by reusing the
    //  InstrumentationRenderer similar to the following commented out line of
    //  code:
    //    buf.write(InstrumentationRenderer(unitInfo, migrationInfo, pathMapper).render());
    //  We'll probably need to generalize the MigrationInfo and PathMapper
    //  classes to support URLs rather than file paths.
    //
    //  When this method is implemented, remove the super invocation below and
    //  remove the implementation of generateBody.
    //
    //  Alternatively, we could refactor InstrumentationRenderer so that we can
    //  use it to generate the body and override generateHead. That might make
    //  it easier to have a more consistent look across the site if we add more
    //  pages.
    super.generatePage(params);
  }
}
