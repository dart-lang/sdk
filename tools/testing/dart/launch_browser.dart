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

import 'browser_controller.dart';
import 'configuration.dart';

void printHelp() {
  print("Usage pattern:");
  print("launch_browser.dart browser url");
  print("Supported browsers: ${Browser.SUPPORTED_BROWSERS}");
}

void main(List<String> arguments) {
  if (arguments.length != 2) {
    print("Wrong number of arguments, please pass in exactly two arguments");
    printHelp();
    return;
  }
  var name = arguments[0];

  if (!Browser.supportedBrowser(name)) {
    print("Specified browser not supported");
    printHelp();
    return;
  }

  var runtime = Runtime.find(name);
  var configuration = new Configuration(runtime: runtime);
  var executable = configuration.browserLocation;
  var browser = new Browser.byRuntime(runtime, executable);
  browser.start(arguments[1]);
}
