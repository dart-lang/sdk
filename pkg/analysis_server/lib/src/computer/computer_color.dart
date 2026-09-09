// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/value.dart' show GenericState;
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// Computer for dart:ui/Flutter Color references.
class ColorComputer {
  final ResolvedUnitResult resolvedUnit;
  final List<ColorReference> _colors = [];

  new(this.resolvedUnit, path.Context pathContext);

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

  /// Extracts color information for the instance creation [expression].
  ///
  /// This handles constructor calls that cannot be evaluated (for example
  /// because they are not const) but are simple well-known dart:ui/Flutter
  /// color constructors that we can manually parse.
  ColorInformation? getConstructorInvocationColorInformation(
    // InvocationExpression or InstanceCreationExpression
    Expression expression,
    ConstructorReferenceNode? constructor,
    ArgumentList argumentList,
  ) {
    if (!expression.staticType.isColor) return null;

    var classElement = constructor?.element?.enclosingElement;
    var className = classElement?.name;
    var constructorName = constructor?.element?.name;
    var constructorArgs = argumentList.arguments.toList();

    // Handle `.new` constructors the same as if called without `.new`.
    if (constructorName == 'new') {
      constructorName = null;
    }

    ColorInformation? color;
    if (_isDartUi(classElement) && className == 'Color') {
      color = _getDartUiColor(constructorName, constructorArgs);
    } else if (_isFlutterPainting(classElement) && className == 'ColorSwatch') {
      color = _getFlutterSwatchColor(constructorName, constructorArgs);
    } else if (_isFlutterMaterial(classElement) &&
        className == 'MaterialAccentColor') {
      color = _getFlutterMaterialAccentColor(constructorName, constructorArgs);
    }

    return color;
  }

  /// Extract the [ColorInformation] for an expression.
  ///
  /// Handles invocations such as constructors and withX() calls, as well as
  /// static constants (via [getExpressionColorObject]). This method calls
  /// itself recusrively to handle expressions like
  /// `Color.fromARGB(...).withRed(...)`.
  ColorInformation? getExpressionColorInformation(Expression expression) {
    var colorObject = getExpressionColorObject(expression);
    if (colorObject != null) {
      return getColorForObject(colorObject);
    }

    // Otherwise, see if we are a supported invocation.
    if (expression is InstanceCreationExpression) {
      return getConstructorInvocationColorInformation(
        expression,
        expression.constructorName,
        expression.argumentList,
      );
    } else if (expression is DotShorthandConstructorInvocation) {
      return getConstructorInvocationColorInformation(
        expression,
        expression,
        expression.argumentList,
      );
    } else if (expression case MethodInvocation(:var realTarget?)) {
      var baseColor = getExpressionColorInformation(realTarget);
      return baseColor != null
          ? getInvocationModifiedColor(baseColor, expression)
          : null;
    }

    // Otherwise, we can't handle this expression.
    return null;
  }

  /// Extract the [DartObject] representing the colour of an expression.
  ///
  /// If [memberName] or [index] are provided, the color will be read from the
  /// member or indexer. This method calls itself recursively to handle member
  /// access so the caller does not usually need to provide these values.
  ///
  /// This method only extracts underlying [DartObject]s and therefore does not
  /// handle invocations that cannot be computed as constants. Use
  /// [getExpressionColorInformation] to handle all expressions (which calls
  /// here).
  DartObject? getExpressionColorObject(
    Expression expression, {
    String? memberName,
    int? index,
  }) {
    // Exit out early if we are an expression that is not a color, but only
    // if we will not try to read a member/index.
    if (!expression.staticType.isColor && memberName == null && index == null) {
      return null;
    }

    // Try to evaluate the constant target.
    var colorConstResult = expression.computeConstantValue();
    var colorConst = colorConstResult?.value;
    if (colorConstResult == null ||
        colorConstResult.diagnostics.isNotEmpty ||
        colorConst == null) {
      // If we failed to compute a constant, try handling member access.
      if (expression is PrefixedIdentifier) {
        // MyThemeClass().instanceField
        return getExpressionColorObject(
          expression.prefix,
          memberName: expression.identifier.name,
        );
      } else if (expression is IndexExpression) {
        // Colors.redAccent[500]
        var index = expression.index;
        var indexValue = index is IntegerLiteral ? index.value : null;
        if (indexValue != null) {
          return getExpressionColorObject(
            expression.realTarget,
            index: indexValue,
          );
        }
      } else if (expression is PropertyAccess) {
        // CupertinoColors.activeBlue.darkColor
        return getExpressionColorObject(
          expression.realTarget,
          memberName: expression.propertyName.name,
        );
      }

      return null;
    }

    // If we want a specific member or swatch index, read that.
    if (memberName != null) {
      colorConst = _getMember(colorConst, memberName);
    } else if (index != null) {
      colorConst = _getSwatchColor(colorConst, index);
    }

    return colorConst;
  }

  /// Returns a color modified by an invocation, such as `withRed(...)` or
  /// `withValues(...)`.
  ///
  /// Returns null if [methodInvocation] is not a known/valid modifier or the
  /// arguments are not valid.
  ColorInformation? getInvocationModifiedColor(
    ColorInformation baseColor,
    MethodInvocation methodInvocation,
  ) {
    var methodName = methodInvocation.methodName.name;

    // We only support some specific methods.
    var isSupportedMethod = const {
      'withAlpha',
      'withRed',
      'withGreen',
      'withBlue',
      'withValues',
    }.contains(methodName);
    if (!isSupportedMethod) {
      return null;
    }

    var args = methodInvocation.argumentList;
    if (methodName == 'withValues') {
      // withValues is named args.
      var alpha = args.byName('alpha')?.doubleValueOrNull;
      var red = args.byName('red')?.doubleValueOrNull;
      var green = args.byName('green')?.doubleValueOrNull;
      var blue = args.byName('blue')?.doubleValueOrNull;

      return baseColor.withValues(alpha, red, green, blue);
    } else {
      // All other methods are a single positional int arg.
      var intArg = args.elementAtOrNull(0)?.integerValueOrNull;

      return switch (methodName) {
        'withAlpha' => baseColor.withAlpha(intArg),
        'withRed' => baseColor.withRed(intArg),
        'withGreen' => baseColor.withGreen(intArg),
        'withBlue' => baseColor.withBlue(intArg),
        _ => null,
      };
    }
  }

  /// Tries to add a color for the [expression].
  bool tryAddColor(Expression expression) {
    var colorInformation = getExpressionColorInformation(expression);
    return _tryRecordColorInformation(expression, colorInformation);
  }

  /// Extracts the color information from dart:ui Color constructor args.
  ColorInformation? _getDartUiColor(String? name, List<Argument> args) {
    if (name == null && args.length == 1) {
      // Color(0xFF000000).
      var arg0 = args[0];
      return arg0 is IntegerLiteral ? getColorForInt(arg0.value) : null;
    } else if (name == 'from') {
      // Color.from(alpha: 1, red: 1, green: 1, blue: 1).
      double? alpha, red, green, blue;
      for (var arg in args.whereType<NamedArgument>()) {
        var expression = arg.argumentExpression;
        var value = expression is DoubleLiteral
            ? expression.value
            : expression is IntegerLiteral
            ? expression.value?.toDouble()
            : null;
        switch (arg.name.lexeme) {
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
      var alpha = opacity != null ? (opacity * 255).round() : null;

      return alpha != null && red != null && green != null && blue != null
          ? ColorInformation(alpha, red, green, blue)
          : null;
    } else {
      return null;
    }
  }

  /// Extracts the color from Flutter MaterialAccentColor constructor args.
  ColorInformation? _getFlutterMaterialAccentColor(
    String? name,
    List<Argument> args,
  ) =>
      // MaterialAccentColor is a subclass of SwatchColor and has the same
      // constructor.
      _getFlutterSwatchColor(name, args);

  /// Extracts the color information from Flutter ColorSwatch constructor args.
  ColorInformation? _getFlutterSwatchColor(String? name, List<Argument> args) {
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
  bool _isDartUi(Element? element) => element?.library?.name == 'dart.ui';

  /// Checks whether this elements library is Flutter Material colors.
  bool _isFlutterMaterial(Element? element) =>
      element?.library?.identifier ==
      'package:flutter/src/material/colors.dart';

  /// Checks whether this elements library is Flutter Painting colors.
  bool _isFlutterPainting(Element? element) =>
      element?.library?.identifier ==
      'package:flutter/src/painting/colors.dart';

  /// Tries to record the [color] for [expression].
  ///
  /// Returns whether a valid color was found and recorded.
  bool _tryRecordColorInformation(
    Expression expression,
    ColorInformation? color,
  ) {
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

    return getColorForDoubles(alpha: alpha, red: red, green: green, blue: blue);
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

  new(int alpha, int red, int green, int blue)
    : alpha = _clamp(alpha),
      red = _clamp(red),
      green = _clamp(green),
      blue = _clamp(blue);

  ColorInformation? withAlpha(int? newAlpha) {
    return newAlpha != null
        ? ColorInformation(newAlpha, red, green, blue)
        : null;
  }

  ColorInformation? withBlue(int? newBlue) {
    return newBlue != null
        ? ColorInformation(alpha, red, green, newBlue)
        : null;
  }

  ColorInformation? withGreen(int? newGreen) {
    return newGreen != null
        ? ColorInformation(alpha, red, newGreen, blue)
        : null;
  }

  ColorInformation? withRed(int? newRed) {
    return newRed != null ? ColorInformation(alpha, newRed, green, blue) : null;
  }

  ColorInformation? withValues(
    double? newAlpha,
    double? newRed,
    double? newGreen,
    double? newBlue,
  ) {
    int getNew(double? newValue, int existingValue) {
      return newValue != null ? (newValue * 255).round() : existingValue;
    }

    return ColorInformation(
      getNew(newAlpha, alpha),
      getNew(newRed, red),
      getNew(newGreen, green),
      getNew(newBlue, blue),
    );
  }

  /// Clamp a number to 0-255.
  static int _clamp(int i) {
    return i < 0
        ? 0
        : i > 255
        ? 255
        : i;
  }
}

/// Information about a specific known location of a [ColorInformation]
/// reference in a document.
class ColorReference {
  final int offset;
  final int length;
  final ColorInformation color;

  new(this.offset, this.length, this.color);
}

class _ColorBuilder extends RecursiveAstVisitor<void> {
  final ColorComputer computer;

  new(this.computer);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    // Usually we return after finding a color, but constructors can
    // have nested colors in their arguments so do not return early.
    computer.tryAddColor(node);

    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (computer.tryAddColor(node)) {
      return;
    }

    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Usually we return after finding a color, but constructors can
    // have nested colors in their arguments so do not return early.
    computer.tryAddColor(node);

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (computer.tryAddColor(node)) {
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (computer.tryAddColor(node)) {
      return;
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (computer.tryAddColor(node)) {
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

extension on Argument {
  /// Gets the double value of this argument or `null`.
  double? get doubleValueOrNull {
    var arg = argumentExpression;

    var isNegated = false;
    if (arg is PrefixExpression) {
      isNegated = arg.operator.type == TokenType.MINUS;
      arg = arg.operand;
    }

    var value = arg is DoubleLiteral
        ? arg.value
        : arg is IntegerLiteral
        ? arg.value?.toDouble()
        : null;
    return isNegated && value != null ? -value : value;
  }

  /// Gets the integer value of this argument or `null`.
  int? get integerValueOrNull {
    var arg = argumentExpression;

    var isNegated = false;
    if (arg is PrefixExpression) {
      isNegated = arg.operator.type == TokenType.MINUS;
      arg = arg.operand;
    }

    var value = arg is IntegerLiteral ? arg.value : null;
    return isNegated && value != null ? -value : value;
  }
}

extension _DartObjectExtensions on DartObject {
  /// Reads the value of the field named [fieldName] from this object.
  ///
  /// If the field is not found, recurses up the super classes.
  DartObject? getFieldFromHierarchy(String fieldName) =>
      getField(fieldName) ??
      getField(GenericState.SUPERCLASS_FIELD)?.getFieldFromHierarchy(fieldName);
}
