// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import 'package:kernel/ast.dart' as ir;
import 'package:js_runtime/synced/load_library_priority.dart';

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
  parameterTrust('parameter:trust',
      forFunctionsOnly: false, internalOnly: false),
  parameterCheck('parameter:check',
      forFunctionsOnly: false, internalOnly: false),
  downcastTrust('downcast:trust', forFunctionsOnly: false, internalOnly: false),
  downcastCheck('downcast:check', forFunctionsOnly: false, internalOnly: false),
  indexBoundsTrust('index-bounds:trust',
      forFunctionsOnly: false, internalOnly: false),
  indexBoundsCheck('index-bounds:check',
      forFunctionsOnly: false, internalOnly: false),

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

  loadLibraryPriorityNormal('load-priority:normal'),
  loadLibraryPriorityHigh('load-priority:high'),
  resourceIdentifier('resource-identifier'),
  ;

  final String name;
  final bool forFunctionsOnly;
  final bool internalOnly;

  // TODO(sra): Review [forFunctionsOnly]. Fields have implied getters and
  // setters, so some annotations meant only for functions could reasonable be
  // placed on a field to apply to the getter and setter.

  const PragmaAnnotation(this.name,
      {this.forFunctionsOnly = false, this.internalOnly = false});

  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> implies = {
    typesTrust: {parameterTrust, downcastTrust},
    typesCheck: {parameterCheck, downcastCheck},
  };
  static const Map<PragmaAnnotation, Set<PragmaAnnotation>> excludes = {
    noInline: {tryInline},
    tryInline: {noInline, resourceIdentifier},
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
    loadLibraryPriorityNormal: {loadLibraryPriorityHigh},
    loadLibraryPriorityHigh: {loadLibraryPriorityNormal},
    resourceIdentifier: {tryInline},
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
  };
}

ir.Library _enclosingLibrary(ir.TreeNode node) {
  while (true) {
    if (node is ir.Library) return node;
    if (node is ir.Member) return node.enclosingLibrary;
    node = node.parent!;
  }
}

EnumSet<PragmaAnnotation> processMemberAnnotations(
    CompilerOptions options,
    DiagnosticReporter reporter,
    ir.Annotatable node,
    List<PragmaAnnotationData> pragmaAnnotationData) {
  EnumSet<PragmaAnnotation> annotations = EnumSet<PragmaAnnotation>();

  ir.Library library = _enclosingLibrary(node);
  Uri uri = library.importUri;
  bool platformAnnotationsAllowed =
      options.testMode || uri.isScheme('dart') || maybeEnableNative(uri);

  for (PragmaAnnotationData data in pragmaAnnotationData) {
    String name = data.name;
    String suffix = data.suffix;
    final annotation = PragmaAnnotation.lookupMap[suffix];
    if (annotation != null) {
      annotations.add(annotation);

      if (data.hasOptions) {
        reporter.reportErrorMessage(
            computeSourceSpanFromTreeNode(node),
            MessageKind.GENERIC,
            {'text': "@pragma('$name') annotation does not take options"});
      }
      if (annotation.forFunctionsOnly) {
        if (node is! ir.Procedure && node is! ir.Constructor) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(node), MessageKind.GENERIC, {
            'text': "@pragma('$name') annotation is only supported "
                "for methods and constructors."
          });
        }
      }
      if (annotation.internalOnly && !platformAnnotationsAllowed) {
        reporter.reportErrorMessage(
            computeSourceSpanFromTreeNode(node),
            MessageKind.GENERIC,
            {'text': "Unrecognized dart2js pragma @pragma('$name')"});
      }
    } else {
      reporter.reportErrorMessage(
          computeSourceSpanFromTreeNode(node),
          MessageKind.GENERIC,
          {'text': "Unknown dart2js pragma @pragma('$name')"});
    }
  }

  Map<PragmaAnnotation, EnumSet<PragmaAnnotation>> reportedExclusions = {};
  for (PragmaAnnotation annotation
      in annotations.iterable(PragmaAnnotation.values)) {
    Set<PragmaAnnotation>? implies = PragmaAnnotation.implies[annotation];
    if (implies != null) {
      for (PragmaAnnotation other in implies) {
        if (annotations.contains(other)) {
          reporter.reportHintMessage(
              computeSourceSpanFromTreeNode(node), MessageKind.GENERIC, {
            'text': "@pragma('dart2js:${annotation.name}') implies "
                "@pragma('dart2js:${other.name}')."
          });
        }
      }
    }
    Set<PragmaAnnotation>? excludes = PragmaAnnotation.excludes[annotation];
    if (excludes != null) {
      for (PragmaAnnotation other in excludes) {
        if (annotations.contains(other) &&
            !(reportedExclusions[other]?.contains(annotation) ?? false)) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(node), MessageKind.GENERIC, {
            'text': "@pragma('dart2js:${annotation.name}') must not be used "
                "with @pragma('dart2js:${other.name}')."
          });
          (reportedExclusions[annotation] ??= EnumSet()).add(other);
        }
      }
    }
    Set<PragmaAnnotation>? requires = PragmaAnnotation.requires[annotation];
    if (requires != null) {
      for (PragmaAnnotation other in requires) {
        if (!annotations.contains(other)) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(node), MessageKind.GENERIC, {
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
  /// Deserializes an [AnnotationsData] object from [source].
  factory AnnotationsData.readFromDataSource(
      CompilerOptions options,
      DiagnosticReporter reporter,
      DataSourceReader source) = AnnotationsDataImpl.readFromDataSource;

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
  /// Indicates that the `fetchpriority` attribute should be set to the
  /// specified value on the injected script tag used to load the library.
  LoadLibraryPriority getLoadLibraryPriorityAt(ir.LoadLibrary node);

  /// Determines whether [member] is annotated as a resource identifier.
  bool methodIsResourceIdentifier(FunctionEntity member);
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

  /// Pragma annotations for members. These are captured for the K-entities and
  /// translated to J-entities.
  // TODO(49475): Change the queries that use [pragmaAnnotation] to use the
  // DirectivesContext so that we can avoid the need for persisting annotations.
  final Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations;

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
      CompilerOptions options, this._reporter, this.pragmaAnnotations)
      : this._options = options,
        this._defaultParameterCheckPolicy = options.defaultParameterCheckPolicy,
        this._defaultImplicitDowncastCheckPolicy =
            options.defaultImplicitDowncastCheckPolicy,
        this._defaultConditionCheckPolicy = options.defaultConditionCheckPolicy,
        this._defaultExplicitCastCheckPolicy =
            options.defaultExplicitCastCheckPolicy,
        this._defaultIndexBoundsCheckPolicy =
            options.defaultIndexBoundsCheckPolicy,
        this._defaultLateVariableCheckPolicy = CheckPolicy.checked,
        this._defaultDisableInlining = options.disableInlining;

  factory AnnotationsDataImpl.readFromDataSource(CompilerOptions options,
      DiagnosticReporter reporter, DataSourceReader source) {
    source.begin(tag);
    Map<MemberEntity, EnumSet<PragmaAnnotation>> pragmaAnnotations =
        source.readMemberMap(
            (MemberEntity member) => EnumSet.fromValue(source.readInt()));
    source.end(tag);
    return AnnotationsDataImpl(options, reporter, pragmaAnnotations);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberMap(pragmaAnnotations,
        (MemberEntity member, EnumSet<PragmaAnnotation> set) {
      sink.writeInt(set.value);
    });
    sink.end(tag);
  }

  bool _hasPragma(MemberEntity member, PragmaAnnotation annotation) {
    EnumSet<PragmaAnnotation>? set = pragmaAnnotations[member];
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
      EnumSet<PragmaAnnotation>? annotations = pragmaAnnotations[member];
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
  CheckPolicy getImplicitDowncastCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = pragmaAnnotations[member];
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
  CheckPolicy getConditionCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = pragmaAnnotations[member];
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
  CheckPolicy getExplicitCastCheckPolicy(MemberEntity? member) {
    if (member != null) {
      EnumSet<PragmaAnnotation>? annotations = pragmaAnnotations[member];
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
      EnumSet<PragmaAnnotation>? annotations = pragmaAnnotations[member];
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
      EnumSet<PragmaAnnotation>? annotations = context.annotations;
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
    ir.TreeNode? node = startNode;
    while (node is! ir.Annotatable) {
      if (node == null) return _root;
      node = node.parent;
    }
    return _nodeToContextMap[node] ??= _findContext(node.parent!).extend(
        processMemberAnnotations(_options, _reporter, node,
            computePragmaAnnotationDataFromIr(node)));
  }

  @override
  LoadLibraryPriority getLoadLibraryPriorityAt(ir.LoadLibrary node) {
    // Annotation may be on enclosing declaration or on the import.
    return _getLoadLibraryPriorityAt(_findContext(node)) ??
        _getLoadLibraryPriorityAt(_findContext(node.import)) ??
        LoadLibraryPriority.normal;
  }

  LoadLibraryPriority? _getLoadLibraryPriorityAt(DirectivesContext? context) {
    while (context != null) {
      EnumSet<PragmaAnnotation>? annotations = context.annotations;
      if (annotations.contains(PragmaAnnotation.loadLibraryPriorityHigh)) {
        return LoadLibraryPriority.high;
      } else if (annotations
          .contains(PragmaAnnotation.loadLibraryPriorityNormal)) {
        return LoadLibraryPriority.normal;
      }
      context = context.parent;
    }
    return null;
  }

  @override
  bool methodIsResourceIdentifier(MemberEntity member) {
    EnumSet<PragmaAnnotation>? annotations = pragmaAnnotations[member];
    if (annotations != null) {
      if (annotations.contains(PragmaAnnotation.resourceIdentifier)) {
        return true;
      }
    }
    return false;
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

  AnnotationsData close(CompilerOptions options, DiagnosticReporter reporter) {
    return AnnotationsDataImpl(options, reporter, pragmaAnnotations);
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

  DirectivesContext.root() : this._(null, EnumSet<PragmaAnnotation>());

  DirectivesContext extend(EnumSet<PragmaAnnotation> annotations) {
    // Shorten chains of equivalent sets of annotations.
    if (this.annotations == annotations) return this;
    final children = _children ??= {};
    return children[annotations] ??= DirectivesContext._(this, annotations);
  }
}
