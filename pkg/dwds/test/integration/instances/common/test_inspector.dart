// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Completer, StreamSubscription;

import 'package:path/path.dart' show basename;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../../fixtures/context.dart';

class TestInspector {
  TestInspector(this.context);
  TestContext context;

  VmService get service => context.debugConnection.vmService;

  Future<void> onBreakPoint(
    Stream<Event> stream,
    String isolateId,
    ScriptRef script,
    String breakPointId,
    Future<void> Function(Event event) body,
  ) async {
    Breakpoint? bp;
    try {
      final line = await context.findBreakpointLine(
        breakPointId,
        isolateId,
        script,
      );
      bp = await service.addBreakpointWithScriptUri(
        isolateId,
        script.uri!,
        line,
      );

      final event = await stream.firstWhere(
        (Event e) => e.kind == EventKind.kPauseBreakpoint,
      );

      await body(event);
    } finally {
      // Remove breakpoint so it doesn't impact other tests or retries.
      if (bp != null) {
        await service.removeBreakpoint(isolateId, bp.id!);
      }
    }
  }

  Future<Map<dynamic, Object?>> getFields(
    String isolateId,
    InstanceRef instanceRef, {
    int? offset,
    int? count,
    int depth = -1,
  }) async {
    final instanceId = instanceRef.id!;

    final result = await service.getObject(
      isolateId,
      instanceId,
      offset: offset,
      count: count,
    );

    expect(result, isA<Instance>());
    final instance = result as Instance;

    expect(
      instance.kind,
      instanceRef.kind,
      reason:
          'object $instanceId with ref kind ${instanceRef.kind} '
          'has an instance kind ${instance.kind}',
    );

    final fields = instance.fields;
    final associations = instance.associations;
    final elements = instance.elements;

    Map<dynamic, InstanceRef>? fieldRefs;
    if (fields != null) {
      fieldRefs = _boundFieldsToMap(fields);
    } else if (associations != null) {
      fieldRefs = _associationsToMap(associations);
    } else if (elements != null) {
      fieldRefs = _elementsToMap(elements);
    } else {
      fieldRefs = {};
    }

    if (depth > 0) {
      depth--;
    }
    if (depth == 0) {
      return fieldRefs;
    }

    final fieldValues = <dynamic, Object?>{};
    for (final p in fieldRefs.entries) {
      fieldValues[p.key] =
          _getValue(p.value) ??
          await getFields(isolateId, p.value, depth: depth);
    }
    return fieldValues;
  }

  Future<Map<String, InstanceRef>> getGetters(
    String isolateId,
    InstanceRef instanceRef,
  ) async {
    final cls =
        await service.getObject(isolateId, instanceRef.classRef!.id!) as Class;
    final getters =
        cls.functions?.where((f) => f.isGetter ?? false).toList() ?? [];

    final results = await Future.wait([
      for (final getter in getters)
        service.evaluate(isolateId, instanceRef.id!, getter.name!),
    ]);

    return Map<String, InstanceRef>.fromIterables(
      getters.map((e) => e.name!),
      results.map((e) => e as InstanceRef),
    );
  }

  Future<InstanceRef> getInstanceRef(
    String isolateId,
    int frame,
    String expression,
  ) async {
    final result = await service.evaluateInFrame(isolateId, frame, expression);
    expect(result, isA<InstanceRef>());
    return result as InstanceRef;
  }

  Future<Instance> getInstance(
    String isolateId,
    int frame,
    String expression,
  ) async {
    final instanceRef = await getInstanceRef(isolateId, frame, expression);

    expect(instanceRef.id, isNotNull);
    final result = await service.getObject(isolateId, instanceRef.id!);

    expect(result, isA<Instance>());
    return result as Instance;
  }

  Future<Map<String?, Instance?>> getFrameVariables(
    String isolateId,
    Frame frame,
  ) async {
    final refs = <String, InstanceRef>{
      for (final variable in frame.vars!)
        variable.name!: variable.value as InstanceRef,
    };
    final instances = <String, Instance>{};
    for (final p in refs.entries) {
      instances[p.key] =
          await service.getObject(isolateId, p.value.id!) as Instance;
    }
    return instances;
  }

  Future<InstanceRef> getDisplayedRef(
    String isolateId,
    String instanceId,
  ) async =>
      await service.invoke(isolateId, instanceId, 'toString', [])
          as InstanceRef;

  Future<Map<dynamic, String?>> getDisplayedFields(
    String isolateId,
    InstanceRef ref,
  ) async {
    final fieldRefs =
        await getFields(isolateId, ref, depth: 1) as Map<dynamic, InstanceRef>;

    Future<String?> toStringValue(InstanceRef ref) async =>
        ref.valueAsString ??
        (await getDisplayedRef(isolateId, ref.id!)).valueAsString;

    final fields = await Future.wait(fieldRefs.values.map(toStringValue));
    return Map<dynamic, String?>.fromIterables(fieldRefs.keys, fields);
  }

  Future<Map<dynamic, String?>> getDisplayedGetters(
    String isolateId,
    InstanceRef ref,
  ) async {
    final fieldRefs =
        await getGetters(isolateId, ref) as Map<dynamic, InstanceRef>;

    Future<String?> toStringValue(InstanceRef ref) async =>
        ref.valueAsString ??
        (await getDisplayedRef(isolateId, ref.id!)).valueAsString;

    final fields = await Future.wait(fieldRefs.values.map(toStringValue));
    return Map<dynamic, String?>.fromIterables(fieldRefs.keys, fields);
  }

  Future<List<Instance>> getElements(
    String isolateId,
    String instanceId,
  ) async {
    final instance = await service.getObject(isolateId, instanceId) as Instance;
    return Future.wait(
      instance.fields!.map(
        (e) async =>
            await service.getObject(isolateId, (e.value as InstanceRef).id!)
                as Instance,
      ),
    );
  }

  Future<String> _locationToString(
    VmService service,
    String isolateId,
    SourceLocation location,
  ) async {
    final script =
        await service.getObject(isolateId, location.script!.id!) as Script;
    final scriptName = basename(script.uri!);
    final tokenPos = location.tokenPos!;
    final line = script.getLineNumberFromTokenPos(tokenPos);
    final column = script.getColumnNumberFromTokenPos(tokenPos);
    return '$scriptName:$line:$column';
  }

  Future<void> runStepIntoThroughProgramRecordingStops(
    String isolateId,

    /// A list to which the pause location is added after each single-step.
    List<String> recordedStops,

    /// A limit on the number of stops to record.
    ///
    /// The program will not be resumed after the length of `recordedStops`
    /// becomes `numStops`.
    int numStops,
  ) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseInterrupted) {
        final isolate = await service.getIsolate(isolateId);
        final frame = isolate.pauseEvent!.topFrame!;
        recordedStops.add(
          await _locationToString(service, isolateId, frame.location!),
        );
        if (recordedStops.length == numStops) {
          await subscription.cancel();
          completer.complete();
        }
        await service.resume(isolateId, step: StepOption.kInto);
      } else if (event.kind == EventKind.kPauseExit) {
        await subscription.cancel();
        completer.complete();
      }
    });
    await service.resume(isolateId, step: StepOption.kInto);
    await completer.future;
  }
}

Map<String, InstanceRef> _associationsToMap(
  Iterable<MapAssociation> associations,
) => Map.fromEntries(
  associations.map(
    (e) =>
        MapEntry((e.key as InstanceRef).valueAsString!, e.value as InstanceRef),
  ),
);

Map<dynamic, InstanceRef> _boundFieldsToMap(Iterable<BoundField> fields) =>
    Map.fromEntries(
      fields
          .where((e) => e.name != null)
          .map((e) => MapEntry(e.name, e.value as InstanceRef)),
    );

Map<dynamic, InstanceRef> _elementsToMap(List<dynamic> fields) =>
    Map.fromEntries(
      fields
          .where((e) => e != null)
          .map((e) => MapEntry(fields.indexOf(e), e as InstanceRef)),
    );

Matcher matchRecordInstanceRef({required int length}) => isA<InstanceRef>()
    .having((e) => e.kind, 'kind', InstanceKind.kRecord)
    .having((e) => e.length, 'length', length)
    .having((e) => e.classRef!, 'classRef', matchRecordClassRef);

Matcher matchRecordTypeInstanceRef({required int length}) => isA<InstanceRef>()
    .having((e) => e.kind, 'kind', InstanceKind.kRecordType)
    .having((e) => e.length, 'length', length)
    .having((e) => e.classRef!, 'classRef', matchRecordTypeClassRef);

Matcher matchTypeInstanceRef(dynamic name) => isA<InstanceRef>()
    .having((e) => e.kind, 'kind', InstanceKind.kType)
    .having((e) => e.name, 'type ref name', name)
    .having((e) => e.classRef, 'classRef', matchTypeClassRef);

Matcher matchPrimitiveInstanceRef({required String kind}) =>
    isA<InstanceRef>().having((e) => e.kind, 'kind', kind);

Matcher matchPrimitiveInstance({
  required String kind,
  required dynamic value,
}) => isA<Instance>()
    .having((e) => e.kind, 'kind', kind)
    .having(_getValue, 'value', value);

Matcher matchPlainInstance({required String libraryId, required String type}) =>
    isA<Instance>()
        .having((e) => e.kind, 'kind', InstanceKind.kPlainInstance)
        .having(
          (e) => e.classRef,
          'classRef',
          matchClassRef(name: type, libraryId: libraryId),
        );

Matcher matchListInstance({required String type}) => isA<Instance>()
    .having((e) => e.kind, 'kind', InstanceKind.kList)
    .having((e) => e.classRef, 'classRef', matchListClassRef(type));

Matcher matchMapInstance({required String type}) => isA<Instance>()
    .having((e) => e.kind, 'kind', InstanceKind.kMap)
    .having((e) => e.classRef, 'classRef', matchMapClassRef(type));

Matcher matchSetInstance({required String type}) => isA<Instance>()
    .having((e) => e.kind, 'kind', InstanceKind.kSet)
    .having((e) => e.classRef, 'classRef', matchSetClassRef(type));

Matcher matchRecordInstance({required int length}) => isA<Instance>()
    .having((e) => e.kind, 'kind', InstanceKind.kRecord)
    .having((e) => e.length, 'length', length)
    .having((e) => e.classRef, 'classRef', matchRecordClassRef);

Matcher matchRecordTypeInstance({required int length}) => isA<Instance>()
    .having((e) => e.kind, 'kind', InstanceKind.kRecordType)
    .having((e) => e.length, 'length', length)
    .having((e) => e.classRef, 'classRef', matchRecordTypeClassRef);

Matcher matchTypeStringInstance(dynamic name) =>
    matchPrimitiveInstance(kind: InstanceKind.kString, value: name);

Matcher matchTypeInstance(dynamic name) => isA<Instance>()
    .having((e) => e.kind, 'kind', InstanceKind.kType)
    .having((e) => e.name, 'type name', name)
    .having((e) => e.classRef, 'classRef', matchTypeClassRef);

Matcher matchRecordClass = matchClass(
  name: matchRecordClassName,
  libraryId: _dartCoreLibrary,
);
Matcher matchTypeClass = matchClass(
  name: matchTypeClassName,
  libraryId: _dartCoreLibrary,
);

/// TODO(annagrin): record type class is reported incorrectly
/// in ddc https://github.com/dart-lang/sdk/issues/54609,
/// remove when fixed.
Matcher matchRecordTypeClass = anyOf(
  matchTypeClass,
  matchClass(name: matchRecordTypeClassName, libraryId: _dartRuntimeLibrary),
);

Matcher matchClass({dynamic name, String? libraryId}) => isA<Class>()
    .having((e) => e.name, 'class name', name)
    .having((e) => e.library, 'library', matchLibraryRef(libraryId));

Matcher matchRecordClassRef = matchClassRef(
  name: matchRecordClassName,
  libraryId: _dartCoreLibrary,
);

/// TODO(annagrin): record type class is reported incorrectly
/// in ddc https://github.com/dart-lang/sdk/issues/54609,
/// remove when fixed.
Matcher matchRecordTypeClassRef = anyOf(
  matchTypeClassRef,
  matchClassRef(name: matchRecordTypeClassName, libraryId: _dartRuntimeLibrary),
);
Matcher matchTypeClassRef = matchClassRef(
  name: matchTypeClassName,
  libraryId: _dartCoreLibrary,
);
Matcher matchListClassRef(String type) => matchClassRef(
  name: matchListClassName(type),
  libraryId: _matchListLibraryName,
);
Matcher matchMapClassRef(String type) =>
    matchClassRef(name: type, libraryId: _dartJsHelperLibrary);
Matcher matchSetClassRef(String type) =>
    matchClassRef(name: type, libraryId: _dartJsHelperLibrary);

Matcher matchClassRef({dynamic name, dynamic libraryId}) => isA<ClassRef>()
    .having((e) => e.name, 'class ref name', name)
    .having((e) => e.library, 'library', matchLibraryRef(libraryId));

Matcher matchLibraryRef(dynamic libraryId) => isA<LibraryRef>()
    .having((e) => e.name, 'library name', libraryId)
    .having((e) => e.id, 'id', libraryId)
    .having((e) => e.uri, 'uri', libraryId);

Object? _getValue(InstanceRef instanceRef) {
  switch (instanceRef.kind) {
    case InstanceKind.kBool:
      return instanceRef.valueAsString == 'true';
    case InstanceKind.kDouble:
    case InstanceKind.kInt:
      return double.parse(instanceRef.valueAsString!);
    case InstanceKind.kString:
      return instanceRef.valueAsString;
    default:
      return null;
  }
}

final _dartCoreLibrary = 'dart:core';
final _dartInterceptorsLibrary = 'dart:_interceptors';
final _dartJsHelperLibrary = 'dart:_js_helper';
final _dartRuntimeLibrary = 'dart:_runtime';

final matchRecordClassName = 'Record';

/// Match types for old and new type systems.
/// - Old type system has
///   - for arrays: `dart:_interceptors|List`
///   - for type: `dart:_runtime|_Type`.
/// - New type system has
///   - for arrays: dart:_interceptors|JSArray`, and
///   - for type: `dart:core|Type`.
/// TODO(annagrin): remove old matchers when DDC enables new type system.
/// TODO(annagrin): `matchTypeClassName` is reported incorrectly
/// in ddc https://github.com/dart-lang/sdk/issues/54609,
final matchTypeClassName = anyOf(['Type', '_Type']);
final matchRecordTypeClassName = 'RecordType';

Matcher matchListClassName(String elementType) =>
    anyOf(['JSArray<$elementType>', 'List<$elementType>']);

final _matchListLibraryName = anyOf([
  _dartInterceptorsLibrary,
  _dartCoreLibrary,
]);
