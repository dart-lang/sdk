// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A function used to determine whether results should be collected for the
 * file with the given [path].
 */
typedef bool ShouldCollectPredicate(String path);

/**
 * An object used to collect partial results (of type [E]) where the partial
 * results are contributed by plugins.
 */
class ResultCollector<E> {
  /**
   * The id used as a plugin id for contributions from the server.
   */
  final String serverId;

  /**
   * A function used to determine whether results should be collected for the
   * file whose path is passed in as an argument.
   */
  final ShouldCollectPredicate _shouldCollect;

  /**
   * A multi-keyed map, where the first key is the (normalized and absolute)
   * path to the file associated with the results, and the second is the id of
   * the plugin that provided the partial results. The value is the partial
   * results contributed by the plugin for the file.
   */
  Map<String, Map<String, E>> resultMap = <String, Map<String, E>>{};

  /**
   * Initialize a newly created result manager.
   */
  ResultCollector(this.serverId, {ShouldCollectPredicate predicate})
      : _shouldCollect = predicate;

  /**
   * Clear any results that have been contributed for the file with the given
   * [filePath], but continue to collect results for the file. This is used when
   * the results for the specified file are known to be invalid, typically
   * because the content of the file has been modified.
   */
  void clearResultsForFile(String filePath) {
    resultMap[filePath]?.clear();
  }

  /**
   * Clear any results that have been contributed by the plugin with the given
   * [pluginId].
   */
  void clearResultsFromPlugin(String pluginId) {
    for (Map<String, E> partialResults in resultMap.values) {
      partialResults.remove(pluginId);
    }
  }

  /**
   * Return an iterator producing the partial results that have been contributed
   * for the given [filePath].
   */
  List<E> getResults(String filePath) {
    Map<String, E> partialResultMap = resultMap[filePath];
    if (partialResultMap == null) {
      return <E>[];
    }
    List<E> values = partialResultMap.values.toList();
    //
    // Ensure that the server's contributions are always first in the list.
    //
    E serverContributions = partialResultMap[serverId];
    if (serverContributions != null && values.remove(serverContributions)) {
      values.insert(0, serverContributions);
    }
    return values;
  }

  /**
   * Return `true` if this collector is collecting results associated with the
   * given [filePath].
   */
  bool isCollectingFor(String filePath) {
    if (_shouldCollect != null) {
      return _shouldCollect(filePath);
    }
    return resultMap.containsKey(filePath);
  }

  /**
   * Record the [partialResults] as having been contributed for the given
   * [filePath] by the plugin with the given [pluginId].
   */
  void putResults(String filePath, String pluginId, E partialResults) {
    Map<String, E> fileResults = resultMap[filePath];
    if (fileResults == null) {
      if (_shouldCollect != null && _shouldCollect(filePath)) {
        resultMap[filePath] = <String, E>{pluginId: partialResults};
      }
    } else {
      fileResults[pluginId] = partialResults;
    }
  }

  /**
   * Start collecting results contributed for the file with the given
   * [filePath]. Unless the collector is told to collect results for a file, any
   * results that are contributed for that file are discarded.
   */
  void startCollectingFor(String filePath) {
    resultMap.putIfAbsent(filePath, () => <String, E>{});
  }

  /**
   * Stop collecting results contributed for the file with the given [filePath].
   * Until the collector is told to start collecting results for the file, any
   * results that are contributed for the file are discarded.
   */
  void stopCollectingFor(String filePath) {
    resultMap.remove(filePath);
  }
}
