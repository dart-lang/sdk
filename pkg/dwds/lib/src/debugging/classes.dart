// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/debugging/metadata/class.dart';
import 'package:dwds/src/services/chrome/chrome_debug_exception.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Keeps track of Dart classes available in the running application.
class ChromeAppClassHelper {
  /// Map of class ID to [Class].
  final _classes = <String, Class>{};

  final ChromeAppInspector inspector;

  ChromeAppClassHelper(this.inspector) {
    final staticClasses = [
      classRefForClosure,
      classRefForString,
      classRefForUnknown,
    ];
    for (final classRef in staticClasses) {
      final classId = classRef.id;
      if (classId != null) {
        _classes[classId] = Class(
          name: classRef.name,
          isAbstract: false,
          isConst: false,
          library: null,
          interfaces: [],
          fields: [],
          functions: [],
          subclasses: [],
          id: classId,
          traceAllocations: false,
        );
      }
    }
  }

  /// Returns the [Class] that corresponds to the provided [objectId].
  ///
  /// If a corresponding class does not exist it will return null.
  Future<Class?> forObjectId(String objectId) async {
    if (!objectId.startsWith('classes|')) return null;
    var clazz = _classes[objectId];
    if (clazz != null) return clazz;
    final splitId = objectId.split('|');
    final libraryId = splitId[1];
    if (libraryId == 'null') {
      throw UnsupportedError('unknown library: $libraryId');
    }
    final libraryRef = await inspector.libraryRefFor(libraryId);
    if (libraryRef == null) {
      throw Exception('Could not find library: $libraryId');
    }
    final classRef = classRefFor(libraryId, splitId.last);
    clazz = await _constructClass(libraryRef, classRef);
    if (clazz == null) {
      throw Exception('Could not construct class: $classRef');
    }
    return _classes[objectId] = clazz;
  }

  /// Constructs a [Class] instance for the provided [LibraryRef] and
  /// [ClassRef].
  Future<Class?> _constructClass(
    LibraryRef libraryRef,
    ClassRef classRef,
  ) async {
    final libraryUri = libraryRef.uri;
    final className = classRef.name;
    final classId = classRef.id;

    if (libraryUri == null || classId == null || className == null) return null;

    final expression = globalToolConfiguration.loadStrategy.dartRuntimeDebugger
        .getClassMetadataJsExpression(libraryUri, className);
    RemoteObject result;
    try {
      result = await inspector.remoteDebugger.evaluate(
        expression,
        returnByValue: true,
        contextId: await inspector.contextId,
      );
    } on ExceptionDetails catch (e) {
      throw ChromeDebugException(e.json, evalContents: expression);
    }

    final classDescriptor = _mapify(result.value);
    final methodRefs = <FuncRef>[];
    final methodDescriptors = _mapify(classDescriptor['methods']);
    methodDescriptors.forEach((name, descriptor) {
      final methodId = 'methods|$classId|$name';
      final methodDescriptor = _mapify(descriptor);
      methodRefs.add(
        FuncRef(
          id: methodId,
          name: name,
          owner: classRef,
          isConst: methodDescriptor['isConst'] as bool? ?? false,
          isStatic: methodDescriptor['isStatic'] as bool? ?? false,
          implicit: methodDescriptor['isImplicit'] as bool? ?? false,
          isAbstract: methodDescriptor['isAbstract'] as bool? ?? false,
          isGetter: methodDescriptor['isGetter'] as bool? ?? false,
          isSetter: methodDescriptor['isSetter'] as bool? ?? false,
        ),
      );
    });
    final fieldRefs = <FieldRef>[];

    final fieldDescriptors = _mapify(classDescriptor['fields']);
    fieldDescriptors.forEach((name, descriptor) {
      final fieldDescriptor = _mapify(descriptor);
      final classMetaData = ClassMetaData(
        runtimeKind: RuntimeObjectKind.type,
        classRef: classRefFor(
          fieldDescriptor['classLibraryId'] as String?,
          fieldDescriptor['className'] as String?,
        ),
      );

      fieldRefs.add(
        FieldRef(
          name: name,
          owner: classRef,
          declaredType: InstanceRef(
            identityHashCode: createId().hashCode,
            id: createId(),
            kind: classMetaData.kind,
            classRef: classMetaData.classRef,
          ),
          isConst: fieldDescriptor['isConst'] as bool? ?? false,
          isFinal: fieldDescriptor['isFinal'] as bool? ?? false,
          isStatic: fieldDescriptor['isStatic'] as bool? ?? false,
          id: createId(),
        ),
      );
    });

    final superClassLibraryId =
        classDescriptor['superClassLibraryId'] as String?;
    final superClassName = classDescriptor['superClassName'] as String?;
    final superClassRef = superClassName == null
        ? null
        : classRefFor(superClassLibraryId, superClassName);

    // TODO: Implement the rest of these
    // https://github.com/dart-lang/webdev/issues/176.
    return Class(
      name: classRef.name,
      isAbstract: false,
      isConst: false,
      library: libraryRef,
      interfaces: [],
      fields: fieldRefs,
      functions: methodRefs,
      subclasses: [],
      id: classId,
      traceAllocations: false,
      superClass: superClassRef,
    );
  }

  Map<String, dynamic> _mapify(dynamic map) =>
      (map as Map<String, dynamic>?) ?? <String, dynamic>{};
}
