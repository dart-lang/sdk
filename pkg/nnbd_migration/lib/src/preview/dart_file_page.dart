// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/unit_renderer.dart';
import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

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
  bool get requiresAuth => true;

  @override
  void generateBody(Map<String, String> params) {
    throw UnsupportedError('generateBody');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    var renderer = UnitRenderer(
        unitInfo, site.migrationInfo, site.pathMapper, site.serviceAuthToken);
    buf.write(jsonEncode(renderer.render().toJson()));
  }
}
