// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:meta/meta.dart';
import 'package:path/src/context.dart';

/// The page that is displayed when a preview of a valid Dart file is requested.
class DartFilePage extends PreviewPage {
  /// The information about the file being previewed.
  final UnitInfo unitInfo;

  /// Initialize a newly created Dart file page within the given [site]. The
  /// [unitInfo] provides the information needed to render the page.
  DartFilePage(PreviewSite site, this.unitInfo)
      // TODO(brianwilkerson) The path needs to be converted to use '/' if that
      //  isn't already done as part of building the unitInfo.
      : super(site, unitInfo.path.substring(1));

  @override
  void generateBody(Map<String, String> params) {
    throw UnsupportedError('generateBody');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    InstrumentationRenderer renderer = InstrumentationRenderer(
        unitInfo,
        PreviewMigrationInfo(site.migrationInfo),
        PreviewPathMapper(site.pathMapper));
    buf.write(renderer.render());
  }
}

/// A wrapper around a migration info that returns the expected paths to the
/// JS and CSS files.
class PreviewMigrationInfo implements MigrationInfo {
  /// The wrapped migration info.
  final MigrationInfo wrappedInfo;

  /// Initialize a newly created migration info to wrap the [wrappedInfo].
  PreviewMigrationInfo(this.wrappedInfo);

  @override
  String get includedRoot => wrappedInfo.includedRoot;

  @override
  String get migrationDate => wrappedInfo.migrationDate;

  @override
  Context get pathContext => wrappedInfo.pathContext;

  @override
  Map<String, UnitInfo> get unitMap => wrappedInfo.unitMap;

  @override
  Set<UnitInfo> get units => wrappedInfo.units;

  @override
  String highlightJsPath(UnitInfo unitInfo) {
    return PreviewSite.highlightJSPagePath;
  }

  @override
  String highlightStylePath(UnitInfo unitInfo) {
    return PreviewSite.highlightCssPagePath;
  }

  @override
  List<Map<String, Object>> unitLinks(UnitInfo currentUnit) {
    List<Map<String, Object>> links = [];
    for (UnitInfo unit in units) {
      int count = unit.fixRegions.length;
      String modificationCount =
          count == 1 ? '(1 modification)' : '($count modifications)';
      bool isNotCurrent = unit != currentUnit;
      links.add({
        'name': _computeName(unit),
        'modificationCount': modificationCount,
        'isLink': isNotCurrent,
        if (isNotCurrent) 'href': _pathTo(target: unit, source: currentUnit)
      });
    }
    return links;
  }

  /// Return the path to [unit] from [includedRoot], to be used as a display
  /// name for a library.
  String _computeName(UnitInfo unit) =>
      pathContext.relative(unit.path, from: includedRoot);

  /// The path to [target], relative to [from].
  String _pathTo({@required UnitInfo target, @required UnitInfo source}) {
    String targetPath = target.path;
    String sourceDir = pathContext.dirname(source.path);
    return pathContext.relative(targetPath, from: sourceDir);
  }
}

/// A wrapper around a path mapper that converts file paths to URIs.
class PreviewPathMapper implements PathMapper {
  /// The wrapped path mapper.
  final PathMapper wrappedMapper;

  /// Initialize a newly created path mapper to wrap the [wrappedMapper].
  PreviewPathMapper(this.wrappedMapper);

  @override
  int get nextIndex => wrappedMapper.nextIndex;

  @override
  void set nextIndex(int nextIndex) {
    wrappedMapper.nextIndex = nextIndex;
  }

  @override
  String get outputFolder => throw UnsupportedError('outputFolder');

  @override
  String get packageRoot => wrappedMapper.packageRoot;

  @override
  Map<String, String> get pathMap => throw UnsupportedError('pathMap');

  @override
  ResourceProvider get provider => wrappedMapper.provider;

  @override
  void set provider(ResourceProvider provider) {
    wrappedMapper.provider = provider;
  }

  @override
  String map(String path) {
    return Uri.file(path).path;
  }
}
