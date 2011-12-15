// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('Smoketest_lib');

#import("benchmarklib.dart");
#import("dart:html");

/** 
 * This is a sample no-op benchmark to ensure that frog has not dramatically
 * broken Firefox.
 */
class Smoketest extends BenchmarkBase {

  const Smoketest() : super("Smoketest");

  void run() {}

  static void main() {
    new Smoketest().report();
  }

  static void log(String str) {
    window.console.log(str);
  }
}
