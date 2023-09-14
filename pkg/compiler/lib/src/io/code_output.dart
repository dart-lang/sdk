// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.code_output;

import '../../compiler_api.dart' as api show OutputSink;
import 'code_output_listener.dart';
export 'code_output_listener.dart';
import 'source_information.dart';

/// Interface for a mapping of target offsets to source locations and for
/// tracking inlining frame data.
///
/// Source-location mapping is used to build standard source-maps files.
/// Inlining frames is used to attach an extension to source-map files to
/// improve deobfuscation of production stack traces.
abstract class SourceLocations {
  /// The name identifying this source mapping.
  String get name;

  /// Adds a [sourceLocation] at the specified [targetOffset].
  void addSourceLocation(int targetOffset, SourceLocation sourcePosition);

  /// Record an inlining call at the [targetOffset].
  ///
  /// The inlining call-site was made from [pushLocation] and calls
  /// [inlinedMethodName].
  // TODO(48820): We might have a [pushPosition].
  void addPush(
      int targetOffset, SourceLocation? pushPosition, String inlinedMethodName);

  /// Record a return of an inlining call at the [targetOffset].
  ///
  /// [isEmpty] indicates that this return also makes the inlining stack empty.
  void addPop(int targetOffset, bool isEmpty);

  /// Applies [f] to every target offset and associated source location.
  void forEachSourceLocation(
      void f(int targetOffset, SourceLocation sourceLocation));

  /// Applies [f] to every target offset and associated frame entry. This is
  /// mostly used to track inlining data.
  void forEachFrameMarker(void f(int targetOffset, FrameEntry frameEntry));

  void close();
}

class _SourceLocationsImpl implements SourceLocations {
  @override
  final String name;
  final AbstractCodeOutput codeOutput;
  Map<int, List<SourceLocation>> markers = {};
  Map<int, List<FrameEntry>> frameMarkers = {};
  bool _closed = false;

  _SourceLocationsImpl(this.name, this.codeOutput);

  @override
  void addSourceLocation(int targetOffset, SourceLocation sourceLocation) {
    assert(targetOffset <= codeOutput.length);
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    List<SourceLocation> sourceLocations =
        markers.putIfAbsent(targetOffset, () => []);
    sourceLocations.add(sourceLocation);
  }

  @override
  void addPush(int targetOffset, SourceLocation? sourceLocation,
      String inlinedMethodName) {
    assert(targetOffset <= codeOutput.length);
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    List<FrameEntry> frames = frameMarkers[targetOffset] ??= [];
    frames.add(FrameEntry.push(sourceLocation, inlinedMethodName));
  }

  @override
  void addPop(int targetOffset, bool isEmpty) {
    assert(targetOffset <= codeOutput.length);
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    List<FrameEntry> frames = frameMarkers[targetOffset] ??= [];
    frames.add(FrameEntry.pop(isEmpty));
  }

  @override
  void forEachSourceLocation(
      void f(int targetOffset, SourceLocation sourceLocation)) {
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    markers.forEach((int targetOffset, List<SourceLocation> sourceLocations) {
      for (SourceLocation sourceLocation in sourceLocations) {
        f(targetOffset, sourceLocation);
      }
    });
  }

  @override
  void forEachFrameMarker(void f(int targetOffset, FrameEntry sourceLocation)) {
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    frameMarkers.forEach((int targetOffset, List<FrameEntry> frameEntries) {
      for (FrameEntry entry in frameEntries) {
        f(targetOffset, entry);
      }
    });
  }

  @override
  void close() {
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    _closed = true;
    frameMarkers.clear();
    markers.clear();
  }

  void _merge(_SourceLocationsImpl other) {
    assert(name == other.name);
    if (_closed) throw UnsupportedError('SourceLocations already closed.');
    int length = codeOutput.length;
    if (other.markers.length > 0) {
      other.markers
          .forEach((int targetOffset, List<SourceLocation> sourceLocations) {
        (markers[length + targetOffset] ??= []).addAll(sourceLocations);
      });
    }

    if (other.frameMarkers.length > 0) {
      other.frameMarkers.forEach((int targetOffset, List<FrameEntry> frames) {
        (frameMarkers[length + targetOffset] ??= []).addAll(frames);
      });
    }
  }
}

abstract class SourceLocationsProvider {
  /// Creates a [SourceLocations] mapping identified by [name] and associates
  /// it with this code output.
  SourceLocations createSourceLocations(String name);

  /// Returns the source location mappings associated with this code output.
  Iterable<SourceLocations> get sourceLocations;
}

abstract class CodeOutput implements SourceLocationsProvider {
  /// Write [text] to this output.
  ///
  /// If the output is closed, a [StateError] is thrown.
  void add(String text);

  /// Adds the content of [buffer] to the output and adds its markers to
  /// [markers].
  ///
  /// If the output is closed, a [StateError] is thrown.
  void addBuffer(CodeBuffer buffer);

  /// Returns the number of characters currently written to this output.
  int get length;

  /// Returns `true` if this output has been closed.
  bool get isClosed;

  /// Closes the output. Further writes will cause a [StateError].
  void close();
}

abstract class AbstractCodeOutput extends CodeOutput {
  final List<CodeOutputListener>? _listeners;

  AbstractCodeOutput([this._listeners]);

  Map<String, _SourceLocationsImpl> sourceLocationsMap = {};
  @override
  bool isClosed = false;

  void _addInternal(String text);

  void _add(String text) {
    _addInternal(text);
    _listeners?.forEach((listener) => listener.onText(text));
  }

  @override
  void add(String text) {
    if (isClosed) {
      throw StateError("Code output is closed. Trying to write '$text'.");
    }
    _add(text);
  }

  @override
  void addBuffer(CodeBuffer other) {
    other.sourceLocationsMap.forEach((String name, _SourceLocationsImpl other) {
      createSourceLocations(name)._merge(other);
    });
    if (!other.isClosed) {
      other.close();
    }
    _add(other.getText());
  }

  @override
  void close() {
    if (isClosed) {
      throw StateError("Code output is already closed.");
    }
    isClosed = true;
    _listeners?.forEach((listener) => listener.onDone(length));
  }

  @override
  Iterable<SourceLocations> get sourceLocations => sourceLocationsMap.values;

  @override
  _SourceLocationsImpl createSourceLocations(String name) {
    return sourceLocationsMap[name] ??= _SourceLocationsImpl(name, this);
  }
}

abstract class BufferedCodeOutput {
  String getText();
}

/// [CodeOutput] using a [StringBuffer] as backend.
class CodeBuffer extends AbstractCodeOutput implements BufferedCodeOutput {
  StringBuffer buffer = StringBuffer();

  CodeBuffer([super.listeners]);

  @override
  void _addInternal(String text) {
    buffer.write(text);
  }

  @override
  int get length => buffer.length;

  @override
  String getText() {
    return buffer.toString();
  }

  @override
  String toString() {
    throw "Don't use CodeBuffer.toString() since it drops sourcemap data.";
  }
}

/// [CodeOutput] using a [CompilationOutput] as backend.
class StreamCodeOutput extends AbstractCodeOutput {
  @override
  int length = 0;
  final api.OutputSink output;

  StreamCodeOutput(this.output, [List<CodeOutputListener>? listeners])
      : super(listeners);

  @override
  void _addInternal(String text) {
    output.add(text);
    length += text.length;
  }

  @override
  void close() {
    output.close();
    super.close();
  }
}
