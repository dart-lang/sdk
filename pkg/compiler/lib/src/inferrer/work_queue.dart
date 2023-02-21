// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;
import 'type_graph_nodes.dart';

const _numBuckets = 2;

/// This function applies a bucket index to each type information.
///
/// Current strategy:
/// Process call sites together effectively splitting intraprocedural type
/// refinement and local type refinement.
int _bucketForInfo(TypeInformation info) {
  if (info is! CallSiteTypeInformation) return 0;
  return 1;
}

/// A work queue for the inferrer. It filters out nodes that are tagged as
/// [TypeInformation.doNotEnqueue], as well as ensures through
/// [TypeInformation.inQueue] that a node is in the queue only once at
/// a time.
///
/// The queue uses a bucketed approach to allow the inferrer to make progress
/// on certain categories of types while also ensuring no category is starved
/// of resources. The queue draws work items from a bucket until it is empty
/// and then proceeds onto the next bucket with work remaining. This allows
/// related work items to be processed closer to each other.
class WorkQueue {
  final List<Queue<TypeInformation>> buckets =
      List.generate(_numBuckets, (_) => Queue());
  int _length = 0;
  int _activeBucket = 0;

  void add(TypeInformation element) {
    if (element.doNotEnqueue) return;
    if (element.inQueue) return;
    buckets[_bucketForInfo(element)].addLast(element);
    element.inQueue = true;
    _length++;
  }

  void addAll(Iterable<TypeInformation> all) {
    all.forEach(add);
  }

  TypeInformation remove() {
    var bucket = buckets[_activeBucket];
    while (bucket.isEmpty) {
      if (++_activeBucket == buckets.length) _activeBucket = 0;
      bucket = buckets[_activeBucket];
    }
    TypeInformation element = bucket.removeFirst();
    element.inQueue = false;
    _length--;
    return element;
  }

  bool get isEmpty => _length == 0;

  int get length => _length;
}
