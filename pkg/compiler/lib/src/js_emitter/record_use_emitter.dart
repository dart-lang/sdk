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
import 'package:record_use/record_use.dart';

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
        RecordedInstanceCreation,
        RecordedConstructorTearOff,
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
    _elementMap,
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
          loadingUnit: LoadingUnit(loadingUnit),
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
          loadingUnit: LoadingUnit(loadingUnit),
          receiver: recordedUse.receiverInRecordUseFormat(_converter),
        );
        callMap.putIfAbsent(recordedUse.function, () => []).add(reference);
        break;
      case RecordedConstInstance():
        final instanceValue = _converter.findInstanceValue(
          recordedUse.constant,
        );
        final reference = InstanceConstantReference(
          instanceConstant: instanceValue,
          loadingUnit: LoadingUnit(loadingUnit),
        );
        instanceMap
            .putIfAbsent(recordedUse.constantClass, () => [])
            .add(reference);
        break;
      case RecordedInstanceCreation():
        final reference = InstanceCreationReference(
          definition: _definitionFromMember(recordedUse.constructor),
          loadingUnit: LoadingUnit(loadingUnit),
          namedArguments: recordedUse.namedArguments.map(
            (k, v) => MapEntry(k, _converter.findValueOrNonConst(v)),
          ),
          positionalArguments: recordedUse.positionalArguments
              .map((v) => _converter.findValueOrNonConst(v))
              .toList(),
        );
        instanceMap.putIfAbsent(recordedUse.cls, () => []).add(reference);
        break;
      case RecordedConstructorTearOff():
        final reference = ConstructorTearoffReference(
          definition: _definitionFromMember(recordedUse.constructor),
          loadingUnit: LoadingUnit(loadingUnit),
        );
        instanceMap.putIfAbsent(recordedUse.cls, () => []).add(reference);
        break;
    }
  }

  /// Returns a [Definition] for [cls].
  ///
  /// Currently only works for top-level classes and enums. If support for more
  /// complex definition paths is needed, it should be added here.
  DefinitionWithMembers _definitionFromClass(ClassEntity cls) {
    final library = Library(cls.library.canonicalUri.toString());
    final definition = _elementMap.getClassDefinition(cls);
    final node = definition.node;
    if (_elementEnvironment.isEnumClass(cls)) return Enum(cls.name, library);
    if (node is ir.Class && node.isMixinDeclaration) {
      return Mixin(cls.name, library);
    }
    return Class(cls.name, library);
  }

  /// Returns a [Definition] for [member].
  ///
  /// Currently only works for constructors and factories in top-level classes
  /// and enums. If support for more complex definition paths is needed, it
  /// should be added here.
  Definition _definitionFromMember(MemberEntity member) {
    final cls = member.enclosingClass!;
    final parent = _definitionFromClass(cls);
    final name = member.name!;
    return name.isEmpty
        ? Constructor.unnamed(parent)
        : Constructor(name, parent);
  }

  Map<String, dynamic> finish() {
    final calls = <DefinitionWithStaticCalls, List<CallReference>>{};
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
          _definitionFromClass(key) as DefinitionWithInstances,
          value.toSet().toList(),
        );
      }),
    ).toJson();
  }

  DefinitionWithStaticCalls _getDefinitionForFunction(FunctionEntity function) {
    final node = _elementMap.getMemberDefinition(function).node;
    if (node is ir.Procedure && isTearOffLowering(node)) {
      final target = getConstructorEffectiveTarget(node);
      return _definitionFromMember(_elementMap.getMember(target))
          as DefinitionWithStaticCalls;
    }

    final libraryUri = function.library.canonicalUri.toString();
    final library = Library(libraryUri);
    final String name = function.name!;

    final String? qualifiedExtensionName =
        extractQualifiedNameFromExtensionMethodName(name);
    if (qualifiedExtensionName != null) {
      final List<String> parts = qualifiedExtensionName.split('.');
      final DefinitionWithMembers extension =
          (node is ir.Procedure && node.isExtensionTypeMember)
          ? ExtensionType(parts[0], library)
          : (hasUnnamedExtensionNamePrefix(name)
                ? Extension.unnamed(library)
                : Extension(parts[0], library));

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

      return _createMemberFromFunction(
            function,
            node,
            extension,
            parts[1],
            isInstance: originallyInstance,
          )
          as DefinitionWithStaticCalls;
    }

    final ScopeWithMembers parent = function.enclosingClass != null
        ? _definitionFromClass(function.enclosingClass!)
        : library;

    return _createMemberFromFunction(
          function,
          node,
          parent,
          name,
          isInstance: !(function.isStatic || function.isTopLevel),
        )
        as DefinitionWithStaticCalls;
  }

  Definition _createMemberFromFunction(
    FunctionEntity function,
    ir.Node? node,
    ScopeWithMembers parent,
    String name, {
    required bool isInstance,
  }) => switch (node) {
    ir.Procedure p
        when p.kind == ir.ProcedureKind.Operator ||
            isExtensionMemberOperator(p) =>
      Operator(name, parent as DefinitionWithMembers),
    ir.Procedure p when p.kind == ir.ProcedureKind.Method => Method(
      name,
      parent,
      isInstanceMember: isInstance,
    ),
    ir.Procedure p when p.kind == ir.ProcedureKind.Getter => Getter(
      name,
      parent,
      isInstanceMember: isInstance,
    ),
    ir.Procedure p when p.kind == ir.ProcedureKind.Setter => Setter(
      name,
      parent,
      isInstanceMember: isInstance,
    ),
    ir.Procedure p when p.kind == ir.ProcedureKind.Factory =>
      name.isEmpty
          ? Constructor.unnamed(parent as DefinitionWithMembers)
          : Constructor(name, parent as DefinitionWithMembers),
    _ when function is ConstructorEntity =>
      name.isEmpty
          ? Constructor.unnamed(parent as DefinitionWithMembers)
          : Constructor(name, parent as DefinitionWithMembers),
    _ => throw UnsupportedError('Unsupported member: $node ($function)'),
  };
}
