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
import 'package:kernel/ast.dart' as ir;
import 'package:record_use/record_use_internal.dart';

import '../common/elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_model/element_map.dart';
import '../js_model/js_world.dart';
import '../universe/recorded_use.dart'
    show
        RecordUseValueConverter,
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
  final JClosedWorld _closedWorld;
  RecordUseCollector(this._closedWorld);

  JsToElementMap get _elementMap => _closedWorld.elementMap;
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  late final RecordUseValueConverter _converter = RecordUseValueConverter(
    _elementEnvironment,
    _closedWorld.annotationsData,
  );

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
          receiver: recordedUse.receiverInRecordUseFormat(_converter),
          namedArguments: recordedUse.namedArgumentsInRecordUseFormat(
            _converter,
          ),
          positionalArguments: recordedUse.positionalArgumentsInRecordUseFormat(
            _converter,
          ),
        );
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedTearOff():
        final reference = CallTearoff(
          loadingUnits: [LoadingUnit(loadingUnit)],
          receiver: recordedUse.receiverInRecordUseFormat(_converter),
        );
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedConstInstance():
        if (_elementEnvironment.isEnumClass(recordedUse.constantClass)) {
          // TODO(https://github.com/dart-lang/native/issues/2908): Support enum
          // constant instances.
          break;
        }
        final instanceValue = _converter.findInstanceValue(
          recordedUse.constant,
        );
        final reference = InstanceConstantReference(
          instanceConstant: instanceValue as InstanceConstant,
          loadingUnits: [LoadingUnit(loadingUnit)],
        );
        instanceMap
            .putIfAbsent(recordedUse.constantClass, () => [])
            .add(reference);
        break;
    }
  }

  Map<String, dynamic> finish() {
    final calls = <Definition, List<CallReference>>{};
    callMap.forEach((k, v) {
      final definition = _getDefinitionForFunction(k);
      // Multiple FunctionEntitys can map to the same Definition, for example
      // an extension member implementation and its extension member tear-off.
      // We merge them here because they represent the same logical member.
      calls.putIfAbsent(definition, () => []).addAll(v);
    });
    return Recordings(
      calls: calls,
      instances: instanceMap.map((key, value) {
        return MapEntry(
          Definition(key.library.canonicalUri.toString(), [
            Name(
              key.name,
              kind: _elementEnvironment.isEnumClass(key)
                  ? DefinitionKind.enumKind
                  : DefinitionKind.classKind,
            ),
          ]),
          value,
        );
      }),
    ).toJson();
  }

  Definition _getDefinitionForFunction(FunctionEntity function) {
    final libraryUri = function.library.canonicalUri.toString();
    final String name = function.name!;

    final node = _elementMap.getMemberDefinition(function).node;
    DefinitionKind kind = DefinitionKind.methodKind;
    if (node is ir.Procedure) {
      if (node.isExtensionMember || node.isExtensionTypeMember) {
        kind = isExtensionMemberTearOff(node)
            ? DefinitionKind.methodKind
            : isExtensionMemberGetter(node)
            ? DefinitionKind.getterKind
            : isExtensionMemberSetter(node)
            ? DefinitionKind.setterKind
            : isExtensionMemberOperator(node)
            ? DefinitionKind.operatorKind
            : DefinitionKind.methodKind;
      } else {
        kind = switch (node.kind) {
          ir.ProcedureKind.Getter => DefinitionKind.getterKind,
          ir.ProcedureKind.Setter => DefinitionKind.setterKind,
          ir.ProcedureKind.Operator => DefinitionKind.operatorKind,
          ir.ProcedureKind.Factory => DefinitionKind.constructorKind,
          ir.ProcedureKind.Method => DefinitionKind.methodKind,
        };
      }
    } else if (function is ConstructorEntity) {
      kind = DefinitionKind.constructorKind;
    }

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
