// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/generator.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] and
 * mixing in [HighlightsMixin]. This implements the creation of the
 * highlighting request based on the assumption that the driver being created is
 * an [AnalysisDriver].
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin] that also uses
 * [HighlightsMixin] as a mix-in.
 */
abstract class DartHighlightsMixin implements HighlightsMixin {
  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) async {
    ResolveResult result = await getResolveResult(path);
    return new DartHighlightsRequestImpl(resourceProvider, result);
  }
}

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for producing highlighting notifications.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class HighlightsMixin implements ServerPlugin {
  /**
   * Return a list containing the highlighting contributors that should be used
   * to create highlighting information for the file with the given [path].
   */
  List<HighlightsContributor> getHighlightsContributors(String path);

  /**
   * Return the highlighting request that should be passes to the contributors
   * returned from [getHighlightsContributors].
   *
   * Throw a [RequestFailure] if the request could not be created.
   */
  Future<HighlightsRequest> getHighlightsRequest(String path);

  @override
  Future<Null> sendHighlightsNotification(String path) async {
    try {
      HighlightsRequest request = await getHighlightsRequest(path);
      HighlightsGenerator generator =
          new HighlightsGenerator(getHighlightsContributors(path));
      GeneratorResult generatorResult =
          await generator.generateHighlightsNotification(request);
      generatorResult.sendNotifications(channel);
    } on RequestFailure {
      // If we couldn't analyze the file, then don't send a notification.
    }
  }
}
