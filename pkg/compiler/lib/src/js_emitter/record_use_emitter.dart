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

import 'package:record_use/record_use_internal.dart';

import '../elements/entities.dart';
import '../js/js.dart' as js;
import '../universe/recorded_use.dart'
    show
        findInstanceValue,
        RecordedCallWithArguments,
        RecordedConstInstance,
        RecordedTearOff,
        RecordedUse;

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
  final Map<ClassEntity, List<InstanceReference>> instanceMap = {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  void _register(String loadingUnit, RecordedUse recordedUse) {
    switch (recordedUse) {
      case RecordedCallWithArguments():
        final reference = CallWithArguments(
          loadingUnit: loadingUnit,
          namedArguments: recordedUse.namedArgumentsInRecordUseFormat(),
          positionalArguments: recordedUse
              .positionalArgumentsInRecordUseFormat(),
        );
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedTearOff():
        final reference = CallTearoff(loadingUnit: loadingUnit);
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedConstInstance():
        final instanceValue = findInstanceValue(recordedUse.constant);
        final reference = InstanceConstantReference(
          instanceConstant: instanceValue,
          loadingUnit: loadingUnit,
        );
        instanceMap
            .putIfAbsent(recordedUse.constantClass, () => [])
            .add(reference);
        break;
    }
  }

  Map<String, dynamic> finish(Map<String, String> environment) => Recordings(
    metadata: Metadata(
      comment: 'Resources referenced by annotated resource identifiers',
      version: version,
      extension: {'AppTag': 'TBD', 'environment': environment},
    ),
    calls: callMap.map(
      (key, value) => MapEntry(
        Definition(key.library.canonicalUri.toString(), [
          if (key.enclosingClass?.name != null) Name(key.enclosingClass!.name),
          Name(key.name!),
        ]),
        value,
      ),
    ),
    instances: instanceMap.map((key, value) {
      return MapEntry(
        Definition(key.library.canonicalUri.toString(), [Name(key.name)]),
        value,
      );
    }),
  ).toJson();
}
