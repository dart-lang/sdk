// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import '../test/coverage_helper.dart';

void main(List<String> arguments) {
  Uri? coverageUri;
  for (String argument in arguments) {
    if (argument.startsWith("--coverage=")) {
      coverageUri = Uri.base
          .resolveUri(Uri.file(argument.substring("--coverage=".length)));
    } else {
      throw "Unsupported argument: $argument";
    }
  }
  if (coverageUri == null) {
    throw "Need --coverage=<dir>/ argument";
  }

  mergeFromDirUri(coverageUri, includeNotCompiled: true);
}

void mergeFromDirUri(Uri coverageUri, {required bool includeNotCompiled}) {
  // TODO(jensj): We should filter stuff out that "doesn't matter", e.g.
  // it's probably okay that toString() isn't covered.

  // TODO(jensj): We should allow for comments to "excuse" something from not
  // being covered. E.g. sometimes we throw after a number of if's saying
  // something like "this can probably never happen", and thus we can't expect
  // to test that.

  // TODO(jensj): Would converting offsets to lines be helpful?

  // TODO(jensj): We should be able to extract the "coverable" offsets from
  // source/dill, thus avoiding asking the VM to do it and basically we would
  // then be able to just ignore the uncompiled stuff from the VM. It could
  // probably also be used for speeding up doing coverage in flutter. We need to
  // be "sharp" about what the VM includes and what the VM doesn't include
  // though. I assume it doesn't include everything, but really I don't know.

  // TODO(jensj): Things that are not covered by one of our suites should
  // probably be marked specifically as we generally want tests "close".

  // Merge the data:
  //  * combine hits, and keep track of where they come from (display name)
  //  * combine misses, but remove misses that are hits
  //  * take the "intersection" of all not compiled entries.
  //    Note that we merge two coverages at a time and we'll keep the
  //    "intersection interval", e.g. if one has 1-100 and another has 25-34,
  //    65-70 and 200-300 the intersection is 25-34 and 65-70.
  Map<Uri, Hit> hits = {};
  Map<Uri, Set<int>> misses = {};
  Map<Uri, Uint32List> notCompiled = {};

  for (FileSystemEntity entry
      in Directory.fromUri(coverageUri).listSync(recursive: true)) {
    if (entry is! File) continue;
    try {
      Coverage coverage = Coverage.loadFromFile(entry);
      print("Loaded $entry as coverage file.");
      _mergeCoverageInto(coverage, misses, hits, notCompiled);
    } catch (e) {
      print("Couldn't load $entry as coverage file.");
    }
  }
  print("");

  Set<Uri> knownUris = {};
  knownUris.addAll(hits.keys);
  knownUris.addAll(misses.keys);
  if (includeNotCompiled) {
    knownUris.addAll(notCompiled.keys);
  }

  for (Uri uri in knownUris.toList()
    ..sort(((a, b) => a.toString().compareTo(b.toString())))) {
    Hit? hit = hits[uri];
    int hitCount = hit?._data.length ?? 0;

    Uint32List? uncompiled;
    if (includeNotCompiled) {
      uncompiled = notCompiled[uri];
    }

    Set<int>? mis = misses[uri];
    int misCount = mis?.length ?? 0;
    if (hitCount + misCount == 0) {
      if (uncompiled == null || uncompiled.isEmpty) {
        // We're not going to print anything. Don't print the uri either.
      } else {
        print("$uri");
      }
    } else {
      if (misCount > 0) {
        print("$uri: ${(hitCount / (hitCount + misCount) * 100).round()}% "
            "($misCount misses)");
      } else {
        print("$uri: 100% (OK)");
      }
    }

    if (mis?.isNotEmpty == true || uncompiled?.isNotEmpty == true) {
      if (mis != null && mis.isNotEmpty) {
        print("Misses: ${mis.toList()..sort()}");
      }
      if (uncompiled != null && uncompiled.isNotEmpty) {
        print("Uncompiled: $uncompiled");
      }
      print("");
    }
  }
}

void _mergeCoverageInto(Coverage coverage, Map<Uri, Set<int>> misses,
    Map<Uri, Hit> hits, Map<Uri, Uint32List> notCompiled) {
  for (FileCoverage fileCoverage in coverage.getAllFileCoverages()) {
    if (fileCoverage.misses.isNotEmpty) {
      Set<int> mis = misses[fileCoverage.uri] ??= {};
      mis.addAll(fileCoverage.misses);
    }

    if (fileCoverage.hits.isNotEmpty) {
      Hit hit = hits[fileCoverage.uri] ??= new Hit();
      for (int fileHit in fileCoverage.hits) {
        hit.addHit(fileHit, coverage.displayName);
      }
    }

    // Do the intersection for not compiled stuff.
    Uint32List? uncompiled = notCompiled[fileCoverage.uri];
    if (uncompiled == null) {
      // No merge --- just take the data as is. The easy way to get the interval
      // list is to just add the data twice, logically taking the intersection
      // with itself.
      _IntervalListIntersectionBuilder builder =
          new _IntervalListIntersectionBuilder();
      for (StartEndPair startEndPair in fileCoverage.notCompiled) {
        builder.addInterval(startEndPair.startPos, startEndPair.endPos);
        builder.addInterval(startEndPair.startPos, startEndPair.endPos);
      }
      notCompiled[fileCoverage.uri] = builder.buildIntervalList();
    } else if (uncompiled.isEmpty) {
      // Intersection will be empty too, so there's nothing to do.
    } else {
      // Create an intersection of two non-empty chunks.
      _IntervalListIntersectionBuilder builder =
          new _IntervalListIntersectionBuilder();
      builder.addIntervalList(uncompiled);
      for (StartEndPair startEndPair in fileCoverage.notCompiled) {
        builder.addInterval(startEndPair.startPos, startEndPair.endPos);
      }
      notCompiled[fileCoverage.uri] = builder.buildIntervalList();
    }
  }

  // Now remove any misses that are actually hits.
  for (MapEntry<Uri, Set<int>> entry in misses.entries) {
    Hit? hit = hits[entry.key];
    if (hit == null) continue;
    entry.value.removeAll(hit._data.keys);
  }
}

class Hit {
  Map<int, List<String>> _data = {};

  void addHit(int offset, String displayName) {
    (_data[offset] ??= []).add(displayName);
  }
}

// Based on (as in mostly a copy from) the _IntervalListBuilder in
// package:kernel/class_hierarchy.dart.
// This only works when adding two interval containers (i.e. getting the
// intersection of two) and each should individually be non-overlapping.
class _IntervalListIntersectionBuilder {
  final List<int> events = <int>[];

  void addInterval(int start, int end) {
    // Add an event point for each interval end point, using the low bit to
    // distinguish opening from closing end points. Closing end points should
    // have the high bit to ensure they occur after an opening end point.
    events.add(start << 1);
    events.add((end << 1) + 1);
  }

  void addIntervalList(Uint32List intervals) {
    for (int i = 0; i < intervals.length; i += 2) {
      addInterval(intervals[i], intervals[i + 1]);
    }
  }

  Uint32List buildIntervalList() {
    // Sort the event points and sweep left to right while tracking how many
    // intervals we are currently inside.
    // Here we want the intersection between two so only include an interval if
    // there are two overlapping.
    events.sort();
    int insideCount = 0; // The number of intervals we are currently inside.
    int storeIndex = 0;
    for (int i = 0; i < events.length; ++i) {
      int event = events[i];
      if (event & 1 == 0) {
        // Start point
        ++insideCount;
        if (insideCount == 2) {
          // Store the results temporarily back in the event array.
          events[storeIndex++] = event >> 1;
        }
      } else {
        // End point
        --insideCount;
        if (insideCount == 1) {
          // Say we had [0, 1] and [1, 2]. That would become 0{0} 1{1} 1{0} 2{1}
          // (with the syntax of actualNumber{beginEndMarkingBit}) which would
          // sort as 0{0} 1{0} 1{1} 2{1} which would mean that after 1{0} we'd
          // have two open and we'd thus have added a store above.
          // Now processing 1{1} though we go back down to 1 and we'd here say
          // store again to mark the end of this interval. But the start and the
          // end is the same and the interval is thus empty. This is not really
          // wrong, but not useful either, so we check if it's the case and
          // undo if it is.
          if (events[storeIndex - 1] == (event >> 1)) {
            // Empty interval --- we skip it and undo the previous store index.
            storeIndex--;
          } else {
            // Non-empty index.
            events[storeIndex++] = event >> 1;
          }
        }
      }
    }
    // Copy the results over to a typed array of the correct length.
    Uint32List result = new Uint32List(storeIndex);
    for (int i = 0; i < storeIndex; ++i) {
      result[i] = events[i];
    }
    return result;
  }
}
