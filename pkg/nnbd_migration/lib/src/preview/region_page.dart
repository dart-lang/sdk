// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/region_renderer.dart';
import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// The HTML that is displayed for a region of code.
class RegionPage extends PreviewPage {
  /// The compilation unit information containing the region.
  final UnitInfo unitInfo;

  /// Initialize a newly created region page within the given [site]. The
  /// [unitInfo] provides the information needed to render the page.
  RegionPage(PreviewSite site, this.unitInfo)
      : super(site, unitInfo.path.substring(1));

  @override
  bool get requiresAuth => true;

  @override
  void generateBody(Map<String, String> params) {
    throw UnsupportedError('generateBody');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    var region = unitInfo.regionAt(int.parse(params['offset']));
    var renderer = RegionRenderer(region, unitInfo, site.migrationInfo,
        site.pathMapper, site.serviceAuthToken);
    buf.write(jsonEncode(renderer.render().toJson()));
  }
}
