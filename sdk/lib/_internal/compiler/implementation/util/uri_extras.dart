// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri_extras;

import 'dart:math';

String relativize(Uri base, Uri uri, bool isWindows) {
  if (!base.path.startsWith('/')) {
    // Also throw an exception if [base] or base.path is null.
    throw new ArgumentError('Expected absolute path: ${base.path}');
  }
  if (!uri.path.startsWith('/')) {
    // Also throw an exception if [uri] or uri.path is null.
    throw new ArgumentError('Expected absolute path: ${uri.path}');
  }
  bool equalsNCS(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }

  String normalize(String path) {
    if (isWindows) {
      return path.toLowerCase();
    } else {
      return path;
    }
  }

  if (equalsNCS(base.scheme, 'file') &&
      equalsNCS(base.scheme, uri.scheme) &&
      base.userInfo == uri.userInfo &&
      equalsNCS(base.host, uri.host) &&
      base.port == uri.port &&
      uri.query == "" && uri.fragment == "") {
    if (normalize(uri.path).startsWith(normalize(base.path))) {
      return uri.path.substring(base.path.lastIndexOf('/') + 1);
    }

    List<String> uriParts = uri.path.split('/');
    List<String> baseParts = base.path.split('/');
    int common = 0;
    int length = min(uriParts.length, baseParts.length);
    while (common < length &&
           normalize(uriParts[common]) == normalize(baseParts[common])) {
      common++;
    }
    if (common == 1 || (isWindows && common == 2)) {
      // The first part will always be an empty string because the
      // paths are absolute. On Windows, we must also consider drive
      // letters or hostnames.
      if (baseParts.length > common + 1) {
        // Avoid using '..' to go to the root, unless we are already there.
        return uri.path;
      }
    }
    StringBuffer sb = new StringBuffer();
    for (int i = common + 1; i < baseParts.length; i++) {
      sb.write('../');
    }
    for (int i = common; i < uriParts.length - 1; i++) {
      sb.write('${uriParts[i]}/');
    }
    sb.write('${uriParts.last}');
    return sb.toString();
  }
  return uri.toString();
}
