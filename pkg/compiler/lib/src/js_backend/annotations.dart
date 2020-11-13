// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../diagnostics/messages.dart';
import '../elements/entities.dart';
import '../ir/annotations.dart';
import '../ir/util.dart';
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

  static const PragmaAnnotation asTrust = const PragmaAnnotation(7, 'as:trust',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation asCheck = const PragmaAnnotation(8, 'as:check',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation typesTrust = const PragmaAnnotation(
      9, 'types:trust',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation typesCheck = const PragmaAnnotation(
      10, 'types:check',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation parameterTrust = const PragmaAnnotation(
      11, 'parameter:trust',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation parameterCheck = const PragmaAnnotation(
      12, 'parameter:check',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation downcastTrust = const PragmaAnnotation(
      13, 'downcast:trust',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation downcastCheck = const PragmaAnnotation(
      14, 'downcast:check',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation indexBoundsTrust = const PragmaAnnotation(
      15, 'index-bounds:trust',
      forFunctionsOnly: false, internalOnly: false);

  static const PragmaAnnotation indexBoundsCheck = const PragmaAnnotation(
      16, 'index-bounds:check',
      forFunctionsOnly: false, internalOnly: false);

  static const List<PragmaAnnotation> values = [
    noInline,
    tryInline,
    disableFinal,
    noElision,
    noThrows,
    noSideEffects,
    assumeDynamic,
    asTrust,
    asCheck,
    typesTrust,
    typesCheck,
    parameterTrust,
    parameterCheck,
    downcastTrust,
    downcastCheck,
    indexBoundsTrust,
    indexBoundsCheck,
  ];

  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> implies = {
    typesTrust: {parameterTrust, downcastTrust},
    typesCheck: {parameterCheck, downcastCheck},
  };
  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> excludes = {
    noInline: {tryInline},
    tryInline: {noInline},
    typesTrust: {typesCheck, parameterCheck, downcastCheck},
    typesCheck: {typesTrust, parameterTrust, downcastTrust},
    parameterTrust: {parameterCheck},
    parameterCheck: {parameterTrust},
    downcastTrust: {downcastCheck},
    downcastCheck: {downcastTrust},
    asTrust: {asCheck},
    asCheck: {asTrust},
  };
  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> requires = {
    noThrows: {noInline},
    noSideEffects: {noInline},
  };
}

EnumSet<PragmaAnnotation> processMemberAnnotations(
    CompilerOptions options,
    DiagnosticReporter reporter,
    ir.Member member,
    List<PragmaAnnotationData> pragmaAnnotationData) {
  EnumSet<PragmaAnnotation> annotations = new EnumSet<PragmaAnnotation>();

  Uri uri = member.enclosingLibrary.importUri;
  bool platformAnnotationsAllowed =
      options.testMode || uri.scheme == 'dart' || maybeEnableNative(uri);

  for (PragmaAnnotationData data in pragmaAnnotationData) {
    String name = data.name;
    String suffix = data.suffix;
    bool found = false;
    for (PragmaAnnotation annotation in PragmaAnnotation.values) {
      if (annotation.name == suffix) {
        found = true;
        annotations.add(annotation);

        if (data.hasOptions) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(member),
              MessageKind.GENERIC,
              {'text': "@pragma('$name') annotation does not take options"});
        }
        if (annotation.forFunctionsOnly) {
          if (member is! ir.Procedure && member is! ir.Constructor) {
            reporter.reportErrorMessage(
                computeSourceSpanFromTreeNode(member), MessageKind.GENERIC, {
              'text': "@pragma('$name') annotation is only supported "
                  "for methods and constructors."
            });
          }
        }
        if (annotation.forFieldsOnly) {
          if (member is! ir.Field) {
            reporter.reportErrorMessage(
                computeSourceSpanFromTreeNode(member), MessageKind.GENERIC, {
              'text': "@pragma('$name') annotation is only supported "
                  "for fields."
            });
          }
        }
        if (annotation.internalOnly && !platformAnnotationsAllowed) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(member),
              MessageKind.GENERIC,
              {'text': "Unrecognized dart2js pragma @pragma('$name')"});
        }
        break;
      }
    }
    if (!found) {
      reporter.reportErrorMessage(
          computeSourceSpanFromTreeNode(member),
          MessageKind.GENERIC,
          {'text': "Unknown dart2js pragma @pragma('$name')"});
    }
  }

  Map<PragmaAnnotation, EnumSet<PragmaAnnotation>> reportedExclusions = {};
  for (PragmaAnnotation annotation
      in annotations.iterable(PragmaAnnotation.values)) {
    Set<PragmaAnnotation> implies = PragmaAnnotation.implies[annotation];
    if (implies != null) {
      for (PragmaAnnotation other in implies) {
        if (annotations.contains(other)) {
          reporter.reportHintMessage(
              computeSourceSpanFromTreeNode(member), MessageKind.GENERIC, {
            'text': "@pragma('dart2js:${annotation.name}') implies "
                "@pragma('dart2js:${other.name}')."
          });
        }
      }
    }
    Set<PragmaAnnotation> excludes = PragmaAnnotation.excludes[annotation];
    if (excludes != null) {
      for (PragmaAnnotation other in excludes) {
        if (annotations.contains(other) &&
            !(reportedExclusions[other]?.contains(annotation) ?? false)) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(member), MessageKind.GENERIC, {
            'text': "@pragma('dart2js:${annotation.name}') must not be used "
                "with @pragma('dart2js:${other.name}')."
          });
          (reportedExclusions[annotation] ??= new EnumSet()).add(other);
        }
      }
    }
    Set<PragmaAnnotation> requires = PragmaAnnotation.requires[annotation];
    if (requires != null) {
      for (PragmaAnnotation other in requires) {
        if (!annotations.contains(other)) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(member), MessageKind.GENERIC, {
            'text': "@pragma('dart2js:${annotation.name}') should always be "
                "combined with @pragma('dart2js:${other.name}')."
          });
        }
      }
    }
  }
  return annotations;
}

abstract class AnnotationsData {
  /// Deserializes a [AnnotationsData] object from [source].
  factory AnnotationsData.readFromDataSource(
          CompilerOptions options, DataSource source) =
      AnnotationsDataImpl.readFromDataSource;

  /// Serializes this [AnnotationsData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Returns `true` if [member] has an `@pragma('dart2js:assumeDynamic')` annotation.
  bool hasAssumeDynamic(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:noInline')`, or
  /// `@pragma('dart2js:noInline')` annotation.
  bool hasNoInline(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:tryInline')`, or
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

  /// Calls [f] for all functions with a `@pragma('dart2js:noInline')`, or
  /// `@pragma('dart2js:noInline')` annotation.
  void forEachNoInline(void f(FunctionEntity function));

  /// Calls [f] for all functions with a `@pragma('dart2js:tryInline')`, or
  /// `@pragma('dart2js:tryInline')` annotation.
  void forEachTryInline(void f(FunctionEntity function));

  /// Calls [f] for all functions with a `@pragma('dart2js:noThrows')`
  /// annotation.
  void forEachNoThrows(void f(FunctionEntity function));

  /// Calls [f] for all functions with a `@pragma('dart2js:noSideEffects')`
  /// annotation.
  void forEachNoSideEffects(void f(FunctionEntity function));

  /// What should the compiler do with parameter type assertions in [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  CheckPolicy getParameterCheckPolicy(MemberEntity member);

  /// What should the compiler do with implicit downcasts in [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  CheckPolicy getImplicitDowncastCheckPolicy(MemberEntity member);

  /// What the compiler should do with a boolean value in a condition context
  /// in [member] when the language specification says it is a runtime error for
  /// it to be null.
  ///
  /// If [member] is `null`, the default policy is returned.
  CheckPolicy getConditionCheckPolicy(MemberEntity member);

  /// Whether should the compiler do with explicit casts in [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  CheckPolicy getExplicitCastCheckPolicy(MemberEntity member);

  /// What should the compiler do with index bounds checks `[]`, `[]=` and
  /// `removeLast()` operations in the body of [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  CheckPolicy getIndexBoundsCheckPolicy(MemberEntity member);
}

class AnnotationsDataImpl implements AnnotationsData {
  /// Tag used for identifying serialized [AnnotationsData] objects in a
  /// debugging data stream.
  static const String tag = 'annotations-data';

  final CheckPolicy _defaultParameterCheckPolicy;
  final CheckPolicy _defaultImplicitDowncastCheckPolicy;
  final CheckPolicy _defaultConditionCheckPolicy;
  final CheckPolicy _defaultExplicitCastCheckPolicy;
  final CheckPolicy _defaultIndexBoundsCheckPolicy;
  final Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations;

  AnnotationsDataImpl(CompilerOptions options, this.pragmaAnnotations)
      : this._defaultParameterCheckPolicy = options.defaultParameterCheckPolicy,
        this._defaultImplicitDowncastCheckPolicy =
            options.defaultImplicitDowncastCheckPolicy,
        this._defaultConditionCheckPolicy = options.defaultConditionCheckPolicy,
        this._defaultExplicitCastCheckPolicy =
            options.defaultExplicitCastCheckPolicy,
        this._defaultIndexBoundsCheckPolicy =
            options.defaultIndexBoundsCheckPolicy;

  factory AnnotationsDataImpl.readFromDataSource(
      CompilerOptions options, DataSource source) {
    source.begin(tag);
    Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations =
        source.readMemberMap(
            (MemberEntity member) => new EnumSet.fromValue(source.readInt()));
    source.end(tag);
    return new AnnotationsDataImpl(options, pragmaAnnotations);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberMap(pragmaAnnotations,
        (MemberEntity member, EnumSet<PragmaAnnotation> set) {
      sink.writeInt(set.value);
    });
    sink.end(tag);
  }

  bool _hasPragma(MemberEntity member, PragmaAnnotation annotation) {
    EnumSet<PragmaAnnotation> set = pragmaAnnotations[member];
    return set != null && set.contains(annotation);
  }

  @override
  bool hasAssumeDynamic(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.assumeDynamic);

  @override
  bool hasNoInline(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noInline);

  @override
  bool hasTryInline(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.tryInline);

  @override
  bool hasDisableFinal(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.disableFinal);

  @override
  bool hasNoElision(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noElision);

  @override
  bool hasNoThrows(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noThrows);

  @override
  bool hasNoSideEffects(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.noSideEffects);

  @override
  void forEachNoInline(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.noInline)) {
        f(member);
      }
    });
  }

  @override
  void forEachTryInline(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.tryInline)) {
        f(member);
      }
    });
  }

  @override
  void forEachNoThrows(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.noThrows)) {
        f(member);
      }
    });
  }

  @override
  void forEachNoSideEffects(void f(FunctionEntity function)) {
    pragmaAnnotations
        .forEach((MemberEntity member, EnumSet<PragmaAnnotation> set) {
      if (set.contains(PragmaAnnotation.noSideEffects)) {
        f(member);
      }
    });
  }

  @override
  CheckPolicy getParameterCheckPolicy(MemberEntity member) {
    if (member != null) {
      EnumSet<PragmaAnnotation> annotations = pragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.typesTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.typesCheck)) {
          return CheckPolicy.checked;
        } else if (annotations.contains(PragmaAnnotation.parameterTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.parameterCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultParameterCheckPolicy;
  }

  @override
  CheckPolicy getImplicitDowncastCheckPolicy(MemberEntity member) {
    if (member != null) {
      EnumSet<PragmaAnnotation> annotations = pragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.typesTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.typesCheck)) {
          return CheckPolicy.checked;
        } else if (annotations.contains(PragmaAnnotation.downcastTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.downcastCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultImplicitDowncastCheckPolicy;
  }

  @override
  CheckPolicy getConditionCheckPolicy(MemberEntity member) {
    if (member != null) {
      EnumSet<PragmaAnnotation> annotations = pragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.typesTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.typesCheck)) {
          return CheckPolicy.checked;
        } else if (annotations.contains(PragmaAnnotation.downcastTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.downcastCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultConditionCheckPolicy;
  }

  @override
  CheckPolicy getExplicitCastCheckPolicy(MemberEntity member) {
    if (member != null) {
      EnumSet<PragmaAnnotation> annotations = pragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.asTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.asCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultExplicitCastCheckPolicy;
  }

  @override
  CheckPolicy getIndexBoundsCheckPolicy(MemberEntity member) {
    if (member != null) {
      EnumSet<PragmaAnnotation> annotations = pragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.indexBoundsTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.indexBoundsCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultIndexBoundsCheckPolicy;
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

  AnnotationsData close(CompilerOptions options) {
    return new AnnotationsDataImpl(options, pragmaAnnotations);
  }
}
