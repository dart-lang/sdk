// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/front_end/resources/resources.g.dart'
    as resources;
import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// The page that contains the CSS used to style the semantic highlighting
/// within a Dart file.
class MaterialIconsPage extends PreviewPage {
  /// Initialize a newly created CSS page within the given [site].
  MaterialIconsPage(PreviewSite site)
      : super(site, PreviewSite.materialIconsPath.substring(1));

  @override
  bool get requiresAuth => false;

  @override
  void generateBody(Map<String, String> params) {
    throw UnimplementedError();
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    buf.write(resources.MaterialIconsRegular_ttf);
  }
}
