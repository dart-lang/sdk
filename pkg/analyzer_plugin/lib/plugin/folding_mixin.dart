// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] and
 * mixing in [FoldingMixin]. This implements the creation of the folding
 * request based on the assumption that the driver being created is an
 * [AnalysisDriver].
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin] that also uses
 * [FoldingMixin] as a mix-in.
 */
abstract class DartFoldingMixin implements FoldingMixin {
  @override
  Future<FoldingRequest> getFoldingRequest(String path) async {
    ResolveResult result = await getResolveResult(path);
    return new DartFoldingRequestImpl(resourceProvider, result);
  }
}

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for producing folding notifications.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class FoldingMixin implements ServerPlugin {
  /**
   * Return a list containing the folding contributors that should be used
   * to create folding regions for the file with the given [path].
   */
  List<FoldingContributor> getFoldingContributors(String path);

  /**
   * Return the folding request that should be passes to the contributors
   * returned from [getFoldingContributors].
   *
   * Throw a [RequestFailure] if the request could not be created.
   */
  Future<FoldingRequest> getFoldingRequest(String path);

  @override
  Future<Null> sendFoldingNotification(String path) async {
    try {
      FoldingRequest request = await getFoldingRequest(path);
      FoldingGenerator generator =
          new FoldingGenerator(getFoldingContributors(path));
      GeneratorResult generatorResult =
          await generator.generateFoldingNotification(request);
      generatorResult.sendNotifications(channel);
    } on RequestFailure {
      // If we couldn't analyze the file, then don't send a notification.
    }
  }
}
