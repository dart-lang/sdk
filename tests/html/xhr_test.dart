// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XHRTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  print(window.location.href);
  asyncTest('XHR', 1, () {
    XMLHttpRequest xhr = new XMLHttpRequest();
    xhr.open("GET", "NonExistingFile", true);
    xhr.on.readyStateChange.add((event) {
        if (xhr.readyState == 4) {
          Expect.equals(0, xhr.status);
          Expect.stringEquals('', xhr.responseText);
          callbackDone();
        }
      });
    xhr.send();
  });

  asyncTest('XHR.get', 1, () {
      new XMLHttpRequest.get("NonExistingFile", (xhr) {
          Expect.equals(XMLHttpRequest.DONE, xhr.readyState);
          Expect.equals(0, xhr.status);
          Expect.stringEquals('', xhr.responseText);
          callbackDone();
      });
  });
}
