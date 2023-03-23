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
/// of resources. We grab a "snapshot" of the active bucket and process elements
/// from it until it is empty. Anything added to the bucket after we have
/// grabbed the snapshot is not processed immediately. Instead once the snapshot
/// is empty we move on to the next bucket. By ignoring elements after the
/// snapshot we prevent the queue from getting stuck on loops within the same
/// bucket.
class WorkQueue {
  final List<Queue<TypeInformation>> buckets =
      List.generate(_numBuckets, (_) => Queue(), growable: false);
  int _length = 0;
  Queue<TypeInformation> _activeQueue = Queue();
  int _activeBucketIndex = 0;

  void add(TypeInformation element) {
    if (element.doNotEnqueue) return;
    if (element.inQueue) return;
    buckets[_bucketForInfo(element)].add(element);
    element.inQueue = true;
    _length++;
  }

  void addAll(Iterable<TypeInformation> all) {
    all.forEach(add);
  }

  TypeInformation remove() {
    while (_activeQueue.isEmpty) {
      assert(_length != 0);
      final bucket = buckets[_activeBucketIndex];
      if (bucket.isNotEmpty) {
        final tmp = _activeQueue;
        _activeQueue = buckets[_activeBucketIndex];
        buckets[_activeBucketIndex] = tmp;
      }
      _incrementBucketIndex();
    }
    final element = _activeQueue.removeFirst();
    _length--;
    element.inQueue = false;
    return element;
  }

  void _incrementBucketIndex() {
    _activeBucketIndex =
        _activeBucketIndex == buckets.length - 1 ? 0 : _activeBucketIndex + 1;
  }

  bool get isEmpty => _length == 0;

  int get length => _length;
}
