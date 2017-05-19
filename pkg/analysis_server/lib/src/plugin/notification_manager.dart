// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/result_collector.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * The object used to coordinate the results of notifications from the analysis
 * server and multiple plugins.
 */
class NotificationManager {
  /**
   * The identifier used to identify results from the server.
   */
  static const String serverId = 'server';

  /**
   * The channel used to send notifications to the client.
   */
  final ServerCommunicationChannel channel;

  /**
   * The resource provider used to get the path context.
   */
  final ResourceProvider provider;

  /**
   * A list of the paths of files and directories that are included for analysis.
   */
  List<String> includedPaths = <String>[];

  /**
   * A list of the paths of files and directories that are excluded from
   * analysis.
   */
  List<String> excludedPaths = <String>[];

  /**
   * The current set of subscriptions to which the client has subscribed.
   */
  Map<server.AnalysisService, Set<String>> currentSubscriptions =
      <server.AnalysisService, Set<String>>{};

  /**
   * The collector being used to collect the analysis errors from the plugins.
   */
  ResultCollector<List<AnalysisError>> errors;

  /**
   * The collector being used to collect the folding regions from the plugins.
   */
  ResultCollector<List<FoldingRegion>> folding;

  /**
   * The collector being used to collect the highlight regions from the plugins.
   */
  ResultCollector<List<HighlightRegion>> highlights;

  /**
   * The collector being used to collect the navigation parameters from the
   * plugins.
   */
  ResultCollector<server.AnalysisNavigationParams> navigation;

  /**
   * The collector being used to collect the occurrences from the plugins.
   */
  ResultCollector<List<Occurrences>> occurrences;

  /**
   * The collector being used to collect the outlines from the plugins.
   */
  ResultCollector<List<Outline>> outlines;

  /**
   * The object used to convert results.
   */
  ResultConverter converter = new ResultConverter();

  /**
   * The object used to merge results.
   */
  ResultMerger merger = new ResultMerger();

  /**
   * Initialize a newly created notification manager.
   */
  NotificationManager(this.channel, this.provider) {
    errors = new ResultCollector<List<AnalysisError>>(serverId,
        predicate: _isIncluded);
    folding = new ResultCollector<List<FoldingRegion>>(serverId);
    highlights = new ResultCollector<List<HighlightRegion>>(serverId);
    navigation = new ResultCollector<server.AnalysisNavigationParams>(serverId);
    occurrences = new ResultCollector<List<Occurrences>>(serverId);
    outlines = new ResultCollector<List<Outline>>(serverId);
  }

  /**
   * Handle the given [notification] from the plugin with the given [pluginId].
   */
  void handlePluginNotification(
      String pluginId, plugin.Notification notification) {
    String event = notification.event;
    switch (event) {
      case plugin.ANALYSIS_NOTIFICATION_ERRORS:
        plugin.AnalysisErrorsParams params =
            new plugin.AnalysisErrorsParams.fromNotification(notification);
        recordAnalysisErrors(pluginId, params.file, params.errors);
        break;
      case plugin.ANALYSIS_NOTIFICATION_FOLDING:
        plugin.AnalysisFoldingParams params =
            new plugin.AnalysisFoldingParams.fromNotification(notification);
        recordFoldingRegions(pluginId, params.file, params.regions);
        break;
      case plugin.ANALYSIS_NOTIFICATION_HIGHLIGHTS:
        plugin.AnalysisHighlightsParams params =
            new plugin.AnalysisHighlightsParams.fromNotification(notification);
        recordHighlightRegions(pluginId, params.file, params.regions);
        break;
      case plugin.ANALYSIS_NOTIFICATION_NAVIGATION:
        plugin.AnalysisNavigationParams params =
            new plugin.AnalysisNavigationParams.fromNotification(notification);
        recordNavigationParams(pluginId, params.file,
            converter.convertAnalysisNavigationParams(params));
        break;
      case plugin.ANALYSIS_NOTIFICATION_OCCURRENCES:
        plugin.AnalysisOccurrencesParams params =
            new plugin.AnalysisOccurrencesParams.fromNotification(notification);
        recordOccurrences(pluginId, params.file, params.occurrences);
        break;
      case plugin.ANALYSIS_NOTIFICATION_OUTLINE:
        plugin.AnalysisOutlineParams params =
            new plugin.AnalysisOutlineParams.fromNotification(notification);
        recordOutlines(pluginId, params.file, params.outline);
        break;
      case plugin.PLUGIN_NOTIFICATION_ERROR:
        plugin.PluginErrorParams params =
            new plugin.PluginErrorParams.fromNotification(notification);
        // TODO(brianwilkerson) There is no indication for the client as to the
        // fact that the error came from a plugin, let alone which plugin it
        // came from. We should consider whether we really want to send them to
        // the client.
        channel.sendNotification(new server.ServerErrorParams(
                params.isFatal, params.message, params.stackTrace)
            .toNotification());
        break;
    }
  }

  /**
   * Record error information from the plugin with the given [pluginId] for the
   * file with the given [filePath].
   */
  void recordAnalysisErrors(
      String pluginId, String filePath, List<AnalysisError> errorData) {
    if (errors.isCollectingFor(filePath)) {
      errors.putResults(filePath, pluginId, errorData);
      List<List<AnalysisError>> unmergedErrors = errors.getResults(filePath);
      List<AnalysisError> mergedErrors =
          merger.mergeAnalysisErrors(unmergedErrors);
      channel.sendNotification(
          new server.AnalysisErrorsParams(filePath, mergedErrors)
              .toNotification());
    }
  }

  /**
   * Record folding information from the plugin with the given [pluginId] for
   * the file with the given [filePath].
   */
  void recordFoldingRegions(
      String pluginId, String filePath, List<FoldingRegion> foldingData) {
    if (folding.isCollectingFor(filePath)) {
      folding.putResults(filePath, pluginId, foldingData);
      List<List<FoldingRegion>> unmergedFolding = folding.getResults(filePath);
      List<FoldingRegion> mergedFolding =
          merger.mergeFoldingRegions(unmergedFolding);
      channel.sendNotification(
          new server.AnalysisFoldingParams(filePath, mergedFolding)
              .toNotification());
    }
  }

  /**
   * Record highlight information from the plugin with the given [pluginId] for
   * the file with the given [filePath].
   */
  void recordHighlightRegions(
      String pluginId, String filePath, List<HighlightRegion> highlightData) {
    if (highlights.isCollectingFor(filePath)) {
      highlights.putResults(filePath, pluginId, highlightData);
      List<List<HighlightRegion>> unmergedHighlights =
          highlights.getResults(filePath);
      List<HighlightRegion> mergedHighlights =
          merger.mergeHighlightRegions(unmergedHighlights);
      channel.sendNotification(
          new server.AnalysisHighlightsParams(filePath, mergedHighlights)
              .toNotification());
    }
  }

  /**
   * Record navigation information from the plugin with the given [pluginId] for
   * the file with the given [filePath].
   */
  void recordNavigationParams(String pluginId, String filePath,
      server.AnalysisNavigationParams navigationData) {
    if (navigation.isCollectingFor(filePath)) {
      navigation.putResults(filePath, pluginId, navigationData);
      List<server.AnalysisNavigationParams> unmergedNavigations =
          navigation.getResults(filePath);
      server.AnalysisNavigationParams mergedNavigations =
          merger.mergeNavigation(unmergedNavigations);
      channel.sendNotification(mergedNavigations.toNotification());
    }
  }

  /**
   * Record occurrences information from the plugin with the given [pluginId]
   * for the file with the given [filePath].
   */
  void recordOccurrences(
      String pluginId, String filePath, List<Occurrences> occurrencesData) {
    if (occurrences.isCollectingFor(filePath)) {
      occurrences.putResults(filePath, pluginId, occurrencesData);
      List<List<Occurrences>> unmergedOccurrences =
          occurrences.getResults(filePath);
      List<Occurrences> mergedOccurrences =
          merger.mergeOccurrences(unmergedOccurrences);
      channel.sendNotification(
          new server.AnalysisOccurrencesParams(filePath, mergedOccurrences)
              .toNotification());
    }
  }

  /**
   * Record outline information from the plugin with the given [pluginId] for
   * the file with the given [filePath].
   */
  void recordOutlines(
      String pluginId, String filePath, List<Outline> outlineData) {
    if (outlines.isCollectingFor(filePath)) {
      outlines.putResults(filePath, pluginId, outlineData);
      List<List<Outline>> unmergedOutlines = outlines.getResults(filePath);
      List<Outline> mergedOutlines = merger.mergeOutline(unmergedOutlines);
      channel.sendNotification(new server.AnalysisOutlineParams(
              filePath, server.FileKind.LIBRARY, mergedOutlines[0])
          .toNotification());
    }
  }

  /**
   * Set the lists of [included] and [excluded] files.
   */
  void setAnalysisRoots(List<String> included, List<String> excluded) {
    includedPaths = included;
    excludedPaths = excluded;
  }

  /**
   * Set the current subscriptions to the given set of [newSubscriptions].
   */
  void setSubscriptions(
      Map<server.AnalysisService, Set<String>> newSubscriptions) {
    /**
     * Return the collector associated with the given service, or `null` if the
     * service is not handled by this manager.
     */
    ResultCollector collectorFor(server.AnalysisService service) {
      switch (service) {
        case server.AnalysisService.FOLDING:
          return folding;
        case server.AnalysisService.HIGHLIGHTS:
          return highlights;
        case server.AnalysisService.NAVIGATION:
          return navigation;
        case server.AnalysisService.OCCURRENCES:
          return occurrences;
        case server.AnalysisService.OUTLINE:
          return outlines;
      }
      return null;
    }

    Set<server.AnalysisService> services =
        new HashSet<server.AnalysisService>();
    services.addAll(currentSubscriptions.keys);
    services.addAll(newSubscriptions.keys);
    services.forEach((server.AnalysisService service) {
      ResultCollector collector = collectorFor(service);
      if (collector != null) {
        Set<String> currentPaths = currentSubscriptions[service];
        Set<String> newPaths = newSubscriptions[service];
        if (currentPaths == null) {
          if (newPaths == null) {
            // This should not happen.
            return;
          }
          // All of the [newPaths] need to be added.
          newPaths.forEach((String filePath) {
            collector.startCollectingFor(filePath);
          });
        } else if (newPaths == null) {
          // All of the [currentPaths] need to be removed.
          currentPaths.forEach((String filePath) {
            collector.stopCollectingFor(filePath);
          });
        } else {
          // Compute the difference of the two sets.
          newPaths.forEach((String filePath) {
            if (!currentPaths.contains(filePath)) {
              collector.startCollectingFor(filePath);
            }
          });
          currentPaths.forEach((String filePath) {
            if (!newPaths.contains(filePath)) {
              collector.stopCollectingFor(filePath);
            }
          });
        }
      }
    });
    currentSubscriptions = newSubscriptions;
  }

  /**
   * Return `true` if errors should be collected for the file with the given
   * [path] (because it is being analyzed).
   */
  bool _isIncluded(String path) {
    bool isIncluded() {
      for (String includedPath in includedPaths) {
        if (provider.pathContext.isWithin(includedPath, path) ||
            provider.pathContext.equals(includedPath, path)) {
          return true;
        }
      }
      return false;
    }

    bool isExcluded() {
      for (String excludedPath in excludedPaths) {
        if (provider.pathContext.isWithin(excludedPath, path)) {
          return true;
        }
      }
      return false;
    }

    // TODO(brianwilkerson) Return false if error notifications are globally
    // disabled.
    return isIncluded() && !isExcluded();
  }
}
