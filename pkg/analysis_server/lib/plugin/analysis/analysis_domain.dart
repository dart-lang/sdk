// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that interacts with the analysis domain of an
 * analysis server.
 *
 * Plugins can gain access to the request handler that implements the analysis
 * domain in order to extend the functionality of that domain. The class
 * [AnalysisDomain] defines the API of the analysis domain that plugins can use.
 *
 * If a plugin is interested in gaining access to the analysis domain, it should
 * register a function by including code like the following in the plugin's
 * registerExtensions method:
 *
 *     AnalysisDomain analysisDomain;
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           SET_ANALYSIS_DOMAIN_EXTENSION_POINT_ID,
 *           (AnalysisDomain domain) => analysisDomain = domain);
 *       ...
 *     }
 */
import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart'
    show AnalysisService;
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, ResultChangedEvent;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/task/model.dart' show ResultDescriptor;
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to get access to an
 * [AnalysisDomain]. The object used as an extension must be a
 * [SetAnalysisDomain].
 */
final String SET_ANALYSIS_DOMAIN_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.SET_ANALISYS_DOMAIN_EXTENSION_POINT);

/**
 * A function that is invoked after the analysis domain has been created and is
 * initialized.
 */
typedef void SetAnalysisDomain(AnalysisDomain domain);

/**
 * An object that gives plugins access to the analysis domain of the analysis
 * server.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AnalysisDomain {
  /**
   * Return the stream that is notified when a new value for the given
   * [result] is computed or invalidated.
   *
   * This method should be used by plugins that need to perform some additional
   * processing after analysis has completed. One example would be a plugin that
   * needed to send a notification to the client because some data was now
   * invalidated.
   */
  Stream<ResultChangedEvent> onResultChanged(ResultDescriptor result);

  /**
   * Schedule sending the given [service] notifications for the given [source]
   * in the given [context].
   */
  void scheduleNotification(
      AnalysisContext context, Source source, AnalysisService service);
}
