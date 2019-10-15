// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show Location, SourceEdit, SourceFileEdit;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';

class FixInfo {
  /// The fix being described.
  SingleNullabilityFix fix;

  /// The reasons why the fix was made.
  List<FixReasonInfo> reasons;

  /// Initialize information about a fix from the given map [entry].
  FixInfo(this.fix, this.reasons);
}

/// A builder used to build the migration information for a library.
class InfoBuilder {
  /// The instrumentation information gathered while the migration engine was
  /// running.
  final InstrumentationInformation info;

  /// The listener used to gather the changes to be applied.
  final DartFixListener listener;

  /// A map from the path of a compilation unit to the information about that
  /// unit.
  final Map<String, UnitInfo> unitMap = {};

  /// Initialize a newly created builder.
  InfoBuilder(this.info, this.listener);

  /// The analysis server used to get information about libraries.
  AnalysisServer get server => listener.server;

  /// Return the migration information for all of the libraries that were
  /// migrated.
  Future<List<UnitInfo>> explainMigration() async {
    Map<Source, SourceInformation> sourceInfoMap = info.sourceInformation;
    List<UnitInfo> units = [];
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
          units.add(_explainUnit(sourceInfo, unitResult, edit));
        }
      }
    }
    return units;
  }

  /// Return details for a fix built from the given [edge], or `null` if the
  /// edge does not have an origin.
  String _baseDescriptionForOrigin(AstNode node) {
    if (node is DefaultFormalParameter) {
      Expression defaultValue = node.defaultValue;
      if (defaultValue == null) {
        return "This parameter has an implicit default value of 'null'";
      } else if (defaultValue is NullLiteral) {
        return "This parameter has an explicit default value of 'null'";
      }
      return "This parameter has a nullable default value";
    } else if (node is FieldFormalParameter) {
      AstNode parent = node.parent;
      if (parent is DefaultFormalParameter) {
        Expression defaultValue = parent.defaultValue;
        if (defaultValue == null) {
          return "This field is initialized by an optional field formal "
              "parameter that has an implicit default value of 'null'";
        } else if (defaultValue is NullLiteral) {
          return "This field is initialized by an optional field formal "
              "parameter that has an explicit default value of 'null'";
        }
        return "This field is initialized by an optional field formal "
            "parameter that has a nullable default value";
      }
      return "This field is initialized by a field formal parameter and a "
          "nullable value is passed as an argument";
    }
    AstNode parent = node.parent;
    if (parent is ArgumentList) {
      if (node is NullLiteral) {
        return "An explicit 'null' is passed as an argument";
      }
      return "A nullable value is explicitly passed as an argument";
    }

    /// If the [node] is the return expression for a function body, return the
    /// function body. Otherwise return `null`.
    AstNode findFunctionBody() {
      if (parent is ExpressionFunctionBody) {
        return parent;
      } else if (parent is ReturnStatement &&
          parent.parent?.parent is BlockFunctionBody) {
        return parent.parent.parent;
      }
      return null;
    }

    AstNode functionBody = findFunctionBody();
    if (functionBody != null) {
      AstNode function = functionBody.parent;
      if (function is MethodDeclaration) {
        if (function.isGetter) {
          return "This getter returns a nullable value";
        }
        return "This method returns a nullable value";
      }
      return "This function returns a nullable value";
    } else if (parent is VariableDeclaration) {
      AstNode grandparent = parent.parent?.parent;
      if (grandparent is FieldDeclaration) {
        if (node is NullLiteral) {
          return "This field is initialized to null";
        }
        return "This field is initialized to a nullable value";
      }
      if (node is NullLiteral) {
        return "This variable is initialized to null";
      }
      return "This variable is initialized to a nullable value";
    } else if (parent is AsExpression) {
      return "The value of the expression is nullable";
    }
    if (node is NullLiteral) {
      return "An explicit 'null' is assigned";
    }
    return "A nullable value is assigned";
  }

  /// Return details for a fix built from the given [edge], or `null` if the
  /// edge does not have an origin.
  String _buildDescriptionForDestination(AstNode node) {
    // Other found types:
    // - ConstructorDeclaration
    if (node.parent is FormalParameterList) {
      return "A nullable value can't be passed as an argument";
    } else {
      return "A nullable value can't be used here";
    }
  }

  /// Return a description of the given [origin].
  String _buildDescriptionForOrigin(AstNode origin) {
    String description = _baseDescriptionForOrigin(origin);
    if (_inTestCode(origin)) {
      // TODO(brianwilkerson) Don't add this if the graph node with which the
      //  origin is associated is also in test code.
      description += " in test code";
    }
    return description;
  }

  /// Return a description of the given [origin] associated with the [edge].
  RegionDetail _buildDetailForOrigin(EdgeOriginInfo origin, EdgeInfo edge) {
    AstNode node = origin.node;
    NavigationTarget target;
    // Some nodes don't need a target; default formal parameters
    // without explicit default values, for example.
    if (node is DefaultFormalParameter && node.defaultValue == null) {
      target = null;
    } else {
      if (origin.kind == EdgeOriginKind.inheritance) {
        // The node is the method declaration in the subclass and we want to
        // link to the corresponding parameter in the declaration in the
        // superclass.
        TypeAnnotation type = info.typeAnnotationForNode(edge.sourceNode);
        if (type != null) {
          CompilationUnit unit = type.thisOrAncestorOfType<CompilationUnit>();
          target = _targetForNode(unit.declaredElement.source.fullName, type);
          return RegionDetail(
              "The corresponding parameter in the overridden method is nullable",
              target);
          // TODO(srawlins): Also, this could be where a return type in an
          //  overridden method is made nullable because an overriding method
          //  was found with a nullable return type. Figure out how to tell
          //  which situation we are in.
        }
      }
      target = _targetForNode(origin.source.fullName, node);
    }
    return RegionDetail(_buildDescriptionForOrigin(node), target);
  }

  /// Compute the details for the fix with the given [fixInfo].
  List<RegionDetail> _computeDetails(FixInfo fixInfo) {
    List<RegionDetail> details = [];
    for (FixReasonInfo reason in fixInfo.reasons) {
      if (reason is NullabilityNodeInfo) {
        for (EdgeInfo edge in reason.upstreamEdges) {
          if (edge.isTriggered) {
            EdgeOriginInfo origin = info.edgeOrigin[edge];
            if (origin != null) {
              details.add(_buildDetailForOrigin(origin, edge));
            } else {
              details.add(
                  RegionDetail('upstream edge with no origin ($edge)', null));
            }
          }
        }
      } else if (reason is EdgeInfo) {
        NullabilityNodeInfo destination = reason.destinationNode;
        var nodeInfo = info.nodeInfoFor(destination);
        if (nodeInfo != null) {
          details.add(RegionDetail(
              _buildDescriptionForDestination(nodeInfo.astNode),
              _targetForNode(nodeInfo.filePath, nodeInfo.astNode)));
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

  /// Return the navigation sources for the unit associated with the [result].
  List<NavigationSource> _computeNavigationSources(ResolvedUnitResult result) {
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
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
        target = _targetFor(
            files[rawTarget.fileIndex], rawTarget.offset, rawTarget.length);
        convertedTargets[targets[0]] = target;
      }
      return NavigationSource(region.offset, region.length, target);
    }).toList();
  }

  /// Return the migration information for the unit associated with the
  /// [result].
  UnitInfo _explainUnit(SourceInformation sourceInfo, ResolvedUnitResult result,
      SourceFileEdit fileEdit) {
    UnitInfo unitInfo = _unitForPath(result.path);
    if (unitInfo.sources == null) {
      unitInfo.sources = _computeNavigationSources(result);
    }
    String content = result.content;
    // [fileEdit] is null when a file has no edits.
    if (fileEdit != null) {
      List<RegionInfo> regions = unitInfo.regions;
      List<SourceEdit> edits = fileEdit.edits;
      edits.sort((first, second) => first.offset.compareTo(second.offset));
      OffsetMapper mapper = OffsetMapper.forEdits(edits);
      // Apply edits in reverse order and build the regions.
      for (SourceEdit edit in edits.reversed) {
        int offset = edit.offset;
        int length = edit.length;
        String replacement = edit.replacement;
        int end = offset + length;
        // Insert the replacement text without deleting the replaced text.
        content = content.replaceRange(end, end, replacement);
        FixInfo fixInfo = _findFixInfo(sourceInfo, offset);
        if (fixInfo != null) {
          String explanation = '${fixInfo.fix.description.appliedMessage}.';
          List<RegionDetail> details = _computeDetails(fixInfo);
          if (length > 0) {
            regions.add(
                RegionInfo(mapper.map(offset), length, explanation, details));
          }
          regions.add(RegionInfo(
              mapper.map(end), replacement.length, explanation, details));
        }
      }
      regions.sort((first, second) => first.offset.compareTo(second.offset));
      unitInfo.offsetMapper = mapper;
    }
    unitInfo.content = content;
    return unitInfo;
  }

  /// Return information about the fix that was applied at the given [offset],
  /// or `null` if the information could not be found. The information is
  /// extracted from the [sourceInfo].
  FixInfo _findFixInfo(SourceInformation sourceInfo, int offset) {
    for (MapEntry<SingleNullabilityFix, List<FixReasonInfo>> entry
        in sourceInfo.fixes.entries) {
      Location location = entry.key.location;
      if (location.offset == offset) {
        return FixInfo(entry.key, entry.value);
      }
    }
    return null;
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

  /// Return the navigation target in the file with the given [filePath] at the
  /// given [offset] ans with the given [length].
  NavigationTarget _targetFor(String filePath, int offset, int length) {
    UnitInfo unitInfo = _unitForPath(filePath);
    NavigationTarget target = NavigationTarget(filePath, offset, length);
    unitInfo.targets.add(target);
    return target;
  }

  /// Return the navigation target corresponding to the given [node] in the file
  /// with the given [filePath].
  NavigationTarget _targetForNode(String filePath, AstNode node) {
    AstNode parent = node.parent;
    if (node is ConstructorDeclaration) {
      if (node.name != null) {
        return _targetFor(filePath, node.name.offset, node.name.length);
      } else {
        return _targetFor(
            filePath, node.returnType.offset, node.returnType.length);
      }
    } else if (node is MethodDeclaration) {
      // Rather than create a NavigationTarget for an entire method declaration
      // (starting at its doc comment, ending at `}`, return a target pointing
      // to the method's name.
      return _targetFor(filePath, node.name.offset, node.name.length);
    } else if (parent is ReturnStatement) {
      // Rather than create a NavigationTarget for an entire expression, return
      // a target pointing to the `return` token.
      return _targetFor(
          filePath, parent.returnKeyword.offset, parent.returnKeyword.length);
    } else if (parent is ExpressionFunctionBody) {
      // Rather than create a NavigationTarget for an entire expression function
      // body, return a target pointing to the `=>` token.
      return _targetFor(filePath, parent.functionDefinition.offset,
          parent.functionDefinition.length);
    } else {
      return _targetFor(filePath, node.offset, node.length);
    }
  }

  /// Return the unit info for the file at the given [path].
  UnitInfo _unitForPath(String path) {
    return unitMap.putIfAbsent(path, () => UnitInfo(path));
  }
}
