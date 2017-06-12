// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_generated.dart';

/**
 * An object that manages the subscriptions for analysis results.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SubscriptionManager {
  /**
   * The current set of subscriptions.
   */
  Map<AnalysisService, List<String>> _subscriptions;

  /**
   * Initialize a newly created subscription manager to have no subscriptions.
   */
  SubscriptionManager();

  /**
   * Return a list of the services for which the file with the given [filePath]
   * has been subscribed.
   */
  List<AnalysisService> servicesForFile(String filePath) {
    List<AnalysisService> services = <AnalysisService>[];
    if (_subscriptions != null) {
      _subscriptions.forEach((AnalysisService service, List<String> files) {
        if (files.contains(filePath)) {
          services.add(service);
        }
      });
    }
    return services;
  }

  /**
   * Set the current set of subscriptions to those described by the given map of
   * [subscriptions]. Return a map representing the subset of the subscriptions
   * that are new. These are the subscriptions for which a notification should
   * be sent. The returned map is keyed by the path of each file for which
   * notifications should be send and has values representing the list of
   * services that were added for that file.
   */
  Map<String, List<AnalysisService>> setSubscriptions(
      Map<AnalysisService, List<String>> subscriptions) {
    Map<String, List<AnalysisService>> newSubscriptions =
        <String, List<AnalysisService>>{};
    if (_subscriptions == null) {
      // This is the first time subscriptions have been set, so all of the
      // subscriptions are new.
      subscriptions.forEach((AnalysisService service, List<String> paths) {
        for (String path in paths) {
          newSubscriptions
              .putIfAbsent(path, () => <AnalysisService>[])
              .add(service);
        }
      });
    } else {
      // The subscriptions have been changed, to we need to compute the
      // difference.
      subscriptions.forEach((AnalysisService service, List<String> paths) {
        List<String> oldPaths = _subscriptions[service];
        for (String path in paths) {
          if (!oldPaths.contains(path)) {
            newSubscriptions
                .putIfAbsent(path, () => <AnalysisService>[])
                .add(service);
          }
        }
      });
    }
    _subscriptions = subscriptions;
    return newSubscriptions;
  }
}
