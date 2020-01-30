// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceEdit, SourceFileEdit;
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

  /// A flag indicating whether types that were not changed (because they should
  /// be non-nullable) should be explained.
  final bool explainNonNullableTypes;

  /// A map from the path of a compilation unit to the information about that
  /// unit.
  final Map<String, UnitInfo> unitMap = {};

  /// Initialize a newly created builder.
  InfoBuilder(this.provider, this.includedPath, this.info, this.listener,
      // TODO(srawlins): Re-enable once
      //  https://github.com/dart-lang/sdk/issues/40253 is fixed.
      {this.explainNonNullableTypes = false});

  /// The analysis server used to get information about libraries.
  AnalysisServer get server => listener.server;

  /// Return the migration information for all of the libraries that were
  /// migrated.
  Future<Set<UnitInfo>> explainMigration() async {
    Map<Source, SourceInformation> sourceInfoMap = info.sourceInformation;
    Set<UnitInfo> units =
        SplayTreeSet<UnitInfo>((u1, u2) => u1.path.compareTo(u2.path));
    for (Source source in sourceInfoMap.keys) {
      String filePath = source.fullName;
      AnalysisSession session =
          server.getAnalysisDriver(filePath).currentSession;
      if (!session.getFile(filePath).isPart) {
        ResolvedLibraryResult result =
            await session.getResolvedLibrary(filePath);
        SourceInformation sourceInfo = sourceInfoMap[source];
        for (ResolvedUnitResult unitResult in result.units) {
          SourceFileEdit edit =
              listener.sourceChange.getFileEdit(unitResult.path);
          UnitInfo unit = _explainUnit(sourceInfo, unitResult, edit);
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
    for (EdgeInfo edge in node.upstreamEdges) {
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

  /// Return detail text for a fix built from an edge with origin info [origin]
  /// and [fixKind].
  String _baseDescriptionForOrigin(
      EdgeOriginInfo origin, NullabilityFixKind fixKind) {
    AstNode node = origin.node;
    AstNode parent = node.parent;

    String aNullableDefault(DefaultFormalParameter node) {
      Expression defaultValue = node.defaultValue;
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

    // Text indicating the type of nullable value found.
    String nullableValue;
    if (node is NullLiteral) {
      nullableValue = "an explicit 'null'";
    } else if (origin.kind == EdgeOriginKind.dynamicAssignment) {
      nullableValue = 'a dynamic value, which is nullable';
    } else {
      nullableValue = 'a nullable value';
    }

    if (origin.kind == EdgeOriginKind.listLengthConstructor) {
      return 'List value type must be nullable because a length is specified,'
          ' and the list items are initialized as null.';
    }

    CompilationUnit unit = node.thisOrAncestorOfType<CompilationUnit>();
    int lineNumber = unit.lineInfo.getLocation(node.offset).lineNumber;

    if (origin.kind == EdgeOriginKind.uninitializedRead) {
      return 'Used on line $lineNumber, when it is possibly uninitialized';
    }

    if (parent is ArgumentList) {
      return capitalize('$nullableValue is passed as an argument');
    }

    /// If the [node] is inside the return expression for a function body,
    /// return the function body. Otherwise return `null`.
    FunctionBody findFunctionBody() {
      if (parent is ExpressionFunctionBody) {
        return parent;
      } else {
        ReturnStatement returnNode =
            parent.thisOrAncestorOfType<ReturnStatement>();
        BlockFunctionBody bodyNode =
            returnNode?.thisOrAncestorOfType<BlockFunctionBody>();
        return bodyNode;
      }
    }

    /// If the [node] is inside a collection literal, return it. Otherwise
    /// return `null`.
    TypedLiteral findCollectionLiteral() {
      AstNode ancestor = parent;
      // Walk up collection elements, except for collection literals.
      while (ancestor is CollectionElement && ancestor is! TypedLiteral) {
        ancestor = ancestor.parent;
      }
      return (ancestor is TypedLiteral) ? ancestor : null;
    }

    FunctionBody functionBody = findFunctionBody();
    if (functionBody != null) {
      AstNode function = functionBody.parent;
      if (function is MethodDeclaration) {
        if (function.isGetter) {
          return 'This getter returns $nullableValue on line $lineNumber';
        }
        return 'This method returns $nullableValue on line $lineNumber';
      }
      return 'This function returns $nullableValue on line $lineNumber';
    }

    TypedLiteral collectionLiteral = findCollectionLiteral();
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
      return 'This named parameter was omitted in a call to this function';
    } else if (parent is VariableDeclaration) {
      AstNode grandparent = parent.parent?.parent;
      if (grandparent is FieldDeclaration) {
        return 'This field is initialized to $nullableValue';
      }
      return 'This variable is initialized to $nullableValue';
    } else if (node is ConstructorDeclaration &&
        origin.kind == EdgeOriginKind.fieldNotInitialized) {
      String constructorName =
          node.declaredElement.enclosingElement.displayName;
      if (node.declaredElement.displayName.isNotEmpty) {
        constructorName =
            '$constructorName.${node.declaredElement.displayName}';
      }
      return "The constructor '$constructorName' does not initialize this "
          'field in its initializer list';
    }

    String enclosingMemberDescription = buildEnclosingMemberDescription(node);
    if (enclosingMemberDescription != null) {
      return capitalize(
          '$nullableValue is assigned in $enclosingMemberDescription');
    } else {
      return capitalize('$nullableValue is assigned');
    }
  }

  /// Return a description of the given [origin].
  String _buildDescriptionForOrigin(
      EdgeOriginInfo origin, NullabilityFixKind fixKind) {
    String description = _baseDescriptionForOrigin(origin, fixKind);
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
    AstNode node = origin.node;
    NavigationTarget target;
    TypeAnnotation type = info.typeAnnotationForNode(edge.sourceNode);
    AstNode typeParent = type?.parent;

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
          CompilationUnit unit = type.thisOrAncestorOfType<CompilationUnit>();
          target = _proximateTargetForNode(
              unit.declaredElement.source.fullName, type);
        }
        String description =
            _buildInheritanceDescriptionForOrigin(origin, type);
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
      String overriddenName = 'the overridden method';
      if (type != null && type.parent is FormalParameter) {
        FormalParameter parameter = type.parent;
        if (parameter.parent is DefaultFormalParameter) {
          parameter = parameter.parent;
        }
        if (parameter.parent is FormalParameterList &&
            parameter.parent.parent is MethodDeclaration) {
          MethodDeclaration method = parameter.parent.parent;
          String methodName = method.name.name;
          ClassOrMixinDeclaration cls = method.parent;
          String className = cls.name.name;
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
    List<RegionDetail> details = [];
    var fixInfo = edit.info;
    for (FixReasonInfo reason in fixInfo?.fixReasons ?? []) {
      if (reason == null) {
        // Sometimes reasons are null, so just ignore them (see for example the
        // test case InfoBuilderTest.test_discardCondition.  If only we had
        // NNBD, we could have prevented this!
        // TODO(paulberry): fix this so that it will never happen.
      } else if (reason is NullabilityNodeInfo) {
        if (reason.isExactNullable) {
          // When the node is exact nullable, that nullability propagated from
          // downstream.
          for (EdgeInfo edge in reason.downstreamEdges) {
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
              details.add(RegionDetail(
                  'exact nullable node with no info ($exactNullableDownstream)',
                  null));
            }
          }
        }

        for (EdgeInfo edge in upstreamTriggeredEdges(reason)) {
          EdgeOriginInfo origin = info.edgeOrigin[edge];
          if (origin != null) {
            details.add(
                _buildDetailForOrigin(origin, edge, fixInfo.description.kind));
          } else {
            details.add(
                RegionDetail('upstream edge with no origin ($edge)', null));
          }
        }
      } else if (reason is EdgeInfo) {
        NullabilityNodeInfo destination = reason.destinationNode;
        NodeInformation nodeInfo = info.nodeInfoFor(destination);
        if (nodeInfo != null && nodeInfo.astNode != null) {
          NavigationTarget target;
          if (destination != info.never && destination != info.always) {
            target =
                _proximateTargetForNode(nodeInfo.filePath, nodeInfo.astNode);
          }
          EdgeOriginInfo edge = info.edgeOrigin[reason];
          details.add(RegionDetail(_describeNonNullEdge(edge), target));
        } else {
          details.add(RegionDetail('node with no info ($destination)', null));
        }
      } else {
        throw UnimplementedError(
            'Unexpected class of reason: ${reason.runtimeType}');
      }
    }
    return details;
  }

  /// Return an edit that can be applied.
  List<EditDetail> _computeEdits(AtomicEditInfo fixInfo, int offset) {
    List<EditDetail> edits = [];
    var fixKind = fixInfo.description.kind;
    switch (fixKind) {
      case NullabilityFixKind.addRequired:
        // TODO(brianwilkerson) This doesn't verify that the meta package has
        //  been imported.
        edits
            .add(EditDetail("Mark with '@required'.", offset, 0, '@required '));
        break;
      case NullabilityFixKind.checkExpression:
        // TODO(brianwilkerson) Determine whether we can know that the fix is
        //  associated with a parameter and insert an assert if it is.
        edits.add(EditDetail('Force null check.', offset, 0, '/*!*/'));
        break;
      case NullabilityFixKind.discardCondition:
      case NullabilityFixKind.discardElse:
      case NullabilityFixKind.discardIf:
      case NullabilityFixKind.discardThen:
      case NullabilityFixKind.removeAs:
      case NullabilityFixKind.removeNullAwareness:
        // There's no need for hints around code that is being removed.
        break;
      case NullabilityFixKind.makeTypeNullable:
      case NullabilityFixKind.noModification:
        edits.add(
            EditDetail('Force type to be non-nullable.', offset, 0, '/*!*/'));
        edits.add(EditDetail('Force type to be nullable.', offset, 0, '/*?*/'));
        break;
    }
    return edits;
  }

  /// Return the navigation sources for the unit associated with the [result].
  List<NavigationSource> _computeNavigationSources(ResolvedUnitResult result) {
    NavigationCollectorImpl collector = NavigationCollectorImpl();
    computeDartNavigation(
        result.session.resourceProvider, collector, result.unit, null, null);
    collector.createRegions();
    List<String> files = collector.files;
    List<protocol.NavigationRegion> regions = collector.regions;
    List<protocol.NavigationTarget> rawTargets = collector.targets;
    List<NavigationTarget> convertedTargets =
        List<NavigationTarget>(rawTargets.length);
    return regions.map((region) {
      List<int> targets = region.targets;
      if (targets.isEmpty) {
        throw StateError('Targets is empty');
      }
      NavigationTarget target = convertedTargets[targets[0]];
      if (target == null) {
        protocol.NavigationTarget rawTarget = rawTargets[targets[0]];
        target = _targetForRawTarget(files[rawTarget.fileIndex], rawTarget);
        convertedTargets[targets[0]] = target;
      }
      return NavigationSource(
          region.offset, null /* line */, region.length, target);
    }).toList();
  }

  /// Compute details about [edgeInfos] which are upstream triggered.
  List<RegionDetail> _computeUpstreamTriggeredDetails(
      Iterable<EdgeInfo> edgeInfos) {
    List<RegionDetail> details = [];
    for (var edge in edgeInfos) {
      EdgeOriginInfo origin = info.edgeOrigin[edge];
      if (origin == null) {
        // TODO(srawlins): I think this shouldn't happen? But it does on the
        //  collection and path packages.
        continue;
      }
      NavigationTarget target =
          _proximateTargetForNode(origin.source.fullName, origin.node);
      if (origin.kind == EdgeOriginKind.expressionChecks) {
        details.add(RegionDetail(
            'This value is unconditionally used in a non-nullable context',
            target));
      } else if (origin.kind == EdgeOriginKind.nonNullAssertion) {
        details
            .add(RegionDetail('This value is asserted to be non-null', target));
      } else if (origin.kind == EdgeOriginKind.nullabilityComment) {
        details.add(RegionDetail(
            'This type is annotated with a non-nullability comment ("/*!*/")',
            target));
      }
    }
    return details;
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

  /// Explain the type annotations that were not changed because they were
  /// determined to be non-nullable.
  void _explainNonNullableTypes(SourceInformation sourceInfo,
      List<RegionInfo> regions, OffsetMapper mapper, LineInfo lineInfo) {
    Iterable<MapEntry<TypeAnnotation, NullabilityNodeInfo>> nonNullableTypes =
        sourceInfo.explicitTypeNullability.entries
            .where((entry) => !entry.value.isNullable);
    for (MapEntry<TypeAnnotation, NullabilityNodeInfo> nonNullableType
        in nonNullableTypes) {
      Iterable<EdgeInfo> upstreamTriggeredEdgeInfos = info.edgeOrigin.keys
          .where((e) =>
              e.sourceNode == nonNullableType.value &&
              e.isUpstreamTriggered &&
              !e.destinationNode.isNullable);
      if (upstreamTriggeredEdgeInfos.isNotEmpty) {
        List<RegionDetail> details =
            _computeUpstreamTriggeredDetails(upstreamTriggeredEdgeInfos);
        if (details.isNotEmpty) {
          TypeAnnotation node = nonNullableType.key;
          regions.add(RegionInfo(
              RegionType.unchanged,
              mapper.map(node.offset),
              node.length,
              lineInfo.getLocation(node.offset).lineNumber,
              'This type is not changed; it is determined to be non-nullable',
              details));
        }
      }
    }
  }

  /// Return the migration information for the unit associated with the
  /// [result].
  UnitInfo _explainUnit(SourceInformation sourceInfo, ResolvedUnitResult result,
      SourceFileEdit fileEdit) {
    UnitInfo unitInfo = _unitForPath(result.path);
    unitInfo.sources ??= _computeNavigationSources(result);
    String content = result.content;
    List<RegionInfo> regions = unitInfo.regions;
    var lineInfo = result.unit.lineInfo;

    // [fileEdit] is null when a file has no edits.
    List<SourceEdit> edits = fileEdit == null ? [] : List.of(fileEdit.edits);
    edits.sort((first, second) => first.offset.compareTo(second.offset));
    OffsetMapper mapper = OffsetMapper.forEdits(edits);

    // Apply edits and build the regions.
    var changes = sourceInfo.changes ?? {};
    var sourceOffsets = changes.keys.toList();
    sourceOffsets.sort();
    int offset = 0;
    int lastSourceOffset = 0;
    for (var sourceOffset in sourceOffsets) {
      offset += sourceOffset - lastSourceOffset;
      lastSourceOffset = sourceOffset;
      var changesForSourceOffset = changes[sourceOffset];
      for (var edit in changesForSourceOffset) {
        int length = edit.length;
        String replacement = edit.replacement;
        int end = offset + length;
        // Insert the replacement text without deleting the replaced text.
        content = content.replaceRange(end, end, replacement);
        var info = edit.info;
        String explanation = info?.description?.appliedMessage;
        List<EditDetail> edits =
            info != null ? _computeEdits(info, sourceOffset) : [];
        List<RegionDetail> details = _computeDetails(edit);
        var lineNumber = lineInfo.getLocation(sourceOffset).lineNumber;
        if (explanation != null) {
          if (length > 0) {
            regions.add(RegionInfo(RegionType.remove, offset, length,
                lineNumber, explanation, details,
                edits: edits));
          } else {
            regions.add(RegionInfo(RegionType.add, offset, replacement.length,
                lineNumber, explanation, details,
                edits: edits));
          }
        }
        offset += replacement.length;
      }
    }
    if (explainNonNullableTypes) {
      _explainNonNullableTypes(
          sourceInfo, regions, mapper, result.unit.lineInfo);
    }
    regions.sort((first, second) => first.offset.compareTo(second.offset));
    unitInfo.offsetMapper = mapper;
    unitInfo.content = content;
    return unitInfo;
  }

  /// Return `true` if the given [node] is from a compilation unit within the
  /// 'test' directory of the package.
  bool _inTestCode(AstNode node) {
    // TODO(brianwilkerson) Generalize this.
    CompilationUnit unit = node.thisOrAncestorOfType<CompilationUnit>();
    CompilationUnitElement unitElement = unit?.declaredElement;
    if (unitElement == null) {
      return false;
    }
    String filePath = unitElement.source.fullName;
    var resourceProvider = unitElement.session.resourceProvider;
    return resourceProvider.pathContext.split(filePath).contains('test');
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
    AstNode parent = node.parent;
    CompilationUnit unit = node.thisOrAncestorOfType<CompilationUnit>();
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

  /// Return the navigation target in the file with the given [filePath] at the
  /// given [offset] ans with the given [length].
  NavigationTarget _targetForNode(
      String filePath, SyntacticEntity node, CompilationUnit unit) {
    UnitInfo unitInfo = _unitForPath(filePath);
    int offset = node.offset;
    int length = node.length;

    int line = unit.lineInfo.getLocation(node.offset).lineNumber;
    NavigationTarget target = NavigationTarget(filePath, offset, line, length);
    unitInfo.targets.add(target);
    return target;
  }

  /// Return the navigation target in the file with the given [filePath] at the
  /// given [offset] ans with the given [length].
  NavigationTarget _targetForRawTarget(
      String filePath, protocol.NavigationTarget rawTarget) {
    UnitInfo unitInfo = _unitForPath(filePath);
    int offset = rawTarget.offset;
    int length = rawTarget.length;
    NavigationTarget target =
        NavigationTarget(filePath, offset, null /* line */, length);
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
    String functionName;
    String baseDescription;

    void describeFunction(AstNode node) {
      if (node is ConstructorDeclaration) {
        if (node.name == null) {
          baseDescription = 'the default constructor of';
          functionName = '';
        } else {
          baseDescription = 'the constructor';
          functionName = node.name.name;
        }
      } else if (node is MethodDeclaration) {
        functionName = node.name.name;
        if (node.isGetter) {
          baseDescription = 'the getter';
        } else if (node.isOperator) {
          baseDescription = 'the operator';
        } else if (node.isSetter) {
          baseDescription = 'the setter';
          functionName += '=';
        } else {
          baseDescription = 'the method';
        }
      } else if (node is FunctionDeclaration) {
        functionName = node.name.name;
        if (node.isGetter) {
          baseDescription = 'the getter';
        } else if (node.isSetter) {
          baseDescription = 'the setter';
          functionName += '=';
        } else {
          baseDescription = 'the function';
        }
      } else if (node is FieldDeclaration) {
        var field = node.thisOrAncestorOfType<VariableDeclaration>();
        field ??= node.fields.variables[0];
        functionName = field.name.name;
        baseDescription = 'the field';
      } else {
        // Throwing here allows us to gather more information. Not throwing here
        // causes an NPE on line 709.
        throw ArgumentError("Can't describe function in ${node.runtimeType}");
      }
    }

    var enclosingClassMember = node.thisOrAncestorOfType<ClassMember>();

    if (enclosingClassMember != null) {
      describeFunction(enclosingClassMember);
      CompilationUnitMember member = enclosingClassMember.parent;
      if (member is NamedCompilationUnitMember) {
        String memberName = member.name.name;
        if (functionName.isEmpty) {
          return "$baseDescription '$memberName'";
        } else {
          return "$baseDescription '$memberName.$functionName'";
        }
      } else if (member is ExtensionDeclaration) {
        if (member.name == null) {
          var extendedTypeString = member.extendedType.type.getDisplayString(
            withNullability: false,
          );
          return "$baseDescription '$functionName' in unnamed extension on $extendedTypeString";
        } else {
          return "$baseDescription '${member.name.name}.$functionName'";
        }
      }
    }
    FunctionDeclaration enclosingFunction =
        node.thisOrAncestorOfType<FunctionDeclaration>();
    if (enclosingFunction is FunctionDeclaration) {
      describeFunction(enclosingFunction);
      return "$baseDescription '$functionName'";
    }
    return null;
  }
}
