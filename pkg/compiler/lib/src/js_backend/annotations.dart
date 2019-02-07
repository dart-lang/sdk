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
import '../serialization/serialization.dart';

/// Returns `true` if inference of parameter types is disabled for [element].
bool _assumeDynamic(KElementEnvironment elementEnvironment,
    KCommonElements commonElements, MemberEntity element) {
  return _hasAnnotation(
      elementEnvironment, element, commonElements.expectAssumeDynamicClass);
}

/// Returns `true` if [element] is annotated with [annotationClass].
bool _hasAnnotation(KElementEnvironment elementEnvironment,
    MemberEntity element, ClassEntity annotationClass) {
  if (annotationClass == null) return false;
  for (ConstantValue value in elementEnvironment.getMemberMetadata(element)) {
    if (value.isConstructedObject) {
      ConstructedConstantValue constructedConstant = value;
      if (constructedConstant.type.element == annotationClass) {
        return true;
      }
    }
  }
  return false;
}

enum PragmaAnnotation {
  noInline,
  tryInline,
  disableFinal,
  noElision,
  noThrows,
  noSideEffects,
  trustTypeAnnotations,
  assumeDynamic,
}

Set<PragmaAnnotation> processMemberAnnotations(
    DiagnosticReporter reporter,
    KCommonElements commonElements,
    KElementEnvironment elementEnvironment,
    AnnotationsDataBuilder annotationsDataBuilder,
    MemberEntity element) {
  Set<PragmaAnnotation> values = new Set<PragmaAnnotation>();
  bool hasNoInline = false;
  bool hasTryInline = false;
  bool disableFinal = false;
  bool noElision = false;

  if (_assumeDynamic(elementEnvironment, commonElements, element)) {
    values.add(PragmaAnnotation.assumeDynamic);
    annotationsDataBuilder.registerAssumeDynamic(element);
  }

  LibraryEntity library = element.library;
  bool platformAnnotationsAllowed = library.canonicalUri.scheme == 'dart' ||
      maybeEnableNative(library.canonicalUri);

  bool hasNoThrows = false;
  bool hasNoSideEffects = false;

  for (ConstantValue constantValue
      in elementEnvironment.getMemberMetadata(element)) {
    if (!constantValue.isConstructedObject) continue;
    ConstructedConstantValue value = constantValue;
    ClassEntity cls = value.type.element;
    assert(cls != null); // Unresolved classes null.

    if (platformAnnotationsAllowed) {
      if (cls == commonElements.forceInlineClass) {
        hasTryInline = true;
        if (element is! FunctionEntity) {
          reporter.internalError(element,
              "@TryInline() is only allowed in methods and constructors.");
        }
      } else if (cls == commonElements.noInlineClass) {
        hasNoInline = true;
        if (element is! FunctionEntity) {
          reporter.internalError(element,
              "@NoInline() is only allowed in methods and constructors.");
        }
      } else if (cls == commonElements.noThrowsClass) {
        hasNoThrows = true;
        bool isValid = true;
        if (element is FunctionEntity) {
          if (element.isTopLevel) {
            isValid = true;
          } else if (element.isStatic) {
            isValid = true;
          } else if (element is ConstructorEntity &&
              element.isFactoryConstructor) {
            isValid = true;
          }
        } else {
          isValid = false;
        }
        if (!isValid) {
          reporter.internalError(
              element,
              "@NoThrows() is currently limited to top-level"
              " or static functions and factory constructors.");
        }
        if (element is FunctionEntity) {
          annotationsDataBuilder.registerCannotThrow(element);
        }
      } else if (cls == commonElements.noSideEffectsClass) {
        hasNoSideEffects = true;
        if (element is FunctionEntity) {
          annotationsDataBuilder.registerSideEffectsFree(element);
        } else {
          reporter.internalError(element,
              "@NoSideEffects() is only allowed in methods and constructors.");
        }
      }
    }

    if (cls == commonElements.expectNoInlineClass) {
      hasNoInline = true;
      if (element is! FunctionEntity) {
        reporter.internalError(element,
            "@NoInline() is only allowed in methods and constructors.");
      }
    } else if (cls == commonElements.metaNoInlineClass) {
      hasNoInline = true;
      if (element is! FunctionEntity) {
        reporter.internalError(
            element, "@noInline is only allowed in methods and constructors.");
      }
    } else if (cls == commonElements.metaTryInlineClass) {
      hasTryInline = true;
      if (element is! FunctionEntity) {
        reporter.internalError(
            element, "@tryInline is only allowed in methods and constructors.");
      }
    } else if (cls == commonElements.pragmaClass) {
      // Recognize:
      //
      //     @pragma('dart2js:noInline')
      //     @pragma('dart2js:tryInline')
      //
      ConstantValue nameValue =
          value.fields[commonElements.pragmaClassNameField];
      if (nameValue == null || !nameValue.isString) continue;
      String name = (nameValue as StringConstantValue).stringValue;
      if (!name.startsWith('dart2js:')) continue;

      ConstantValue optionsValue =
          value.fields[commonElements.pragmaClassOptionsField];
      if (name == 'dart2js:noInline') {
        if (!optionsValue.isNull) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC,
              {'text': "@pragma('$name') annotation does not take options"});
        }
        if (element is! FunctionEntity) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC, {
            'text': "@pragma('$name') annotation is only supported "
                "for methods and constructors."
          });
        }
        hasNoInline = true;
      } else if (name == 'dart2js:tryInline') {
        if (!optionsValue.isNull) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC,
              {'text': "@pragma('$name') annotation does not take options"});
        }
        if (element is! FunctionEntity) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC, {
            'text': "@pragma('$name') annotation is only supported "
                "for methods and constructors."
          });
        }
        hasTryInline = true;
      } else if (!platformAnnotationsAllowed) {
        reporter.reportErrorMessage(element, MessageKind.GENERIC,
            {'text': "Unknown dart2js pragma @pragma('$name')"});
      } else {
        // Handle platform-only `@pragma` annotations.
        if (name == 'dart2js:disableFinal') {
          if (!optionsValue.isNull) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC,
                {'text': "@pragma('$name') annotation does not take options"});
          }
          if (element is! FunctionEntity) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC, {
              'text': "@pragma('$name') annotation is only supported "
                  "for methods and constructors."
            });
          }
          disableFinal = true;
        } else if (name == 'dart2js:noElision') {
          if (!optionsValue.isNull) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC,
                {'text': "@pragma('$name') annotation does not take options"});
          }
          if (element is! FieldEntity) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC, {
              'text': "@pragma('$name') annotation is only supported "
                  "for fields."
            });
          }
          noElision = true;
        } else {
          reporter.reportErrorMessage(element, MessageKind.GENERIC,
              {'text': "Unknown dart2js pragma @pragma('$name')"});
        }
      }
    }
  }

  if (hasTryInline && hasNoInline) {
    reporter.reportErrorMessage(element, MessageKind.GENERIC,
        {'text': '@tryInline must not be used with @noInline.'});
    hasTryInline = false;
  }
  if (hasNoInline) {
    values.add(PragmaAnnotation.noInline);
    if (element is FunctionEntity) {
      annotationsDataBuilder.markAsNonInlinable(element);
    }
  }
  if (hasTryInline) {
    values.add(PragmaAnnotation.tryInline);
    if (element is FunctionEntity) {
      annotationsDataBuilder.markAsTryInline(element);
    }
  }
  if (disableFinal) {
    values.add(PragmaAnnotation.disableFinal);
    if (element is FunctionEntity) {
      annotationsDataBuilder.markAsDisableFinal(element);
    }
  }
  if (noElision) {
    values.add(PragmaAnnotation.noElision);
    if (element is FieldEntity) {
      annotationsDataBuilder.markAsNoElision(element);
    }
  }
  if (hasNoThrows && !hasNoInline) {
    reporter.internalError(
        element, "@NoThrows() should always be combined with @noInline.");
  }
  if (hasNoSideEffects && !hasNoInline) {
    reporter.internalError(
        element, "@NoSideEffects() should always be combined with @noInline.");
  }
  return values;
}

abstract class AnnotationsData {
  /// Deserializes a [AnnotationsData] object from [source].
  factory AnnotationsData.readFromDataSource(DataSource source) =
      AnnotationsDataImpl.readFromDataSource;

  /// Serializes this [AnnotationsData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Functions with a `@NoInline()`, `@noInline`, or
  /// `@pragma('dart2js:noInline')` annotation.
  Iterable<FunctionEntity> get nonInlinableFunctions;

  /// Functions with a `@ForceInline()`, `@tryInline`, or
  /// `@pragma('dart2js:tryInline')` annotation.
  Iterable<FunctionEntity> get tryInlineFunctions;

  /// Functions with a `@pragma('dart2js:disableFinal')` annotation.
  Iterable<FunctionEntity> get disableFinalFunctions;

  /// Fields with a `@pragma('dart2js:noElision')` annotation.
  Iterable<FieldEntity> get noElisionFields;

  /// Functions with a `@NoThrows()` annotation.
  Iterable<FunctionEntity> get cannotThrowFunctions;

  /// Functions with a `@NoSideEffects()` annotation.
  Iterable<FunctionEntity> get sideEffectFreeFunctions;

  /// Members with a `@AssumeDynamic()` annotation.
  Iterable<MemberEntity> get assumeDynamicMembers;
}

class AnnotationsDataImpl implements AnnotationsData {
  /// Tag used for identifying serialized [AnnotationsData] objects in a
  /// debugging data stream.
  static const String tag = 'annotations-data';

  final Iterable<FunctionEntity> nonInlinableFunctions;
  final Iterable<FunctionEntity> tryInlineFunctions;
  final Iterable<FunctionEntity> disableFinalFunctions;
  final Iterable<FieldEntity> noElisionFields;
  final Iterable<FunctionEntity> cannotThrowFunctions;
  final Iterable<FunctionEntity> sideEffectFreeFunctions;
  final Iterable<MemberEntity> assumeDynamicMembers;

  AnnotationsDataImpl(
      this.nonInlinableFunctions,
      this.tryInlineFunctions,
      this.disableFinalFunctions,
      this.noElisionFields,
      this.cannotThrowFunctions,
      this.sideEffectFreeFunctions,
      this.assumeDynamicMembers);

  factory AnnotationsDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    Iterable<FunctionEntity> nonInlinableFunctions =
        source.readMembers<FunctionEntity>(emptyAsNull: true) ??
            const <FunctionEntity>[];
    Iterable<FunctionEntity> tryInlineFunctions =
        source.readMembers<FunctionEntity>(emptyAsNull: true) ??
            const <FunctionEntity>[];
    Iterable<FunctionEntity> disableFinalFunctions =
        source.readMembers<FunctionEntity>(emptyAsNull: true) ??
            const <FunctionEntity>[];
    Iterable<FieldEntity> noElisionFields =
        source.readMembers<FieldEntity>(emptyAsNull: true) ??
            const <FieldEntity>[];
    Iterable<FunctionEntity> cannotThrowFunctions =
        source.readMembers<FunctionEntity>(emptyAsNull: true) ??
            const <FunctionEntity>[];
    Iterable<FunctionEntity> sideEffectFreeFunctions =
        source.readMembers<FunctionEntity>(emptyAsNull: true) ??
            const <FunctionEntity>[];
    Iterable<MemberEntity> assumeDynamicMembers =
        source.readMembers<MemberEntity>(emptyAsNull: true) ??
            const <MemberEntity>[];
    source.end(tag);
    return new AnnotationsDataImpl(
        nonInlinableFunctions,
        tryInlineFunctions,
        disableFinalFunctions,
        noElisionFields,
        cannotThrowFunctions,
        sideEffectFreeFunctions,
        assumeDynamicMembers);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMembers(nonInlinableFunctions);
    sink.writeMembers(tryInlineFunctions);
    sink.writeMembers(disableFinalFunctions);
    sink.writeMembers(noElisionFields);
    sink.writeMembers(cannotThrowFunctions);
    sink.writeMembers(sideEffectFreeFunctions);
    sink.writeMembers(assumeDynamicMembers);
    sink.end(tag);
  }
}

class AnnotationsDataBuilder implements AnnotationsData {
  List<FunctionEntity> _nonInlinableFunctions;
  List<FunctionEntity> _tryInlinableFunctions;
  List<FunctionEntity> _disableFinalFunctions;
  List<FieldEntity> _noElisionFields;
  List<FunctionEntity> _cannotThrowFunctions;
  List<FunctionEntity> _sideEffectFreeFunctions;
  List<MemberEntity> _trustTypeAnnotationsMembers;
  List<MemberEntity> _assumeDynamicMembers;

  void markAsNonInlinable(FunctionEntity function) {
    _nonInlinableFunctions ??= <FunctionEntity>[];
    _nonInlinableFunctions.add(function);
  }

  void markAsTryInline(FunctionEntity function) {
    _tryInlinableFunctions ??= <FunctionEntity>[];
    _tryInlinableFunctions.add(function);
  }

  void markAsDisableFinal(FunctionEntity function) {
    _disableFinalFunctions ??= <FunctionEntity>[];
    _disableFinalFunctions.add(function);
  }

  void markAsNoElision(FieldEntity field) {
    _noElisionFields ??= <FieldEntity>[];
    _noElisionFields.add(field);
  }

  void registerCannotThrow(FunctionEntity function) {
    _cannotThrowFunctions ??= <FunctionEntity>[];
    _cannotThrowFunctions.add(function);
  }

  void registerSideEffectsFree(FunctionEntity function) {
    _sideEffectFreeFunctions ??= <FunctionEntity>[];
    _sideEffectFreeFunctions.add(function);
  }

  void registerAssumeDynamic(MemberEntity member) {
    _assumeDynamicMembers ??= <MemberEntity>[];
    _assumeDynamicMembers.add(member);
  }

  Iterable<FunctionEntity> get nonInlinableFunctions =>
      _nonInlinableFunctions ?? const <FunctionEntity>[];
  Iterable<FunctionEntity> get tryInlineFunctions =>
      _tryInlinableFunctions ?? const <FunctionEntity>[];
  Iterable<FunctionEntity> get disableFinalFunctions =>
      _disableFinalFunctions ?? const <FunctionEntity>[];
  Iterable<FieldEntity> get noElisionFields =>
      _noElisionFields ?? const <FieldEntity>[];
  Iterable<FunctionEntity> get cannotThrowFunctions =>
      _cannotThrowFunctions ?? const <FunctionEntity>[];
  Iterable<FunctionEntity> get sideEffectFreeFunctions =>
      _sideEffectFreeFunctions ?? const <FunctionEntity>[];
  Iterable<MemberEntity> get trustTypeAnnotationsMembers =>
      _trustTypeAnnotationsMembers ?? const <MemberEntity>[];
  Iterable<MemberEntity> get assumeDynamicMembers =>
      _assumeDynamicMembers ?? const <MemberEntity>[];

  void writeToDataSink(DataSink sink) {
    throw new UnsupportedError('AnnotationsDataBuilder.writeToDataSink');
  }
}
