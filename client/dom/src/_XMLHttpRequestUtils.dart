// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XMLHttpRequestUtils {

  // Helper for factory XMLHttpRequest.getTEMPNAME
  static XMLHttpRequest getTEMPNAME(String url,
                                    onSuccess(XMLHttpRequest request)) {
    final request = new XMLHttpRequest();
    request.open('GET', url, true);

    // TODO(terry): Validate after client login added if necessary to forward
    //              cookies to server.
    request.withCredentials = true;

    // Status 0 is for local XHR request.
    request.on.readyStateChange.add((e) {
      if (request.readyState == XMLHttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        onSuccess(request);
      }
    });

    request.send();

    return request;
  }
}
