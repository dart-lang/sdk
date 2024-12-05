// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'internal/usage.dart';
import 'internal/usage_record.dart';
import 'public/arguments.dart';
import 'public/identifier.dart';
import 'public/metadata.dart';
import 'public/reference.dart';

extension type RecordedUsages._(UsageRecord _usages) {
  RecordedUsages.fromJson(Map<String, dynamic> json)
      : this._(UsageRecord.fromJson(json));

  /// Show the metadata for this recording of usages.
  Metadata get metadata => _usages.metadata;

  /// Finds all const arguments for calls to the [method].
  ///
  /// The definition must be annotated with `@RecordUse()`. If there are no
  /// calls to the definition, either because it was treeshaken, because it was
  /// not annotated, or because it does not exist, returns `null`.
  ///
  /// Returns an empty iterable if the arguments were not collected.
  ///
  /// Example:
  /// ```dart
  /// import 'package:meta/meta.dart' show ResourceIdentifier;
  /// void main() {
  ///   print(SomeClass.someStaticMethod(42));
  /// }
  ///
  /// class SomeClass {
  ///   @ResourceIdentifier('id')
  ///   static someStaticMethod(int i) {
  ///     return i + 1;
  ///   }
  /// }
  /// ```
  ///
  /// Would mean that
  /// ```
  /// argumentsTo(Identifier(
  ///           uri: 'path/to/file.dart',
  ///           parent: 'SomeClass',
  ///           name: 'someStaticMethod'),
  ///       ).first ==
  ///       Arguments(
  ///         constArguments: ConstArguments(positional: {1: IntConstant(42)}),
  ///       );
  /// ```
  Iterable<Arguments>? argumentsTo(Identifier method) => _callTo(method)
      ?.references
      .map((reference) => reference.arguments)
      .whereType();

  /// Finds all fields of a const instance of the class at [classIdentifier].
  ///
  /// The definition must be annotated with `@RecordUse()`. If there are
  /// no instances of the definition, either because it was treeshaken, because
  /// it was not annotated, or because it does not exist, returns `null`.
  ///
  /// The types of fields supported are defined at
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   print(SomeClass.someStaticMethod(42));
  /// }
  ///
  /// class SomeClass {
  ///   @AnnotationClass('freddie')
  ///   static someStaticMethod(int i) {
  ///     return i + 1;
  ///   }
  /// }
  ///
  /// @ResourceIdentifier()
  /// class AnnotationClass {
  ///   final String s;
  ///   const AnnotationClass(this.s);
  /// }
  /// ```
  ///
  /// Would mean that
  /// ```
  /// instancesOf(Identifier(
  ///           uri: 'path/to/file.dart',
  ///           name: 'AnnotationClass'),
  ///       ).first.instanceConstant ==
  ///       [
  ///         InstanceConstant(fields: {'s': 'freddie'})
  ///       ];
  /// ```
  ///
  /// What kinds of fields can be recorded depends on the implementation of
  /// https://dart-review.googlesource.com/c/sdk/+/369620/13/pkg/vm/lib/transformations/record_use/record_instance.dart
  Iterable<InstanceReference>? instancesOf(Identifier classIdentifier) =>
      _usages.instances
          .firstWhereOrNull(
              (instance) => instance.definition.identifier == classIdentifier)
          ?.references;

  /// Checks if any call to [method] has non-const arguments.
  ///
  /// The definition must be annotated with `@RecordUse()`. If there are no
  /// calls to the definition, either because it was treeshaken, because it was
  /// not annotated, or because it does not exist, returns `false`.
  bool hasNonConstArguments(Identifier method) =>
      _callTo(method)?.references.any(
        (reference) {
          final nonConstArguments = reference.arguments?.nonConstArguments;
          final hasNamed = nonConstArguments?.named.isNotEmpty ?? false;
          final hasPositional =
              nonConstArguments?.positional.isNotEmpty ?? false;
          return hasNamed || hasPositional;
        },
      ) ??
      false;

  Usage<CallReference>? _callTo(Identifier definition) => _usages.calls
      .firstWhereOrNull((call) => call.definition.identifier == definition);
}
