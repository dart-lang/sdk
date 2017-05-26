// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library package_testing_support;

import 'test_configurations.dart' show testConfigurations;

import 'test_options.dart' show TestOptionsParser;

import 'test_suite.dart' show TestUtils;

void main(List<String> arguments) {
  TestUtils.setDartDirUri(Uri.base);
  var configurations = <Map>[];
  for (var argument in arguments) {
    configurations.addAll(new TestOptionsParser().parse(argument.split(" ")));
  }
  testConfigurations(configurations);
}
