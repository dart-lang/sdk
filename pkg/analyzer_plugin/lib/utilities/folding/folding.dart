// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * The information about a requested set of folding regions when computing
 * folding regions in a `.dart` file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFoldingRequest implements FoldingRequest {
  /**
   * The analysis result for the file for which the folding regions are being
   * requested.
   */
  ResolveResult get result;
}

/**
 * An object that [FoldingContributor]s use to record folding regions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FoldingCollector {
  /**
   * Record a new folding region corresponding to the given [range] that has the
   * given [kind].
   */
  void addRange(SourceRange range, FoldingKind kind);

  /**
   * Record a new folding region with the given [offset] and [length] that has
   * the given [kind].
   */
  void addRegion(int offset, int length, FoldingKind kind);
}

/**
 * An object used to produce folding regions.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class FoldingContributor {
  /**
   * Contribute folding regions into the given [collector].
   */
  void computeFolding(FoldingRequest request, FoldingCollector collector);
}

/**
 * A generator that will generate an 'analysis.folding' notification.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FoldingGenerator {
  /**
   * The contributors to be used to generate the folding regions.
   */
  final List<FoldingContributor> contributors;

  /**
   * Initialize a newly created folding generator to use the given
   * [contributors].
   */
  FoldingGenerator(this.contributors);

  /**
   * Create an 'analysis.folding' notification. If any of the contributors
   * throws an exception, also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateFoldingNotification(FoldingRequest request) {
    List<Notification> notifications = <Notification>[];
    FoldingCollectorImpl collector = new FoldingCollectorImpl();
    for (FoldingContributor contributor in contributors) {
      try {
        contributor.computeFolding(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    notifications.add(new AnalysisFoldingParams(request.path, collector.regions)
        .toNotification());
    return new GeneratorResult(null, notifications);
  }
}

/**
 * The information about a requested set of folding regions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FoldingRequest {
  /**
   * Return the path of the file for which folding regions are being requested.
   */
  String get path;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;
}
