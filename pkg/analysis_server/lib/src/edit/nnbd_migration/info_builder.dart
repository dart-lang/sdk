// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show Location, SourceEdit, SourceFileEdit;
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
        ParsedLibraryResult result = await session.getParsedLibrary(filePath);
        libraries
            .add(_explainLibrary(result, info, sourceInfo[source], listener));
      }
    }
    return libraries;
  }

  /// Compute the details for the fix with the given [fixInfo].
  List<RegionDetail> _computeDetails(FixInfo fixInfo) {
    List<RegionDetail> details = [];
    for (FixReasonInfo reason in fixInfo.reasons) {
      if (reason is NullabilityNodeInfo) {
        for (EdgeInfo edge in reason.upstreamEdges) {
          EdgeOriginInfo origin = info.edgeOrigin[edge];
          if (origin != null) {
            AstNode node = origin.node;
            if (node.parent is ArgumentList) {
              if (node is NullLiteral) {
                details.add(RegionDetail(
                    'null is explicitly passed as an argument.',
                    _targetFor(origin)));
              } else {
                details.add(RegionDetail(
                    'A nullable value is explicitly passed as an argument.',
                    _targetFor(origin)));
              }
            } else {
              details.add(RegionDetail(
                  'A nullable value is assigned.', _targetFor(origin)));
            }
          }
        }
      } else if (reason is EdgeInfo) {
        // TODO(brianwilkerson) Implement this after finding an example whose
        //  reason is an edge.
      } else {
        throw UnimplementedError(
            'Unexpected class of reason: ${reason.runtimeType}');
      }
    }
    return details;
  }

  /// Return the migration information for the given library.
  LibraryInfo _explainLibrary(
      ParsedLibraryResult result,
      InstrumentationInformation info,
      SourceInformation sourceInfo,
      DartFixListener listener) {
    List<UnitInfo> units = [];
    for (ParsedUnitResult unit in result.units) {
      SourceFileEdit edit = listener.sourceChange.getFileEdit(unit.path);
      units.add(_explainUnit(sourceInfo, unit, edit));
    }
    return LibraryInfo(units);
  }

  /// Return the migration information for the given unit.
  UnitInfo _explainUnit(SourceInformation sourceInfo, ParsedUnitResult result,
      SourceFileEdit fileEdit) {
    List<RegionInfo> regions = [];
    String content = result.content;
    // [fileEdit] is null when a file has no edits.
    if (fileEdit == null) {
      return UnitInfo(result.path, content, regions);
    }
    List<SourceEdit> edits = fileEdit.edits;
    edits.sort((first, second) => first.offset.compareTo(second.offset));
    // Compute the deltas for the regions that will be computed as we apply the
    // edits. We need the deltas because the offsets to the regions are relative
    // to the edited source, but the edits are being applied in reverse order so
    // the offset in the pre-edited source will not match the offset in the
    // post-edited source. The deltas compensate for that difference.
    List<int> deltas = [];
    int previousDelta = 0;
    for (SourceEdit edit in edits) {
      deltas.add(previousDelta);
      previousDelta += (edit.replacement.length - edit.length);
    }
    // Apply edits in reverse order and build the regions.
    int index = edits.length - 1;
    for (SourceEdit edit in edits.reversed) {
      int offset = edit.offset;
      int length = edit.length;
      String replacement = edit.replacement;
      int end = offset + length;
      int delta = deltas[index--];
      // Insert the replacement text without deleting the replaced text.
      content = content.replaceRange(end, end, replacement);
      FixInfo fixInfo = _findFixInfo(sourceInfo, offset);
      String explanation = '${fixInfo.fix.description.appliedMessage}.';
      List<RegionDetail> details = _computeDetails(fixInfo);
      if (length > 0) {
        regions.add(RegionInfo(offset + delta, length, explanation, details));
      }
      regions.add(
          RegionInfo(end + delta, replacement.length, explanation, details));
    }
    regions.sort((first, second) => first.offset.compareTo(second.offset));
    return UnitInfo(result.path, content, regions);
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

  NavigationTarget _targetFor(EdgeOriginInfo origin) {
    AstNode node = origin.node;
    return NavigationTarget(origin.source.fullName, node.offset, node.length);
  }
}
