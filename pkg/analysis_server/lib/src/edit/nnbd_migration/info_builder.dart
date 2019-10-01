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
  Future<List<LibraryInfo>> explainMigration() async {
    Map<Source, SourceInformation> sourceInfo = info.sourceInformation;
    List<LibraryInfo> libraries = [];
    for (Source source in sourceInfo.keys) {
      String filePath = source.fullName;
      AnalysisSession session =
          server.getAnalysisDriver(filePath).currentSession;
      if (!session.getFile(filePath).isPart) {
        ResolvedLibraryResult result =
            await session.getResolvedLibrary(filePath);
        libraries
            .add(_explainLibrary(result, info, sourceInfo[source], listener));
      }
    }
    return libraries;
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

  /// Return details for a fix built from the given [edge], or `null` if the
  /// edge does not have an origin.
  String _buildDescriptionForOrigin(AstNode node) {
    String /*!*/ description;
    if (node.parent is ArgumentList) {
      if (node is NullLiteral) {
        description = "An explicit 'null' is passed as an argument";
      } else {
        description = "A nullable value is explicitly passed as an argument";
      }
    } else {
      if (node is NullLiteral) {
        description = "An explicit 'null' is assigned";
      } else {
        description = "A nullable value is assigned";
      }
    }
    if (_inTestCode(node)) {
      description += " in test code";
    }
    return description;
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
              details.add(RegionDetail(_buildDescriptionForOrigin(origin.node),
                  _targetForNode(origin.source.fullName, origin.node)));
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

  /// Return the migration information for the given library.
  LibraryInfo _explainLibrary(
      ResolvedLibraryResult result,
      InstrumentationInformation info,
      SourceInformation sourceInfo,
      DartFixListener listener) {
    List<UnitInfo> units = [];
    for (ResolvedUnitResult unitResult in result.units) {
      SourceFileEdit edit = listener.sourceChange.getFileEdit(unitResult.path);
      units.add(_explainUnit(sourceInfo, unitResult, edit));
    }
    return LibraryInfo(units);
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

  /// Return the navigation target corresponding to the given [node] in the file
  /// with the given [filePath].
  NavigationTarget _targetForNode(String filePath, AstNode node) {
    return _targetFor(filePath, node.offset, node.length);
  }

  /// Return the navigation target in the file with the given [filePath] at the
  /// given [offset] ans with the given [length].
  NavigationTarget _targetFor(String filePath, int offset, int length) {
    UnitInfo unitInfo = _unitForPath(filePath);
    NavigationTarget target = NavigationTarget(filePath, offset, length);
    unitInfo.targets.add(target);
    return target;
  }

  /// Return the unit info for the file at the given [path].
  UnitInfo _unitForPath(String path) {
    return unitMap.putIfAbsent(path, () => UnitInfo(path));
  }
}
