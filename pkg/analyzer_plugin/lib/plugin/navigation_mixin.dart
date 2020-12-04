// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';

/// A mixin that can be used when creating a subclass of [ServerPlugin] and
/// mixing in [NavigationMixin]. This implements the creation of the navigation
/// request based on the assumption that the driver being created is an
/// [AnalysisDriver].
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin] that also uses [NavigationMixin]
/// as a mix-in.
mixin DartNavigationMixin implements NavigationMixin {
  @override
  Future<NavigationRequest> getNavigationRequest(
      AnalysisGetNavigationParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var result = await getResolvedUnitResult(path);
    var offset = parameters.offset;
    var length = parameters.length;
    if (offset < 0 && length < 0) {
      offset = 0;
      length = result.content.length;
    }
    return DartNavigationRequestImpl(resourceProvider, offset, length, result);
  }
}

/// A mixin that can be used when creating a subclass of [ServerPlugin] to
/// provide most of the implementation for handling navigation requests.
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin].
mixin NavigationMixin implements ServerPlugin {
  /// Return a list containing the navigation contributors that should be used to
  /// create navigation information for the file with the given [path]
  List<NavigationContributor> getNavigationContributors(String path);

  /// Return the navigation request that should be passes to the contributors
  /// returned from [getNavigationContributors].
  ///
  /// Throw a [RequestFailure] if the request could not be created.
  Future<NavigationRequest> getNavigationRequest(
      AnalysisGetNavigationParams parameters);

  @override
  Future<AnalysisGetNavigationResult> handleAnalysisGetNavigation(
      AnalysisGetNavigationParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var request = await getNavigationRequest(parameters);
    var generator = NavigationGenerator(getNavigationContributors(path));
    var result = generator.generateNavigationResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }

  /// Send a navigation notification for the file with the given [path] to the
  /// server.
  @override
  Future<void> sendNavigationNotification(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    try {
      var request =
          await getNavigationRequest(AnalysisGetNavigationParams(path, -1, -1));
      var generator = NavigationGenerator(getNavigationContributors(path));
      var generatorResult = generator.generateNavigationNotification(request);
      generatorResult.sendNotifications(channel);
    } on RequestFailure {
      // If we couldn't analyze the file, then don't send a notification.
    }
  }
}
