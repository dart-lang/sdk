// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';

/// A mixin that can be used when creating a subclass of [ServerPlugin] and
/// mixing in [HighlightsMixin]. This implements the creation of the
/// highlighting request based on the assumption that the driver being created is
/// an [AnalysisDriver].
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin] that also uses [HighlightsMixin]
/// as a mix-in.
mixin DartHighlightsMixin implements HighlightsMixin {
  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var result = await getResolvedUnitResult(path);
    return DartHighlightsRequestImpl(resourceProvider, result);
  }
}

/// A mixin that can be used when creating a subclass of [ServerPlugin] to
/// provide most of the implementation for producing highlighting notifications.
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin].
mixin HighlightsMixin implements ServerPlugin {
  /// Return a list containing the highlighting contributors that should be used
  /// to create highlighting information for the file with the given [path].
  List<HighlightsContributor> getHighlightsContributors(String path);

  /// Return the highlighting request that should be passes to the contributors
  /// returned from [getHighlightsContributors].
  ///
  /// Throw a [RequestFailure] if the request could not be created.
  Future<HighlightsRequest> getHighlightsRequest(String path);

  @override
  Future<void> sendHighlightsNotification(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    try {
      var request = await getHighlightsRequest(path);
      var generator = HighlightsGenerator(getHighlightsContributors(path));
      var generatorResult = generator.generateHighlightsNotification(request);
      generatorResult.sendNotifications(channel);
    } on RequestFailure {
      // If we couldn't analyze the file, then don't send a notification.
    }
  }
}
