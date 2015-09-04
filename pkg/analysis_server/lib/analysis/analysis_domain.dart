// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis aspect of analysis server.
 */
library analysis_server.analysis;

import 'dart:async';

import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/protocol.dart' show AnalysisService;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, ComputedResult;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/task/model.dart' show ResultDescriptor;
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to get access to
 * `AnalysisSite`. The object used as an extension must be
 * a [SetAnalysisDomain].
 */
final String SET_ANALYSIS_DOMAIN_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.SET_ANALISYS_DOMAIN_EXTENSION_POINT);

/**
 * A function that is invoked on the `analysis` domain creation.
 */
typedef void SetAnalysisDomain(AnalysisDomain site);

/**
 * An object that gives [SetAnalysisDomain]s access to the `analysis` domain
 * of the analysis server.
 *
 * Clients are not expected to subtype this class.
 */
abstract class AnalysisDomain {
  /**
   * Return the stream that is notified when a new value for the given
   * [descriptor] is computed.
   */
  Stream<ComputedResult> onResultComputed(ResultDescriptor descriptor);

  /**
   * Schedule sending the given [service] notifications for the given [source]
   * in the given [context].
   */
  void scheduleNotification(
      AnalysisContext context, Source source, AnalysisService service);
}
