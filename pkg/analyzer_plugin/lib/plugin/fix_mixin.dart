// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for handling fix requests.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class FixesMixin implements ServerPlugin {
  /**
   * Return a list containing the fix contributors that should be used to create
   * fixes when used in the context of the given analysis [driver].
   */
  List<FixContributor> getFixContributors(
      covariant AnalysisDriverGeneric driver);

  /**
   * Return the result of using the given analysis [driver] to produce a fully
   * resolved AST for the file with the given [path].
   */
  Future<ResolveResult> getResolveResultForFixes(
      covariant AnalysisDriverGeneric driver, String path);

  @override
  Future<EditGetFixesResult> handleEditGetFixes(
      EditGetFixesParams parameters) async {
    String path = parameters.file;
    ContextRoot contextRoot = contextRootContaining(path);
    if (contextRoot == null) {
      // Return an error from the request.
      throw new RequestFailure(
          RequestErrorFactory.pluginError('Failed to analyze $path', null));
    }
    AnalysisDriverGeneric driver = driverMap[contextRoot];
    ResolveResult analysisResult = await getResolveResultForFixes(driver, path);
    FixesRequestImpl request = new FixesRequestImpl(
        resourceProvider, parameters.offset, analysisResult);
    FixGenerator generator = new FixGenerator(getFixContributors(driver));
    GeneratorResult result = await generator.generateFixesResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }
}
