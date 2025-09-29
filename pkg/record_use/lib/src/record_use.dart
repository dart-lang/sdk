// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../record_use_internal.dart';

/// Holds all information recorded during compilation.
///
/// This can be queried using the methods provided, which each take an
/// [Identifier] which must be annotated with `@RecordUse` from `package:meta`.
extension type RecordedUsages._(Recordings _recordings) {
  RecordedUsages.fromJson(Map<String, Object?> json)
    : this._(Recordings.fromJson(json));

  /// Show the metadata for this recording of usages.
  Metadata get metadata => _recordings.metadata;

  /// Finds all const arguments for calls to the [identifier].
  ///
  /// The definition must be annotated with `@RecordUse()`. If there are no
  /// calls to the definition, either because it was treeshaken, because it was
  /// not annotated, or because it does not exist, returns empty.
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
  ///       [
  ///         {1: 42}
  ///       ]
  /// ```
  Iterable<({Map<String, Object?> named, List<Object?> positional})>
  constArgumentsFor(Identifier identifier) {
    return _recordings.calls[identifier]?.whereType<CallWithArguments>().map(
          (call) => (
            named: call.namedArguments.map(
              (name, argument) => MapEntry(name, argument?.toValue()),
            ),
            positional:
                call.positionalArguments
                    .map((argument) => argument?.toValue())
                    .toList(),
          ),
        ) ??
        [];
  }

  /// Finds all constant fields of a const instance of the class [identifier].
  ///
  /// The definition must be annotated with `@RecordUse()`. If there are
  /// no instances of the definition, either because it was treeshaken, because
  /// it was not annotated, or because it does not exist, returns empty.
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
  /// @RecordUse()
  /// class AnnotationClass {
  ///   final String s;
  ///   const AnnotationClass(this.s);
  /// }
  /// ```
  ///
  /// Would mean that
  /// ```
  /// constantsOf(Identifier(
  ///           uri: 'path/to/file.dart',
  ///           name: 'AnnotationClass'),
  ///       ).first['s'] == 'freddie';
  /// ```
  ///
  /// What kinds of fields can be recorded depends on the implementation of
  /// https://dart-review.googlesource.com/c/sdk/+/369620/13/pkg/vm/lib/transformations/record_use/record_instance.dart
  Iterable<ConstantInstance> constantsOf(Identifier identifier) {
    return _recordings.instances[identifier]?.map(
          (reference) => ConstantInstance(reference.instanceConstant.fields),
        ) ??
        [];
  }

  /// Checks if any call to [identifier] has non-const arguments, or if any
  /// tear-off was recorded.
  ///
  /// The definition must be annotated with `@RecordUse()`. If there are no
  /// calls to the definition, either because it was treeshaken, because it was
  /// not annotated, or because it does not exist, returns `false`.
  bool hasNonConstArguments(Identifier identifier) {
    return (_recordings.calls[identifier] ?? []).any(
      (element) => switch (element) {
        CallTearOff() => true,
        CallWithArguments call => call.positionalArguments.any(
          (argument) => argument == null,
        ),
      },
    );
  }
}

extension type ConstantInstance(Map<String, Constant> _fields) {
  bool hasField(String key) => _fields.containsKey(key);

  Object? operator [](String key) {
    if (!hasField(key)) {
      throw ArgumentError('No field with name $key found.');
    }
    return _fields[key]!.toValue();
  }
}
