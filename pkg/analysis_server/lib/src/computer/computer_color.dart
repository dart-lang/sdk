// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/value.dart' show GenericState;
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// Computer for dart:ui/Flutter Color references.
class ColorComputer {
  final ResolvedUnitResult resolvedUnit;
  final List<ColorReference> _colors = [];

  ColorComputer(this.resolvedUnit, path.Context pathContext);

  /// Returns information about the color references in [resolvedUnit].
  ///
  /// This method should only be called once for any instance of this class.
  List<ColorReference> compute() {
    var visitor = _ColorBuilder(this);
    resolvedUnit.unit.accept(visitor);
    assert(
      _colors.length == _colors.map((color) => color.offset).toSet().length,
      'Every color reference should have a unique offset',
    );
    return _colors;
  }

  /// Tries to add a color for the [expression].
  ///
  /// If [target] is supplied, will be used instead of [expression] allowing
  /// a value to be read from the member [memberName] or from a swatch value
  /// with index [index].
  bool tryAddColor(
    Expression expression, {
    Expression? target,
    String? memberName,
    int? index,
  }) {
    if (!expression.staticType.isColor) return false;

    target ??= expression;

    // Try to evaluate the constant target.
    var colorConstResult = target.computeConstantValue();
    var colorConst = colorConstResult.value;
    if (colorConstResult.errors.isNotEmpty || colorConst == null) return false;

    // If we want a specific member or swatch index, read that.
    if (memberName != null) {
      colorConst = _getMember(colorConst, memberName);
    } else if (index != null) {
      colorConst = _getSwatchColor(colorConst, index);
    }

    return _tryRecordColor(expression, colorConst);
  }

  /// Tries to add a color for the instance creation [expression].
  ///
  /// This handles constructor calls that cannot be evaluated (for example
  /// because they are not const) but are simple well-known dart:ui/Flutter
  /// color constructors that we can manually parse.
  bool tryAddKnownColorConstructor(InstanceCreationExpression expression) {
    if (!expression.staticType.isColor) return false;

    var constructor = expression.constructorName;
    var staticElement = constructor.element;
    var classElement = staticElement?.enclosingElement2;
    var className = classElement?.name;
    var constructorName = constructor.name?.name;
    var constructorArgs = expression.argumentList.arguments.toList();

    ColorInformation? color;
    if (_isDartUi(classElement) && className == 'Color') {
      color = _getDartUiColor(constructorName, constructorArgs);
    } else if (_isFlutterPainting(classElement) && className == 'ColorSwatch') {
      color = _getFlutterSwatchColor(constructorName, constructorArgs);
    } else if (_isFlutterMaterial(classElement) &&
        className == 'MaterialAccentColor') {
      color = _getFlutterMaterialAccentColor(constructorName, constructorArgs);
    }

    return _tryRecordColorInformation(expression, color);
  }

  /// Extracts the color information from dart:ui Color constructor args.
  ColorInformation? _getDartUiColor(String? name, List<Expression> args) {
    if (name == null && args.length == 1) {
      // Color(0xFF000000).
      var arg0 = args[0];
      return arg0 is IntegerLiteral ? getColorForInt(arg0.value) : null;
    } else if (name == 'from') {
      // Color.from(alpha: 1, red: 1, green: 1, blue: 1).
      double? alpha, red, green, blue;
      for (var arg in args.whereType<NamedExpression>()) {
        var expression = arg.expression;
        var value = expression is DoubleLiteral
            ? expression.value
            : expression is IntegerLiteral
                ? expression.value?.toDouble()
                : null;
        switch (arg.name.label.name) {
          case 'alpha':
            alpha = value;
          case 'red':
            red = value;
          case 'green':
            green = value;
          case 'blue':
            blue = value;
        }
      }
      return getColorForDoubles(
        alpha: alpha,
        red: red,
        green: green,
        blue: blue,
      );
    } else if (name == 'fromARGB' && args.length == 4) {
      // Color.fromARGB(255, 255, 255, 255).
      var arg0 = args[0];
      var arg1 = args[1];
      var arg2 = args[2];
      var arg3 = args[3];

      var alpha = arg0 is IntegerLiteral ? arg0.value : null;
      var red = arg1 is IntegerLiteral ? arg1.value : null;
      var green = arg2 is IntegerLiteral ? arg2.value : null;
      var blue = arg3 is IntegerLiteral ? arg3.value : null;

      return alpha != null && red != null && green != null && blue != null
          ? ColorInformation(alpha, red, green, blue)
          : null;
    } else if (name == 'fromRGBO' && args.length == 4) {
      // Color.fromRGBO(255, 255, 255, 1.0).
      var arg0 = args[0];
      var arg1 = args[1];
      var arg2 = args[2];
      var arg3 = args[3];

      var red = arg0 is IntegerLiteral ? arg0.value : null;
      var green = arg1 is IntegerLiteral ? arg1.value : null;
      var blue = arg2 is IntegerLiteral ? arg2.value : null;
      var opacity = arg3 is IntegerLiteral
          ? arg3.value
          : arg3 is DoubleLiteral
              ? arg3.value
              : null;
      var alpha = opacity != null ? (opacity * 255).toInt() : null;

      return alpha != null && red != null && green != null && blue != null
          ? ColorInformation(alpha, red, green, blue)
          : null;
    } else {
      return null;
    }
  }

  /// Extracts the color from Flutter MaterialAccentColor constructor args.
  ColorInformation? _getFlutterMaterialAccentColor(
          String? name, List<Expression> args) =>
      // MaterialAccentColor is a subclass of SwatchColor and has the same
      // constructor.
      _getFlutterSwatchColor(name, args);

  /// Extracts the color information from Flutter ColorSwatch constructor args.
  ColorInformation? _getFlutterSwatchColor(
      String? name, List<Expression> args) {
    if (name == null && args.isNotEmpty) {
      var arg0 = args[0];
      return arg0 is IntegerLiteral ? getColorForInt(arg0.value) : null;
    } else {
      return null;
    }
  }

  /// Extracts a named member from a color.
  ///
  /// Well-known getters like `shade500` will be mapped onto the swatch value
  /// with a matching index.
  DartObject? _getMember(DartObject target, String memberName) {
    var color = target.getFieldFromHierarchy(memberName);
    if (color != null) {
      return color;
    }

    // If we didn't get a color but it's a getter we know how to read from a
    // swatch, try that.
    if (memberName.startsWith('shade')) {
      var shadeNumber = int.tryParse(memberName.substring(5));
      if (shadeNumber != null) {
        return _getSwatchColor(target, shadeNumber);
      }
    }

    return null;
  }

  /// Extracts a specific shade index from a Flutter SwatchColor.
  DartObject? _getSwatchColor(DartObject target, int swatchValue) {
    var swatch = target.getFieldFromHierarchy('_swatch')?.toMapValue();
    if (swatch == null) return null;

    var key = swatch.keys.firstWhereOrNull(
      (key) => key?.toIntValue() == swatchValue,
    );
    if (key == null) return null;

    return swatch[key];
  }

  /// Checks whether this elements library is dart:ui.
  bool _isDartUi(Element2? element) => element?.library2?.name == 'dart.ui';

  /// Checks whether this elements library is Flutter Material colors.
  bool _isFlutterMaterial(Element2? element) =>
      element?.library2?.identifier ==
      'package:flutter/src/material/colors.dart';

  /// Checks whether this elements library is Flutter Painting colors.
  bool _isFlutterPainting(Element2? element) =>
      element?.library2?.identifier ==
      'package:flutter/src/painting/colors.dart';

  /// Tries to record a color from [colorConst] for [expression].
  ///
  /// Returns whether a valid color was found and recorded.
  bool _tryRecordColor(Expression expression, DartObject? colorConst) =>
      _tryRecordColorInformation(expression, getColorForObject(colorConst));

  /// Tries to record the [color] for [expression].
  ///
  /// Returns whether a valid color was found and recorded.
  bool _tryRecordColorInformation(
      Expression expression, ColorInformation? color) {
    if (color == null) return false;

    // Record the color against the original entire expression.
    _colors.add(ColorReference(expression.offset, expression.length, color));
    return true;
  }

  /// Gets [ColorInformation] from a set of doubles that are stored internally
  /// in a dart:ui Color object.
  static ColorInformation? getColorForDoubles({
    required double? alpha,
    required double? red,
    required double? green,
    required double? blue,
  }) {
    return alpha != null && red != null && green != null && blue != null
        ? ColorInformation(
            (alpha * 255.0).round() & 0xff,
            (red * 255.0).round() & 0xff,
            (green * 255.0).round() & 0xff,
            (blue * 255.0).round() & 0xff,
          )
        : null;
  }

  /// Gets [ColorInformation] from a value like `0xFFFF9000` which is used in
  /// the default `Color()` constructor.
  static ColorInformation? getColorForInt(int? value) {
    return value != null
        ? ColorInformation(
            (value >> 24) & 0xff,
            (value >> 16) & 0xff,
            (value >> 8) & 0xff,
            value & 0xff,
          )
        : null;
  }

  /// Gets [ColorInformation] from the dart:ui Color object [color].
  static ColorInformation? getColorForObject(DartObject? color) {
    if (color == null || color.isNull || !color.type.isColor) return null;

    // If the object has a "color" field, walk down to that, because some colors
    // like CupertinoColors have a "value=0" with an overridden getter that
    // would always result in a value representing black.
    color = color.getFieldFromHierarchy('color') ?? color;

    var alpha = color.getFieldFromHierarchy('a')?.toDoubleValue();
    var red = color.getFieldFromHierarchy('r')?.toDoubleValue();
    var green = color.getFieldFromHierarchy('g')?.toDoubleValue();
    var blue = color.getFieldFromHierarchy('b')?.toDoubleValue();

    return getColorForDoubles(
      alpha: alpha,
      red: red,
      green: green,
      blue: blue,
    );
  }
}

/// Information about a color that is present in a document.
class ColorInformation {
  /// Alpha as a value from 0 to 255.
  final int alpha;

  /// Red as a value from 0 to 255.
  final int red;

  /// Green as a value from 0 to 255.
  final int green;

  /// Blue as a value from 0 to 255.
  final int blue;

  ColorInformation(this.alpha, this.red, this.green, this.blue);
}

/// Information about a specific known location of a [ColorInformation]
/// reference in a document.
class ColorReference {
  final int offset;
  final int length;
  final ColorInformation color;

  ColorReference(this.offset, this.length, this.color);
}

class _ColorBuilder extends RecursiveAstVisitor<void> {
  final ColorComputer computer;

  _ColorBuilder(this.computer);

  @override
  void visitIndexExpression(IndexExpression node) {
    // Colors.redAccent[500].
    var index = node.index;
    var indexValue = index is IntegerLiteral ? index.value : null;
    if (indexValue != null) {
      if (computer.tryAddColor(
        node,
        target: node.realTarget,
        index: indexValue,
      )) {
        return;
      }
    }
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Usually we return after finding a color, but constructors can
    // have nested colors in their arguments so we walk all the way down.
    if (!computer.tryAddColor(node)) {
      // If we couldn't evaluate the constant, try the well-known color
      // constructors for dart:ui/Flutter.
      computer.tryAddKnownColorConstructor(node);
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Try the whole node as a constant (eg. `MyThemeClass.staticField`).
    if (computer.tryAddColor(node)) {
      return;
    }

    // Try a field of a static, (eg. `const MyThemeClass().instanceField`).
    if (computer.tryAddColor(
      node,
      target: node.prefix,
      memberName: node.identifier.name,
    )) {
      return;
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Handle things like CupertinoColors.activeBlue.darkColor where we can't
    // evaluate the whole expression, but can evaluate CupertinoColors.activeBlue
    // and read the darkColor.
    if (computer.tryAddColor(
      node,
      target: node.realTarget,
      memberName: node.propertyName.name,
    )) {
      return;
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    computer.tryAddColor(node);

    super.visitSimpleIdentifier(node);
  }
}

extension _DartObjectExtensions on DartObject {
  /// Reads the value of the field [field] from this object.
  ///
  /// If the field is not found, recurses up the super classes.
  DartObject? getFieldFromHierarchy(String fieldName) =>
      getField(fieldName) ??
      getField(GenericState.SUPERCLASS_FIELD)?.getFieldFromHierarchy(fieldName);
}
