// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../vm_service.dart';

class IsolateHelper {
  static HeapSpace getNewSpace(Isolate isolate) {
    Map m = isolate.json['_heaps']['new'];
    return HeapSpace.parse(m);
  }

  static HeapSpace getOldSpace(Isolate isolate) {
    Map m = isolate.json['_heaps']['old'];
    return HeapSpace.parse(m);
  }

  static List<TagCounter> getTagCounters(Isolate isolate) {
    Map m = isolate.json['_tagCounters'];
    List<String> names = m['names'];
    List<int> counters = m['counters'];

    List<TagCounter> result = [];
    for (int i = 0; i < counters.length; i++) {
      result.add(new TagCounter(names[i], counters[i]));
    }
    return result;
  }
}

class AllocationProfileHelper {
  static HeapSpace getNewSpace(AllocationProfile profile) {
    return HeapSpace.parse(profile.json['heaps']['new']);
  }

  static HeapSpace getOldSpace(AllocationProfile profile) {
    return HeapSpace.parse(profile.json['heaps']['old']);
  }
}

class GcEventHelper {
  static String reason(Event event) => event.json['reason'];

  static HeapSpace getNewSpace(Event event) {
    return HeapSpace.parse(event.json['new']);
  }

  static HeapSpace getOldSpace(Event event) {
    return HeapSpace.parse(event.json['old']);
  }
}

class TagCounter {
  final String name;
  final int count;

  TagCounter(this.name, this.count);
}

//class GraphEventHelper {
//  // int chunkIndex
//  // int chunkCount
//  // int nodeCount
//}
