// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Emitter for recorded uses of definitions annotated with `@RecordUse()`.
///
/// See [documentation](../../../doc/record_uses.md) for examples.
///
/// To appear in the output, arguments must be primitive constants i.e. int,
/// double, String, bool, null. Other constants (e.g. enums, const objects) will
/// simply be missing as though they were not constants.
library;

import 'package:record_use/record_use_internal.dart';

import '../js/js.dart' as js;
import '../universe/recorded_use.dart'
    show RecordedUse, RecordedCallWithArguments, RecordedTearOff;

class _AnnotationMonitor implements js.JavaScriptAnnotationMonitor {
  final RecordUseCollector _collector;
  final String _filename;
  _AnnotationMonitor(this._collector, this._filename);

  @override
  void onAnnotations(List<Object> annotations) {
    for (Object annotation in annotations) {
      if (annotation is RecordedUse) {
        _collector._register(_filename, annotation);
      }
    }
  }
}

class RecordUseCollector {
  final Map<Identifier, List<CallReference>> callMap = {};
  //TODO(mosum): Also register the part file of the definition.
  final Map<Identifier, String> loadingUnits = {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  /// Save a [recordedUse] in the [callMap].
  void _register(String loadingUnit, RecordedUse recordedUse) {
    final identifier = recordedUse.identifier.toPackageRecordUseFormat();
    final callReference = switch (recordedUse) {
      RecordedCallWithArguments() => CallWithArguments(
        loadingUnit: loadingUnit,
        namedArguments: {},
        positionalArguments: recordedUse.arguments,
        location: recordedUse.location,
      ),
      RecordedTearOff() => CallTearOff(
        loadingUnit: loadingUnit,
        location: recordedUse.location,
      ),
    };
    callMap.putIfAbsent(identifier, () => []).add(callReference);
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
