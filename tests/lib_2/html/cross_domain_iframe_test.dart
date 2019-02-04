// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:expect/minitest.dart';

main() {
  var uri = Uri.parse(window.location.href);

  var crossOriginPort = int.parse(uri.queryParameters['crossOriginPort']);
  var crossOrigin = '${uri.scheme}://${uri.host}:$crossOriginPort';
  var crossOriginUrl =
      '$crossOrigin/root_dart/tests/lib_2/html/cross_domain_iframe_script.html';

  var iframe = new IFrameElement();
  iframe.src = crossOriginUrl;
  document.body.append(iframe);

  return window.onMessage
      .where((MessageEvent event) {
        return event.origin == crossOrigin;
      })
      .first
      .then((MessageEvent event) {
        expect(event.data, equals('foobar'));
        expect(event.source, isNotNull);
      });
}
