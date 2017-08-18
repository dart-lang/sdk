// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.starter;

import 'dart:async';

import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:plugin/plugin.dart';

/**
 * An object that can be used to start a command-line analysis. This class
 * exists so that clients can configure a command-line analyzer before starting
 * it.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CommandLineStarter {
  /**
   * Initialize a newly created starter to start up a command-line analysis.
   */
  factory CommandLineStarter() = Driver;

  /**
   * Set the package resolver provider used to override the way package URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default package resolution scheme should be used instead.
   */
  void set packageResolverProvider(ResolverProvider provider);

  /**
   * Set the [plugins] that are defined outside the analyzer_cli package.
   */
  void set userDefinedPlugins(List<Plugin> plugins);

  /**
   * Use the given command-line [arguments] to start this analyzer.
   */
  Future<Null> start(List<String> arguments);
}
