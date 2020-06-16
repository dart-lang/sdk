// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/result_collector.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:path/path.dart';

/// The object used to coordinate the results of notifications from the analysis
/// server and multiple plugins.
abstract class AbstractNotificationManager {
  /// The identifier used to identify results from the server.
  static const String serverId = 'server';

  /// The path context.
  final Context pathContext;

  /// A list of the paths of files and directories that are included for
  /// analysis.
  List<String> includedPaths = <String>[];

  /// A list of the paths of files and directories that are excluded from
  /// analysis.
  List<String> excludedPaths = <String>[];

  /// The current set of subscriptions to which the client has subscribed.
  Map<server.AnalysisService, Set<String>> currentSubscriptions =
      <server.AnalysisService, Set<String>>{};

  /// The collector being used to collect the analysis errors from the plugins.
  ResultCollector<List<AnalysisError>> errors;

  /// The collector being used to collect the folding regions from the plugins.
  ResultCollector<List<FoldingRegion>> folding;

  /// The collector being used to collect the highlight regions from the
  /// plugins.
  ResultCollector<List<HighlightRegion>> highlights;

  /// The collector being used to collect the navigation parameters from the
  /// plugins.
  ResultCollector<server.AnalysisNavigationParams> navigation;

  /// The collector being used to collect the occurrences from the plugins.
  ResultCollector<List<Occurrences>> occurrences;

  /// The collector being used to collect the outlines from the plugins.
  ResultCollector<List<Outline>> outlines;

  /// The object used to convert results.
  final ResultConverter converter = ResultConverter();

  /// The object used to merge results.
  final ResultMerger merger = ResultMerger();

  /// Initialize a newly created notification manager.
  AbstractNotificationManager(this.pathContext) {
    errors =
        ResultCollector<List<AnalysisError>>(serverId, predicate: _isIncluded);
    folding = ResultCollector<List<FoldingRegion>>(serverId);
    highlights = ResultCollector<List<HighlightRegion>>(serverId);
    navigation = ResultCollector<server.AnalysisNavigationParams>(serverId);
    occurrences = ResultCollector<List<Occurrences>>(serverId);
    outlines = ResultCollector<List<Outline>>(serverId);
  }

  /// Handle the given [notification] from the plugin with the given [pluginId].
  void handlePluginNotification(
      String pluginId, plugin.Notification notification) {
    var event = notification.event;
    switch (event) {
      case plugin.ANALYSIS_NOTIFICATION_ERRORS:
        var params = plugin.AnalysisErrorsParams.fromNotification(notification);
        recordAnalysisErrors(pluginId, params.file, params.errors);
        break;
      case plugin.ANALYSIS_NOTIFICATION_FOLDING:
        var params =
            plugin.AnalysisFoldingParams.fromNotification(notification);
        recordFoldingRegions(pluginId, params.file, params.regions);
        break;
      case plugin.ANALYSIS_NOTIFICATION_HIGHLIGHTS:
        var params =
            plugin.AnalysisHighlightsParams.fromNotification(notification);
        recordHighlightRegions(pluginId, params.file, params.regions);
        break;
      case plugin.ANALYSIS_NOTIFICATION_NAVIGATION:
        var params =
            plugin.AnalysisNavigationParams.fromNotification(notification);
        recordNavigationParams(pluginId, params.file,
            converter.convertAnalysisNavigationParams(params));
        break;
      case plugin.ANALYSIS_NOTIFICATION_OCCURRENCES:
        var params =
            plugin.AnalysisOccurrencesParams.fromNotification(notification);
        recordOccurrences(pluginId, params.file, params.occurrences);
        break;
      case plugin.ANALYSIS_NOTIFICATION_OUTLINE:
        var params =
            plugin.AnalysisOutlineParams.fromNotification(notification);
        recordOutlines(pluginId, params.file, params.outline);
        break;
      case plugin.PLUGIN_NOTIFICATION_ERROR:
        sendPluginErrorNotification(notification);
        break;
    }
  }

  /// Record error information from the plugin with the given [pluginId] for the
  /// file with the given [filePath].
  void recordAnalysisErrors(
      String pluginId, String filePath, List<AnalysisError> errorData) {
    if (errors.isCollectingFor(filePath)) {
      errors.putResults(filePath, pluginId, errorData);
      var unmergedErrors = errors.getResults(filePath);
      var mergedErrors = merger.mergeAnalysisErrors(unmergedErrors);
      sendAnalysisErrors(filePath, mergedErrors);
    }
  }

  /// Record folding information from the plugin with the given [pluginId] for
  /// the file with the given [filePath].
  void recordFoldingRegions(
      String pluginId, String filePath, List<FoldingRegion> foldingData) {
    if (folding.isCollectingFor(filePath)) {
      folding.putResults(filePath, pluginId, foldingData);
      var unmergedFolding = folding.getResults(filePath);
      var mergedFolding = merger.mergeFoldingRegions(unmergedFolding);
      sendFoldingRegions(filePath, mergedFolding);
    }
  }

  /// Record highlight information from the plugin with the given [pluginId] for
  /// the file with the given [filePath].
  void recordHighlightRegions(
      String pluginId, String filePath, List<HighlightRegion> highlightData) {
    if (highlights.isCollectingFor(filePath)) {
      highlights.putResults(filePath, pluginId, highlightData);
      var unmergedHighlights = highlights.getResults(filePath);
      var mergedHighlights = merger.mergeHighlightRegions(unmergedHighlights);
      sendHighlightRegions(filePath, mergedHighlights);
    }
  }

  /// Record navigation information from the plugin with the given [pluginId]
  /// for the file with the given [filePath].
  void recordNavigationParams(String pluginId, String filePath,
      server.AnalysisNavigationParams navigationData) {
    if (navigation.isCollectingFor(filePath)) {
      navigation.putResults(filePath, pluginId, navigationData);
      var unmergedNavigations = navigation.getResults(filePath);
      var mergedNavigations = merger.mergeNavigation(unmergedNavigations);
      sendNavigations(mergedNavigations);
    }
  }

  /// Record occurrences information from the plugin with the given [pluginId]
  /// for the file with the given [filePath].
  void recordOccurrences(
      String pluginId, String filePath, List<Occurrences> occurrencesData) {
    if (occurrences.isCollectingFor(filePath)) {
      occurrences.putResults(filePath, pluginId, occurrencesData);
      var unmergedOccurrences = occurrences.getResults(filePath);
      var mergedOccurrences = merger.mergeOccurrences(unmergedOccurrences);
      sendOccurrences(filePath, mergedOccurrences);
    }
  }

  /// Record outline information from the plugin with the given [pluginId] for
  /// the file with the given [filePath].
  void recordOutlines(
      String pluginId, String filePath, List<Outline> outlineData) {
    if (outlines.isCollectingFor(filePath)) {
      outlines.putResults(filePath, pluginId, outlineData);
      var unmergedOutlines = outlines.getResults(filePath);
      var mergedOutlines = merger.mergeOutline(unmergedOutlines);
      sendOutlines(filePath, mergedOutlines);
    }
  }

  /// Sends errors for a file to the client.
  void sendAnalysisErrors(String filePath, List<AnalysisError> mergedErrors);

  /// Sends folding regions for a file to the client.
  void sendFoldingRegions(String filePath, List<FoldingRegion> mergedFolding);

  /// Sends highlight regions for a file to the client.
  void sendHighlightRegions(
      String filePath, List<HighlightRegion> mergedHighlights);

  /// Sends navigation regions for a file to the client.
  void sendNavigations(server.AnalysisNavigationParams mergedNavigations);

  /// Sends occurrences for a file to the client.
  void sendOccurrences(String filePath, List<Occurrences> mergedOccurrences);

  /// Sends outlines for a file to the client.
  void sendOutlines(String filePath, List<Outline> mergedOutlines);

  /// Sends plugin errors to the client.
  void sendPluginErrorNotification(plugin.Notification notification);

  /// Set the lists of [included] and [excluded] files.
  void setAnalysisRoots(List<String> included, List<String> excluded) {
    includedPaths = included;
    excludedPaths = excluded;
  }

  /// Set the current subscriptions to the given set of [newSubscriptions].
  void setSubscriptions(
      Map<server.AnalysisService, Set<String>> newSubscriptions) {
    /// Return the collector associated with the given service, or `null` if the
    /// service is not handled by this manager.
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

    Set<server.AnalysisService> services = HashSet<server.AnalysisService>();
    services.addAll(currentSubscriptions.keys);
    services.addAll(newSubscriptions.keys);
    services.forEach((server.AnalysisService service) {
      var collector = collectorFor(service);
      if (collector != null) {
        var currentPaths = currentSubscriptions[service];
        var newPaths = newSubscriptions[service];
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

  /// Return `true` if errors should be collected for the file with the given
  /// [path] (because it is being analyzed).
  bool _isIncluded(String path) {
    bool isIncluded() {
      for (var includedPath in includedPaths) {
        if (pathContext.isWithin(includedPath, path) ||
            pathContext.equals(includedPath, path)) {
          return true;
        }
      }
      return false;
    }

    bool isExcluded() {
      for (var excludedPath in excludedPaths) {
        if (pathContext.isWithin(excludedPath, path)) {
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

class NotificationManager extends AbstractNotificationManager {
  /// The identifier used to identify results from the server.
  static const String serverId = AbstractNotificationManager.serverId;

  /// The channel used to send notifications to the client.
  final ServerCommunicationChannel channel;

  /// Initialize a newly created notification manager.
  NotificationManager(this.channel, Context pathContext) : super(pathContext);

  /// Sends errors for a file to the client.
  @override
  void sendAnalysisErrors(String filePath, List<AnalysisError> mergedErrors) {
    channel.sendNotification(
        server.AnalysisErrorsParams(filePath, mergedErrors).toNotification());
  }

  /// Sends folding regions for a file to the client.
  @override
  void sendFoldingRegions(String filePath, List<FoldingRegion> mergedFolding) {
    channel.sendNotification(
        server.AnalysisFoldingParams(filePath, mergedFolding).toNotification());
  }

  /// Sends highlight regions for a file to the client.
  @override
  void sendHighlightRegions(
      String filePath, List<HighlightRegion> mergedHighlights) {
    channel.sendNotification(
        server.AnalysisHighlightsParams(filePath, mergedHighlights)
            .toNotification());
  }

  /// Sends navigation regions for a file to the client.
  @override
  void sendNavigations(server.AnalysisNavigationParams mergedNavigations) {
    channel.sendNotification(mergedNavigations.toNotification());
  }

  /// Sends occurrences for a file to the client.
  @override
  void sendOccurrences(String filePath, List<Occurrences> mergedOccurrences) {
    channel.sendNotification(
        server.AnalysisOccurrencesParams(filePath, mergedOccurrences)
            .toNotification());
  }

  /// Sends outlines for a file to the client.
  @override
  void sendOutlines(String filePath, List<Outline> mergedOutlines) {
    channel.sendNotification(server.AnalysisOutlineParams(
            filePath, server.FileKind.LIBRARY, mergedOutlines[0])
        .toNotification());
  }

  /// Sends plugin errors to the client.
  @override
  void sendPluginErrorNotification(plugin.Notification notification) {
    var params = plugin.PluginErrorParams.fromNotification(notification);
    // TODO(brianwilkerson) There is no indication for the client as to the
    // fact that the error came from a plugin, let alone which plugin it
    // came from. We should consider whether we really want to send them to
    // the client.
    channel.sendNotification(server.ServerErrorParams(
            params.isFatal, params.message, params.stackTrace)
        .toNotification());
  }
}
