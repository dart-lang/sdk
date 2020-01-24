// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Representation of a source-map file with dart2js-specific extensions, and
/// helper functions to parse them.

import 'dart:convert';
import 'dart:io';

import 'package:source_maps/source_maps.dart';
import 'package:source_maps/src/vlq.dart';

import 'util.dart';

/// Representation of a source-map file with dart2js-specific extensions.
///
/// Dart2js adds a special section that provides: tables of minified names and a
/// table of inlining frame data.
class Dart2jsMapping {
  final SingleMapping sourceMap;

  final Map<String, String> globalNames = {};
  final Map<String, String> instanceNames = {};
  final Map<int, List<FrameEntry>> frames = {};
  List<int> _frameIndex;
  List<int> get frameIndex {
    if (_frameIndex == null) {
      _frameIndex = frames.keys.toList()..sort();
    }
    return _frameIndex;
  }

  Dart2jsMapping(this.sourceMap, Map json, {Logger logger}) {
    var extensions = json['x_org_dartlang_dart2js'];
    if (extensions == null) return;
    var minifiedNames = extensions['minified_names'];
    if (minifiedNames != null) {
      _extractMinifedNames(
          minifiedNames['global'], sourceMap, globalNames, logger);
      _extractMinifedNames(
          minifiedNames['instance'], sourceMap, instanceNames, logger);
    }
    String jsonFrames = extensions['frames'];
    if (jsonFrames != null) {
      new _FrameDecoder(jsonFrames).parseFrames(frames, sourceMap);
    }
  }

  Dart2jsMapping.json(Map json) : this(parseJson(json), json);
}

class FrameEntry {
  final String callUri;
  final int callLine;
  final int callColumn;
  final String inlinedMethodName;
  final bool isEmpty;
  FrameEntry.push(
      this.callUri, this.callLine, this.callColumn, this.inlinedMethodName)
      : isEmpty = false;
  FrameEntry.pop(this.isEmpty)
      : callUri = null,
        callLine = null,
        callColumn = null,
        inlinedMethodName = null;

  bool get isPush => callUri != null;
  bool get isPop => callUri == null;

  toString() {
    if (isPush)
      return "push $inlinedMethodName @ $callUri:$callLine:$callColumn";
    return isEmpty ? 'pop: empty' : 'pop';
  }
}

const _marker = "\n//# sourceMappingURL=";
Dart2jsMapping parseMappingFor(Uri uri, {Logger logger}) {
  var file = new File.fromUri(uri);
  if (!file.existsSync()) {
    logger?.log('Error: no such file: $uri');
    return null;
  }
  var contents = file.readAsStringSync();
  var urlIndex = contents.indexOf(_marker);
  var sourcemapPath;
  if (urlIndex != -1) {
    sourcemapPath = contents.substring(urlIndex + _marker.length).trim();
  } else {
    logger?.log('Error: source-map url marker not found in $uri\n'
        '       trying $uri.map');
    sourcemapPath = '${uri.pathSegments.last}.map';
  }

  assert(!sourcemapPath.contains('\n'));
  var sourcemapFile = new File.fromUri(uri.resolve(sourcemapPath));
  if (!sourcemapFile.existsSync()) {
    logger?.log('Error: no such file: $sourcemapFile');
    return null;
  }
  var json = jsonDecode(sourcemapFile.readAsStringSync());
  return new Dart2jsMapping(parseJson(json), json, logger: logger);
}

class _FrameDecoder implements Iterator<String> {
  final String _internal;
  final int _length;
  int index = -1;
  _FrameDecoder(this._internal) : _length = _internal.length;

  // Iterator API is used by decodeVlq to consume VLQ entries.
  bool moveNext() => ++index < _length;

  String get current =>
      (index >= 0 && index < _length) ? _internal[index] : null;

  bool get hasTokens => index < _length - 1 && _length > 0;

  int _readDelta() => decodeVlq(this);

  void parseFrames(Map<int, List<FrameEntry>> frames, SingleMapping sourceMap) {
    var offset = 0;
    var uriId = 0;
    var nameId = 0;
    var line = 0;
    var column = 0;
    while (hasTokens) {
      offset += _readDelta();
      List<FrameEntry> entries = frames[offset] ??= [];
      var marker = _internal[index + 1];
      if (marker == ';') {
        entries.add(new FrameEntry.pop(true));
        index++;
        continue;
      } else if (marker == ',') {
        entries.add(new FrameEntry.pop(false));
        index++;
        continue;
      } else {
        uriId += _readDelta();
        var uri = sourceMap.urls[uriId];
        line += _readDelta();
        column += _readDelta();
        nameId += _readDelta();
        var name = sourceMap.names[nameId];
        entries.add(new FrameEntry.push(uri, line, column, name));
      }
    }
  }
}

_extractMinifedNames(String encodedInput, SingleMapping sourceMap,
    Map<String, String> minifiedNames, Logger logger) {
  List<String> input = encodedInput.split(',');
  if (input.length % 2 != 0) {
    logger?.log("Error: expected an even number of entries");
  }
  for (int i = 0; i < input.length; i += 2) {
    String minifiedName = input[i];
    int id = int.tryParse(input[i + 1]);
    minifiedNames[minifiedName] = sourceMap.names[id];
  }
}
