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
   * [subscriptions].
   */
  void setSubscriptions(Map<AnalysisService, List<String>> subscriptions) {
    _subscriptions = subscriptions;
  }
}
