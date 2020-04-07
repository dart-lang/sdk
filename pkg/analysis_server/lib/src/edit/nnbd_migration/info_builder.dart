// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

/// A builder used to build the migration information for a library.
class InfoBuilder {
  /// The resource provider used to access the file system.
  ResourceProvider provider;

  String includedPath;

  /// The instrumentation information gathered while the migration engine was
  /// running.
  final InstrumentationInformation info;

  /// The listener used to gather the changes to be applied.
  final DartFixListener listener;

  /// The dartfix adapter, which can be used to report exceptions that occur.
  final NullabilityMigrationAdapter adapter;

  /// The [NullabilityMigration] instance for this migration.
  final NullabilityMigration migration;

  /// A map from the path of a compilation unit to the information about that
  /// unit.
  final Map<String, UnitInfo> unitMap = {};

  /// Initialize a newly created builder.
  InfoBuilder(this.provider, this.includedPath, this.info, this.listener,
      this.adapter, this.migration);

  /// The analysis server used to get information about libraries.
  AnalysisServer get server => listener.server;

  /// Return the migration information for all of the libraries that were
  /// migrated.
  Future<Set<UnitInfo>> explainMigration() async {
    var sourceInfoMap = info.sourceInformation;
    Set<UnitInfo> units =
        SplayTreeSet<UnitInfo>((u1, u2) => u1.path.compareTo(u2.path));
    for (var source in sourceInfoMap.keys) {
      var filePath = source.fullName;
      var session = server.getAnalysisDriver(filePath).currentSession;
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

  /// Return detail text for a fix built from an edge with origin info [origin]
  /// and [fixKind].
  ///
  /// Text is meant to be used as the beginning of a sentence. It is written in
  /// present tense, beginning with a capital letter, not ending in a period.
  String _baseDescriptionForOrigin(
      EdgeOriginInfo origin, NullabilityFixKind fixKind) {
    var node = origin.node;
    var parent = node.parent;

    String aNullableDefault(DefaultFormalParameter node) {
      var defaultValue = node.defaultValue;
      if (defaultValue == null) {
        return "an implicit default value of 'null'";
      } else if (defaultValue is NullLiteral) {
        return "an explicit default value of 'null'";
      }
      return 'a nullable default value';
    }

    if (node is DefaultFormalParameter) {
      if (fixKind == NullabilityFixKind.addRequired) {
        return 'This parameter is non-nullable, so cannot have '
            '${aNullableDefault(node)}';
      } else {
        return 'This parameter has ${aNullableDefault(node)}';
      }
    } else if (node is FieldFormalParameter) {
      if (parent is DefaultFormalParameter) {
        return 'This field is initialized by an optional field formal '
            'parameter that has ${aNullableDefault(parent)}';
      }
      return 'This field is initialized by a field formal parameter and a '
          'nullable value is passed as an argument';
    } else if (parent is DefaultFormalParameter) {
      return 'This parameter has ${aNullableDefault(parent)}';
    } else if (parent is AsExpression) {
      return 'The value of the expression is nullable';
    }

    if (origin.kind == EdgeOriginKind.listLengthConstructor) {
      return 'A length is specified in the "List()" constructor and the list '
          'items are initialized to null';
    }
    if (origin.kind == EdgeOriginKind.typeParameterInstantiation) {
      return 'This type parameter is instantiated with a nullable type';
    }
    if (origin.kind == EdgeOriginKind.inferredTypeParameterInstantiation) {
      return 'This type parameter is instantiated with an inferred nullable '
          'type';
    }

    var unit = node.thisOrAncestorOfType<CompilationUnit>();
    var lineNumber = unit.lineInfo.getLocation(node.offset).lineNumber;

    if (origin.kind == EdgeOriginKind.uninitializedRead) {
      return 'Used on line $lineNumber, when it is possibly uninitialized';
    } else if (origin.kind == EdgeOriginKind.implicitNullReturn) {
      return 'This function contains a return statement with no value on line '
          '$lineNumber, which implicitly returns null.';
    }

    // Text indicating the type of nullable value found.
    String nullableValue;
    if (node is NullLiteral) {
      nullableValue = "an explicit 'null'";
    } else if (origin.kind == EdgeOriginKind.dynamicAssignment) {
      nullableValue = 'a dynamic value, which is nullable';
    } else {
      nullableValue = 'a nullable value';
    }

    /// If the [node] is inside the return expression for a function body,
    /// return the function body. Otherwise return `null`.
    FunctionBody findFunctionBody() {
      if (parent is ExpressionFunctionBody) {
        return parent;
      } else {
        var returnNode = parent.thisOrAncestorOfType<ReturnStatement>();
        var bodyNode = returnNode?.thisOrAncestorOfType<BlockFunctionBody>();
        return bodyNode;
      }
    }

    /// If the [node] is inside a collection literal, return it. Otherwise
    /// return `null`.
    TypedLiteral findCollectionLiteral() {
      var ancestor = parent;
      // Walk up collection elements, except for collection literals.
      while (ancestor is CollectionElement && ancestor is! TypedLiteral) {
        ancestor = ancestor.parent;
      }
      return (ancestor is TypedLiteral) ? ancestor : null;
    }

    var functionBody = findFunctionBody();
    if (functionBody != null) {
      var function = functionBody.parent;
      if (function is MethodDeclaration) {
        if (function.isGetter) {
          return 'This getter returns $nullableValue on line $lineNumber';
        }
        return 'This method returns $nullableValue on line $lineNumber';
      }
      return 'This function returns $nullableValue on line $lineNumber';
    }

    var collectionLiteral = findCollectionLiteral();
    if (collectionLiteral != null) {
      if (collectionLiteral is ListLiteral) {
        return 'This list is initialized with $nullableValue on line '
            '$lineNumber';
      } else if (collectionLiteral is SetOrMapLiteral) {
        var mapOrSet = collectionLiteral.isMap ? 'map' : 'set';
        return 'This $mapOrSet is initialized with $nullableValue on line '
            '$lineNumber';
      }
    } else if (node is InvocationExpression &&
        origin.kind == EdgeOriginKind.namedParameterNotSupplied) {
      return 'This named parameter is omitted in a call to this function';
    } else if (parent is ArgumentList) {
      return capitalize('$nullableValue is passed as an argument');
    } else if (parent is VariableDeclaration) {
      var grandparent = parent.parent?.parent;
      if (grandparent is FieldDeclaration) {
        return 'This field is initialized to $nullableValue';
      }
      return 'This variable is initialized to $nullableValue';
    } else if (origin.kind == EdgeOriginKind.fieldNotInitialized) {
      if (node is ConstructorDeclaration) {
        var constructorName = node.declaredElement.enclosingElement.displayName;
        if (node.declaredElement.displayName.isNotEmpty) {
          constructorName =
              '$constructorName.${node.declaredElement.displayName}';
        }
        return "The constructor '$constructorName' does not initialize this "
            'field in its initializer list';
      } else {
        return 'This field is not initialized';
      }
    }

    var enclosingMemberDescription = buildEnclosingMemberDescription(node);
    if (enclosingMemberDescription != null) {
      return capitalize(
          '$nullableValue is assigned in $enclosingMemberDescription');
    } else {
      assert(false, 'no enclosing member description');
      return capitalize('$nullableValue is assigned');
    }
  }

  /// Return a description of the given [origin].
  String _buildDescriptionForOrigin(
      EdgeOriginInfo origin, NullabilityFixKind fixKind) {
    var description = _baseDescriptionForOrigin(origin, fixKind);
    if (_inTestCode(origin.node)) {
      // TODO(brianwilkerson) Don't add this if the graph node with which the
      //  origin is associated is also in test code.
      description += ' in test code';
    }
    return description;
  }

  /// Return a description of the given [origin] associated with the [edge].
  RegionDetail _buildDetailForOrigin(
      EdgeOriginInfo origin, EdgeInfo edge, NullabilityFixKind fixKind) {
    var node = origin.node;
    NavigationTarget target;
    var type = info.typeAnnotationForNode(edge.sourceNode);
    var typeParent = type?.parent;

    if (typeParent is GenericFunctionType && type == typeParent.returnType) {
      var description =
          'A function-typed value with a nullable return type is assigned';
      target = _proximateTargetForNode(origin.source.fullName, node);
      return RegionDetail(description, target);
    }
    if (typeParent is FormalParameter) {
      FormalParameterList parameterList =
          typeParent.parent is DefaultFormalParameter
              ? typeParent.parent.parent
              : typeParent.parent;
      if (parameterList.parent is GenericFunctionType) {
        var description =
            'The function-typed element in which this parameter is declared is '
            'assigned to a function whose matching parameter is nullable';
        target = _proximateTargetForNode(origin.source.fullName, node);
        return RegionDetail(description, target);
      }
    }

    // Some nodes don't need a target; default formal parameters
    // without explicit default values, for example.
    if (node is DefaultFormalParameter && node.defaultValue == null) {
      target = null;
    } else {
      if (origin.kind == EdgeOriginKind.parameterInheritance ||
          origin.kind == EdgeOriginKind.returnTypeInheritance) {
        // The node is the method declaration in the subclass and we want to
        // link to the either the corresponding parameter in the declaration in
        // the superclass, or the return type in the declaration in that
        // subclass.
        if (type != null) {
          var unit = type.thisOrAncestorOfType<CompilationUnit>();
          target = _proximateTargetForNode(
              unit.declaredElement.source.fullName, type);
        }
        var description = _buildInheritanceDescriptionForOrigin(origin, type);
        return RegionDetail(description, target);
      } else {
        target = _proximateTargetForNode(origin.source.fullName, node);
      }
    }
    return RegionDetail(_buildDescriptionForOrigin(origin, fixKind), target);
  }

  String _buildInheritanceDescriptionForOrigin(
      EdgeOriginInfo origin, TypeAnnotation type) {
    if (origin.kind == EdgeOriginKind.parameterInheritance) {
      var overriddenName = 'the overridden method';
      if (type != null && type.parent is FormalParameter) {
        FormalParameter parameter = type.parent;
        if (parameter.parent is DefaultFormalParameter) {
          parameter = parameter.parent;
        }
        if (parameter.parent is FormalParameterList &&
            parameter.parent.parent is MethodDeclaration) {
          MethodDeclaration method = parameter.parent.parent;
          var methodName = method.name.name;
          ClassOrMixinDeclaration cls = method.parent;
          var className = cls.name.name;
          overriddenName += ', $className.$methodName,';
        }
      }
      return 'The corresponding parameter in $overriddenName is nullable';
    } else {
      return 'An overridding method has a nullable return value';
    }
  }

  /// Compute the details for the fix with the given [edit].
  List<RegionDetail> _computeDetails(AtomicEdit edit) {
    var details = <RegionDetail>[];
    var fixInfo = edit.info;
    for (var reason in fixInfo?.fixReasons ?? []) {
      if (reason == null) {
        // Sometimes reasons are null, so just ignore them (see for example the
        // test case InfoBuilderTest.test_discardCondition.  If only we had
        // NNBD, we could have prevented this!
        // TODO(paulberry): fix this so that it will never happen.
      } else if (reason is NullabilityNodeInfo) {
        if (reason.isExactNullable) {
          // When the node is exact nullable, that nullability propagated from
          // downstream.
          for (var edge in reason.downstreamEdges) {
            final exactNullableDownstream = edge.destinationNode;
            if (!exactNullableDownstream.isExactNullable) {
              // This wasn't the source of the nullability.
              continue;
            }

            var nodeInfo = info.nodeInfoFor(exactNullableDownstream);
            if (nodeInfo != null) {
              // TODO(mfairhurst): Give a better text description.
              details.add(RegionDetail(
                  'This is later required to accept null.',
                  _proximateTargetForNode(
                      nodeInfo.filePath, nodeInfo.astNode)));
            } else {
              final description =
                  'exact nullable node with no info ($exactNullableDownstream)';
              assert(false, description);
              details.add(RegionDetail(description, null));
            }
          }
        }

        for (var edge in upstreamTriggeredEdges(reason)) {
          var origin = info.edgeOrigin[edge];
          if (origin != null) {
            details.add(
                _buildDetailForOrigin(origin, edge, fixInfo.description.kind));
          } else {
            final description = 'upstream edge with no origin ($edge)';
            assert(false, description);
            details.add(RegionDetail(description, null));
          }
        }
      } else if (reason is EdgeInfo) {
        var destination = reason.destinationNode;
        var nodeInfo = info.nodeInfoFor(destination);
        var edge = info.edgeOrigin[reason];
        if (destination == info.never) {
          details.add(RegionDetail(_describeNonNullEdge(edge), null));
        } else if (nodeInfo != null && nodeInfo.astNode != null) {
          NavigationTarget target;
          if (destination != info.always) {
            target =
                _proximateTargetForNode(nodeInfo.filePath, nodeInfo.astNode);
          }
          details.add(RegionDetail(_describeNonNullEdge(edge), target));
        } else {
          // Likely an assignment to a migrated type.
          final description = 'node with no info ($destination)';
          assert(false, description);
          details.add(RegionDetail(description, null));
        }
      } else if (reason is SimpleFixReasonInfo) {
        details.add(RegionDetail(reason.description, null));
      } else {
        throw UnimplementedError(
            'Unexpected class of reason: ${reason.runtimeType}');
      }
    }
    return details;
  }

  /// Return an edit that can be applied.
  List<EditDetail> _computeEdits(AtomicEditInfo fixInfo, int offset) {
    var edits = <EditDetail>[];
    var fixKind = fixInfo.description.kind;
    switch (fixKind) {
      case NullabilityFixKind.addRequired:
        // TODO(brianwilkerson) This doesn't verify that the meta package has
        //  been imported.
        edits
            .add(EditDetail("Mark with '@required'.", offset, 0, '@required '));
        break;
      case NullabilityFixKind.castExpression:
      case NullabilityFixKind.checkExpression:
        // TODO(brianwilkerson) Determine whether we can know that the fix is
        //  associated with a parameter and insert an assert if it is.
        edits.add(EditDetail('Add /*!*/ hint', offset, 0, '/*!*/'));
        break;
      case NullabilityFixKind.removeAs:
      case NullabilityFixKind.removeDeadCode:
      case NullabilityFixKind.removeLanguageVersionComment:
        // There's no need for hints around code that is being removed.
        break;
      case NullabilityFixKind.makeTypeNullable:
      case NullabilityFixKind.typeNotMadeNullable:
        edits.add(EditDetail('Add /*!*/ hint', offset, 0, '/*!*/'));
        edits.add(EditDetail('Add /*?*/ hint', offset, 0, '/*?*/'));
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
    var convertedTargets = List<NavigationTarget>(rawTargets.length);
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

  void _computeTraceNonNullableInfo(
      NullabilityNodeInfo node, List<TraceInfo> traces) {
    var entries = <TraceEntryInfo>[];
    var step = node.whyNotNullable;
    if (step == null) {
      return;
    }
    assert(identical(step.node, node));
    while (step != null) {
      entries.add(_nodeToTraceEntry(step.node));
      if (step.codeReference != null) {
        entries.add(_stepToTraceEntry(step));
      }
      step = step.principalCause;
    }
    var description = 'Non-nullability reason';
    traces.add(TraceInfo(description, entries));
  }

  void _computeTraceNullableInfo(
      NullabilityNodeInfo node, List<TraceInfo> traces) {
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
    var description = 'Nullability reason';
    traces.add(TraceInfo(description, entries));
  }

  List<TraceInfo> _computeTraces(List<FixReasonInfo> fixReasons) {
    var traces = <TraceInfo>[];
    for (var reason in fixReasons) {
      if (reason is NullabilityNodeInfo) {
        if (reason.isNullable) {
          _computeTraceNullableInfo(reason, traces);
        } else {
          _computeTraceNonNullableInfo(reason, traces);
        }
      } else if (reason is EdgeInfo) {
        assert(reason.sourceNode.isNullable);
        assert(!reason.destinationNode.isNullable);
        _computeTraceNullableInfo(reason.sourceNode, traces);
        _computeTraceNonNullableInfo(reason.destinationNode, traces);
      } else if (reason is SimpleFixReasonInfo) {
        _addSimpleTrace(reason, traces);
      } else {
        assert(false, 'Unrecognized reason type: ${reason.runtimeType}');
      }
    }
    return traces;
  }

  /// Describe why an edge may have gotten a '!'.
  String _describeNonNullEdge(EdgeOriginInfo edge) {
    // TODO(mfairhurst/paulberry): Do NOT use astNode/parent to create this
    // description, as we are just duplicating work if we do so.
    final astNode = edge.node;
    final parent = astNode.parent;
    if (parent is PropertyAccess && parent.target == astNode ||
        parent is PrefixedIdentifier && parent.prefix == astNode) {
      return 'This value must be null-checked before accessing its properties.';
    }
    if (parent is MethodInvocation && parent.target == astNode) {
      return 'This value must be null-checked before calling its methods.';
    }

    return 'This value must be null-checked before use here.';
  }

  /// Return the migration information for the unit associated with the
  /// [result].
  UnitInfo _explainUnit(SourceInformation sourceInfo, ResolvedUnitResult result,
      SourceFileEdit fileEdit) {
    var unitInfo = _unitForPath(result.path);
    unitInfo.sources ??= _computeNavigationSources(result);
    var content = result.content;
    unitInfo.originalContent = content;
    var regions = unitInfo.regions;
    var lineInfo = result.unit.lineInfo;
    var insertions = <int, List<AtomicEdit>>{};

    // Apply edits and build the regions.
    var changes = sourceInfo.changes ?? {};
    var sourceOffsets = changes.keys.toList();
    sourceOffsets.sort();
    var offset = 0;
    var lastSourceOffset = 0;
    for (var sourceOffset in sourceOffsets) {
      offset += sourceOffset - lastSourceOffset;
      lastSourceOffset = sourceOffset;
      var changesForSourceOffset = changes[sourceOffset];
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
        var edits = info != null ? _computeEdits(info, sourceOffset) : [];
        List<RegionDetail> details;
        try {
          details = _computeDetails(edit);
        } catch (e, st) {
          // TODO(mfairhurst): get the correct Source, and an AstNode.
          if (migration.isPermissive) {
            adapter.reportException(result.libraryElement.source, null, e, st);
            details = [];
          } else {
            rethrow;
          }
        }
        var lineNumber = lineInfo.getLocation(sourceOffset).lineNumber;
        var traces = info == null ? const [] : _computeTraces(info.fixReasons);
        var description = info?.description;
        if (description != null) {
          var explanation = description.appliedMessage;
          var kind = description.kind;
          if (length > 0) {
            regions.add(RegionInfo(RegionType.remove, offset, length,
                lineNumber, explanation, details, kind,
                edits: edits, traces: traces));
          } else {
            if (edit.isInformative) {
              regions.add(RegionInfo(RegionType.informative, offset,
                  replacement.length, lineNumber, explanation, const [], kind,
                  edits: edits, traces: traces));
            } else {
              regions.add(RegionInfo(RegionType.add, offset, replacement.length,
                  lineNumber, explanation, details, kind,
                  edits: edits, traces: traces));
            }
          }
        }
        offset += replacement.length;
      }
    }

    // Build the map from source file offset to offset in the modified text.
    // We only account for insertions because in the code above, we don't delete
    // the modified text.
    var edits = insertions.toSourceEdits();
    edits.sort((first, second) => first.offset.compareTo(second.offset));
    var mapper = OffsetMapper.forEdits(edits);
    regions.sort((first, second) => first.offset.compareTo(second.offset));
    unitInfo.offsetMapper = mapper;
    unitInfo.content = content;
    return unitInfo;
  }

  /// Return `true` if the given [node] is from a compilation unit within the
  /// 'test' directory of the package.
  bool _inTestCode(AstNode node) {
    // TODO(brianwilkerson) Generalize this.
    var unit = node.thisOrAncestorOfType<CompilationUnit>();
    var unitElement = unit?.declaredElement;
    if (unitElement == null) {
      return false;
    }
    var filePath = unitElement.source.fullName;
    var resourceProvider = unitElement.session.resourceProvider;
    return resourceProvider.pathContext.split(filePath).contains('test');
  }

  TraceEntryInfo _makeTraceEntry(
      String description, CodeReference codeReference) {
    var length = 1; // TODO(paulberry): figure out the correct value.
    return TraceEntryInfo(
        description,
        codeReference?.function,
        codeReference == null
            ? null
            : NavigationTarget(codeReference.path, codeReference.column,
                codeReference.line, length));
  }

  TraceEntryInfo _nodeToTraceEntry(NullabilityNodeInfo node) {
    var description = node.toString(); // TODO(paulberry): improve this message
    return _makeTraceEntry(description, node.codeReference);
  }

  /// Return the navigation target corresponding to the given [node] in the file
  /// with the given [filePath].
  ///
  /// Rather than a NavigationTarget targeting exactly [node], heuristics are
  /// made to point to a narrower target, for example the name of a
  /// method declaration, rather the the entire declaration.
  NavigationTarget _proximateTargetForNode(String filePath, AstNode node) {
    if (node == null) {
      return null;
    }
    var parent = node.parent;
    var unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (node is ConstructorDeclaration) {
      if (node.name != null) {
        return _targetForNode(filePath, node.name, unit);
      } else {
        return _targetForNode(filePath, node.returnType, unit);
      }
    } else if (node is MethodDeclaration) {
      // Rather than create a NavigationTarget for an entire method declaration
      // (starting at its doc comment, ending at `}`, return a target pointing
      // to the method's name.
      return _targetForNode(filePath, node.name, unit);
    } else if (parent is ReturnStatement) {
      // Rather than create a NavigationTarget for an entire expression, return
      // a target pointing to the `return` token.
      return _targetForNode(filePath, parent.returnKeyword, unit);
    } else if (parent is ExpressionFunctionBody) {
      // Rather than create a NavigationTarget for an entire expression function
      // body, return a target pointing to the `=>` token.
      return _targetForNode(filePath, parent.functionDefinition, unit);
    } else {
      return _targetForNode(filePath, node, unit);
    }
  }

  TraceEntryInfo _stepToTraceEntry(PropagationStepInfo step) {
    var description = step.edge?.description;
    description ??= step.toString(); // TODO(paulberry): improve this message.
    return _makeTraceEntry(description, step.codeReference);
  }

  /// Return the navigation target in the file with the given [filePath] at the
  /// given [offset] ans with the given [length].
  NavigationTarget _targetForNode(
      String filePath, SyntacticEntity node, CompilationUnit unit) {
    var unitInfo = _unitForPath(filePath);
    var offset = node.offset;
    var length = node.length;

    var line = unit.lineInfo.getLocation(node.offset).lineNumber;
    var target = NavigationTarget(filePath, offset, line, length);
    unitInfo.targets.add(target);
    return target;
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
              enclosingNode.parent, 'the default constructor of', '');
        } else {
          return _describeClassOrExtensionMember(
              enclosingNode.parent, 'the constructor', enclosingNode.name.name);
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
            enclosingNode.parent, baseDescription, functionName);
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
          grandParent.parent, 'the field', variableName);
    } else if (grandParent is TopLevelVariableDeclaration) {
      return "the variable '$variableName'";
    } else {
      return null;
    }
  }
}
