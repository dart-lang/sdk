// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Handles textDocument/colorPresentation.
///
/// This request is sent by the client if it allowed the user to pick a color
/// using a color picker (in a location returned by textDocument/documentColor)
/// and needs a representation of this color, including the edits to insert it
/// into the source file.
class DocumentColorPresentationHandler
    extends
        SharedMessageHandler<ColorPresentationParams, List<ColorPresentation>> {
  /// A pattern for removing trailing zeros (and if no decimal part, the period)
  /// from numbers formatted for code.
  final _trailingZerosAndPeriodPattern = RegExp(r'\.?0+$');

  DocumentColorPresentationHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_colorPresentation;

  @override
  LspJsonHandler<ColorPresentationParams> get jsonHandler =>
      ColorPresentationParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<List<ColorPresentation>>> handle(
    ColorPresentationParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success([]);
    }

    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
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
    required InterfaceElement2 colorType,
    required String typeName,
    required String invocationString,
    required bool includeConstKeyword,
  }) async {
    var builder = ChangeBuilder(session: unit.session);
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
    var editsForThisFile =
        builder.sourceChange.edits
            .where((edit) => edit.file == unit.path)
            .expand((edit) => edit.edits)
            .toList();

    // LSP requires that we separate the main edit (changing the color code)
    // from anything else (imports).
    var mainEdit = editsForThisFile.singleWhere(
      (edit) => edit.offset == editRange.offset,
    );
    var otherEdits = editsForThisFile.where(
      (edit) => edit.offset != editRange.offset,
    );

    return ColorPresentation(
      label: '$typeName$invocationString',
      textEdit: toTextEdit(unit.lineInfo, mainEdit),
      additionalTextEdits:
          otherEdits.isNotEmpty
              ? otherEdits
                  .map((edit) => toTextEdit(unit.lineInfo, edit))
                  .toList()
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
    var analysisContext = unit.session.analysisContext;
    if (!analysisContext.contextRoot.isAnalyzed(unit.path)) {
      return success([]);
    }

    var alphaDouble = params.color.alpha;
    var redDouble = params.color.red;
    var greenDouble = params.color.green;
    var blueDouble = params.color.blue;
    var opacityDouble = params.color.alpha;

    var alphaDoubleRounded = _roundDouble(alphaDouble);
    var redDoubleRounded = _roundDouble(redDouble);
    var greenDoubleRounded = _roundDouble(greenDouble);
    var blueDoubleRounded = _roundDouble(blueDouble);

    // The values in LSP are decimals 0-1 so should be scaled up to 255 that
    // we use internally (except for opacity is which 0-1).
    var alpha = (alphaDouble * 255).toInt();
    var red = (redDouble * 255).toInt();
    var green = (greenDouble * 255).toInt();
    var blue = (blueDouble * 255).toInt();

    var editStart = toOffset(unit.lineInfo, params.range.start);
    var editEnd = toOffset(unit.lineInfo, params.range.end);

    return (editStart, editEnd).mapResults((editStart, editEnd) async {
      var editRange = SourceRange(editStart, editEnd - editStart);

      var sessionHelper = AnalysisSessionHelper(unit.session);
      var colorType = await sessionHelper.getFlutterClass2('Color');
      if (colorType == null) {
        // If we can't find the class (perhaps because this isn't a Flutter
        // project) we will not include any results. In theory the client should
        // not be calling this request in that case.
        return success([]);
      }

      var requiresConstKeyword = _willRequireConstKeyword(
        editRange.offset,
        unit,
      );
      var colorValue = _colorValueForComponents(alpha, red, green, blue);
      var colorValueHex =
          '0x${colorValue.toRadixString(16).toUpperCase().padLeft(8, '0')}';

      var colorFromARGB = await _createColorPresentation(
        unit: unit,
        editRange: editRange,
        colorType: colorType,
        typeName: 'Color',
        invocationString: '.fromARGB($alpha, $red, $green, $blue)',
        includeConstKeyword: requiresConstKeyword,
      );

      var colorFromRGBO = await _createColorPresentation(
        unit: unit,
        editRange: editRange,
        colorType: colorType,
        typeName: 'Color',
        invocationString: '.fromRGBO($red, $green, $blue, $opacityDouble)',
        includeConstKeyword: requiresConstKeyword,
      );

      var colorFrom = await _createColorPresentation(
        unit: unit,
        editRange: editRange,
        colorType: colorType,
        typeName: 'Color',
        invocationString:
            '.from(alpha: $alphaDoubleRounded, red: $redDoubleRounded, '
            'green: $greenDoubleRounded, blue: $blueDoubleRounded)',
        includeConstKeyword: requiresConstKeyword,
      );

      var colorDefault = await _createColorPresentation(
        unit: unit,
        editRange: editRange,
        colorType: colorType,
        typeName: 'Color',
        invocationString: '($colorValueHex)',
        includeConstKeyword: requiresConstKeyword,
      );

      return success([colorFromARGB, colorFromRGBO, colorFrom, colorDefault]);
    });
  }

  /// Rounds doubles to 3 decimal places for writing into code because that's
  /// enough to preserve the 255 values supported by color pickers without
  /// looking like:
  ///
  /// ```
  /// Color.from(alpha: 1, red: 0.7490196078431373, green: 0.5019607843137255, blue: 0.25098039215686274)
  /// ```
  String _roundDouble(num value) {
    return value
        .toStringAsFixed(3)
        .replaceAll(_trailingZerosAndPeriodPattern, '');
  }

  /// Checks whether a `const` keyword is required in front of inserted
  /// constructor calls to preserve existing semantics.
  ///
  /// `const` should be inserted if the existing expression is constant but
  /// we are not already in a constant context.
  bool _willRequireConstKeyword(int offset, ResolvedUnitResult unit) {
    var node = NodeLocator2(offset).searchWithin(unit.unit);
    if (node is! Expression) {
      return false;
    }

    // `const` is unnecessary if we're in a constant context.
    if (node.inConstantContext) {
      return false;
    }

    if (node is InstanceCreationExpression) {
      return node.isConst;
    } else if (node is SimpleIdentifier) {
      var parent = node.parent;
      var element =
          parent is PrefixedIdentifier ? parent.element : node.element;

      return switch (element) {
        GetterElement(:var variable3) || SetterElement(:var variable3) =>
          variable3?.isConst ?? false,
        VariableElement2() => element.isConst,
        _ => false,
      };
    } else {
      return false;
    }
  }
}
