// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// The outcome of looking up the getter or the setter of a property.
enum LookupOutcome {
  /// The lookup succeeded.
  ///
  /// The element is still `null` when the receiver needs none, for example
  /// for `dynamicTarget.foo`, or `functionTyped.call`.
  resolved,

  /// Nothing was found, and the failure has not been reported yet.
  notFound,

  /// The name is missing, and the parser has already reported it.
  missingName,

  /// More than one applicable extension declares the member, and none of them
  /// is more specific; this has already been reported.
  ambiguousExtensions,

  /// The receiver is potentially nullable, and the unchecked access has
  /// already been reported.
  nullableReceiver;

  /// The outcome of a lookup that produced [element].
  factory LookupOutcome.of(InternalExecutableElement? element) {
    return element != null ? resolved : notFound;
  }
}

/// The result of attempting to resolve an identifier to elements.
class ResolutionResult extends SimpleResolutionResult {
  /// The outcome of looking up [getter2].
  final LookupOutcome getterOutcome;

  /// The outcome of looking up [setter2].
  final LookupOutcome setterOutcome;

  /// The [FunctionType] referenced with `call`.
  final FunctionTypeImpl? callFunctionType;

  /// The field referenced in a [RecordType].
  final RecordTypeFieldImpl? recordField;

  /// Initialize a newly created result to represent resolving a single
  /// reading and / or writing result.
  ResolutionResult({
    super.getter2,
    this.getterOutcome = LookupOutcome.notFound,
    super.setter2,
    this.setterOutcome = LookupOutcome.notFound,
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

class SimpleStaticExtensionResolutionResult {
  /// Returns the single element with the given name.
  ///
  /// Note that the resolution is performed on the name of the member, not on
  /// its basename. Hence, the result is a single member.
  final InternalExecutableElement? member;

  const SimpleStaticExtensionResolutionResult({this.member});
}
