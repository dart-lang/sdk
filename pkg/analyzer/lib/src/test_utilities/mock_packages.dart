// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/// Helper for creating mock packages.
class MockPackages {
  /// Create a fake 'angular' package that can be used by tests.
  static void addAngularMetaPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('angular_meta.dart').writeAsStringSync(r'''
library angular.meta;

const _VisibleForTemplate visibleForTemplate = const _VisibleForTemplate();

const _VisibleOutsideTemplate visibleOutsideTemplate = const _VisibleOutsideTemplate();

class _VisibleForTemplate {
  const _VisibleForTemplate();
}

class _VisibleOutsideTemplate {
  const _VisibleOutsideTemplate();
}
''');
  }

  /// Create a fake 'ffi' package that can be used by tests.
  static void addFfiPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('ffi.dart').writeAsStringSync(r'''
import 'dart:ffi';

const Allocator calloc = _CallocAllocator();

abstract class Allocator {
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});

  void free(Pointer pointer);
}

final class Utf8 extends Opaque {}

class _CallocAllocator implements Allocator {
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment})
      => throw '';

  @override
  void free(Pointer pointer) => throw '';
}
''');
  }

  /// Create a fake 'js' package that can be used by tests.
  static void addJsPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('js.dart').writeAsStringSync(r'''
library js;

class JS {
  const JS([String js]);
}
''');
  }

  /// Create a fake 'meta' package that can be used by tests.
  static void addMetaPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('meta.dart').writeAsStringSync(r'''
library meta;

import 'meta_meta.dart';

const _AlwaysThrows alwaysThrows = _AlwaysThrows();

@Deprecated('Use the `covariant` modifier instead')
const _Checked checked = _Checked();

const _DoNotStore doNotStore = _DoNotStore();

const _Experimental experimental = _Experimental();

const _Factory factory = _Factory();

const Immutable immutable = Immutable();

const _Internal internal = _Internal();

const _IsTest isTest = _IsTest();

const _IsTestGroup isTestGroup = _IsTestGroup();

const _Literal literal = _Literal();

const _MustBeOverridden mustBeOverridden = _MustBeOverridden();

const _MustCallSuper mustCallSuper = _MustCallSuper();

const _NonVirtual nonVirtual = _NonVirtual();

const _OptionalTypeArgs optionalTypeArgs = _OptionalTypeArgs();

const _Protected protected = _Protected();

@experimental
const _Redeclare redeclare = _Redeclare();

const _Reopen reopen = _Reopen();

const Required required = Required();

const _Sealed sealed = _Sealed();

const UseResult useResult = UseResult();

@Deprecated('No longer has meaning')
const _Virtual virtual = _Virtual();

const _VisibleForOverriding visibleForOverriding = _VisibleForOverriding();

const _VisibleForTesting visibleForTesting = _VisibleForTesting();

class Immutable {
  final String reason;

  const Immutable([this.reason = '']);
}

@Target({
  TargetKind.getter,
  TargetKind.setter,
  TargetKind.method,
})
class _Redeclare {
  const _Redeclare();
}

@Target({
  TargetKind.classType,
  TargetKind.mixinType,
})
class _Reopen {
  const _Reopen();
}

class Required {
  final String reason;

  const Required([this.reason = '']);
}

@Target({
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.topLevelVariable,
})
class UseResult {
  final String reason;

  final String? parameterDefined;

  const UseResult([this.reason = '']) : parameterDefined = null;

  const UseResult.unless({required this.parameterDefined, this.reason = ''});
}

class _AlwaysThrows {
  const _AlwaysThrows();
}

class _Checked {
  const _Checked();
}

@Target({
  TargetKind.classType,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.library,
  TargetKind.method,
})
class _DoNotStore {
  const _DoNotStore();
}

class _Experimental {
  const _Experimental();
}

class _Factory {
  const _Factory();
}

class _Internal {
  const _Internal();
}

class _IsTest {
  const _IsTest();
}

class _IsTestGroup {
  const _IsTestGroup();
}

class _Literal {
  const _Literal();
}

@Target({
  TargetKind.field,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.setter,
})
class _MustBeOverridden {
  const _MustBeOverridden();
}

@Target({
  TargetKind.field,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.setter,
})
class _MustCallSuper {
  const _MustCallSuper();
}

class _NonVirtual {
  const _NonVirtual();
}

@Target({
  TargetKind.classType,
  TargetKind.extension,
  TargetKind.extensionType,
  TargetKind.function,
  TargetKind.method,
  TargetKind.mixinType,
  TargetKind.typedefType,
})
class _OptionalTypeArgs {
  const _OptionalTypeArgs();
}

class _Protected {
  const _Protected();
}

class _Sealed {
  const _Sealed();
}

class _VisibleForOverriding {
  const _VisibleForOverriding();
}

class _VisibleForTesting {
  const _VisibleForTesting();
}
''');
    libFolder.getChildAssumingFile('meta_meta.dart').writeAsStringSync(r'''
library meta_meta;

@Target({TargetKind.classType})
class Target {
  final Set<TargetKind> kinds;
  const Target(this.kinds);
}


class TargetKind {
  const TargetKind._(this.displayString, this.name);

  int get index => values.indexOf(this);

  final String displayString;
  final String name;

  static const classType = TargetKind._('classes', 'classType');
  static const enumType = TargetKind._('enums', 'enumType');
  static const extension = TargetKind._('extensions', 'extension');
  static const extensionType = TargetKind._('extension types', 'extensionType');
  static const field = TargetKind._('fields', 'field');
  static const function = TargetKind._('top-level functions', 'function');
  static const library = TargetKind._('libraries', 'library');
  static const getter = TargetKind._('getters', 'getter');
  static const method = TargetKind._('methods', 'method');
  static const mixinType = TargetKind._('mixins', 'mixinType');
  static const parameter = TargetKind._('parameters', 'parameter');
  static const setter = TargetKind._('setters', 'setter');
  static const topLevelVariable =
      TargetKind._('top-level variables', 'topLevelVariable');
  static const type =
      TargetKind._('types (classes, enums, mixins, or typedefs)', 'type');
  static const typedefType = TargetKind._('typedefs', 'typedefType');

  static const values = [
    classType,
    enumType,
    extension,
    extensionType,
    field,
    function,
    library,
    getter,
    method,
    mixinType,
    parameter,
    setter,
    topLevelVariable,
    type,
    typedefType,
  ];

  @override
  String toString() => 'TargetKind.$name';
}
''');
  }
}
