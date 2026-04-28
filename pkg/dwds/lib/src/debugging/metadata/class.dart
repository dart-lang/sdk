// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/services/chrome/chrome_debug_exception.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const _dartCoreLibrary = 'dart:core';

/// A hard-coded ClassRef for the Closure class.
final classRefForClosure = classRefFor(_dartCoreLibrary, InstanceKind.kClosure);

/// A hard-coded ClassRef for the String class.
final classRefForString = classRefFor(_dartCoreLibrary, InstanceKind.kString);

/// A hard-coded ClassRef for a (non-existent) class called Unknown.
final classRefForUnknown = classRefFor(_dartCoreLibrary, 'Unknown');

/// Returns a [LibraryRef] for the provided library ID and class name.
LibraryRef libraryRefFor(String libraryId) =>
    LibraryRef(id: libraryId, name: libraryId, uri: libraryId);

/// Returns a [ClassRef] for the provided library ID and class name.
ClassRef classRefFor(Object? libraryId, Object? dartName) {
  final library = libraryId as String? ?? _dartCoreLibrary;
  final name = dartName as String?;
  return ClassRef(
    id: classIdFor(library, name),
    name: name,
    library: libraryRefFor(library),
  );
}

String classIdFor(String libraryId, String? name) => 'classes|$libraryId|$name';
String classMetaDataIdFor(ClassRef classRef) =>
    '${classRef.library!.id!}:${classRef.name}';

/// DDC runtime object kind.
///
/// Object kinds are determined using DDC runtime API and
/// are used to translate from JavaScript objects to their
/// vm service protocol representation.
enum RuntimeObjectKind {
  object,
  set,
  list,
  map,
  function,
  record,
  type,
  recordType,
  nativeError,
  nativeObject;

  // TODO(annagrin): Update when built-in parsing is available.
  // We can also implement a faster parser if needed.
  // https://github.com/dart-lang/language/issues/2348
  static final parse = values.byName;

  String toInstanceKind() {
    return switch (this) {
      object || nativeObject || nativeError => InstanceKind.kPlainInstance,
      set => InstanceKind.kSet,
      list => InstanceKind.kList,
      map => InstanceKind.kMap,
      function => InstanceKind.kClosure,
      record => InstanceKind.kRecord,
      type => InstanceKind.kType,
      recordType => InstanceKind.kRecordType,
    };
  }
}

/// Meta data for a remote Dart class in Chrome.
class ClassMetaData {
  /// Runtime object kind.
  final RuntimeObjectKind runtimeKind;

  /// Class id.
  ///
  /// Takes the form of 'libraryId:name'.
  final String id;

  /// Type name for Type instances.
  ///
  /// For example, `int`, `String`, `MyClass`, `List<int>`.
  final String? typeName;

  /// The length of the object, if applicable.
  final int? length;

  /// The dart type name for the object.
  ///
  /// For example, `int`, `List<String>`, `Null`
  String? get dartName => classRef.name;

  /// Class ref for the class metadata.
  final ClassRef classRef;

  /// Instance kind for vm service protocol.
  String get kind => runtimeKind.toInstanceKind();

  factory ClassMetaData({
    Object? typeName,
    Object? length,
    required RuntimeObjectKind runtimeKind,
    required ClassRef classRef,
  }) {
    final id = classMetaDataIdFor(classRef);
    return ClassMetaData._(
      id,
      classRef,
      typeName as String?,
      int.tryParse('$length'),
      runtimeKind,
    );
  }

  ClassMetaData._(
    this.id,
    this.classRef,
    this.typeName,
    this.length,
    this.runtimeKind,
  );
}

/// Metadata helper for objects and class refs.
///
/// Allows to get runtime metadata from DDC runtime
/// and provides functionality to detect some of the
/// runtime kinds of objects.
class ChromeClassMetaDataHelper {
  static final _logger = Logger('ClassMetadata');

  final ChromeAppInspector _inspector;

  /// Runtime object kinds for class refs.
  final _runtimeObjectKinds = <String, RuntimeObjectKind>{};

  ChromeClassMetaDataHelper(this._inspector);

  /// Returns the [ClassMetaData] for the Chrome [remoteObject].
  ///
  /// Returns null if the [remoteObject] is not a Dart class.
  Future<ClassMetaData?> metaDataFor(RemoteObject remoteObject) async {
    try {
      final evalExpression = globalToolConfiguration
          .loadStrategy
          .dartRuntimeDebugger
          .getObjectMetadataJsExpression();

      final result = await _inspector.jsCallFunctionOn(
        remoteObject,
        evalExpression,
        [remoteObject],
        returnByValue: true,
      );
      final metadata = result.value as Map;
      final className = metadata['className'];

      if (className == null) {
        return null;
      }

      final typeName = metadata['typeName'];
      final library = metadata['libraryId'];
      final runtimeKind = RuntimeObjectKind.parse(
        metadata['runtimeKind'] as String,
      );
      final length = metadata['length'];

      final classRef = classRefFor(library, className);
      _addRuntimeObjectKind(classRef, runtimeKind);

      return ClassMetaData(
        typeName: typeName,
        length: length,
        runtimeKind: runtimeKind,
        classRef: classRef,
      );
    } on ChromeDebugException catch (e, s) {
      _logger.fine(
        'Could not create class metadata for ${remoteObject.json}',
        e,
        s,
      );
      return null;
    }
  }

  // Stores runtime object kind for class refs.
  void _addRuntimeObjectKind(ClassRef classRef, RuntimeObjectKind runtimeKind) {
    final id = classRef.id;
    if (id == null) {
      throw StateError('No classRef id for $classRef');
    }
    _runtimeObjectKinds[id] = runtimeKind;
  }

  /// Returns true for non-dart JavaScript classes.
  bool isNativeJsObject(ClassRef? classRef) {
    final id = classRef?.id;
    return id != null &&
        _runtimeObjectKinds[id] == RuntimeObjectKind.nativeObject;
  }

  /// Returns true for non-dart JavaScript classes.
  bool isNativeJsError(ClassRef? classRef) {
    final id = classRef?.id;
    return id != null &&
        _runtimeObjectKinds[id] == RuntimeObjectKind.nativeError;
  }
}
