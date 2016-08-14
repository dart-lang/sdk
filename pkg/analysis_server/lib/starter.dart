// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.starter;

import 'package:analysis_server/src/server/driver.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:plugin/plugin.dart';

/**
 * An object that can be used to start an analysis server. This class exists so
 * that clients can configure an analysis server before starting it.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ServerStarter {
  /**
   * Initialize a newly created starter to start up an analysis server.
   */
  factory ServerStarter() = Driver;

  /**
   * Set the instrumentation [server] that is to be used by the analysis server.
   */
  void set instrumentationServer(InstrumentationServer server);

  /**
   * Set the file resolver provider used to override the way file URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default file resolution scheme should be used instead.
   */
  void set fileResolverProvider(ResolverProvider provider);

  /**
   * Set the package resolver provider used to override the way package URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default package resolution scheme should be used instead.
   */
  void set packageResolverProvider(ResolverProvider provider);

  /**
   * Set the [plugins] that are defined outside the analysis_server package.
   */
  void set userDefinedPlugins(List<Plugin> plugins);

  /**
   * Use the given command-line [arguments] to start this server.
   */
  void start(List<String> arguments);
}
