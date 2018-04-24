// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/server/driver.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';

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
   * Set the file resolver provider used to override the way file URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default file resolution scheme should be used instead.
   */
  void set fileResolverProvider(ResolverProvider provider);

  /**
   * Set the instrumentation [server] that is to be used by the analysis server.
   */
  void set instrumentationServer(InstrumentationServer server);

  /**
   * Set the package resolver provider used to override the way package URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default package resolution scheme should be used instead.
   */
  void set packageResolverProvider(ResolverProvider provider);

  /**
   * Use the given command-line [arguments] to start this server.
   *
   * At least temporarily returns AnalysisServer so that consumers of the
   * starter API can then use the server, this is done as a stopgap for the
   * angular plugin until the official plugin API is finished.
   */
  AnalysisServer start(List<String> arguments);
}
