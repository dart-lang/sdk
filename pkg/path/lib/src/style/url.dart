// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.style.url;

import '../style.dart';

/// The style for URL paths.
class UrlStyle extends Style {
  UrlStyle();

  final name = 'url';
  final separator = '/';
  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern = new RegExp(
      r"(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$");
  final rootPattern = new RegExp(r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*");
  final relativeRootPattern = new RegExp(r"^/");

  String pathFromUri(Uri uri) => uri.toString();

  Uri relativePathToUri(String path) => Uri.parse(path);
  Uri absolutePathToUri(String path) => Uri.parse(path);
}
