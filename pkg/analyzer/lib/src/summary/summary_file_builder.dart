// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.summary_file_builder;

import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;
import 'package:analyzer/src/summary/index_unit.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:path/path.dart';

const int FIELD_SPEC_INDEX = 1;
const int FIELD_SPEC_SUM = 0;
const int FIELD_STRONG_INDEX = 3;
const int FIELD_STRONG_SUM = 2;

class BuilderOutput {
  final List<int> sum;
  final List<int> index;

  BuilderOutput(this.sum, this.index);

  void writeMultiple(String outputDirectoryPath, String modeName) {
    // Write summary.
    {
      String outputPath = join(outputDirectoryPath, '$modeName.sum');
      File file = new File(outputPath);
      file.writeAsBytesSync(sum, mode: FileMode.WRITE_ONLY);
    }
    // Write index.
    {
      String outputPath = join(outputDirectoryPath, '$modeName.index');
      File file = new File(outputPath);
      file.writeAsBytesSync(index, mode: FileMode.WRITE_ONLY);
    }
  }
}

class SummaryBuilder {
  final AnalysisContext _context;
  final Iterable<Source> _librarySources;

  SummaryBuilder(this._librarySources, this._context);

  factory SummaryBuilder.forSdk(String sdkPath, bool strongMode) {
    //
    // Prepare SDK.
    //
    DirectoryBasedDartSdk sdk =
        new DirectoryBasedDartSdk(new JavaFile(sdkPath), strongMode);
    sdk.useSummary = false;
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = strongMode;

    //
    // Prepare 'dart:' URIs to serialize.
    //
    Set<String> uriSet =
        sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
    if (!strongMode) {
      uriSet.add('dart:html/nativewrappers.dart');
    }
    uriSet.add('dart:html_common/html_common_dart2js.dart');

    Set<Source> librarySources = new HashSet<Source>();
    for (String uri in uriSet) {
      librarySources.add(sdk.mapDartUri(uri));
    }

    return new SummaryBuilder(librarySources, sdk.context);
  }

  BuilderOutput build() => new _Builder(_context, _librarySources).build();
}

/**
 * Intermediary summary output result.
 */
class SummaryOutput {
  final BuilderOutput spec;
  final BuilderOutput strong;
  SummaryOutput(this.spec, this.strong);

  /**
   * Write this summary output to the given [outputPath] and return the
   * created file.
   */
  File write(String outputPath) {
    fb.Builder builder = new fb.Builder();
    fb.Offset specSumOffset = builder.writeListUint8(spec.sum);
    fb.Offset specIndexOffset = builder.writeListUint8(spec.index);
    fb.Offset strongSumOffset = builder.writeListUint8(strong.sum);
    fb.Offset strongIndexOffset = builder.writeListUint8(strong.index);
    builder.startTable();
    builder.addOffset(FIELD_SPEC_SUM, specSumOffset);
    builder.addOffset(FIELD_SPEC_INDEX, specIndexOffset);
    builder.addOffset(FIELD_STRONG_SUM, strongSumOffset);
    builder.addOffset(FIELD_STRONG_INDEX, strongIndexOffset);
    fb.Offset offset = builder.endTable();
    return new File(outputPath)
      ..writeAsBytesSync(builder.finish(offset), mode: FileMode.WRITE_ONLY);
  }
}

class _Builder {
  final Set<Source> processedSources = new Set<Source>();

  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
  final PackageIndexAssembler indexAssembler = new PackageIndexAssembler();

  final AnalysisContext context;
  final Iterable<Source> librarySources;

  _Builder(this.context, this.librarySources);

  /**
   * Build a strong or spec mode summary for the Dart SDK at [sdkPath].
   */
  BuilderOutput build() {
    //
    // Serialize each source.
    //
    for (Source source in librarySources) {
      _serializeLibrary(source);
    }
    //
    // Assemble the output.
    //
    List<int> sumBytes = bundleAssembler.assemble().toBuffer();
    List<int> indexBytes = indexAssembler.assemble().toBuffer();
    return new BuilderOutput(sumBytes, indexBytes);
  }

  /**
   * Serialize the library with the given [source] and all its direct or
   * indirect imports and exports.
   */
  void _serializeLibrary(Source source) {
    if (!processedSources.add(source)) {
      return;
    }
    LibraryElement element = context.computeLibraryElement(source);
    bundleAssembler.serializeLibraryElement(element);
    element.importedLibraries.forEach((e) => _serializeLibrary(e.source));
    element.exportedLibraries.forEach((e) => _serializeLibrary(e.source));
    // Index every unit of the library.
    for (CompilationUnitElement unitElement in element.units) {
      Source unitSource = unitElement.source;
      CompilationUnit unit =
          context.resolveCompilationUnit2(unitSource, source);
      indexAssembler.indexUnit(unit);
    }
  }
}
