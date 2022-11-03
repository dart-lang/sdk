// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;
import 'type_graph_nodes.dart';

/// A work queue for the inferrer. It filters out nodes that are tagged as
/// [TypeInformation.doNotEnqueue], as well as ensures through
/// [TypeInformation.inQueue] that a node is in the queue only once at
/// a time.
class WorkQueue {
  final Queue<TypeInformation> queue = Queue<TypeInformation>();

  void add(TypeInformation element) {
    if (element.doNotEnqueue) return;
    if (element.inQueue) return;
    queue.addLast(element);
    element.inQueue = true;
  }

  void addAll(Iterable<TypeInformation> all) {
    all.forEach(add);
  }

  TypeInformation remove() {
    TypeInformation element = queue.removeFirst();
    element.inQueue = false;
    return element;
  }

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;
}
