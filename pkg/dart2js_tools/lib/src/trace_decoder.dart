// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to expand and deobfuscate stack traces.
library;

// ignore: implementation_imports
import 'package:source_maps/src/utils.dart';
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';

import 'dart2js_mapping.dart';
import 'sourcemap_helper.dart';
import 'util.dart';

/// Provides the result of deobfuscating a stack trace.
class StackDeobfuscationResult {
  /// Representation of the obfuscated stack trace.
  final Trace original;

  /// Representation of the deobfuscated stack trace.
  final Trace deobfuscated;

  /// Details about how one original frame maps to deobfuscated frames. A single
  /// frame might map to many frames (in the case of inlining), or to a null
  /// value (when we were unable to deobfuscate it).
  final Map<Frame, List<Frame>> frameMap;

  StackDeobfuscationResult(this.original, this.deobfuscated, this.frameMap);
}

/// Parse [stackTrace] and deobfuscate it using source-map data available from
/// [provider].
StackDeobfuscationResult deobfuscateStack(
    String stackTrace, FileProvider provider) {
  var trace = Trace.parse(stackTrace.trim());
  var deobfuscatedFrames = <Frame>[];
  var frameMap = <Frame, List<Frame>>{};
  for (var frame in trace.frames) {
    var frameLine = frame.line;
    // If there's no line information, there's no way to translate this frame.
    // We could return it as-is, but these lines are usually not useful anyways.
    if (frameLine == null) {
      continue;
    }

    // If there's no column, try using the first column of the line.
    var column = frame.column ?? 1;

    Dart2jsMapping? mapping = provider.mappingFor(frame.uri);
    if (mapping == null) continue;

    // Subtract 1 because stack traces use 1-indexed lines and columns and
    // source maps uses 0-indexed.
    SourceSpan? span = mapping.sourceMap
        .spanFor(frameLine - 1, column - 1, uri: frame.uri.toString());

    // If we can't find a source span, ignore the frame. It's probably something
    // internal that the user doesn't care about.
    if (span == null) continue;

    List<Frame> mappedFrames = frameMap[frame] = [];

    SourceFile jsFile = provider.fileFor(frame.uri);
    int offset = jsFile.getOffset(frameLine - 1, column - 1);
    String nameOf(int id) =>
        _normalizeName(id >= 0 ? mapping.sourceMap.names[id] : null);

    Uri? fileName = span.sourceUrl;
    int targetLine = span.start.line + 1;
    int targetColumn = span.start.column + 1;

    // Expand inlining data.  When present, the fileName, line and column above
    // correspond to the deepest inlined function, as we expand each frame we
    // consume the location information, and retrieve the location information
    // of the caller frame until we reach the actual function that dart2js
    // inlined all the code into.
    Map<int, List<FrameEntry>> frames = mapping.frames;
    List<int> index = mapping.frameIndex;
    int key = binarySearch<int>(index, (i) => i > offset) - 1;
    int depth = 0;
    outer:
    while (key >= 0) {
      for (var frame in frames[index[key]]!.reversed) {
        if (frame.isEmpty) break outer;
        if (frame.isPush) {
          if (depth <= 0) {
            mappedFrames.add(Frame(fileName!, targetLine, targetColumn,
                "${_normalizeName(frame.inlinedMethodName)}(inlined)"));
            fileName = Uri.parse(frame.callUri!);
            targetLine = (frame.callLine ?? 0) + 1;
            targetColumn = (frame.callColumn ?? 0) + 1;
          } else {
            depth--;
          }
        }
        if (frame.isPop) {
          depth++;
        }
      }
      key--;
    }

    var functionEntry = findEnclosingFunction(provider, frame.uri, offset);
    String methodName = nameOf(functionEntry?.sourceNameId ?? -1);
    mappedFrames.add(Frame(fileName!, targetLine, targetColumn, methodName));
    deobfuscatedFrames.addAll(mappedFrames);
  }
  return StackDeobfuscationResult(trace, Trace(deobfuscatedFrames), frameMap);
}

/// Ensure we don't use spaces in method names. At this time, they are only
/// introduced by `<anonymous function>`.
String _normalizeName(String? methodName) =>
    methodName?.replaceAll("<anonymous function>", "<anonymous>") ??
    '<unknown>';
