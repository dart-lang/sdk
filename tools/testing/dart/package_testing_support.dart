// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'configuration.dart';
import 'options.dart';
import 'repository.dart';
import 'test_configurations.dart';

void main(List<String> arguments) {
  Repository.uri = Uri.base;
  var configurations = <Configuration>[];
  for (var argument in arguments) {
    configurations.addAll(new OptionsParser().parse(argument.split(" ")));
  }
  testConfigurations(configurations);
}
