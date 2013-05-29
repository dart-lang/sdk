// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Simple command line interface to launching browsers.
 * Uses the browser_controller framework.
 * The usage is:
 *   DARTBIN launch_browser.dart BROWSER_NAME URL
 * DARTBIN should be the checked in stable binary.
 */

import "dart:io";
import "browser_controller.dart";

void printHelp() {
  print("Usage pattern:");
  print("launch_browser.dart browser url");
  print("Supported browsers: ${Browser.SUPPORTED_BROWSERS}");
}

void main() {
  var args = new Options().arguments;
  if (args.length != 2) {
    print("Wrong number of arguments, please pass in exactly two arguments");
    printHelp();
    return;
  }

  if (!Browser.supportedBrowser(args[0])) {
    print("Specified browser not supported");
    printHelp();
    return;
  }

  var browser = new Browser.byName(args[0]);
  browser.start(args[1]);

}
