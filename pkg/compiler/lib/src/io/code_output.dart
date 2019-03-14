// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.code_output;

import '../../compiler_new.dart';
import 'source_information.dart';

/// Listener interface for [CodeOutput] activity.
abstract class CodeOutputListener {
  /// Called when [text] is added to the output.
  void onText(String text);

  /// Called when the output is closed with a final length of [length].
  void onDone(int length);
}

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
  void addPush(
      int targetOffset, SourceLocation pushPosition, String inlinedMethodName);

  /// Record a return of an inlining call at the [targetOffset].
  ///
  /// [isEmpty] indicates that this return also makes the inlining stack empty.
  void addPop(int targetOffset, bool isEmpty);

  /// Applies [f] to every target offset and associated source location.
  void forEachSourceLocation(
      void f(int targetOffset, SourceLocation sourceLocation));

  /// Recorded inlining data per target-offset.
  Map<int, List<FrameEntry>> get frameMarkers;
}

class _SourceLocationsImpl implements SourceLocations {
  @override
  final String name;
  final AbstractCodeOutput codeOutput;
  Map<int, List<SourceLocation>> markers = <int, List<SourceLocation>>{};
  @override
  Map<int, List<FrameEntry>> frameMarkers = <int, List<FrameEntry>>{};

  _SourceLocationsImpl(this.name, this.codeOutput);

  @override
  void addSourceLocation(int targetOffset, SourceLocation sourceLocation) {
    assert(targetOffset <= codeOutput.length);
    List<SourceLocation> sourceLocations =
        markers.putIfAbsent(targetOffset, () => <SourceLocation>[]);
    sourceLocations.add(sourceLocation);
  }

  @override
  void addPush(int targetOffset, SourceLocation sourceLocation,
      String inlinedMethodName) {
    assert(targetOffset <= codeOutput.length);
    List<FrameEntry> frames = frameMarkers[targetOffset] ??= [];
    frames.add(new FrameEntry.push(sourceLocation, inlinedMethodName));
  }

  @override
  void addPop(int targetOffset, bool isEmpty) {
    assert(targetOffset <= codeOutput.length);
    List<FrameEntry> frames = frameMarkers[targetOffset] ??= [];
    frames.add(new FrameEntry.pop(isEmpty));
  }

  @override
  void forEachSourceLocation(
      void f(int targetOffset, SourceLocation sourceLocation)) {
    markers.forEach((int targetOffset, List<SourceLocation> sourceLocations) {
      for (SourceLocation sourceLocation in sourceLocations) {
        f(targetOffset, sourceLocation);
      }
    });
  }

  void _merge(_SourceLocationsImpl other) {
    assert(name == other.name);
    int length = codeOutput.length;
    if (other.markers.length > 0) {
      other.markers
          .forEach((int targetOffset, List<SourceLocation> sourceLocations) {
        (markers[length + targetOffset] ??= <SourceLocation>[])
            .addAll(sourceLocations);
      });
    }

    if (other.frameMarkers.length > 0) {
      other.frameMarkers.forEach((int targetOffset, List<FrameEntry> frames) {
        (frameMarkers[length + targetOffset] ??= <FrameEntry>[]).addAll(frames);
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
  Map<String, _SourceLocationsImpl> sourceLocationsMap =
      <String, _SourceLocationsImpl>{};
  @override
  bool isClosed = false;

  void _addInternal(String text);

  @override
  void add(String text) {
    if (isClosed) {
      throw new StateError("Code output is closed. Trying to write '$text'.");
    }
    _addInternal(text);
  }

  @override
  void addBuffer(CodeBuffer other) {
    other.sourceLocationsMap.forEach((String name, _SourceLocationsImpl other) {
      createSourceLocations(name)._merge(other);
    });
    if (!other.isClosed) {
      other.close();
    }
    _addInternal(other.getText());
  }

  @override
  void close() {
    if (isClosed) {
      throw new StateError("Code output is already closed.");
    }
    isClosed = true;
  }

  @override
  Iterable<SourceLocations> get sourceLocations => sourceLocationsMap.values;

  @override
  _SourceLocationsImpl createSourceLocations(String name) {
    return sourceLocationsMap[name] ??= new _SourceLocationsImpl(name, this);
  }
}

abstract class BufferedCodeOutput {
  String getText();
}

/// [CodeOutput] using a [StringBuffer] as backend.
class CodeBuffer extends AbstractCodeOutput implements BufferedCodeOutput {
  StringBuffer buffer = new StringBuffer();

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
  final OutputSink output;
  final List<CodeOutputListener> _listeners;

  StreamCodeOutput(this.output, [this._listeners]);

  @override
  void _addInternal(String text) {
    output.add(text);
    length += text.length;
    if (_listeners != null) {
      _listeners.forEach((listener) => listener.onText(text));
    }
  }

  @override
  void close() {
    output.close();
    super.close();
    if (_listeners != null) {
      _listeners.forEach((listener) => listener.onDone(length));
    }
  }
}
