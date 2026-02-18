// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../elements/entities.dart';
import '../ir/annotations.dart';
import '../ir/util.dart';
import '../kernel/dart2js_target.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../util/enumset.dart';

/// `@pragma('dart2js:...')` annotations understood by dart2js.
///
/// Some of these annotations are (documented
/// elsewhere)[pkg/compiler/doc/pragmas.md].
enum PragmaAnnotation {
  /// Tells the optimizing compiler to not inline the annotated method.
  noInline('noInline', forFunctionsOnly: true),

  /// Tells the optimizing compiler to always inline the annotated method, if
  /// possible.
  tryInline('tryInline', forFunctionsOnly: true),

  /// Annotation on a member that tells the optimizing compiler to disable
  /// inlining at call sites within the member.
  disableInlining('disable-inlining'),

  disableFinal('disableFinal', forFunctionsOnly: true, internalOnly: true),
  noElision('noElision'),

  /// Tells the optimizing compiler that the annotated method cannot throw.
  /// Requires @pragma('dart2js:noInline') to function correctly.
  noThrows('noThrows', forFunctionsOnly: true, internalOnly: true),

  /// Tells the optimizing compiler that the annotated method has no
  /// side-effects. Allocations don't count as side-effects, since they can be
  /// dropped without changing the semantics of the program.
  ///
  /// Requires @pragma('dart2js:noInline') to function correctly.
  noSideEffects('noSideEffects', forFunctionsOnly: true, internalOnly: true),

  /// Use this as metadata on method declarations to disable closed world
  /// assumptions on parameters, effectively assuming that the runtime arguments
  /// could be any value. Note that the constraints due to static types still
  /// apply.
  assumeDynamic('assumeDynamic', forFunctionsOnly: true, internalOnly: true),

  asTrust('as:trust', forFunctionsOnly: false, internalOnly: false),
  asCheck('as:check', forFunctionsOnly: false, internalOnly: false),
  typesTrust('types:trust', forFunctionsOnly: false, internalOnly: false),
  typesCheck('types:check', forFunctionsOnly: false, internalOnly: false),
  parameterTrust(
    'parameter:trust',
    forFunctionsOnly: false,
    internalOnly: false,
  ),
  parameterCheck(
    'parameter:check',
    forFunctionsOnly: false,
    internalOnly: false,
  ),
  downcastTrust('downcast:trust', forFunctionsOnly: false, internalOnly: false),
  downcastCheck('downcast:check', forFunctionsOnly: false, internalOnly: false),
  indexBoundsTrust(
    'index-bounds:trust',
    forFunctionsOnly: false,
    internalOnly: false,
  ),
  indexBoundsCheck(
    'index-bounds:check',
    forFunctionsOnly: false,
    internalOnly: false,
  ),

  /// Annotation for a `late` field to omit the checks on the late field. The
  /// annotation is not restricted to a field since it is copied from the field
  /// to the getter and setter.
  // TODO(45682): Make this annotation apply to local and static late variables.
  lateTrust('late:trust'),

  /// Annotation for a `late` field to perform the checks on the late field. The
  /// annotation is not restricted to a field since it is copied from the field
  /// to the getter and setter.
  // TODO(45682): Make this annotation apply to local and static late variables.
  lateCheck('late:check'),

  loadLibraryPriority('load-priority', hasOption: true),
  recordUse('record-use'),

  throwWithoutHelperFrame('stack-starts-at-throw'),

  allowCSE('allow-cse'),
  allowDCE('allow-dce');

  final String name;
  final bool forFunctionsOnly;
  final bool internalOnly;
  final bool hasOption;

  // TODO(sra): Review [forFunctionsOnly]. Fields have implied getters and
  // setters, so some annotations meant only for functions could reasonable be
  // placed on a field to apply to the getter and setter.

  const PragmaAnnotation(
    this.name, {
    this.forFunctionsOnly = false,
    this.internalOnly = false,
    this.hasOption = true,
  });

  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> implies = {
    typesTrust: {parameterTrust, downcastTrust},
    typesCheck: {parameterCheck, downcastCheck},
    recordUse: {noInline},
  };
  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> excludes = {
    noInline: {tryInline},
    tryInline: {noInline, recordUse},
    typesTrust: {typesCheck, parameterCheck, downcastCheck},
    typesCheck: {typesTrust, parameterTrust, downcastTrust},
    parameterTrust: {parameterCheck},
    parameterCheck: {parameterTrust},
    downcastTrust: {downcastCheck},
    downcastCheck: {downcastTrust},
    asTrust: {asCheck},
    asCheck: {asTrust},
    lateTrust: {lateCheck},
    lateCheck: {lateTrust},
    recordUse: {tryInline},
  };
  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> requires = {
    noThrows: {noInline},
    noSideEffects: {noInline},
  };

  static final Map<String, PragmaAnnotation> lookupMap = {
    for (final annotation in values) annotation.name: annotation,
    // Aliases
    'never-inline': noInline,
    'prefer-inline': tryInline,
    'resource-identifier': recordUse,
  };
}

ir.Library _enclosingLibrary(ir.TreeNode node) {
  while (true) {
    if (node is ir.Library) return node;
    if (node is ir.Member) return node.enclosingLibrary;
    node = node.parent!;
  }
}

EnumSet<PragmaAnnotation> processPragmaAnnotations(
  CompilerOptions options,
  DiagnosticReporter reporter,
  ir.Annotatable node,
  List<PragmaAnnotationData> pragmaAnnotationData,
) {
  EnumSet<PragmaAnnotation> annotations = EnumSet<PragmaAnnotation>.empty();

  ir.Library library = _enclosingLibrary(node);
  Uri uri = library.importUri;
  bool platformAnnotationsAllowed =
      options.testMode || uri.isScheme('dart') || maybeEnableNative(uri);

  for (PragmaAnnotationData data in pragmaAnnotationData) {
    String name = data.name;
    String suffix = data.suffix;
    final annotation = PragmaAnnotation.lookupMap[suffix];
    if (annotation != null) {
      annotations = annotations.add(annotation);

      if (data.options != null && !annotation.hasOption) {
        reporter.reportErrorMessage(
          computeSourceSpanFromTreeNode(node),
          MessageKind.generic,
          {'text': "@pragma('$name') annotation does not take options"},
        );
      }
      if (annotation.forFunctionsOnly) {
        if (node is! ir.Procedure && node is! ir.Constructor) {
          reporter.reportErrorMessage(
            computeSourceSpanFromTreeNode(node),
            MessageKind.generic,
            {
              'text':
                  "@pragma('$name') annotation is only supported "
                  "for methods and constructors.",
            },
          );
        }
      }
      if (annotation.internalOnly && !platformAnnotationsAllowed) {
        reporter.reportErrorMessage(
          computeSourceSpanFromTreeNode(node),
          MessageKind.generic,
          {'text': "Unrecognized dart2js pragma @pragma('$name')"},
        );
      }
    } else {
      reporter.reportErrorMessage(
        computeSourceSpanFromTreeNode(node),
        MessageKind.generic,
        {'text': "Unknown dart2js pragma @pragma('$name')"},
      );
    }
  }

  Map<PragmaAnnotation, EnumSet<PragmaAnnotation>> reportedExclusions = {};
  EnumSet<PragmaAnnotation> impliedAnnotations = EnumSet.empty();
  for (PragmaAnnotation annotation in annotations.iterable(
    PragmaAnnotation.values,
  )) {
    Set<PragmaAnnotation>? implies = PragmaAnnotation.implies[annotation];
    if (implies != null) {
      for (PragmaAnnotation other in implies) {
        if (annotations.contains(other)) {
          reporter.reportHintMessage(
            computeSourceSpanFromTreeNode(node),
            MessageKind.generic,
            {
              'text':
                  "@pragma('dart2js:${annotation.name}') implies "
                  "@pragma('dart2js:${other.name}').",
            },
          );
        } else {
          impliedAnnotations = impliedAnnotations.add(other);
        }
      }
    }
    Set<PragmaAnnotation>? excludes = PragmaAnnotation.excludes[annotation];
    if (excludes != null) {
      for (PragmaAnnotation other in excludes) {
        if (annotations.contains(other) &&
            !(reportedExclusions[other]?.contains(annotation) ?? false)) {
          reporter.reportErrorMessage(
            computeSourceSpanFromTreeNode(node),
            MessageKind.generic,
            {
              'text':
                  "@pragma('dart2js:${annotation.name}') must not be used "
                  "with @pragma('dart2js:${other.name}').",
            },
          );
          reportedExclusions.update(
            annotation,
            (exclusions) => exclusions.add(other),
            ifAbsent: () => EnumSet.fromValue(other),
          );
        }
      }
    }
    Set<PragmaAnnotation>? requires = PragmaAnnotation.requires[annotation];
    if (requires != null) {
      for (PragmaAnnotation other in requires) {
        if (!annotations.contains(other)) {
          reporter.reportErrorMessage(
            computeSourceSpanFromTreeNode(node),
            MessageKind.generic,
            {
              'text':
                  "@pragma('dart2js:${annotation.name}') should always be "
                  "combined with @pragma('dart2js:${other.name}').",
            },
          );
        }
      }
    }
  }
  return annotations.union(impliedAnnotations);
}

abstract class AnnotationsData {
  /// Deserializes an [AnnotationsData] object from [source].
  factory AnnotationsData.readFromDataSource(
    CompilerOptions options,
    DiagnosticReporter reporter,
    DataSourceReader source,
  ) = AnnotationsDataImpl.readFromDataSource;

  /// Serializes this [AnnotationsData] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// Returns `true` if [member] has an `@pragma('dart2js:assumeDynamic')`
  /// annotation.
  bool hasAssumeDynamic(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:noInline')` annotation.
  bool hasNoInline(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:tryInline')`
  /// annotation.
  bool hasTryInline(MemberEntity member);

  /// Returns `true` if inlining is disabled at call sites inside [member].
  // TODO(49475): This should be a property of call site, but ssa/builder.dart
  // does not currently always pass the call site ir.TreeNode.
  bool hasDisableInlining(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:disableFinal')`
  /// annotation.
  bool hasDisableFinal(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:noElision')`
  /// annotation.
  bool hasNoElision(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:noThrows')` annotation.
  bool hasNoThrows(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:noSideEffects')`
  /// annotation.
  bool hasNoSideEffects(MemberEntity member);

  /// What the compiler should do with parameter type assertions in [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  // TODO(49475): Need this be nullable?
  CheckPolicy getParameterCheckPolicy(MemberEntity? member);

  /// What the compiler should do with implicit downcasts in [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  // TODO(49475): Need this be nullable?
  CheckPolicy getImplicitDowncastCheckPolicy(MemberEntity? member);

  /// What the compiler should do with a boolean value in a condition context
  /// in [member] when the language specification says it is a runtime error for
  /// it to be null.
  ///
  /// If [member] is `null`, the default policy is returned.
  // TODO(49475): Need this be nullable?
  CheckPolicy getConditionCheckPolicy(MemberEntity? member);

  /// What the compiler should do with explicit casts in [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  // TODO(49475): Need this be nullable?
  CheckPolicy getExplicitCastCheckPolicy(MemberEntity? member);

  /// What the compiler should do with index bounds checks `[]`, `[]=` and
  /// `removeLast()` operations in the body of [member].
  ///
  /// If [member] is `null`, the default policy is returned.
  // TODO(49475): Need this be nullable?
  CheckPolicy getIndexBoundsCheckPolicy(MemberEntity? member);

  /// What the compiler should do with late field checks at a position in the
  /// body of a method. The method is usually the getter or setter for a late
  /// field.
  // If we change our late field lowering to happen later, [node] could be the
  // [ir.Field].
  CheckPolicy getLateVariableCheckPolicyAt(ir.TreeNode node);

  /// The priority to load the specified library with.
  ///
  /// This can be an arbitrary string to be interpreted by the custom deferred
  /// loader.
  String getLoadLibraryPriority(ir.LoadLibrary node);

  /// Determines whether [member] is annotated with `RecordUse()`.
  bool shouldRecordMethodUses(FunctionEntity member);

  /// Returns `true` if instances of [clazz] should be recorded when
  /// used as annotations.
  bool shouldRecordConstInstances(ClassEntity clazz);

  /// Is this node in a context requesting that the captured stack in a `throw`
  /// expression generates extra code to avoid having a runtime helper on the
  /// stack?
  bool throwWithoutHelperFrame(ir.TreeNode node);

  /// Returns `true` if [member] has a `@pragma('dart2js:allow-cse')`
  /// annotation.
  bool allowCSE(MemberEntity member);

  /// Returns `true` if [member] has a `@pragma('dart2js:allow-dce')`
  /// annotation.
  bool allowDCE(MemberEntity member);
}

class AnnotationsDataImpl implements AnnotationsData {
  /// Tag used for identifying serialized [AnnotationsData] objects in a
  /// debugging data stream.
  static const String tag = 'annotations-data';

  final CompilerOptions _options;
  final DiagnosticReporter _reporter;

  final CheckPolicy _defaultParameterCheckPolicy;
  final CheckPolicy _defaultImplicitDowncastCheckPolicy;
  final CheckPolicy _defaultConditionCheckPolicy;
  final CheckPolicy _defaultExplicitCastCheckPolicy;
  final CheckPolicy _defaultIndexBoundsCheckPolicy;
  final CheckPolicy _defaultLateVariableCheckPolicy;
  final bool _defaultDisableInlining;

  /// Pragma annotations for classes.
  final Map<ClassEntity, EnumSet<PragmaAnnotation>> classPragmaAnnotations;

  /// Pragma annotations for members. These are captured for the K-entities and
  /// translated to J-entities.
  // TODO(49475): Change the queries that use [pragmaAnnotation] to use the
  // DirectivesContext so that we can avoid the need for persisting annotations.
  final Map<MemberEntity, EnumSet<PragmaAnnotation>> memberPragmaAnnotations;

  /// Pragma annotation environments for annotatable places in the Kernel
  /// AST. These annotations generated on demand and not precomputed or
  /// persisted.  This map is a cache of the pragma annotation environment and
  /// its enclosing environments.
  // TODO(49475): Periodically clear this map to release references to tree
  // nodes.
  final Map<ir.Annotatable, DirectivesContext> _nodeToContextMap = {};

  /// Root annotation environment that allows similar
  final DirectivesContext _root = DirectivesContext.root();

  AnnotationsDataImpl(
    CompilerOptions options,
    this._reporter,
    this.classPragmaAnnotations,
    this.memberPragmaAnnotations,
  ) : _options = options,
      _defaultParameterCheckPolicy = options.defaultParameterCheckPolicy,
      _defaultImplicitDowncastCheckPolicy =
          options.defaultImplicitDowncastCheckPolicy,
      _defaultConditionCheckPolicy = options.defaultConditionCheckPolicy,
      _defaultExplicitCastCheckPolicy = options.defaultExplicitCastCheckPolicy,
      _defaultIndexBoundsCheckPolicy = options.defaultIndexBoundsCheckPolicy,
      _defaultLateVariableCheckPolicy = CheckPolicy.checked,
      _defaultDisableInlining = options.disableInlining;

  factory AnnotationsDataImpl.readFromDataSource(
    CompilerOptions options,
    DiagnosticReporter reporter,
    DataSourceReader source,
  ) {
    source.begin(tag);
    Map<ClassEntity, EnumSet<PragmaAnnotation>> classPragmaAnnotations = source
        .readClassMap(() => EnumSet.fromRawBits(source.readInt()));
    Map<MemberEntity, EnumSet<PragmaAnnotation>> memberPragmaAnnotations =
        source.readMemberMap(
          (MemberEntity member) => EnumSet.fromRawBits(source.readInt()),
        );
    source.end(tag);
    return AnnotationsDataImpl(
      options,
      reporter,
      classPragmaAnnotations,
      memberPragmaAnnotations,
    );
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeClassMap(classPragmaAnnotations, (EnumSet<PragmaAnnotation> set) {
      sink.writeInt(set.mask.bits);
    });
    sink.writeMemberMap(memberPragmaAnnotations, (
      MemberEntity member,
      EnumSet<PragmaAnnotation> set,
    ) {
      sink.writeInt(set.mask.bits);
    });
    sink.end(tag);
  }

  bool _hasPragma(MemberEntity member, PragmaAnnotation annotation) {
    EnumSet<PragmaAnnotation>? set = memberPragmaAnnotations[member];
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
  bool hasDisableInlining(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.disableInlining) ||
      _defaultDisableInlining;

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
  CheckPolicy getParameterCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = memberPragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.parameterTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.parameterCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultParameterCheckPolicy;
  }

  @override
  CheckPolicy getImplicitDowncastCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = memberPragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.downcastTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.downcastCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultImplicitDowncastCheckPolicy;
  }

  @override
  CheckPolicy getConditionCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = memberPragmaAnnotations[member];
      if (annotations != null) {
        if (annotations.contains(PragmaAnnotation.downcastTrust)) {
          return CheckPolicy.trusted;
        } else if (annotations.contains(PragmaAnnotation.downcastCheck)) {
          return CheckPolicy.checked;
        }
      }
    }
    return _defaultConditionCheckPolicy;
  }

  @override
  CheckPolicy getExplicitCastCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = memberPragmaAnnotations[member];
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
  CheckPolicy getIndexBoundsCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = memberPragmaAnnotations[member];
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

  @override
  CheckPolicy getLateVariableCheckPolicyAt(ir.TreeNode node) {
    return _getLateVariableCheckPolicyAt(_findContext(node));
  }

  CheckPolicy _getLateVariableCheckPolicyAt(DirectivesContext? context) {
    while (context != null) {
      EnumSet<PragmaAnnotation> annotations = context.annotations;
      if (annotations.contains(PragmaAnnotation.lateTrust)) {
        return CheckPolicy.trusted;
      } else if (annotations.contains(PragmaAnnotation.lateCheck)) {
        return CheckPolicy.checked;
      }
      context = context.parent;
    }
    return _defaultLateVariableCheckPolicy;
  }

  DirectivesContext _findContext(ir.TreeNode startNode) {
    final node = _getContextNode(startNode);
    if (node == null) return _root;
    return _nodeToContextMap[node] ??= _getContext(node);
  }

  ir.Annotatable? _getContextNode(ir.TreeNode startNode) {
    ir.TreeNode? node = startNode;
    while (node is! ir.Annotatable) {
      if (node == null) return null;
      node = node.parent;
    }
    return node;
  }

  DirectivesContext _getContext(ir.Annotatable node) {
    return _nodeToContextMap[node] ??= _findContext(node.parent!).extend(
      processPragmaAnnotations(
        _options,
        _reporter,
        node,
        computePragmaAnnotationDataFromIr(node),
      ),
    );
  }

  @override
  String getLoadLibraryPriority(ir.LoadLibrary node) {
    String? getPragmaOptionForNode(ir.TreeNode node) {
      ir.Annotatable? contextNode = _getContextNode(node);
      if (contextNode == null) return null;
      if (!_hasLoadLibraryPriority(_getContext(contextNode))) return null;
      final pragmaData = computePragmaAnnotationDataFromIr(contextNode);
      final annotationData = pragmaData.firstWhere(
        (d) =>
            PragmaAnnotation.lookupMap[d.suffix] ==
            PragmaAnnotation.loadLibraryPriority,
      );
      final option = annotationData.options;
      if (option is! ir.StringConstant) return null;
      return option.value;
    }

    // Annotation may be on enclosing declaration or on the import.
    return getPragmaOptionForNode(node) ??
        getPragmaOptionForNode(node.import) ??
        '';
  }

  bool _hasLoadLibraryPriority(DirectivesContext? context) {
    while (context != null) {
      EnumSet<PragmaAnnotation> annotations = context.annotations;
      if (annotations.contains(PragmaAnnotation.loadLibraryPriority)) {
        return true;
      }
      context = context.parent;
    }
    return false;
  }

  @override
  bool shouldRecordMethodUses(FunctionEntity member) {
    EnumSet<PragmaAnnotation>? annotations = memberPragmaAnnotations[member];
    if (annotations != null) {
      if (annotations.contains(PragmaAnnotation.recordUse)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRecordConstInstances(ClassEntity clazz) {
    EnumSet<PragmaAnnotation>? set = classPragmaAnnotations[clazz];
    return set != null && set.contains(PragmaAnnotation.recordUse);
  }

  @override
  bool throwWithoutHelperFrame(ir.TreeNode node) {
    return _throwWithoutHelperFrame(_findContext(node));
  }

  bool _throwWithoutHelperFrame(DirectivesContext? context) {
    while (context != null) {
      EnumSet<PragmaAnnotation>? annotations = context.annotations;
      if (annotations.contains(PragmaAnnotation.throwWithoutHelperFrame)) {
        return true;
      }
      context = context.parent;
    }
    return false;
  }

  @override
  bool allowCSE(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.allowCSE);

  @override
  bool allowDCE(MemberEntity member) =>
      _hasPragma(member, PragmaAnnotation.allowDCE);
}

class AnnotationsDataBuilder {
  Map<MemberEntity, EnumSet<PragmaAnnotation>> memberPragmaAnnotations = {};
  Map<ClassEntity, EnumSet<PragmaAnnotation>> classPragmaAnnotations = {};

  void registerPragmaAnnotations(
    MemberEntity member,
    EnumSet<PragmaAnnotation> annotations,
  ) {
    if (annotations.isNotEmpty) {
      memberPragmaAnnotations[member] = annotations;
    }
  }

  void registerPragmaAnnotationsForClass(
    ClassEntity cls,
    EnumSet<PragmaAnnotation> annotations,
  ) {
    if (annotations.isNotEmpty) {
      classPragmaAnnotations[cls] = annotations;
    }
  }

  AnnotationsData close(CompilerOptions options, DiagnosticReporter reporter) {
    return AnnotationsDataImpl(
      options,
      reporter,
      classPragmaAnnotations,
      memberPragmaAnnotations,
    );
  }
}

/// A [DirectivesContext] is a chain of enclosing parent annotatable
/// scopes.
///
/// The context chain for a location always starts with a node that reflects the
/// annotations at the location so that it is possible to determine if an
/// annotation is 'on' the element. Chains for different locations that have the
/// same structure are shared. `method1` and `method2` have the same annotations
/// in scope, with no annotations on the method itself but inheriting
/// `late:trust` from the class scope. This is represented by DirectivesContext
/// [D].
///
/// Links in the context chain above the element may be compressed, so `class
/// DD` and `method4` share the chain [F] with no annotations on the element but
/// inheriting `late:check` from the enclosing library scope.
///
///     @pragma('dart2js:late:check')
///     library foo;  // [B]
///
///     @pragma('dart2js:late:trust')
///     class CC {  // [C]
///       method1(){}  // [D]
///       method2(){}  // [D]
///       @pragma('dart2js:noInline')
///       method3(){}  // [E]
///     }
///
///     class DD {  // [F]
///       method4(); // [F]
///     }
///
///
///     A: parent: null,  pragmas: {}
///
///     B: parent: A,     pragmas: {late:check}
///
///     C: parent: B,     pragmas: {late:trust}
///
///     D: parent: C,     pragmas: {}
///     E: parent: C,     pragmas: {noInline}
///
///     F: parent: B,     pragmas: {}
///
/// The root scope [A] is empty. We could remove it and start the root scope at
/// the library, but the shared root might be a good place to put a set of
/// annotations derived from the command-line.
///
/// If we ever introduce a single annotation that means something different in
/// different positions (e.g. on a class vs. on a method), we might want to make
/// the [DirectivesContext] have a 'scope-kind'.
class DirectivesContext {
  final DirectivesContext? parent;
  final EnumSet<PragmaAnnotation> annotations;

  Map<EnumSet<PragmaAnnotation>, DirectivesContext>? _children;

  DirectivesContext._(this.parent, this.annotations);

  DirectivesContext.root() : this._(null, EnumSet<PragmaAnnotation>.empty());

  DirectivesContext extend(EnumSet<PragmaAnnotation> annotations) {
    // Shorten chains of equivalent sets of annotations.
    if (this.annotations == annotations) return this;
    final children = _children ??= {};
    return children[annotations] ??= DirectivesContext._(this, annotations);
  }
}
