// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceChange;
import 'package:analyzer_plugin/utilities/assist/assist.dart';

/**
 * A description of a single proposed assist.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Assist {
  /**
   * A comparator that can be used to sort assists by their relevance. The most
   * relevant assists will be sorted before assists with a lower relevance.
   * Assists with the same relevance are sorted alphabetically.
   */
  static final Comparator<Assist> SORT_BY_RELEVANCE = (Assist a, Assist b) {
    if (a.kind.priority != b.kind.priority) {
      return a.kind.priority - b.kind.priority;
    }
    return a.change.message.compareTo(b.change.message);
  };

  /**
   * A description of the assist being proposed.
   */
  final AssistKind kind;

  /**
   * The change to be made in order to apply the assist.
   */
  final SourceChange change;

  /**
   * Initialize a newly created assist to have the given [kind] and [change].
   */
  Assist(this.kind, this.change);

  @override
  String toString() {
    return 'Assist(kind=$kind, change=$change)';
  }
}
