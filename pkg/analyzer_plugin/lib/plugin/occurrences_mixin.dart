// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/utilities/occurrences/occurrences.dart';
import 'package:analyzer_plugin/utilities/generator.dart';
import 'package:analyzer_plugin/utilities/occurrences/occurrences.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] and
 * mixing in [OccurrencesMixin]. This implements the creation of the occurrences
 * request based on the assumption that the driver being created is an
 * [AnalysisDriver].
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin] that also uses
 * [OccurrencesMixin] as a mix-in.
 */
abstract class DartOccurrencesMixin implements OccurrencesMixin {
  @override
  Future<OccurrencesRequest> getOccurrencesRequest(String path) async {
    ResolveResult result = await getResolveResult(path);
    return new DartOccurrencesRequestImpl(resourceProvider, result);
  }
}

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for producing occurrences notifications.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class OccurrencesMixin implements ServerPlugin {
  /**
   * Return a list containing the occurrences contributors that should be used
   * to create occurrences information for the file with the given [path].
   */
  List<OccurrencesContributor> getOccurrencesContributors(String path);

  /**
   * Return the occurrences request that should be passes to the contributors
   * returned from [getOccurrencesContributors].
   *
   * Throw a [RequestFailure] if the request could not be created.
   */
  Future<OccurrencesRequest> getOccurrencesRequest(String path);

  @override
  Future<Null> sendOccurrencesNotification(String path) async {
    try {
      OccurrencesRequest request = await getOccurrencesRequest(path);
      OccurrencesGenerator generator =
          new OccurrencesGenerator(getOccurrencesContributors(path));
      GeneratorResult generatorResult =
          await generator.generateOccurrencesNotification(request);
      generatorResult.sendNotifications(channel);
    } on RequestFailure {
      // If we couldn't analyze the file, then don't send a notification.
    }
  }
}
