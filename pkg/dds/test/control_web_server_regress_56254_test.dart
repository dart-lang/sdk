// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:math';

import 'package:test/test.dart';

void main() {
  test(
    "Ensure controlWebServer doesn't return before DDS connects",
    () async {
      final noServiceStartedInfo = await Service.getInfo();
      expect(noServiceStartedInfo.serverUri, isNull);

      // Before the fix for issue 56254, Service.controlWebServer would block
      // on the first call, waiting until DDS had finished starting to respond,
      // while subsequent calls would return as soon as the VM service HTTP
      // server had started, exposing the internal VM service URI. This could
      // result in clients connecting directly to the VM service while DDS was
      // initializing, only for them to be disconnected immediately once DDS
      // invoked _yieldControlToDDS.
      final serviceInfos = await Future.wait(
        [
          for (int i = 0; i < 100; ++i)
            // Add a random delay of at least 10ms so not all web server
            // control requests are fired at the same time.
            Future.delayed(
              Duration(
                milliseconds: Random().nextInt(90) + 10,
              ),
            ).then(
              (_) => Service.controlWebServer(
                enable: true,
                silenceOutput: true,
              ),
            ),
        ],
      );

      // If Service.controlWebServer returns while DDS is still starting we can
      // expect to see two service URIs: one for the VM service and one for DDS.
      // The correct behavior is to only return the DDS URI.
      final serviceInfosUris = <Uri?>{
        for (final info in serviceInfos) info.serverUri,
      };
      expect(serviceInfosUris.length, 1);
    },
    // It's possible this test could flake, but it shouldn't consistently fail.
    retry: 3,
  );
}
