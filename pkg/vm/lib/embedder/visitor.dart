// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:vm/modular/target/vm.dart' show VmTarget;
import 'package:vm/transformations/pragma.dart';

import 'collector.dart';

bool _allowsCall(ParsedEntryPointPragma pragma) =>
    pragma.type == PragmaEntryPointType.Default ||
    pragma.type == PragmaEntryPointType.CallOnly;

bool _allowsGet(ParsedEntryPointPragma pragma) =>
    pragma.type == PragmaEntryPointType.Default ||
    pragma.type == PragmaEntryPointType.GetterOnly;

bool _allowsSet(ParsedEntryPointPragma pragma) =>
    pragma.type == PragmaEntryPointType.Default ||
    pragma.type == PragmaEntryPointType.SetterOnly;

EntryPointShimCollector visitLibrary(
  Component component,
  Library library, {
  CoreTypes? coreTypes,
  bool createUninitializedInstanceMethods = false,
  bool errorOnUnhandledEntryPoints = false,
}) {
  coreTypes ??= CoreTypes(component);
  final collector = EntryPointShimCollector(
    coreTypes,
    errorOnUnhandledEntryPoints,
  );
  final visitor = EntryPointShimVisitor(coreTypes, library, collector);
  component.accept(visitor);
  return visitor.collector;
}

class EntryPointShimVisitor extends RecursiveVisitor {
  final Library _library;
  final EntryPointShimCollector _collector;
  final bool _createUninitializedInstances;
  final PragmaAnnotationParser _pragmaParser;

  EntryPointShimVisitor(
    CoreTypes coreTypes,
    this._library,
    this._collector, {
    bool createUninitializedInstanceMethods = false,
  }) : _createUninitializedInstances = createUninitializedInstanceMethods,
       _pragmaParser = ConstantPragmaAnnotationParser(
         coreTypes,
         VmTarget(const TargetFlags()),
       );

  EntryPointShimCollector get collector => _collector;

  ParsedEntryPointPragma? _entryPointAnnotation(Annotatable node) {
    if ((node as dynamic).enclosingLibrary != _library) {
      return null;
    }

    final pragmas = _pragmaParser
        .parsedPragmas<ParsedEntryPointPragma>(node.annotations)
        .where(
          (p) =>
              p.type != PragmaEntryPointType.Extendable &&
              p.type != PragmaEntryPointType.ImplicitlyExtendable &&
              p.type != PragmaEntryPointType.CanBeOverridden,
        );
    if (pragmas.isEmpty) return null;
    var pragma = pragmas.first;
    if (pragma.type != PragmaEntryPointType.Default) {
      for (final p in pragmas.skip(1)) {
        if (p.type == PragmaEntryPointType.Default) {
          pragma = p;
          break;
        }
        if (p.type != pragma.type) {
          throw "Incompatible non-default pragmas: ${pragma.type} and ${p.type}";
        }
      }
    }
    return pragma;
  }

  @override
  void visitField(Field field) {
    final pragma = _entryPointAnnotation(field);
    if (pragma != null) {
      assert(pragma.type != PragmaEntryPointType.CallOnly);
      assert(!field.isFinal || pragma.type != PragmaEntryPointType.SetterOnly);
      if (_allowsGet(pragma)) {
        _collector.addAll(field.getterReference, {
          EntryPointRole.getter,
          // If the field's value has a Function type, then the value can be
          // both retrieved and invoked using a single Dart_Invoke call.
          if (field.getterType is FunctionType) EntryPointRole.call,
        });
      }
      if (_allowsSet(pragma)) {
        _collector.add(field.setterReference!, EntryPointRole.setter);
      }
    }
    super.visitField(field);
  }

  @override
  void visitConstructor(Constructor constructor) {
    final pragma = _entryPointAnnotation(constructor);
    if (pragma != null) {
      assert(_allowsCall(pragma));
      _collector.addAll(constructor.reference, {
        // Dart_New
        EntryPointRole.allocation,
        // Dart_InvokeConstructor
        if (_createUninitializedInstances) EntryPointRole.initialization,
      });
    }
    super.visitConstructor(constructor);
  }

  @override
  void visitProcedure(Procedure procedure) {
    final pragma = _entryPointAnnotation(procedure);
    if (pragma != null) {
      if (procedure.isGetter) {
        assert(_allowsGet(pragma));
        _collector.addAll(procedure.reference, {
          EntryPointRole.getter,
          // If the returned value has a Function type, then the closure value
          // can be both retrieved and invoked using a single Dart_Invoke call.
          if (procedure.getterType is FunctionType) EntryPointRole.call,
        });
      } else if (procedure.isSetter) {
        assert(_allowsSet(pragma));
        // Treat the procedure the same as a field, since both are accessed via
        // Dart_SetField.
        _collector.add(procedure.reference, EntryPointRole.setter);
      } else if (procedure.isFactory) {
        assert(_allowsCall(pragma));
        _collector.add(procedure.reference, EntryPointRole.call);
      } else {
        _collector.addAll(procedure.reference, {
          if (_allowsCall(pragma)) EntryPointRole.call,
          if (_allowsGet(pragma)) EntryPointRole.closure,
        });
      }
    }
    super.visitProcedure(procedure);
  }

  @override
  void visitClass(Class cls) {
    final pragma = _entryPointAnnotation(cls);
    if (pragma != null) {
      assert(pragma.type == PragmaEntryPointType.Default);
      final canAllocate = !cls.isAbstract && _createUninitializedInstances;
      _collector.addAll(cls.reference, {
        EntryPointRole.class_,
        EntryPointRole.nonNullableType,
        EntryPointRole.nullableType,
        if (canAllocate) EntryPointRole.allocation,
      });
    }
    super.visitClass(cls);
  }
}
