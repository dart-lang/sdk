// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Emitter for resource identifiers embedded in the program.
///
/// See [documentation](../../../doc/resource_identifiers.md) for examples.
///
/// .../foo_resource.dart:
///
///     @pragma('dart2js:resource-identifer')
///     Resource getResource(String group, int index) { ... }
///
/// .../my_resources.dart:
///
///       ...
///       getResource('group1', 1);
///       ...
///       getResource('group2', 2);
///       ...
///       getResource('group1', 10);    // optimized away.
///       ...
///       getResource('group1', 100);
///       ...
///       getResource('group1', 1000);  // optimized away.
///       ...
///       getResource('group1', 1001);
///
///
/// Some of the calls above are tree-shaken. Some are placed in one 'part' file
/// and the others in a different 'part' file. The generated resources file
/// contains the constant arguments to the calls, arranged by resource identifer
/// and 'part' file.
///
/// `main.js.resources.json`:
/// ```json
/// {...
///  "environment": {     // Command-line environment
///      "foo": "bar",    //   -Dfoo=bar
///   }
///  "identifiers": [
///     {"name": "getResource",
///      "uri": ".../foo_resource.dart",
///      "nonconstant": false, // No calls without a constant.
///      "files": [
///         {"filename": "main.js_13.part.js",
///          "references": [
///             {"1": "group1", "2": 1},
///             {"1": "group1", "2": 1001},
///             {"1": "group2", "2": 2}
///            ]}
///         {"filename": "main.js_282.part.js",
///          "references": [
///             {"1": "group1", "2": 100},
///            ]}
///        ]},
///     -- next identifer
///    ]
/// }
/// ```
///
/// To appear in the output, arguments must be primitive constants i.e. int,
/// double, String, bool, null. Other constants (e.g. enums, const objects) will
/// simply be missing as though they were not constants.

library js_emitter.resource_info_emitter;

import 'dart:convert' show jsonDecode;
import 'dart:io' show Platform;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import '../js/js.dart' as js;
import '../universe/resource_identifier.dart'
    show ResourceIdentifier, ResourceIdentifierLocation;

class _AnnotationMonitor implements js.JavaScriptAnnotationMonitor {
  final ResourceInfoCollector _collector;
  final String _filename;
  _AnnotationMonitor(this._collector, this._filename);

  @override
  void onAnnotations(List<Object> annotations) {
    for (Object annotation in annotations) {
      if (annotation is ResourceIdentifier) {
        _collector._register(_filename, annotation);
      }
    }
  }
}

class ResourceInfoCollector {
  final Map<_ResourceIdentifierKey, _ResourceIdentifierInfo> _identifierMap =
      {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  void _register(String filename, ResourceIdentifier identifier) {
    final key = _ResourceIdentifierKey(identifier.name, identifier.uri);
    final info = _identifierMap[key] ??= _ResourceIdentifierInfo(key);
    if (identifier.nonconstant) info.nonconstant = true;
    (info._files[filename] ??= []).add(identifier);
  }

  Object finish(Map<String, String> environment) {
    Map<String, Object> json = {
      '_comment': r'Resources referenced by annotated resource identifers',
      'AppTag': 'TBD',
      'environment': environment,
      'identifiers': _identifierMap.values.toList()
        ..sort(_ResourceIdentifierInfo.compare)
    };
    return json;
  }
}

class _ResourceIdentifierKey {
  final String name;
  final Uri uri;

  _ResourceIdentifierKey(this.name, this.uri);

  @override
  bool operator ==(Object other) =>
      other is _ResourceIdentifierKey && name == other.name && uri == other.uri;

  @override
  late final int hashCode = Object.hash(name, uri);
}

class _ResourceIdentifierInfo {
  final _ResourceIdentifierKey _key;
  bool nonconstant = false;
  final Map<String, List<ResourceIdentifier>> _files = {};
  _ResourceIdentifierInfo(this._key);

  static int compare(_ResourceIdentifierInfo a, _ResourceIdentifierInfo b) {
    int r = a._key.name.compareTo(b._key.name);
    if (r != 0) return r;
    return a._key.uri.toString().compareTo(b._key.uri.toString());
  }

  Map<String, dynamic> toJson() {
    final files = _files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      "name": _key.name,
      "uri": _key.uri.toString(),
      "nonconstant": nonconstant,
      "files": [
        for (final entry in files)
          {
            "filename": entry.key,
            "references": [
              for (final resourceIdentifier in entry.value)
                {
                  if (resourceIdentifier.location != null)
                    '@': _locationToJson(resourceIdentifier.location!),
                  ...jsonDecode(resourceIdentifier.arguments)
                }
            ]
          }
      ]
    };
  }

  Map<String, dynamic> _locationToJson(ResourceIdentifierLocation location) {
    return {
      'uri': fe.relativizeUri(Uri.base, location.uri, Platform.isWindows),
      if (location.line != null) 'line': location.line,
      if (location.column != null) 'column': location.column,
    };
  }
}
