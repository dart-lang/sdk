// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Emitter for resource identifiers embedded in the program.
///
/// See [documentation](../../../doc/resource_identifiers.md) for examples.
///
/// .../foo_resource.dart:
///
///     @pragma('dart2js:resource-identifier')
///     @pragma('dart2js:noInline')
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
/// contains the constant arguments to the calls, arranged by resource
/// identifier and 'part' file.
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
///     -- next identifier
///    ]
/// }
/// ```
///
/// To appear in the output, arguments must be primitive constants i.e. int,
/// double, String, bool, null. Other constants (e.g. enums, const objects) will
/// simply be missing as though they were not constants.

library;

import 'package:record_use/record_use_internal.dart';

import '../js/js.dart' as js;
import '../universe/resource_identifier.dart' show ResourceIdentifier;

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
  final Map<Identifier, List<CallReference>> callMap = {};
  //TODO(mosum): Also register the part file of the definition.
  final Map<Identifier, String> loadingUnits = {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  /// Save a [resourceIdentifier] in the [callMap].
  void _register(String loadingUnit, ResourceIdentifier resourceIdentifier) {
    final identifier = Identifier(
      importUri: resourceIdentifier.uri.toString(),
      scope: resourceIdentifier.parent,
      name: resourceIdentifier.name,
    );
    callMap
        .putIfAbsent(identifier, () => [])
        .add(
          CallWithArguments(
            loadingUnit: loadingUnit,
            namedArguments: {},
            positionalArguments: resourceIdentifier.arguments,
            location: resourceIdentifier.location,
          ),
        );
  }

  Map<String, dynamic> finish(Map<String, String> environment) => Recordings(
    metadata: Metadata.fromJson({
      'comment': 'Resources referenced by annotated resource identifiers',
      'AppTag': 'TBD',
      'environment': environment,
      "version": version.toString(),
    }),
    callsForDefinition: callMap.map(
      (key, value) => MapEntry(
        Definition(identifier: key, loadingUnit: loadingUnits[key]),
        value,
      ),
    ),
    instancesForDefinition: {},
  ).toJson();
}
