// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Handles textDocument/colorPresentation.
///
/// This request is sent by the client if it allowed the user to pick a color
/// using a color picker (in a location returned by textDocument/documentColor)
/// and needs a representation of this color, including the edits to insert it
/// into the source file.
class DocumentColorPresentationHandler extends LspMessageHandler<
    ColorPresentationParams, List<ColorPresentation>> {
  DocumentColorPresentationHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_colorPresentation;

  @override
  LspJsonHandler<ColorPresentationParams> get jsonHandler =>
      ColorPresentationParams.jsonHandler;

  @override
  Future<ErrorOr<List<ColorPresentation>>> handle(
    ColorPresentationParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success([]);
    }

    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    return unit.mapResult((unit) => _getPresentations(params, unit));
  }

  /// Converts individual 0-255 ARGB values into a single int value as
  /// 0xAARRGGBB as used by the dart:ui Color class.
  int _colorValueForComponents(int alpha, int red, int green, int blue) {
    return (alpha << 24) | (red << 16) | (green << 8) | (blue << 0);
  }

  /// Creates a [ColorPresentation] for inserting code to produce a dart:ui
  /// or Flutter Color at [editRange].
  ///
  /// [colorType] is the Type of the Color class whose constructor will be
  /// called. This will be replaced into [editRange] and any required import
  /// statement will produce additional edits.
  ///
  /// [label] is the visible label shown to the user and should roughly reflect
  /// the code that will be inserted.
  ///
  /// [invocationString] is written immediately after [colorType] in [editRange].
  Future<ColorPresentation> _createColorPresentation({
    required ResolvedUnitResult unit,
    required SourceRange editRange,
    required InterfaceElement colorType,
    required String label,
    required String invocationString,
    required bool includeConstKeyword,
  }) async {
    final builder = ChangeBuilder(session: unit.session);
    await builder.addDartFileEdit(unit.path, (builder) {
      builder.addReplacement(editRange, (builder) {
        if (includeConstKeyword) {
          builder.write('const ');
        }
        builder.writeType(colorType.thisType);
        builder.write(invocationString);
      });
    });

    // We can only apply changes to the same file, so filter any change from the
    // builder to only include this file, otherwise we may corrupt the users
    // source (although hopefully we don't produce edits for other files).
    final editsForThisFile = builder.sourceChange.edits
        .where((edit) => edit.file == unit.path)
        .expand((edit) => edit.edits)
        .toList();

    // LSP requires that we separate the main edit (changing the color code)
    // from anything else (imports).
    final mainEdit =
        editsForThisFile.singleWhere((edit) => edit.offset == editRange.offset);
    final otherEdits =
        editsForThisFile.where((edit) => edit.offset != editRange.offset);

    return ColorPresentation(
      label: label,
      textEdit: toTextEdit(unit.lineInfo, mainEdit),
      additionalTextEdits: otherEdits.isNotEmpty
          ? otherEdits.map((edit) => toTextEdit(unit.lineInfo, edit)).toList()
          : null,
    );
  }

  /// Builds a list of valid color presentations for the requested color.
  Future<ErrorOr<List<ColorPresentation>>> _getPresentations(
    ColorPresentationParams params,
    ResolvedUnitResult unit,
  ) async {
    // If this file is outside of analysis roots, we cannot build edits for it
    // so return null to signal to the client that it should not try to modify
    // the source.
    final analysisContext = unit.session.analysisContext;
    if (!analysisContext.contextRoot.isAnalyzed(unit.path)) {
      return success([]);
    }

    // The values in LSP are decimals 0-1 so should be scaled up to 255 that
    // we use internally (except for opacity is which 0-1).
    final alpha = (params.color.alpha * 255).toInt();
    final red = (params.color.red * 255).toInt();
    final green = (params.color.green * 255).toInt();
    final blue = (params.color.blue * 255).toInt();
    final opacity = params.color.alpha;

    final editStart = toOffset(unit.lineInfo, params.range.start);
    final editEnd = toOffset(unit.lineInfo, params.range.end);

    if (editStart.isError) return failure(editStart);
    if (editEnd.isError) return failure(editEnd);

    final editRange =
        SourceRange(editStart.result, editEnd.result - editStart.result);

    final sessionHelper = AnalysisSessionHelper(unit.session);
    final flutter = Flutter.instance;
    final colorType = await sessionHelper.getClass(flutter.widgetsUri, 'Color');
    if (colorType == null) {
      // If we can't find the class (perhaps because this isn't a Flutter
      // project) we will not include any results. In theory the client should
      // not be calling this request in that case.
      return success([]);
    }

    final requiresConstKeyword =
        _willRequireConstKeyword(editRange.offset, unit);
    final colorValue = _colorValueForComponents(alpha, red, green, blue);
    final colorValueHex =
        '0x${colorValue.toRadixString(16).toUpperCase().padLeft(8, '0')}';

    final colorFromARGB = await _createColorPresentation(
      unit: unit,
      editRange: editRange,
      colorType: colorType,
      label: 'Color.fromARGB($alpha, $red, $green, $blue)',
      invocationString: '.fromARGB($alpha, $red, $green, $blue)',
      includeConstKeyword: requiresConstKeyword,
    );

    final colorFromRGBO = await _createColorPresentation(
      unit: unit,
      editRange: editRange,
      colorType: colorType,
      label: 'Color.fromRGBO($red, $green, $blue, $opacity)',
      invocationString: '.fromRGBO($red, $green, $blue, $opacity)',
      includeConstKeyword: requiresConstKeyword,
    );

    final colorDefault = await _createColorPresentation(
      unit: unit,
      editRange: editRange,
      colorType: colorType,
      label: 'Color($colorValueHex)',
      invocationString: '($colorValueHex)',
      includeConstKeyword: requiresConstKeyword,
    );

    return success([
      colorFromARGB,
      colorFromRGBO,
      colorDefault,
    ]);
  }

  /// Checks whether a `const` keyword is required in front of inserted
  /// constructor calls to preserve existing semantics.
  bool _willRequireConstKeyword(int offset, ResolvedUnitResult unit) {
    // We should insert `const` if the existing expression is constant, but
    // we are not already in a constant context.
    var node = NodeLocator2(offset).searchWithin(unit.unit);

    if (node is! SimpleIdentifier) {
      return false;
    }

    final parent = node.parent;
    final staticElement = parent is PrefixedIdentifier
        ? parent.staticElement
        : node.staticElement;
    final target = staticElement is PropertyAccessorElement
        ? staticElement.variable
        : staticElement;

    final existingIsConst = target is ConstVariableElement;
    final isInConstantContext = node.inConstantContext;

    return existingIsConst && !isInConstantContext;
  }
}
