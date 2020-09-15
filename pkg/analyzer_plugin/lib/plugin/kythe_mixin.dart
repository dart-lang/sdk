// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/kythe/entries.dart';
import 'package:analyzer_plugin/utilities/kythe/entries.dart';

/// A mixin that can be used when creating a subclass of [ServerPlugin] and
/// mixing in [KytheMixin]. This implements the creation of the kythe.getEntries
/// request based on the assumption that the driver being created is an
/// [AnalysisDriver].
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin] that also uses [KytheMixin] as a
/// mix-in.
mixin DartEntryMixin implements EntryMixin {
  @override
  Future<EntryRequest> getEntryRequest(
      KytheGetKytheEntriesParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var result = await getResolvedUnitResult(path);
    return DartEntryRequestImpl(resourceProvider, result);
  }
}

/// A mixin that can be used when creating a subclass of [ServerPlugin] to
/// provide most of the implementation for handling kythe.getEntries requests.
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin].
mixin EntryMixin implements ServerPlugin {
  /// Return a list containing the entry contributors that should be used to
  /// create entries for the file with the given [path]
  List<EntryContributor> getEntryContributors(String path);

  /// Return the entries request that should be passes to the contributors
  /// returned from [getEntryContributors].
  ///
  /// Throw a [RequestFailure] if the request could not be created.
  Future<EntryRequest> getEntryRequest(KytheGetKytheEntriesParams parameters);

  @override
  Future<KytheGetKytheEntriesResult> handleKytheGetKytheEntries(
      KytheGetKytheEntriesParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var request = await getEntryRequest(parameters);
    var generator = EntryGenerator(getEntryContributors(path));
    var result = generator.generateGetEntriesResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }
}
