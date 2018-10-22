// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import '../common_elements.dart' show KCommonElements, KElementEnvironment;
import '../constants/values.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../diagnostics/messages.dart';
import '../elements/entities.dart';
import '../native/native.dart' as native;
import '../serialization/serialization.dart';

/// Returns `true` if parameter and returns types should be trusted for
/// [element].
bool _trustTypeAnnotations(KElementEnvironment elementEnvironment,
    KCommonElements commonElements, MemberEntity element) {
  return _hasAnnotation(elementEnvironment, element,
      commonElements.expectTrustTypeAnnotationsClass);
}

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

/// Process backend specific annotations.
// TODO(johnniwinther): Merge this with [AnnotationProcessor].
AnnotationsData processAnnotations(
    DiagnosticReporter reporter,
    KCommonElements commonElements,
    KElementEnvironment elementEnvironment,
    Iterable<MemberEntity> processedMembers) {
  AnnotationsDataBuilder annotationsDataBuilder = new AnnotationsDataBuilder();

  void processMemberAnnotations(MemberEntity element) {
    bool hasNoInline = false;
    bool hasTryInline = false;

    if (_trustTypeAnnotations(elementEnvironment, commonElements, element)) {
      annotationsDataBuilder.registerTrustTypeAnnotations(element);
    }

    if (_assumeDynamic(elementEnvironment, commonElements, element)) {
      annotationsDataBuilder.registerAssumeDynamic(element);
    }

    // TODO(sra): Check for inappropriate annotations on fields.
    if (element.isField) return;

    FunctionEntity method = element;
    LibraryEntity library = element.library;
    bool platformAnnotationsAllowed = library.canonicalUri.scheme == 'dart' ||
        native.maybeEnableNative(library.canonicalUri);

    bool hasNoThrows = false;
    bool hasNoSideEffects = false;

    for (ConstantValue constantValue
        in elementEnvironment.getMemberMetadata(method)) {
      if (!constantValue.isConstructedObject) continue;
      ConstructedConstantValue value = constantValue;
      ClassEntity cls = value.type.element;
      assert(cls != null); // Unresolved classes null.

      if (platformAnnotationsAllowed) {
        if (cls == commonElements.forceInlineClass) {
          hasTryInline = true;
        } else if (cls == commonElements.noInlineClass) {
          hasNoInline = true;
        } else if (cls == commonElements.noThrowsClass) {
          hasNoThrows = true;
          bool isValid = true;
          if (method.isTopLevel) {
            isValid = true;
          } else if (method.isStatic) {
            isValid = true;
          } else if (method is ConstructorEntity &&
              method.isFactoryConstructor) {
            isValid = true;
          }
          if (!isValid) {
            reporter.internalError(
                method,
                "@NoThrows() is currently limited to top-level"
                " or static functions and factory constructors.");
          }
          annotationsDataBuilder.registerCannotThrow(method);
        } else if (cls == commonElements.noSideEffectsClass) {
          hasNoSideEffects = true;
          annotationsDataBuilder.registerSideEffectsFree(method);
        }
      }

      if (cls == commonElements.expectNoInlineClass) {
        hasNoInline = true;
      } else if (cls == commonElements.metaNoInlineClass) {
        hasNoInline = true;
      } else if (cls == commonElements.metaTryInlineClass) {
        hasTryInline = true;
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
          hasNoInline = true;
        } else if (name == 'dart2js:tryInline') {
          if (!optionsValue.isNull) {
            reporter.reportErrorMessage(element, MessageKind.GENERIC,
                {'text': "@pragma('$name') annotation does not take options"});
          }
          hasTryInline = true;
        } else if (!platformAnnotationsAllowed) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC,
              {'text': "Unknown dart2js pragma @pragma('$name')"});
        } else {
          // Handle platform-only `@pragma` annotations.
        }
      }
    }

    if (hasTryInline && hasNoInline) {
      reporter.reportErrorMessage(element, MessageKind.GENERIC,
          {'text': '@tryInline must not be used with @noInline.'});
      hasTryInline = false;
    }
    if (hasNoInline) {
      annotationsDataBuilder.markAsNonInlinable(method);
    }
    if (hasTryInline) {
      annotationsDataBuilder.markAsTryInline(method);
    }
    if (hasNoThrows && !hasNoInline) {
      reporter.internalError(
          method, "@NoThrows() should always be combined with @noInline.");
    }
    if (hasNoSideEffects && !hasNoInline) {
      reporter.internalError(
          method, "@NoSideEffects() should always be combined with @noInline.");
    }
  }

  for (MemberEntity entity in processedMembers) {
    processMemberAnnotations(entity);
  }

  return annotationsDataBuilder;
}

abstract class AnnotationsData {
  /// Deserializes a [AnnotationsData] object from [source].
  factory AnnotationsData.readFromDataSource(DataSource source) =
      AnnotationsDataImpl.readFromDataSource;

  /// Serializes this [AnnotationsData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Functions with a `@NoInline()` or `@noInline` annotation.
  Iterable<FunctionEntity> get nonInlinableFunctions;

  /// Functions with a `@ForceInline()` or `@tryInline` annotation.
  Iterable<FunctionEntity> get tryInlineFunctions;

  /// Functions with a `@NoThrows()` annotation.
  Iterable<FunctionEntity> get cannotThrowFunctions;

  /// Functions with a `@NoSideEffects()` annotation.
  Iterable<FunctionEntity> get sideEffectFreeFunctions;

  /// Members with a `@TrustTypeAnnotations()` annotation.
  Iterable<MemberEntity> get trustTypeAnnotationsMembers;

  /// Members with a `@AssumeDynamic()` annotation.
  Iterable<MemberEntity> get assumeDynamicMembers;
}

class AnnotationsDataImpl implements AnnotationsData {
  /// Tag used for identifying serialized [AnnotationsData] objects in a
  /// debugging data stream.
  static const String tag = 'annotations-data';

  final Iterable<FunctionEntity> nonInlinableFunctions;
  final Iterable<FunctionEntity> tryInlineFunctions;
  final Iterable<FunctionEntity> cannotThrowFunctions;
  final Iterable<FunctionEntity> sideEffectFreeFunctions;
  final Iterable<MemberEntity> trustTypeAnnotationsMembers;
  final Iterable<MemberEntity> assumeDynamicMembers;

  AnnotationsDataImpl(
      this.nonInlinableFunctions,
      this.tryInlineFunctions,
      this.cannotThrowFunctions,
      this.sideEffectFreeFunctions,
      this.trustTypeAnnotationsMembers,
      this.assumeDynamicMembers);

  factory AnnotationsDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    Iterable<FunctionEntity> nonInlinableFunctions = source.readMembers();
    Iterable<FunctionEntity> tryInlineFunctions = source.readMembers();
    Iterable<FunctionEntity> cannotThrowFunctions = source.readMembers();
    Iterable<FunctionEntity> sideEffectFreeFunctions = source.readMembers();
    Iterable<MemberEntity> trustTypeAnnotationsMembers = source.readMembers();
    Iterable<MemberEntity> assumeDynamicMembers = source.readMembers();
    source.end(tag);
    return new AnnotationsDataImpl(
        nonInlinableFunctions,
        tryInlineFunctions,
        cannotThrowFunctions,
        sideEffectFreeFunctions,
        trustTypeAnnotationsMembers,
        assumeDynamicMembers);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMembers(nonInlinableFunctions);
    sink.writeMembers(tryInlineFunctions);
    sink.writeMembers(cannotThrowFunctions);
    sink.writeMembers(sideEffectFreeFunctions);
    sink.writeMembers(trustTypeAnnotationsMembers);
    sink.writeMembers(assumeDynamicMembers);
    sink.end(tag);
  }
}

class AnnotationsDataBuilder implements AnnotationsData {
  List<FunctionEntity> _nonInlinableFunctions = <FunctionEntity>[];
  List<FunctionEntity> _tryInlinableFunctions = <FunctionEntity>[];
  List<FunctionEntity> _cannotThrowFunctions = <FunctionEntity>[];
  List<FunctionEntity> _sideEffectFreeFunctions = <FunctionEntity>[];
  List<MemberEntity> _trustTypeAnnotationsMembers = <MemberEntity>[];
  List<MemberEntity> _assumeDynamicMembers = <MemberEntity>[];

  void markAsNonInlinable(FunctionEntity function) {
    _nonInlinableFunctions.add(function);
  }

  void markAsTryInline(FunctionEntity function) {
    _tryInlinableFunctions.add(function);
  }

  void registerCannotThrow(FunctionEntity function) {
    _cannotThrowFunctions.add(function);
  }

  void registerSideEffectsFree(FunctionEntity function) {
    _sideEffectFreeFunctions.add(function);
  }

  void registerTrustTypeAnnotations(MemberEntity member) {
    _trustTypeAnnotationsMembers.add(member);
  }

  void registerAssumeDynamic(MemberEntity member) {
    _assumeDynamicMembers.add(member);
  }

  Iterable<FunctionEntity> get nonInlinableFunctions => _nonInlinableFunctions;
  Iterable<FunctionEntity> get tryInlineFunctions => _tryInlinableFunctions;
  Iterable<FunctionEntity> get cannotThrowFunctions => _cannotThrowFunctions;
  Iterable<FunctionEntity> get sideEffectFreeFunctions =>
      _sideEffectFreeFunctions;
  Iterable<MemberEntity> get trustTypeAnnotationsMembers =>
      _trustTypeAnnotationsMembers;
  Iterable<MemberEntity> get assumeDynamicMembers => _assumeDynamicMembers;

  void writeToDataSink(DataSink sink) {
    throw new UnsupportedError('AnnotationsDataBuilder.writeToDataSink');
  }
}
