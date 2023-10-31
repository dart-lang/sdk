// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/src/vm_service.dart';
import 'package:test/test.dart';

import '../common/test_helper.dart';

class Page {
  Page.fromJson(Map<String, dynamic> json)
      : objectStart = json['objectStart'],
        objects = json['objects'].cast<int>();

  final String objectStart;
  final List<int> objects;
}

class HeapMap extends Response {
  static HeapMap? parse(Map<String, dynamic>? json) =>
      json == null ? null : HeapMap._fromJson(json);

  HeapMap._fromJson(Map<String, dynamic> json)
      : freeClassId = json['freeClassId'],
        unitSizeBytes = json['unitSizeBytes'],
        pageSizeBytes = json['pageSizeBytes'],
        classList = ClassList.parse(json['classList'])!,
        pages = json['pages'].map<Page>((e) => Page.fromJson(e)).toList();

  @override
  String get type => 'HeapMap';

  final int freeClassId;
  final int unitSizeBytes;
  final int pageSizeBytes;
  final ClassList classList;
  final List<Page> pages;
}

enum GCType {
  none,
  scavenge,
  markSweep,
  markCompact;

  @override
  String toString() {
    switch (this) {
      case GCType.none:
        return '';
      case GCType.scavenge:
        return 'scavenge';
      case GCType.markCompact:
        return 'mark-compact';
      case GCType.markSweep:
        return 'mark-sweep';
    }
  }
}

extension on VmService {
  Future<HeapMap> getHeapMap(String isolateId,
          {GCType gc = GCType.none}) async =>
      await callMethod('_getHeapMap', isolateId: isolateId, args: {
        if (gc != GCType.none) 'gc': gc.toString(),
      }) as HeapMap;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    // Setup
    addTypeFactory('HeapMap', HeapMap.parse);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result = await service.getHeapMap(isolateId);
    expect(result.freeClassId, isPositive);
    expect(result.unitSizeBytes, isPositive);
    expect(result.pageSizeBytes, isPositive);
    expect(result.classList.classes, isNotNull);
    expect(result.pages, isNotEmpty);
    expect(result.pages[0].objectStart, isNotEmpty);
    expect(result.pages[0].objects, isNotEmpty);
    expect(result.pages[0].objects[0], isPositive);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result = await service.getHeapMap(
      isolateId,
      gc: GCType.markCompact,
    );
    expect(result.freeClassId, isPositive);
    expect(result.unitSizeBytes, isPositive);
    expect(result.pageSizeBytes, isPositive);
    expect(result.classList.classes, isNotNull);
    expect(result.pages, isNotEmpty);
    expect(result.pages[0].objectStart, isNotEmpty);
    expect(result.pages[0].objects, isNotEmpty);
    expect(result.pages[0].objects[0], isPositive);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result = await service.getHeapMap(
      isolateId,
      gc: GCType.markSweep,
    );
    expect(result.freeClassId, isPositive);
    expect(result.unitSizeBytes, isPositive);
    expect(result.pageSizeBytes, isPositive);
    expect(result.classList.classes, isNotNull);
    expect(result.pages, isNotEmpty);
    expect(result.pages[0].objectStart, isNotEmpty);
    expect(result.pages[0].objects, isNotEmpty);
    expect(result.pages[0].objects[0], isPositive);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result = await service.getHeapMap(
      isolateId,
      gc: GCType.scavenge,
    );
    expect(result.freeClassId, isPositive);
    expect(result.unitSizeBytes, isPositive);
    expect(result.pageSizeBytes, isPositive);
    expect(result.classList.classes, isNotNull);
    expect(result.pages, isNotEmpty);
    expect(result.pages[0].objectStart, isNotEmpty);
    expect(result.pages[0].objects, isNotEmpty);
    expect(result.pages[0].objects[0], isPositive);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_heap_map_rpc_test.dart',
    );
