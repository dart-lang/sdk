// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/options.dart';
import 'package:test_runner/src/repository.dart';
import 'package:test_runner/src/test_configurations.dart';

void main(List<String> arguments) {
  Repository.uri = Uri.base;
  var configurations = <TestConfiguration>[];
  for (var argument in arguments) {
    configurations.addAll(OptionsParser().parse(argument.split(" ")));
  }
  testConfigurations(configurations);
}
