// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import '../common_elements.dart' show KCommonElements, KElementEnvironment;
import '../constants/values.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../diagnostics/messages.dart';
import '../elements/entities.dart';
import '../kernel/dart2js_target.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../util/enumset.dart';

class PragmaAnnotation {
  final int _index;
  final String name;
  final bool forFunctionsOnly;
  final bool forFieldsOnly;
  final bool internalOnly;

  const PragmaAnnotation(this._index, this.name,
      {this.forFunctionsOnly: false,
      this.forFieldsOnly: false,
      this.internalOnly: false});

  int get index {
    assert(_index == values.indexOf(this));
    return _index;
  }

  /// Tells the optimizing compiler to not inline the annotated method.
  static const PragmaAnnotation noInline =
      const PragmaAnnotation(0, 'noInline', forFunctionsOnly: true);

  /// Tells the optimizing compiler to always inline the annotated method, if
  /// possible.
  static const PragmaAnnotation tryInline =
      const PragmaAnnotation(1, 'tryInline', forFunctionsOnly: true);

  static const PragmaAnnotation disableFinal = const PragmaAnnotation(
      2, 'disableFinal',
      forFunctionsOnly: true, internalOnly: true);

  static const PragmaAnnotation noElision =
      const PragmaAnnotation(3, 'noElision');

  /// Tells the optimizing compiler that the annotated method cannot throw.
  /// Requires @pragma('dart2js:noInline') to function correctly.
  static const PragmaAnnotation noThrows = const PragmaAnnotation(4, 'noThrows',
      forFunctionsOnly: true, internalOnly: true);

  /// Tells the optimizing compiler that the annotated method has no
  /// side-effects. Allocations don't count as side-effects, since they can be
  /// dropped without changing the semantics of the program.
  ///
  /// Requires @pragma('dart2js:noInline') to function correctly.
  static const PragmaAnnotation noSideEffects = const PragmaAnnotation(
      5, 'noSideEffects',
      forFunctionsOnly: true, internalOnly: true);

  /// Use this as metadata on method declarations to disable closed world
  /// assumptions on parameters, effectively assuming that the runtime arguments
  /// could be any value. Note that the constraints due to static types still
  /// apply.
  static const PragmaAnnotation assumeDynamic = const PragmaAnnotation(
      6, 'assumeDynamic',
      forFunctionsOnly: true, internalOnly: true);

  static const List<PragmaAnnotation> values = [
    noInline,
    tryInline,
    disableFinal,
    noElision,
    noThrows,
    noSideEffects,
    assumeDynamic,
  ];
}

Set<PragmaAnnotation> processMemberAnnotations(
    CompilerOptions options,
    DiagnosticReporter reporter,
    KCommonElements commonElements,
    KElementEnvironment elementEnvironment,
    AnnotationsDataBuilder annotationsDataBuilder,
    MemberEntity element) {
  EnumSet<PragmaAnnotation> values = new EnumSet<PragmaAnnotation>();

  LibraryEntity library = element.library;
  bool platformAnnotationsAllowed = options.testMode ||
      library.canonicalUri.scheme == 'dart' ||
      maybeEnableNative(library.canonicalUri);

  for (ConstantValue constantValue
      in elementEnvironment.getMemberMetadata(element)) {
    if (!constantValue.isConstructedObject) continue;
    ConstructedConstantValue value = constantValue;
    ClassEntity cls = value.type.element;
    assert(cls != null); // Unresolved classes null.

    if (cls == commonElements.metaNoInlineClass) {
      values.add(PragmaAnnotation.noInline);
      if (element is! FunctionEntity) {
        reporter.internalError(
            element, "@noInline is only allowed in methods and constructors.");
      }
    } else if (cls == commonElements.metaTryInlineClass) {
      values.add(PragmaAnnotation.tryInline);
      if (element is! FunctionEntity) {
        reporter.internalError(
            element, "@tryInline is only allowed in methods and constructors.");
      }
    } else if (cls == commonElements.pragmaClass) {
      ConstantValue nameValue =
          value.fields[commonElements.pragmaClassNameField];
      if (nameValue == null || !nameValue.isString) continue;
      String name = (nameValue as StringConstantValue).stringValue;
      String prefix = 'dart2js:';
      if (!name.startsWith(prefix)) continue;
      String suffix = name.substring(prefix.length);

      ConstantValue optionsValue =
          value.fields[commonElements.pragmaClassOptionsField];
      bool found = false;
      for (PragmaAnnotation annotation in PragmaAnnotation.values) {
        if (annotation.name == suffix) {
          found = true;
          values.add(annotation);

          if (!optionsValue.isNull) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC,
                {'text': "@pragma('$name') annotation does not take options"});
          }
          if (annotation.forFunctionsOnly) {
            if (element is! FunctionEntity) {
              reporter.reportErrorMessage(element, MessageKind.GENERIC, {
                'text': "@pragma('$name') annotation is only supported "
                    "for methods and constructors."
              });
            }
          }
          if (annotation.forFieldsOnly) {
            if (element is! FieldEntity) {
              reporter.reportErrorMessage(element, MessageKind.GENERIC, {
                'text': "@pragma('$name') annotation is only supported "
                    "for fields."
              });
            }
          }
          if (annotation.internalOnly && !platformAnnotationsAllowed) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC,
                {'text': "Unrecognized dart2js pragma @pragma('$name')"});
          }
          break;
        }
      }
      if (!found) {
        reporter.reportErrorMessage(element, MessageKind.GENERIC,
            {'text': "Unknown dart2js pragma @pragma('$name')"});
      }
    }
  }

  if (values.contains(PragmaAnnotation.tryInline) &&
      values.contains(PragmaAnnotation.noInline)) {
    reporter.reportErrorMessage(element, MessageKind.GENERIC,
        {'text': '@tryInline must not be used with @noInline.'});
    values.remove(PragmaAnnotation.tryInline);
  }
  if (values.contains(PragmaAnnotation.noThrows) &&
      !values.contains(PragmaAnnotation.noInline)) {
    reporter.internalError(
        element, "@NoThrows() should always be combined with @noInline.");
  }
  if (values.contains(PragmaAnnotation.noSideEffects) &&
      !values.contains(PragmaAnnotation.noInline)) {
    reporter.internalError(
        element, "@NoSideEffects() should always be combined with @noInline.");
  }
  annotationsDataBuilder.registerPragmaAnnotations(element, values);
  return new Set<PragmaAnnotation>.from(
      values.iterable(PragmaAnnotation.values));
}

abstract class AnnotationsData {
  /// Deserializes a [AnnotationsData] object from [source].
  factory AnnotationsData.readFromDataSource(DataSource source) =
      AnnotationsDataImpl.readFromDataSource;

  /// Serializes this [AnnotationsData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Returns `true` if [member] has an `@pragma('dart2js:assumeDynamic')` annotation.
  bool hasAssumeDynamic(MemberEntity member);

  /// Returns `true` if [member] has a `@noInline`, or
  /// `@pragma('dart2js:noInline')` annotation.
  bool hasNoInline(MemberEntity member);

  /// Returns `true` if [member] has a `@tryInline`, or
  /// `@pragma('dart2js:tryInline')` annotation.
  bool hasTryInline(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:disableFinal')`
  /// annotation.
  bool hasDisableFinal(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:noElision')`
  /// annotation.
  bool hasNoElision(MemberEntity member);

  /// Returns `true` if [member] has a `@NoThrows()` annotation.
  bool hasNoThrows(MemberEntity member);

  /// Returns `true` if [member] has a `@NoSideEffects()` annotation.
  bool hasNoSideEffects(MemberEntity member);

  /// Calls [f] for all functions with a `@noInline`, or
  /// `@pragma('dart2js:noInline')` annotation.
  void forEachNoInline(void f(FunctionEntity function));

  /// Calls [f] for all functions with a `@tryInline`, or
  /// `@pragma('dart2js:tryInline')` annotation.
  void forEachTryInline(void f(FunctionEntity function));

  /// Calls [f] for all functions with a `@pragma('dart2js:noThrows')`
  /// annotation.
  void forEachNoThrows(void f(FunctionEntity function));

  /// Calls [f] for all functions with a `@pragma('dart2js:noSideEffects')`
  /// annotation.
  void forEachNoSideEffects(void f(FunctionEntity function));
}

class AnnotationsDataImpl implements AnnotationsData {
  /// Tag used for identifying serialized [AnnotationsData] objects in a
  /// debugging data stream.
  static const String tag = 'annotations-data';

  final Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations;

  AnnotationsDataImpl(this.pragmaAnnotations);

  factory AnnotationsDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations =
        source.readMemberMap(() => new EnumSet.fromValue(source.readInt()));
    source.end(tag);
    return new AnnotationsDataImpl(pragmaAnnotations);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberMap(pragmaAnnotations, (EnumSet<PragmaAnnotation> set) {
      sink.writeInt(set.value);
    });
    sink.end(tag);
  }

  bool _hasPragma(MemberEntity member, PragmaAnnotation annotation) {
    EnumSet<PragmaAnnotation> set = pragmaAnnotations[member];
    return set != null && set.contains(annotation);
  }

  bool hasAssumeDynamic(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.assumeDynamic);

  bool hasNoInline(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noInline);

  bool hasTryInline(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.tryInline);

  bool hasDisableFinal(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.disableFinal);

  bool hasNoElision(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noElision);

  bool hasNoThrows(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noThrows);

  bool hasNoSideEffects(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noSideEffects);

  void forEachNoInline(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.noInline)) {
        f(member);
      }
    });
  }

  void forEachTryInline(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.tryInline)) {
        f(member);
      }
    });
  }

  void forEachNoThrows(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.noThrows)) {
        f(member);
      }
    });
  }

  void forEachNoSideEffects(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.noSideEffects)) {
        f(member);
      }
    });
  }
}

class AnnotationsDataBuilder {
  Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations = {};

  void registerPragmaAnnotations(
      MemberEntity member, EnumSet<PragmaAnnotation> annotations) {
    if (annotations.isNotEmpty) {
      pragmaAnnotations[member] = annotations;
    }
  }

  AnnotationsData close() {
    return new AnnotationsDataImpl(pragmaAnnotations);
  }
}
