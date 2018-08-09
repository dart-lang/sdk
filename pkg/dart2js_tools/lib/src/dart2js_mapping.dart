// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Representation of a source-map file with dart2js-specific extensions, and
/// helper functions to parse them.

import 'dart:convert';
import 'dart:io';

import 'package:source_maps/source_maps.dart';

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

  Dart2jsMapping(this.sourceMap, Map json) {
    var extensions = json['x_org_dartlang_dart2js'];
    if (extensions == null) return;
    var minifiedNames = extensions['minified_names'];
    if (minifiedNames != null) {
      minifiedNames['global'].forEach((minifiedName, id) {
        globalNames[minifiedName] = sourceMap.names[id];
      });
      minifiedNames['instance'].forEach((minifiedName, id) {
        instanceNames[minifiedName] = sourceMap.names[id];
      });
    }
    List jsonFrames = extensions['frames'];
    if (jsonFrames != null) {
      for (List values in jsonFrames) {
        if (values.length < 2) {
          warn("warning: incomplete frame data: $values");
          continue;
        }
        int offset = values[0];
        List<FrameEntry> entries = frames[offset] ??= [];
        if (entries.length > 0) {
          warn("warning: duplicate entries for $offset");
          continue;
        }
        for (int i = 1; i < values.length; i++) {
          var current = values[i];
          if (current == -1) {
            entries.add(new FrameEntry.pop(false));
          } else if (current == 0) {
            entries.add(new FrameEntry.pop(true));
          } else {
            if (current is List) {
              if (current.length == 4) {
                entries.add(new FrameEntry.push(sourceMap.urls[current[0]],
                    current[1], current[2], sourceMap.names[current[3]]));
              } else {
                warn("warning: unexpected entry $current");
              }
            } else {
              warn("warning: unexpected entry $current");
            }
          }
        }
      }
    }
  }
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
Dart2jsMapping parseMappingFor(Uri uri) {
  var file = new File.fromUri(uri);
  if (!file.existsSync()) {
    warn('Error: no such file: $uri');
    return null;
  }
  var contents = file.readAsStringSync();
  var urlIndex = contents.indexOf(_marker);
  var sourcemapPath;
  if (urlIndex != -1) {
    sourcemapPath = contents.substring(urlIndex + _marker.length).trim();
  } else {
    warn('Error: source-map url marker not found in $uri\n'
        '       trying $uri.map');
    sourcemapPath = '${uri.pathSegments.last}.map';
  }

  assert(!sourcemapPath.contains('\n'));
  var sourcemapFile = new File.fromUri(uri.resolve(sourcemapPath));
  if (!sourcemapFile.existsSync()) {
    warn('Error: no such file: $sourcemapFile');
    return null;
  }
  var json = jsonDecode(sourcemapFile.readAsStringSync());
  return new Dart2jsMapping(parseJson(json), json);
}
