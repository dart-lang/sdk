// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:vm_service_protos/vm_service_protos.dart';

class TraceData {
  final trace = Trace();
  final seenEvents = <String>{};
  final seenStacks = <List<Frame>>{};
  final seenTracks = <int>{};
  final seenTrackDescriptors = <int>{};

  TraceData.fromBytes(Uint8List bytes) {
    trace.mergeFromBuffer(bytes);

    var state = IncrementalState();
    for (var packet in trace.packet) {
      if ((packet.sequenceFlags &
              TracePacket_SequenceFlags.SEQ_INCREMENTAL_STATE_CLEARED.value) !=
          0) {
        state = IncrementalState();
      }

      if (packet.hasInternedData()) {
        state.update(packet.internedData);
      }

      if (packet.hasTrackEvent()) {
        final trackEvent = packet.trackEvent;
        if (trackEvent.type == TrackEvent_Type.TYPE_SLICE_BEGIN ||
            trackEvent.type == TrackEvent_Type.TYPE_INSTANT) {
          final name = state.eventNames[packet.trackEvent.nameIid.toInt()]!;
          seenEvents.add(name);
          seenTracks.add(trackEvent.trackUuid.toInt());
        }
      }

      if (packet.hasModuleSymbols()) {
        state.addSymbols(packet.moduleSymbols);
      }

      if (packet.hasTrackDescriptor()) {
        final trackDescriptor = packet.trackDescriptor;
        seenTrackDescriptors.add(trackDescriptor.uuid.toInt());
      }

      if (packet.hasPerfSample()) {
        seenStacks.add(state.stacks[packet.perfSample.callstackIid.toInt()]!);
      }
    }
  }

  Iterable<List<String>> get flattenedSeenStacks {
    return seenStacks.map(
      (stack) => stack
          .expand((f) => f.functionNames ?? const <String>['<?>'])
          .toList(),
    );
  }

  bool hasSeenStack(List<String> expectedStack) {
    return seenStacks.firstWhereOrNull(
          (stack) => stackMatches(stack, expectedStack),
        ) !=
        null;
  }
}

bool stackMatches(List<Frame> stack, List<String> expected) {
  var i = 0;
  var j = 0;
  final expandedStack = stack
      .expand(
        (f) =>
            f.functionNames ??
            ['${f.iid} ${f.mapping?.iid ?? '?'}@${f.relPc ?? '?'}'],
      )
      .toList();
  while (j < expected.length) {
    while (i < expandedStack.length && expandedStack[i] != expected[j]) {
      i++;
    }
    if (i == expandedStack.length) {
      return false;
    }
    j++;
  }
  return true;
}

class Frame {
  final int iid;

  List<String>? functionNames;
  Mapping? mapping;
  int? relPc;

  Frame(this.iid);
}

class Mapping {
  final int iid;
  final String? path;
  final String? buildId;
  final int start;
  final int end;

  Mapping({
    required this.iid,
    this.buildId,
    this.path,
    required this.start,
    required this.end,
  });
}

class IncrementalState {
  final eventNames = <int, String>{};
  final functionNames = <int, String>{};
  final frames = <int, Frame>{};
  final stacks = <int, List<Frame>>{};
  final mappingPaths = <int, String>{};
  final mappings = <int, Mapping>{};
  final buildIds = <int, String>{};

  void update(InternedData internedData) {
    for (var eventName in internedData.eventNames) {
      eventNames[eventName.iid.toInt()] = eventName.name;
    }

    for (var functionName in internedData.functionNames) {
      functionNames[functionName.iid.toInt()] = utf8.decode(functionName.str);
    }

    for (var buildId in internedData.buildIds) {
      buildIds[buildId.iid.toInt()] = utf8.decode(buildId.str);
    }

    for (var mappingPath in internedData.mappingPaths) {
      mappingPaths[mappingPath.iid.toInt()] = utf8.decode(mappingPath.str);
    }

    for (var mapping in internedData.mappings) {
      // This way of formatting paths matches the way Perfetto UI handles it.
      var path = mapping.pathStringIds
          .map((id) => mappingPaths[id.toInt()]!)
          .join('/');
      if (!path.startsWith('/')) {
        path = '/$path';
      }
      mappings[mapping.iid.toInt()] = Mapping(
        iid: mapping.iid.toInt(),
        start: mapping.start.toInt(),
        end: mapping.end.toInt(),
        buildId: mapping.buildId.toInt() != 0
            ? buildIds[mapping.buildId.toInt()]!
            : null,
        path: path,
      );
    }

    for (var frame in internedData.frames) {
      final f = frames[frame.iid.toInt()] ??= Frame(frame.iid.toInt());

      final functionNameId = frame.functionNameId.toInt();
      if (functionNameId != 0) {
        f.functionNames = [functionNames[functionNameId]!];
      }

      final mappingId = frame.mappingId.toInt();
      if (mappingId != 0) {
        f.mapping = mappings[mappingId]!;
      }

      f.relPc = frame.relPc.toInt();
    }

    for (var stack in internedData.callstacks) {
      stacks[stack.iid.toInt()] = stack.frameIds
          .map((iid) => frames[iid.toInt()]!)
          .toList(growable: false);
    }
  }

  void addSymbols(ModuleSymbols moduleSymbols) {
    final buildId = moduleSymbols.buildId;
    final symbols = {
      for (var s in moduleSymbols.addressSymbols)
        s.address.toInt(): [
          for (var l in s.lines) l.functionName,
        ].reversed.toList(),
    };

    // Resymbolize collected frames using newly added symbols.
    for (var frame in frames.values) {
      if (frame case Frame(
        functionNames: null,
        :final mapping?,
        :final relPc?,
      ) when mapping.buildId == buildId && mapping.path == moduleSymbols.path) {
        final names = symbols[relPc];
        if (names != null && names.isNotEmpty) {
          frame.functionNames = names;
        }
      }
    }
  }
}
