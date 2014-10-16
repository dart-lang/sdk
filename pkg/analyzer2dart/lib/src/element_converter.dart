// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Convertion of elements between the analyzer element model and the dart2js
/// element model.

library analyzer2dart.element_converter;

import 'package:compiler/implementation/elements/elements.dart' as dart2js;
import 'package:compiler/implementation/elements/modelx.dart' as modelx;
import 'package:compiler/implementation/util/util.dart' as util;
import 'package:compiler/implementation/dart_types.dart' as dart2js;
import 'package:analyzer/src/generated/element.dart' as analyzer;

part 'modely.dart';

class ElementConverter {
  /// Map from analyzer elements to their equivalent dart2js elements.
  Map<analyzer.Element, dart2js.Element> conversionMap =
      <analyzer.Element, dart2js.Element>{};

  /// Map from dart2js elements to their equivalent analyzer elements.
  Map<dart2js.Element, analyzer.Element> inversionMap =
      <dart2js.Element, analyzer.Element>{};

  ElementConverterVisitor visitor;

  ElementConverter() {
    visitor = new ElementConverterVisitor(this);
  }

  dart2js.Element convertElement(analyzer.Element input) {
    return conversionMap.putIfAbsent(input, () {
      dart2js.Element output = convertElementInternal(input);
      inversionMap[output] = input;
      return output;
    });
  }

  dart2js.FunctionType convertFunctionType(analyzer.FunctionType input) {
    dart2js.DartType returnType = convertType(input.returnType);
    List<dart2js.DartType> requiredParameterTypes =
        input.normalParameterTypes.map(convertType).toList();
    List<dart2js.DartType> positionalParameterTypes =
            input.optionalParameterTypes.map(convertType).toList();
    List<String> namedParameters =
        input.namedParameterTypes.keys.toList()..sort();
    List<dart2js.DartType> namedParameterTypes =
        namedParameters.map((String name) {
      return convertType(input.namedParameterTypes[name]);
    }).toList();
    return new dart2js.FunctionType.synthesized(
        returnType,
        requiredParameterTypes,
        positionalParameterTypes,
        namedParameters,
        namedParameterTypes);
  }

  dart2js.DartType convertType(analyzer.DartType input) {
    if (input.isVoid) {
      return const dart2js.VoidType();
    } else if (input.isDynamic) {
      return const dart2js.DynamicType();
    } else if (input is analyzer.TypeParameterType) {
      return new dart2js.TypeVariableType(convertElement(input.element));
    } else if (input is analyzer.InterfaceType) {
      List<dart2js.DartType> typeArguments =
          input.typeArguments.map(convertType).toList();
      return new dart2js.InterfaceType(
          convertElement(input.element), typeArguments);
    } else if (input is analyzer.FunctionType) {
      if (input.element is analyzer.FunctionTypeAliasElement) {
        List<dart2js.DartType> typeArguments =
            input.typeArguments.map(convertType).toList();
        return new dart2js.ResolvedTypedefType(
            convertElement(input.element),
            typeArguments,
            convertFunctionType(input));
      } else {
        assert(input.typeArguments.isEmpty);
        return convertFunctionType(input);
      }
    }
    throw new UnsupportedError(
        "Conversion of $input (${input.runtimeType}) is not supported.");
  }

  analyzer.Element invertElement(dart2js.Element input) {
    return inversionMap[input];
  }

  dart2js.Element convertElementInternal(analyzer.Element input) {
    dart2js.Element output = input.accept(visitor);
    if (output != null) return output;
    throw new UnsupportedError(
        "Conversion of $input (${input.runtimeType}) is not supported.");
  }
}

/// Visitor that converts analyzer elements to dart2js elements.
class ElementConverterVisitor
    extends analyzer.SimpleElementVisitor<dart2js.Element> {
  final ElementConverter converter;

  ElementConverterVisitor(this.converter);

  @override
  dart2js.LibraryElement visitLibraryElement(analyzer.LibraryElement input) {
    return new LibraryElementY(converter, input);
  }

  @override
  dart2js.FunctionElement visitFunctionElement(analyzer.FunctionElement input) {
    return new TopLevelFunctionElementY(converter, input);
  }

  @override
  dart2js.ParameterElement visitParameterElement(
      analyzer.ParameterElement input) {
    return new ParameterElementY(converter, input);
  }

  @override
  dart2js.ClassElement visitClassElement(analyzer.ClassElement input) {
    return new ClassElementY(converter, input);
  }

  @override
  dart2js.TypedefElement visitFunctionTypeAliasElement(
      analyzer.FunctionTypeAliasElement input) {
    return new TypedefElementY(converter, input);
  }

  @override
  dart2js.FieldElement visitTopLevelVariableElement(
      analyzer.TopLevelVariableElement input) {
    return new TopLevelVariableElementY(converter, input);
  }

  @override
  dart2js.Element visitPropertyAccessorElement(
      analyzer.PropertyAccessorElement input) {
    if (input.isSynthetic) {
      return input.variable.accept(this);
    }
    return null;
  }
}
