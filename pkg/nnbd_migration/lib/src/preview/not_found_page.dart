// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// The page that is displayed when an invalid URL is requested.
class NotFoundPage extends PreviewPage {
  /// Initialize a newly created file-not-found page within the given [site].
  /// The [id] is the portion of the path to the page that follows the initial
  /// slash ('/').
  NotFoundPage(PreviewSite site, String id) : super(site, id);

  @override
  bool get requiresAuth => false;

  @override
  void generateBody(Map<String, String> params) {
    buf.write('''
<h1>404 Not found</h1>
<p>
'$path' not found.
</p>
''');
  }
}
