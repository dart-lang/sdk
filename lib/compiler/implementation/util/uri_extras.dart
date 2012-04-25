// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('uri_extras');

#import('dart:uri');

String relativize(Uri base, Uri uri) {
  if (base.scheme == 'file' &&
      base.scheme == uri.scheme &&
      base.userInfo == uri.userInfo &&
      base.domain == uri.domain &&
      base.port == uri.port &&
      uri.query == "" && uri.fragment == "") {
    if (uri.path.startsWith(base.path)) {
      return uri.path.substring(base.path.length);
    }
    List<String> uriParts = uri.path.split('/');
    List<String> baseParts = base.path.split('/');
    int common = 0;
    int length = Math.min(uriParts.length, baseParts.length);
    while (common < length && uriParts[common] == baseParts[common]) {
      common++;
    }
    StringBuffer sb = new StringBuffer();
    for (int i = common + 1; i < baseParts.length; i++) {
      sb.add('../');
    }
    for (int i = common; i < uriParts.length - 1; i++) {
      sb.add('${uriParts[i]}/');
    }
    sb.add('${uriParts.last()}');
    return sb.toString();
  }
  return uri.toString();
}
