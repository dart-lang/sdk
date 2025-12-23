// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

import 'meta_meta.dart';

/// The set of compilation units that make up the mock 'meta' package.
final List<MockLibraryUnit> units = [_metaUnit, metaMetaUnit];

final _metaUnit = MockLibraryUnit('lib/meta.dart', r'''
library meta;

import 'meta_meta.dart';

@Deprecated("Use a return type of 'Never' instead")
const _AlwaysThrows alwaysThrows = _AlwaysThrows();

const _AwaitNotRequired awaitNotRequired = _AwaitNotRequired();

@Deprecated('Use the `covariant` modifier instead')
const _Checked checked = _Checked();

const _DoNotStore doNotStore = _DoNotStore();

const _DoNotSubmit doNotSubmit = _DoNotSubmit();

const _Experimental experimental = _Experimental();

const _Factory factory = _Factory();

const Immutable immutable = Immutable();

const _Internal internal = _Internal();

const _IsTest isTest = _IsTest();

const _IsTestGroup isTestGroup = _IsTestGroup();

const _Literal literal = _Literal();

@experimental
const _MustBeConst mustBeConst = _MustBeConst();

const _MustBeOverridden mustBeOverridden = _MustBeOverridden();

const _MustCallSuper mustCallSuper = _MustCallSuper();

const _NonVirtual nonVirtual = _NonVirtual();

const _OptionalTypeArgs optionalTypeArgs = _OptionalTypeArgs();

const _Protected protected = _Protected();

const _Redeclare redeclare = _Redeclare();

const _Reopen reopen = _Reopen();

@Deprecated(
  'In Dart 2.12 and later, use the built-in `required` keyword to mark a '
  'named parameter as required.',
)
const Required required = Required();

const _Sealed sealed = _Sealed();

const UseResult useResult = UseResult();

@Deprecated('No longer has meaning')
const _Virtual virtual = _Virtual();

const _VisibleForOverriding visibleForOverriding = _VisibleForOverriding();

const _VisibleForTesting visibleForTesting = _VisibleForTesting();

@Target({TargetKind.classType, TargetKind.extensionType, TargetKind.mixinType})
class Immutable {
  final String reason;

  const Immutable([this.reason = '']);
}

@experimental
class RecordUse {
  const RecordUse();
}

@Deprecated(
  'In Dart 2.12 and later, use the built-in `required` keyword to mark a '
  'named parameter as required.',
)
class Required {
  final String reason;

  const Required([this.reason = '']);
}

@Target({
  TargetKind.constructor,
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

@Target({
  TargetKind.constructor,
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.topLevelVariable,
})
class _AwaitNotRequired {
  const _AwaitNotRequired();
}

class _Checked {
  const _Checked();
}

@Target({
  TargetKind.classType,
  TargetKind.constructor,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.library,
  TargetKind.method,
  TargetKind.mixinType,
})
class _DoNotStore {
  const _DoNotStore();
}

@Target({
  TargetKind.constructor,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.optionalParameter,
  TargetKind.setter,
  TargetKind.topLevelVariable,
})
class _DoNotSubmit {
  const _DoNotSubmit();
}

class _Experimental {
  const _Experimental();
}

@Target({TargetKind.method})
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

@Target({TargetKind.parameter, TargetKind.extensionType})
class _MustBeConst {
  const _MustBeConst();
}

@Target({TargetKind.overridableMember})
class _MustBeOverridden {
  const _MustBeOverridden();
}

@Target({TargetKind.overridableMember})
class _MustCallSuper {
  const _MustCallSuper();
}

@Target({TargetKind.overridableMember})
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

@Target({TargetKind.getter, TargetKind.setter, TargetKind.method})
class _Redeclare {
  const _Redeclare();
}

@Target({TargetKind.classType, TargetKind.mixinType})
class _Reopen {
  const _Reopen();
}

@Target({TargetKind.classType})
class _Sealed {
  const _Sealed();
}

@Deprecated('No longer has meaning')
class _Virtual {
  const _Virtual();
}

@Target({TargetKind.overridableMember})
class _VisibleForOverriding {
  const _VisibleForOverriding();
}

@Target({
  TargetKind.constructor,
  TargetKind.enumValue,
  TargetKind.extension,
  TargetKind.extensionType,
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.parameter,
  TargetKind.setter,
  TargetKind.typedefType,
  TargetKind.type,
  TargetKind.topLevelVariable,
})
class _VisibleForTesting {
  const _VisibleForTesting();
}
''');
