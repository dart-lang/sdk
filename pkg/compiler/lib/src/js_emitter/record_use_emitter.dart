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

// ignore: implementation_imports
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:record_use/record_use_internal.dart';

import '../common/elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
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
  final JElementEnvironment _elementEnvironment;
  RecordUseCollector(this._elementEnvironment);

  final Map<FunctionEntity, List<CallReference>> callMap = {};
  final Map<ClassEntity, List<InstanceReference>> instanceMap = {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  void _register(String loadingUnit, RecordedUse recordedUse) {
    switch (recordedUse) {
      case RecordedCallWithArguments():
        final reference = CallWithArguments(
          loadingUnits: [LoadingUnit(loadingUnit)],
          namedArguments: recordedUse.namedArgumentsInRecordUseFormat(),
          positionalArguments: recordedUse
              .positionalArgumentsInRecordUseFormat(),
        );
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedTearOff():
        final reference = CallTearoff(loadingUnits: [LoadingUnit(loadingUnit)]);
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedConstInstance():
        final instanceValue = findInstanceValue(recordedUse.constant);
        final reference = InstanceConstantReference(
          instanceConstant: instanceValue,
          loadingUnits: [LoadingUnit(loadingUnit)],
        );
        instanceMap
            .putIfAbsent(recordedUse.constantClass, () => [])
            .add(reference);
        break;
    }
  }

  Map<String, dynamic> finish(Map<String, String> environment) => Recordings(
    metadata: Metadata(
      comment:
          'Recorded usages of objects tagged with a `RecordUse` annotation',
      version: version,
      extension: {'AppTag': 'TBD', 'environment': environment},
    ),
    calls: callMap.map((k, v) => MapEntry(_getDefinitionForFunction(k), v)),
    instances: instanceMap.map((key, value) {
      return MapEntry(
        Definition(key.library.canonicalUri.toString(), [
          Name(kind: DefinitionKind.classKind, key.name),
        ]),
        value,
      );
    }),
  ).toJson();

  Definition _getDefinitionForFunction(FunctionEntity function) {
    final libraryUri = function.library.canonicalUri.toString();
    final String name = function.name!;

    DefinitionKind kind = switch (function) {
      _ when function.isGetter => DefinitionKind.getterKind,
      _ when function.isSetter => DefinitionKind.setterKind,
      ConstructorEntity() => DefinitionKind.constructorKind,
      _ => DefinitionKind.methodKind,
    };

    final String? qualifiedExtensionName =
        extractQualifiedNameFromExtensionMethodName(name);
    if (qualifiedExtensionName != null) {
      final List<String> parts = qualifiedExtensionName.split('.');

      var originallyInstance = false;
      _elementEnvironment.forEachParameter(function, (
        DartType type,
        String? name,
        ConstantValue? defaultValue,
      ) {
        if (isExtensionThisName(name)) {
          originallyInstance = true;
        }
      });

      return Definition(libraryUri, [
        Name(
          hasUnnamedExtensionNamePrefix(name) ? '<unnamed>' : parts[0],
          kind: DefinitionKind.extensionKind,
        ),
        Name(
          parts[1],
          kind: kind,
          disambiguators: {
            originallyInstance
                ? DefinitionDisambiguator.instanceDisambiguator
                : DefinitionDisambiguator.staticDisambiguator,
          },
        ),
      ]);
    }

    return Definition(libraryUri, [
      if (function.enclosingClass != null)
        Name(function.enclosingClass!.name, kind: DefinitionKind.classKind),
      Name(
        name,
        kind: kind,
        disambiguators: {
          (function.isStatic || function.isTopLevel)
              ? DefinitionDisambiguator.staticDisambiguator
              : DefinitionDisambiguator.instanceDisambiguator,
        },
      ),
    ]);
  }
}
