// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// The result of attempting to resolve an identifier to elements.
class ResolutionResult extends SimpleResolutionResult {
  /// If `true`, then the [getter2] is `null`, and this is an error that has
  /// not yet been reported, and the client should report it.
  ///
  /// If `false`, then the [getter2] is valid. Usually this means that the
  /// correct target has been found. But the [getter2] still might be `null`,
  /// when there was an error, and it has already been reported (e.g. when
  /// ambiguous extension);  or when `null` is the only possible result (e.g.
  /// when `dynamicTarget.foo`, or `functionTyped.call`).
  final bool needsGetterError;

  /// If `true`, the result type must be invalid.
  final bool isGetterInvalid;

  /// If `true`, then the [setter2] is `null`, and this is an error that has
  /// not yet been reported, and the client should report it.
  ///
  /// If `false`, then the [setter2] is valid. Usually this means that the
  /// correct target has been found. But the [setter2] still might be `null`,
  /// when there was an error, and it has already been reported (e.g. when
  /// ambiguous extension);  or when `null` is the only possible result (e.g.
  /// when `dynamicTarget.foo`).
  final bool needsSetterError;

  /// The [FunctionType] referenced with `call`.
  final FunctionTypeImpl? callFunctionType;

  /// The field referenced in a [RecordType].
  final RecordTypeFieldImpl? recordField;

  /// Initialize a newly created result to represent resolving a single
  /// reading and / or writing result.
  ResolutionResult({
    super.getter2,
    this.needsGetterError = true,
    this.isGetterInvalid = false,
    super.setter2,
    this.needsSetterError = true,
    this.callFunctionType,
    this.recordField,
  });
}

class SimpleResolutionResult {
  /// Return the element that is invoked for reading.
  final InternalExecutableElement? getter2;

  /// Return the element that is invoked for writing.
  final InternalExecutableElement? setter2;

  const SimpleResolutionResult({this.getter2, this.setter2});
}
