// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/preview/pages.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// A page displayed on the preview site.
abstract class PreviewPage extends Page {
  /// The site containing the page.
  final PreviewSite site;

  /// Initialize a newly created page within the given [site]. The [id] is the
  /// portion of the path to the page that follows the initial slash ('/').
  PreviewPage(this.site, String id) : super(id);

  /// Whether pages of this type require authorization.
  bool get requiresAuth;

  /// Generate the content of the body tag.
  void generateBody(Map<String, String> params);

  /// Generate the content of the head tag.
  void generateHead() {
    buf.writeln('<meta charset="utf-8">');
    buf.writeln('<meta name="viewport" content="width=device-width, '
        'initial-scale=1.0">');
    buf.writeln('<title>${site.title}</title>');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    buf.writeln('<!DOCTYPE html><html lang="en">');
    buf.writeln('<head>');
    buf.writeln('</head>');
    generateHead();
    buf.writeln('<body>');
    generateBody(params);
    buf.writeln('</body>');
    buf.writeln('</html>');
  }
}
