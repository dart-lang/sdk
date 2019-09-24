// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A builder used to build the migration information for a library.
class InfoBuilder {
  /// The analysis session used to get information about libraries.
  AnalysisServer server;

  /// Initialize a newly created builder.
  InfoBuilder(this.server);

  /// Return the migration information for all of the libraries that were
  /// migrated.
  Future<List<LibraryInfo>> explainMigration(
      InstrumentationInformation info, DartFixListener listener) async {
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

  /// Return the migration information for the given library.
  LibraryInfo _explainLibrary(
      ParsedLibraryResult result,
      InstrumentationInformation info,
      SourceInformation sourceInfo,
      DartFixListener listener) {
    List<UnitInfo> units = [];
    for (ParsedUnitResult unit in result.units) {
      SourceFileEdit edit = listener.sourceChange.getFileEdit(unit.path);
      units.add(_explainUnit(unit, edit));
    }
    return LibraryInfo(units);
  }

  /// Return the migration information for the given unit.
  UnitInfo _explainUnit(ParsedUnitResult result, SourceFileEdit fileEdit) {
    List<RegionInfo> regions = [];
    String content = result.content;
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
      int end = offset + length - 1;
      int delta = deltas[index--];
      // Insert the replacement text without deleting the replaced text.
      content = content.replaceRange(end, end, replacement);
      if (length > 0) {
        // TODO(brianwilkerson) Create a sensible explanation.
        regions.add(RegionInfo(offset + delta, length, 'removed'));
      }
      // TODO(brianwilkerson) Create a sensible explanation.
      regions.add(RegionInfo(end + delta, replacement.length, 'added'));
    }
    regions.sort((first, second) => first.offset.compareTo(second.offset));
    return UnitInfo(result.path, content, regions);
  }
}
