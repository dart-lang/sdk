// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/utilities/outline/outline.dart';
import 'package:analyzer_plugin/utilities/generator.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] and
 * mixing in [OutlineMixin]. This implements the creation of the outline
 * request based on the assumption that the driver being created is an
 * [AnalysisDriver].
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin] that also uses
 * [OutlineMixin] as a mix-in.
 */
abstract class DartOutlineMixin implements OutlineMixin {
  @override
  Future<OutlineRequest> getOutlineRequest(String path) async {
    ResolveResult result = await getResolveResult(path);
    return new DartOutlineRequestImpl(resourceProvider, result);
  }
}

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for producing outline notifications.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class OutlineMixin implements ServerPlugin {
  /**
   * Return a list containing the outline contributors that should be used to
   * create outline information for the file with the given [path].
   */
  List<OutlineContributor> getOutlineContributors(String path);

  /**
   * Return the outline request that should be passes to the contributors
   * returned from [getOutlineContributors].
   *
   * Throw a [RequestFailure] if the request could not be created.
   */
  Future<OutlineRequest> getOutlineRequest(String path);

  @override
  Future<Null> sendOutlineNotification(String path) async {
    try {
      OutlineRequest request = await getOutlineRequest(path);
      OutlineGenerator generator =
          new OutlineGenerator(getOutlineContributors(path));
      GeneratorResult generatorResult =
          await generator.generateOutlineNotification(request);
      generatorResult.sendNotifications(channel);
    } on RequestFailure {
      // If we couldn't analyze the file, then don't send a notification.
    }
  }
}
