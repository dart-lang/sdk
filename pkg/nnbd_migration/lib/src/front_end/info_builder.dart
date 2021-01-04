// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation_dart.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/driver_provider_impl.dart';
import 'package:nnbd_migration/src/front_end/instrumentation_information.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/offset_mapper.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:nnbd_migration/src/utilities/progress_bar.dart';

/// A builder used to build the migration information for a library.
class InfoBuilder {
  /// The node mapper for the migration state.
  NodeMapper nodeMapper;

  /// The logger to use for showing progress when explaining the migration.
  final Logger _logger;

  /// The resource provider used to access the file system.
  ResourceProvider provider;

  String includedPath;

  /// The instrumentation information gathered while the migration engine was
  /// running.
  final InstrumentationInformation info;

  /// The listener used to gather the changes to be applied.
  final DartFixListener listener;

  /// The [NullabilityMigration] instance for this migration.
  final NullabilityMigration migration;

  /// A map from the path of a compilation unit to the information about that
  /// unit.
  final Map<String, UnitInfo> unitMap = {};

  /// Initialize a newly created builder.
  InfoBuilder(this.provider, this.includedPath, this.info, this.listener,
      this.migration, this.nodeMapper, this._logger);

  /// The provider used to get information about libraries.
  DriverProviderImpl get driverProvider => listener.server;

  /// Return the migration information for all of the libraries that were
  /// migrated.
  Future<Set<UnitInfo>> explainMigration() async {
    var sourceInfoMap = info.sourceInformation;
    Set<UnitInfo> units =
        SplayTreeSet<UnitInfo>((u1, u2) => u1.path.compareTo(u2.path));
    var progressBar = ProgressBar(_logger, sourceInfoMap.length);

    for (var source in sourceInfoMap.keys) {
      progressBar.tick();
      var filePath = source.fullName;
      var session = driverProvider.getAnalysisSession(filePath);
      if (!session.getFile(filePath).isPart) {
        var result = await session.getResolvedLibrary(filePath);
        for (var unitResult in result.units) {
          var sourceInfo =
              sourceInfoMap[unitResult.unit.declaredElement.source];
          // Note: there might have been no information for this unit in
          // sourceInfoMap.  That can happen if there's an already-migrated
          // library being referenced by the code being migrated, but not all
          // parts of that library are referenced.  To avoid exceptions later
          // on, we just create an empty SourceInformation object.
          // TODO(paulberry): we don't do a good job of the case where the
          // already-migrated library's defining compilation unit isn't
          // referenced (we'll just skip the entire library because we'll only
          // ever see its parts).
          sourceInfo ??= SourceInformation();
          var edit = listener.sourceChange.getFileEdit(unitResult.path);
          var unit = _explainUnit(sourceInfo, unitResult, edit);
          if (provider.pathContext.isWithin(includedPath, unitResult.path)) {
            units.add(unit);
          }
        }
      }
    }
    progressBar.complete();
    return units;
  }

  Iterable<EdgeInfo> upstreamTriggeredEdges(NullabilityNodeInfo node,
      {bool skipExactNullable = true}) {
    var edges = <EdgeInfo>[];
    for (var edge in node.upstreamEdges) {
      if (skipExactNullable &&
          node.isExactNullable &&
          edge.sourceNode.isExactNullable) {
        // When an exact nullable points here, the nullability propagated
        // in the other direction.
        continue;
      }
      if (edge.isTriggered) {
        edges.add(edge);
      }
    }
    for (final containerNode in node.outerCompoundNodes) {
      // We must include the exact nullable edges in the upstream triggered
      // edges of the container node. If this node is in a substitution node,
      // then it's possible it was marked exact nullable because it's container
      // was marked nullable. It's container could have been marked nullable by
      // another exact nullable node. We cannot tell. Err on the side of
      // surfacing too many reasons.
      edges.addAll(
          upstreamTriggeredEdges(containerNode, skipExactNullable: false));
    }

    return edges;
  }

  void _addSimpleTrace(SimpleFixReasonInfo info, List<TraceInfo> traces) {
    traces.add(TraceInfo(
        'Reason', [_makeTraceEntry(info.description, info.codeReference)]));
  }

  /// Returns a list of edits that can be applied.
  List<EditDetail> _computeEdits(
      AtomicEditInfo fixInfo, int offset, ResolvedUnitResult result) {
    var content = result.content;

    EditDetail removeHint(String description) => EditDetail.fromSourceEdit(
        description,
        fixInfo.hintComment.changesToRemove(content).toSourceEdits().single);

    EditDetail changeHint(String description, String replacement) =>
        EditDetail.fromSourceEdit(
            description,
            fixInfo.hintComment
                .changesToReplace(content, replacement)
                .toSourceEdits()
                .single);

    var edits = <EditDetail>[];
    var fixKind = fixInfo.description.kind;
    switch (fixKind) {
      case NullabilityFixKind.addLateDueToHint:
        edits.add(removeHint('Remove /*late*/ hint'));
        break;
      case NullabilityFixKind.addLateFinalDueToHint:
        edits.add(removeHint('Remove /*late final*/ hint'));
        break;
      case NullabilityFixKind.addRequired:
        var metaImport =
            _findImportDirective(result.unit, 'package:meta/meta.dart');
        if (metaImport == null) {
          edits.add(
              EditDetail('Add /*required*/ hint', offset, 0, '/*required*/ '));
        } else {
          var prefix = metaImport.prefix?.name;
          if (prefix == null) {
            edits.add(
                EditDetail("Mark with '@required'", offset, 0, '@required '));
          } else {
            edits.add(EditDetail(
                "Mark with '@required'", offset, 0, '@$prefix.required '));
          }
        }
        break;
      case NullabilityFixKind.checkExpression:
        // TODO(brianwilkerson) Determine whether we can know that the fix is
        //  associated with a parameter and insert an assert if it is.
        edits.add(EditDetail('Add /*!*/ hint', offset, 0, '/*!*/'));
        break;
      case NullabilityFixKind.checkExpressionDueToHint:
        edits.add(removeHint('Remove /*!*/ hint'));
        break;
      case NullabilityFixKind.downcastExpression:
      case NullabilityFixKind.otherCastExpression:
        // There's no useful hint to apply to casts.
        break;
      case NullabilityFixKind.removeAs:
      case NullabilityFixKind.removeDeadCode:
      case NullabilityFixKind.removeLanguageVersionComment:
        // There's no need for hints around code that is being removed.
        break;
      case NullabilityFixKind.addType:
      case NullabilityFixKind.replaceVar:
        // There's no need for hints around inserted types.
        break;
      case NullabilityFixKind.makeTypeNullable:
      case NullabilityFixKind.typeNotMadeNullable:
        edits.add(EditDetail('Add /*!*/ hint', offset, 0, '/*!*/'));
        edits.add(EditDetail('Add /*?*/ hint', offset, 0, '/*?*/'));
        break;
      case NullabilityFixKind.makeTypeNullableDueToHint:
        edits.add(changeHint('Change to /*!*/ hint', '/*!*/'));
        edits.add(removeHint('Remove /*?*/ hint'));
        break;
      case NullabilityFixKind.typeNotMadeNullableDueToHint:
        edits.add(removeHint('Remove /*!*/ hint'));
        edits.add(changeHint('Change to /*?*/ hint', '/*?*/'));
        break;
      case NullabilityFixKind.addLate:
      case NullabilityFixKind.addLateDueToTestSetup:
        // We could add an edit to add a `/*?*/` hint, but the offset is a
        // little tricky.
        break;
      case NullabilityFixKind.conditionFalseInStrongMode:
      case NullabilityFixKind.conditionTrueInStrongMode:
      case NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode:
      case NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode:
        // We don't offer any edits around weak-only code.
        // TODO(paulberry): offer edits to delete the code that would be dead in
        // strong mode (https://github.com/dart-lang/sdk/issues/41554).
        break;
      case NullabilityFixKind.compoundAssignmentHasBadCombinedType:
      case NullabilityFixKind.compoundAssignmentHasNullableSource:
        // We don't offer any edits around bad compound assignments or bad
        // increment/decrement operations.
        break;
      case NullabilityFixKind.addImport:
      case NullabilityFixKind.changeMethodName:
        // These fix kinds have to do with changing iterable method calls to
        // their "OrNull" equivalents.  We don't offer any hints around
        // this transformation.
        break;
      case NullabilityFixKind.noValidMigrationForNull:
        // We don't offer any edits around unmigratable `null`s.  The user has
        // to fix manually.
        break;
    }
    return edits;
  }

  /// Return the navigation sources for the unit associated with the [result].
  List<NavigationSource> _computeNavigationSources(ResolvedUnitResult result) {
    var collector = NavigationCollectorImpl();
    computeDartNavigation(
        result.session.resourceProvider, collector, result.unit, null, null);
    collector.createRegions();
    var files = collector.files;
    var regions = collector.regions;
    var rawTargets = collector.targets;
    var convertedTargets =
        List<NavigationTarget>.filled(rawTargets.length, null);
    return regions.map((region) {
      var targets = region.targets;
      if (targets.isEmpty) {
        throw StateError('Targets is empty');
      }
      var target = convertedTargets[targets[0]];
      if (target == null) {
        var rawTarget = rawTargets[targets[0]];
        target = _targetForRawTarget(files[rawTarget.fileIndex], rawTarget);
        convertedTargets[targets[0]] = target;
      }
      return NavigationSource(
          region.offset, null /* line */, region.length, target);
    }).toList();
  }

  void _computeTraceNonNullableInfo(NullabilityNodeInfo node,
      List<TraceInfo> traces, FixReasonTarget target) {
    var entries = <TraceEntryInfo>[];
    var description = 'Non-nullability reason${target.suffix}';
    var step = node.whyNotNullable;
    if (step == null) {
      if (node != info.never) {
        // 'never' indicates we're describing an edge to never, such as a `!`.
        traces.add(TraceInfo(description, [
          _nodeToTraceEntry(node,
              description: 'No reason found to make nullable')
        ]));
      }
      return;
    }
    assert(identical(step.node, node));
    while (step != null && !step.isStartingPoint) {
      entries.add(_nodeToTraceEntry(step.node));
      if (step.codeReference != null) {
        entries.add(_stepToTraceEntry(step));
      }
      step = step.principalCause;
    }
    traces.add(TraceInfo(description, entries));
  }

  void _computeTraceNullableInfo(NullabilityNodeInfo node,
      List<TraceInfo> traces, FixReasonTarget target) {
    var entries = <TraceEntryInfo>[];
    var step = node.whyNullable;
    if (step == null) {
      return;
    }
    assert(identical(step.targetNode, node));
    while (step != null) {
      entries.add(_nodeToTraceEntry(step.targetNode));
      if (step.codeReference != null) {
        entries.add(_stepToTraceEntry(step));
      }
      step = step.principalCause;
    }
    var description = 'Nullability reason${target.suffix}';
    traces.add(TraceInfo(description, entries));
  }

  List<TraceInfo> _computeTraces(
      Map<FixReasonTarget, FixReasonInfo> fixReasons) {
    var traces = <TraceInfo>[];
    for (var entry in fixReasons.entries) {
      var reason = entry.value;
      if (reason is NullabilityNodeInfo) {
        if (reason.isNullable) {
          _computeTraceNullableInfo(reason, traces, FixReasonTarget.root);
        } else {
          _computeTraceNonNullableInfo(reason, traces, FixReasonTarget.root);
        }
      } else if (reason is EdgeInfo) {
        if (reason.sourceNode.isNullable &&
            !reason.destinationNode.isNullable) {
          var target = entry.key;
          _computeTraceNullableInfo(reason.sourceNode, traces, target);
          _computeTraceNonNullableInfo(reason.destinationNode, traces, target);
        }
      } else if (reason is SimpleFixReasonInfo) {
        _addSimpleTrace(reason, traces);
      } else {
        assert(false, 'Unrecognized reason type: ${reason.runtimeType}');
      }
    }
    return traces;
  }

  /// Return the migration information for the unit associated with the
  /// [result].
  UnitInfo _explainUnit(SourceInformation sourceInfo, ResolvedUnitResult result,
      SourceFileEdit fileEdit) {
    var unitInfo = _unitForPath(result.path);
    unitInfo.sources ??= _computeNavigationSources(result);
    var content = result.content;
    unitInfo.diskContent = content;
    var alreadyMigrated =
        result.unit.featureSet.isEnabled(Feature.non_nullable);
    unitInfo.wasExplicitlyOptedOut = result.unit.languageVersionToken != null;
    unitInfo.migrationStatus = alreadyMigrated
        ? UnitMigrationStatus.alreadyMigrated
        // Whether or not a file is explicitly opted out, its initial status for
        // this migration is "migrating." It must be again explicitly opted out
        // in the preview app in order to keep the unit opted out.
        : UnitMigrationStatus.migrating;
    var regions = unitInfo.regions;

    // There are certain rare conditions involving generated code in a bazel
    // workspace that can cause a source file to get processed more than once by
    // the migration tool (sometimes with a correct URI, sometimes with an
    // incorrect URI that corresponds to a file path in the `bazel-out`
    // directory).  That can cause this method to get called twice for the same
    // unit.  To avoid this creating user-visible problems, we need to ensure
    // that any regions left over from the previous invocation are cleared out
    // before we re-populate the region list.
    regions.clear();

    var lineInfo = result.unit.lineInfo;
    var insertions = <int, List<AtomicEdit>>{};
    var infosSeen = Set<AtomicEditInfo>.identity();

    // Apply edits and build the regions.
    var changes = sourceInfo.changes ?? {};
    var sourceOffsets = changes.keys.toList();
    sourceOffsets.sort();
    var offset = 0;
    var sourceOffset = 0;
    for (var nextSourceOffset in sourceOffsets) {
      var changesForSourceOffset = changes[nextSourceOffset];
      var unchangedTextLength = nextSourceOffset - sourceOffset;
      offset += unchangedTextLength;
      sourceOffset += unchangedTextLength;
      for (var edit in changesForSourceOffset) {
        var length = edit.length;
        var replacement = edit.replacement;
        var end = offset + length;
        // Insert the replacement text without deleting the replaced text.
        if (replacement.isNotEmpty) {
          content = content.replaceRange(end, end, replacement);
          (insertions[sourceOffset] ??= []).add(AtomicEdit.insert(replacement));
        }
        var info = edit.info;
        var edits = info != null
            ? _computeEdits(info, sourceOffset, result)
            : <EditDetail>[];
        var lineNumber = lineInfo.getLocation(sourceOffset).lineNumber;
        var traces = info == null
            ? const <TraceInfo>[]
            : _computeTraces(info.fixReasons);
        var description = info?.description;
        var isCounted = info != null && infosSeen.add(info);
        var explanation = description?.appliedMessage;
        var kind = description?.kind;
        if (edit.isInsertion) {
          regions.add(RegionInfo(
              edit.isInformative ? RegionType.informative : RegionType.add,
              offset,
              replacement.length,
              lineNumber,
              explanation,
              kind,
              isCounted,
              edits: edits,
              traces: traces));
        } else if (edit.isDeletion) {
          regions.add(RegionInfo(
              edit.isInformative ? RegionType.informative : RegionType.remove,
              offset,
              length,
              lineNumber,
              explanation,
              kind,
              isCounted,
              edits: edits,
              traces: traces));
        } else if (edit.isReplacement) {
          assert(!edit.isInformative);
          regions.add(RegionInfo(RegionType.remove, offset, length, lineNumber,
              explanation, kind, isCounted,
              edits: edits, traces: traces));
          regions.add(RegionInfo(RegionType.add, end, replacement.length,
              lineNumber, explanation, kind, isCounted,
              edits: edits, traces: traces));
        } else {
          throw StateError(
              'Edit is not an insertion, deletion, replacement, nor '
              'informative: $edit');
        }
        sourceOffset += length;
        offset += length + replacement.length;
      }
    }

    // Build the map from source file offset to offset in the modified text.
    // We only account for insertions because in the code above, we don't delete
    // the modified text.
    var edits = insertions.toSourceEdits();
    edits.sort((first, second) => first.offset.compareTo(second.offset));
    var mapper = OffsetMapper.forEdits(edits);
    regions.sort((first, second) => first.offset.compareTo(second.offset));
    unitInfo.migrationOffsetMapper = mapper;
    unitInfo.content = content;
    return unitInfo;
  }

  /// Searches [unit] for an import directive whose URI matches [uri], returning
  /// it if found, or `null` if not found.
  ImportDirective _findImportDirective(CompilationUnit unit, String uri) {
    for (var directive in unit.directives) {
      if (directive is ImportDirective && directive.uriContent == uri) {
        return directive;
      }
    }
    return null;
  }

  TraceEntryInfo _makeTraceEntry(
      String description, CodeReference codeReference,
      {List<HintAction> hintActions = const []}) {
    var length = 1; // TODO(paulberry): figure out the correct value.
    return TraceEntryInfo(
        description,
        codeReference?.function,
        codeReference == null
            ? null
            : NavigationTarget(codeReference.path, codeReference.offset,
                codeReference.line, length),
        hintActions: hintActions);
  }

  TraceEntryInfo _nodeToTraceEntry(NullabilityNodeInfo node,
      {String description}) {
    description ??= node.toString(); // TODO(paulberry): improve this message
    return _makeTraceEntry(description, node.codeReference,
        hintActions: node.hintActions.keys
            .map((kind) => HintAction(kind, nodeMapper.idForNode(node)))
            .toList());
  }

  TraceEntryInfo _stepToTraceEntry(PropagationStepInfo step) {
    var description = step.edge?.description;
    description ??= step.toString(); // TODO(paulberry): improve this message.
    return _makeTraceEntry(description, step.codeReference);
  }

  /// Return the navigation target in the file with the given [filePath] at the
  /// given [offset] ans with the given [length].
  NavigationTarget _targetForRawTarget(
      String filePath, protocol.NavigationTarget rawTarget) {
    var unitInfo = _unitForPath(filePath);
    var offset = rawTarget.offset;
    var length = rawTarget.length;
    var target = NavigationTarget(filePath, offset, null /* line */, length);
    unitInfo.targets.add(target);
    return target;
  }

  /// Return the unit info for the file at the given [path].
  UnitInfo _unitForPath(String path) {
    return unitMap.putIfAbsent(path, () => UnitInfo(path));
  }

  /// Builds a description for [node]'s enclosing member(s).
  ///
  /// This may include a class and method name, for example, or the name of the
  /// enclosing top-level member.
  @visibleForTesting
  static String buildEnclosingMemberDescription(AstNode node) {
    for (var enclosingNode = node;
        enclosingNode != null;
        enclosingNode = enclosingNode.parent) {
      if (enclosingNode is ConstructorDeclaration) {
        if (enclosingNode.name == null) {
          return _describeClassOrExtensionMember(
              enclosingNode.parent as CompilationUnitMember,
              'the default constructor of',
              '');
        } else {
          return _describeClassOrExtensionMember(
              enclosingNode.parent as CompilationUnitMember,
              'the constructor',
              enclosingNode.name.name);
        }
      } else if (enclosingNode is MethodDeclaration) {
        var functionName = enclosingNode.name.name;
        String baseDescription;
        if (enclosingNode.isGetter) {
          baseDescription = 'the getter';
        } else if (enclosingNode.isOperator) {
          baseDescription = 'the operator';
        } else if (enclosingNode.isSetter) {
          baseDescription = 'the setter';
          functionName += '=';
        } else {
          baseDescription = 'the method';
        }
        return _describeClassOrExtensionMember(
            enclosingNode.parent as CompilationUnitMember,
            baseDescription,
            functionName);
      } else if (enclosingNode is FunctionDeclaration &&
          enclosingNode.parent is CompilationUnit) {
        var functionName = enclosingNode.name.name;
        String baseDescription;
        if (enclosingNode.isGetter) {
          baseDescription = 'the getter';
        } else if (enclosingNode.isSetter) {
          baseDescription = 'the setter';
          functionName += '=';
        } else {
          baseDescription = 'the function';
        }
        return "$baseDescription '$functionName'";
      } else if (enclosingNode is VariableDeclaration) {
        var description = _describeVariableDeclaration(enclosingNode);
        if (description != null) return description;
      } else if (enclosingNode is VariableDeclarationList) {
        var description =
            _describeVariableDeclaration(enclosingNode.variables[0]);
        if (description != null) return description;
      }
    }
    throw ArgumentError(
        "Can't describe enclosing member of ${node.runtimeType}");
  }

  static String _describeClassOrExtensionMember(CompilationUnitMember parent,
      String baseDescription, String functionName) {
    if (parent is NamedCompilationUnitMember) {
      var parentName = parent.name.name;
      if (functionName.isEmpty) {
        return "$baseDescription '$parentName'";
      } else {
        return "$baseDescription '$parentName.$functionName'";
      }
    } else if (parent is ExtensionDeclaration) {
      if (parent.name == null) {
        var extendedTypeString = parent.extendedType.type.getDisplayString(
          withNullability: false,
        );
        return "$baseDescription '$functionName' in unnamed extension on $extendedTypeString";
      } else {
        return "$baseDescription '${parent.name.name}.$functionName'";
      }
    } else {
      throw ArgumentError(
          'Unexpected class or extension type ${parent.runtimeType}');
    }
  }

  static String _describeVariableDeclaration(VariableDeclaration node) {
    var variableName = node.name.name;
    var parent = node.parent;
    var grandParent = parent.parent;
    if (grandParent is FieldDeclaration) {
      return _describeClassOrExtensionMember(
          grandParent.parent as CompilationUnitMember,
          'the field',
          variableName);
    } else if (grandParent is TopLevelVariableDeclaration) {
      return "the variable '$variableName'";
    } else {
      return null;
    }
  }
}
