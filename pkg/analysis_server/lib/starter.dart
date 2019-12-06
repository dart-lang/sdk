// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
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

  /***
   * An optional manager to handle file systems which may not always be
   * available.
   */
  void set detachableFileSystemManager(DetachableFileSystemManager manager);

  /**
   * Set the file resolver provider used to override the way file URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default file resolution scheme should be used instead.
   */
  void set fileResolverProvider(ResolverProvider provider);

  /**
   * Set the instrumentation [service] that is to be used by the analysis server.
   */
  void set instrumentationService(InstrumentationService service);

  /**
   * Set the package resolver provider used to override the way package URI's
   * are resolved in some contexts. The provider should return `null` if the
   * default package resolution scheme should be used instead.
   */
  void set packageResolverProvider(ResolverProvider provider);

  /**
   * Use the given command-line [arguments] to start this server.
   */
  void start(List<String> arguments);
}
