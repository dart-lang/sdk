// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/kythe/entries.dart';
import 'package:analyzer_plugin/utilities/generator.dart';
import 'package:analyzer_plugin/utilities/kythe/entries.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] and
 * mixing in [KytheMixin]. This implements the creation of the kythe.getEntries
 * request based on the assumption that the driver being created is an
 * [AnalysisDriver].
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin] that also uses
 * [KytheMixin] as a mix-in.
 */
abstract class DartEntryMixin implements EntryMixin {
  @override
  Future<EntryRequest> getEntryRequest(
      KytheGetKytheEntriesParams parameters) async {
    String path = parameters.file;
    AnalysisDriver driver = driverForPath(path);
    if (driver == null) {
      // Return an error from the request.
      throw new RequestFailure(
          RequestErrorFactory.pluginError('Failed to analyze $path', null));
    }
    ResolveResult result = await driver.getResult(path);
    return new DartEntryRequestImpl(resourceProvider, result);
  }
}

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for handling kythe.getEntries requests.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class EntryMixin implements ServerPlugin {
  /**
   * Return a list containing the entry contributors that should be used to
   * create entries for the file with the given [path]
   */
  List<EntryContributor> getEntryContributors(String path);

  /**
   * Return the entries request that should be passes to the contributors
   * returned from [getEntryContributors].
   */
  Future<EntryRequest> getEntryRequest(KytheGetKytheEntriesParams parameters);

  @override
  Future<KytheGetKytheEntriesResult> handleKytheGetKytheEntries(
      KytheGetKytheEntriesParams parameters) async {
    String path = parameters.file;
    EntryRequest request = await getEntryRequest(parameters);
    EntryGenerator generator = new EntryGenerator(getEntryContributors(path));
    GeneratorResult result =
        await generator.generateGetEntriesResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }
}
