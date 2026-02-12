// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Emitter for recorded uses of definitions annotated with `@RecordUse()`.
///
/// See [documentation](../../../doc/record_uses.md) for examples.
///
/// To appear in the output, arguments must be constants i.e. int, String, bool,
/// null, List, Map, or constant objects.
library;

import 'package:compiler/src/elements/entities.dart';
import 'package:record_use/record_use_internal.dart';

import '../js/js.dart' as js;
import '../universe/recorded_use.dart'
    show RecordedCallWithArguments, RecordedTearOff, RecordedUse;

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
  RecordUseCollector();

  final Map<FunctionEntity, List<CallReference>> callMap = {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  void _register(String loadingUnit, RecordedUse recordedUse) {
    if (!recordedUse.function.library.canonicalUri.isScheme('package')) {
      return;
    }
    final callReference = switch (recordedUse) {
      RecordedCallWithArguments() => CallWithArguments(
        loadingUnit: loadingUnit,
        namedArguments: recordedUse.namedArgumentsInRecordUseFormat(),
        positionalArguments: recordedUse.positionalArgumentsInRecordUseFormat(),
      ),
      RecordedTearOff() => CallTearoff(loadingUnit: loadingUnit),
    };
    callMap.putIfAbsent(recordedUse.function, () => []).add(callReference);
  }

  Map<String, dynamic> finish(Map<String, String> environment) => Recordings(
    metadata: Metadata(
      comment: 'Resources referenced by annotated resource identifiers',
      version: version,
      extension: {'AppTag': 'TBD', 'environment': environment},
    ),
    calls: callMap.map(
      (key, value) => MapEntry(
        Definition(
          name: key.name!,
          scope: key.enclosingClass?.name,
          importUri: key.library.canonicalUri.toString(),
        ),
        value,
      ),
    ),
    instances: <Definition, List<InstanceReference>>{},
  ).toJson();
}
