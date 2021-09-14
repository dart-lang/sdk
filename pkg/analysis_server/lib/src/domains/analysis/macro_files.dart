// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';

class MacroElementLocationProvider implements ElementLocationProvider {
  final MacroFiles _macroFiles;

  MacroElementLocationProvider(this._macroFiles);

  @override
  protocol.Location? forElement(Element element) {
    if (element is HasMacroGenerationData) {
      var macro = (element as HasMacroGenerationData).macro;
      if (macro != null) {
        return _forElement(element, macro);
      }
    }
  }

  protocol.Location? _forElement(Element element, MacroGenerationData macro) {
    var unitElement = element.thisOrAncestorOfType<CompilationUnitElement>();
    if (unitElement is! CompilationUnitElementImpl) {
      return null;
    }

    var generatedFile = _macroFiles.generatedFile(unitElement);
    if (generatedFile == null) {
      return null;
    }

    var nameOffset = element.nameOffset;
    var nameLength = element.nameLength;

    var lineInfo = generatedFile.lineInfo;
    var offsetLocation = lineInfo.getLocation(nameOffset);
    var endLocation = lineInfo.getLocation(nameOffset + nameLength);

    return protocol.Location(generatedFile.path, nameOffset, nameLength,
        offsetLocation.lineNumber, offsetLocation.columnNumber,
        endLine: endLocation.lineNumber, endColumn: endLocation.columnNumber);
  }
}

/// Note, this class changes the file system.
class MacroFiles {
  final ResourceProvider _resourceProvider;

  /// Keys are source paths.
  final Map<String, _MacroGeneratedFile> _files = {};

  MacroFiles(this._resourceProvider);

  /// If [unitElement] has macro-generated elements, write the combined
  /// content into a new file in `.dart_tool`, and return the description of
  /// this file.
  _MacroGeneratedFile? generatedFile(CompilationUnitElementImpl unitElement) {
    var sourcePath = unitElement.source.fullName;

    var result = _files[sourcePath];
    if (result != null) {
      return result;
    }

    var sourceFile = _resourceProvider.getFile(sourcePath);

    // TODO(scheglov) Use workspace?
    Folder? packageRoot;
    for (var parent in sourceFile.parent2.withAncestors) {
      if (parent.getChildAssumingFile(file_paths.pubspecYaml).exists) {
        packageRoot = parent;
        break;
      }
    }
    if (packageRoot == null) {
      return null;
    }

    var pathContext = _resourceProvider.pathContext;
    var relativePath = pathContext.relative(
      sourcePath,
      from: packageRoot.path,
    );
    var generatedPath = pathContext.join(
        packageRoot.path, '.dart_tool', 'analyzer', 'macro', relativePath);

    var generatedContent = unitElement.macroGeneratedContent;
    if (generatedContent == null) {
      return null;
    }

    try {
      _resourceProvider.getFile(generatedPath)
        ..parent2.create()
        ..writeAsStringSync(generatedContent);
    } on FileSystemException {
      return null;
    }

    return _files[sourcePath] = _MacroGeneratedFile(
      generatedPath,
      generatedContent,
    );
  }
}

class _MacroGeneratedFile {
  final String path;
  final String content;
  final LineInfo lineInfo;

  _MacroGeneratedFile(this.path, this.content)
      : lineInfo = LineInfo.fromContent(content);
}
