// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/**
 * A partial implementation of an [AssistContributor] that provides a utility
 * method to make it easier to add assists.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [AssistContributor].
 */
abstract class AssistContributorMixin implements AssistContributor {
  /**
   * The collector to which assists should be added.
   */
  AssistCollector get collector;

  /**
   * Add an assist. Use the [kind] of the assist to get the message and priority,
   * and use the change [builder] to get the edits that comprise the assist. If
   * the message has parameters, then use the list of [args] to populate the
   * message.
   */
  void addAssist(AssistKind kind, ChangeBuilder builder, {List<Object> args}) {
    SourceChange change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.message = formatList(kind.message, args);
    collector.addAssist(
        new PrioritizedSourceChange(kind.priority, builder.sourceChange));
  }
}
