// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

/**
 * The result produced by a generator.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class GeneratorResult {
  /**
   * The result to be sent to the server, or `null` if there is no response, as
   * when the generator is generating a notification.
   */
  final ResponseResult result;

  /**
   * The notifications that should be sent to the server. The list will be empty
   * if there are no notifications.
   */
  final List<Notification> notifications;

  /**
   * Initialize a newly created generator result with the given [result] and
   * [notifications].
   */
  GeneratorResult(this.result, this.notifications);

  /**
   * Use the given communications [channel] to send the notifications to the
   * server.
   */
  void sendNotifications(PluginCommunicationChannel channel) {
    for (final notification in notifications) {
      channel.sendNotification(notification);
    }
  }
}
