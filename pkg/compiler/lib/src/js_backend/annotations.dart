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

const VERBOSE_OPTIMIZER_HINTS = false;

/// Returns `true` if inlining is disabled for [element].
bool _noInline(KElementEnvironment elementEnvironment,
    KCommonElements commonElements, MemberEntity element) {
  if (_hasAnnotation(
      elementEnvironment, element, commonElements.metaNoInlineClass)) {
    return true;
  }
  if (_hasAnnotation(
      elementEnvironment, element, commonElements.expectNoInlineClass)) {
    // TODO(floitsch): restrict to elements from the test directory.
    return true;
  }
  return _hasAnnotation(
      elementEnvironment, element, commonElements.noInlineClass);
}

/// Returns `true` if inlining is requested for [element].
bool _tryInline(KElementEnvironment elementEnvironment,
    KCommonElements commonElements, MemberEntity element) {
  if (_hasAnnotation(
      elementEnvironment, element, commonElements.metaTryInlineClass)) {
    return true;
  }
  return false;
}

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
    bool hasForceInline = false;

    if (_trustTypeAnnotations(elementEnvironment, commonElements, element)) {
      annotationsDataBuilder.registerTrustTypeAnnotations(element);
    }

    if (_assumeDynamic(elementEnvironment, commonElements, element)) {
      annotationsDataBuilder.registerAssumeDynamic(element);
    }

    if (element.isFunction || element.isConstructor) {
      if (_noInline(elementEnvironment, commonElements, element)) {
        hasNoInline = true;
        annotationsDataBuilder.markAsNonInlinable(element);
      }
      if (_tryInline(elementEnvironment, commonElements, element)) {
        hasForceInline = true;
        if (hasNoInline) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC,
              {'text': '@tryInline must not be used with @noInline.'});
        } else {
          annotationsDataBuilder.markAsTryInline(element);
        }
      }
    }

    if (element.isField) return;
    FunctionEntity method = element;

    LibraryEntity library = method.library;
    if (library.canonicalUri.scheme != 'dart' &&
        !native.maybeEnableNative(library.canonicalUri)) {
      return;
    }

    bool hasNoThrows = false;
    bool hasNoSideEffects = false;
    for (ConstantValue constantValue
        in elementEnvironment.getMemberMetadata(method)) {
      if (!constantValue.isConstructedObject) continue;
      ObjectConstantValue value = constantValue;
      ClassEntity cls = value.type.element;
      if (cls == commonElements.forceInlineClass) {
        hasForceInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Must inline"});
        }
        annotationsDataBuilder.markAsTryInline(method);
      } else if (cls == commonElements.noInlineClass) {
        hasNoInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Cannot inline"});
        }
        annotationsDataBuilder.markAsNonInlinable(method);
      } else if (cls == commonElements.noThrowsClass) {
        hasNoThrows = true;
        bool isValid = true;
        if (method.isTopLevel) {
          isValid = true;
        } else if (method.isStatic) {
          isValid = true;
        } else if (method is ConstructorEntity && method.isFactoryConstructor) {
          isValid = true;
        }
        if (!isValid) {
          reporter.internalError(
              method,
              "@NoThrows() is currently limited to top-level"
              " or static functions and factory constructors.");
        }
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Cannot throw"});
        }
        annotationsDataBuilder.registerCannotThrow(method);
      } else if (cls == commonElements.noSideEffectsClass) {
        hasNoSideEffects = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Has no side effects"});
        }
        annotationsDataBuilder.registerSideEffectsFree(method);
      }
    }
    if (hasForceInline && hasNoInline) {
      reporter.internalError(
          method, "@ForceInline() must not be used with @NoInline.");
    }
    if (hasNoThrows && !hasNoInline) {
      reporter.internalError(
          method, "@NoThrows() should always be combined with @NoInline.");
    }
    if (hasNoSideEffects && !hasNoInline) {
      reporter.internalError(
          method, "@NoSideEffects() should always be combined with @NoInline.");
    }
  }

  for (MemberEntity entity in processedMembers) {
    processMemberAnnotations(entity);
  }

  return annotationsDataBuilder;
}

abstract class AnnotationsData {
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
}
