// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// The page that is displayed when a request could not be authenticated.
class UnauthorizedPage extends PreviewPage {
  /// Initialize a newly created unauthorized page within the given [site].
  /// The [id] is the portion of the path to the page that follows the initial
  /// slash ('/').
  UnauthorizedPage(PreviewSite site, String id) : super(site, id);

  @override
  bool get requiresAuth => false;

  @override
  void generateBody(Map<String, String> params) {
    buf.write('''
<h1>401 Unauthorized</h1>
<p>
Request for '$path' is unauthorized.
</p>
''');
  }
}
