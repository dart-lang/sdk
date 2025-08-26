// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/record_type_builder.dart';

class VarianceBuilder {
  final Linker _linker;
  final Set<TypeAlias> _pending = Set.identity();
  final Set<TypeAlias> _visit = Set.identity();

  VarianceBuilder(this._linker);

  void perform() {
    for (var builder in _linker.builders.values) {
      for (var linkingUnit in builder.units) {
        for (var node in linkingUnit.node.declarations) {
          if (node is FunctionTypeAliasImpl) {
            _pending.add(node);
          } else if (node is GenericTypeAliasImpl) {
            _pending.add(node);
          }
        }
      }
    }

    for (var builder in _linker.builders.values) {
      for (var linkingUnit in builder.units) {
        for (var node in linkingUnit.node.declarations) {
          if (node is ClassTypeAliasImpl) {
            _typeParameters(node.typeParameters);
          } else if (node is ClassDeclarationImpl) {
            _typeParameters(node.typeParameters);
          } else if (node is EnumDeclarationImpl) {
            _typeParameters(node.typeParameters);
          } else if (node is FunctionTypeAliasImpl) {
            _functionTypeAlias(node);
          } else if (node is GenericTypeAliasImpl) {
            _genericTypeAlias(node);
          } else if (node is MixinDeclarationImpl) {
            _typeParameters(node.typeParameters);
          }
        }
      }
    }
  }

  Variance _compute(TypeParameterElement variable, DartType? type) {
    if (type is TypeParameterType) {
      if (type.element == variable) {
        return Variance.covariant;
      } else {
        return Variance.unrelated;
      }
    } else if (type is NamedTypeBuilder) {
      var element = type.element;
      var arguments = type.arguments;
      if (element is InterfaceElementImpl) {
        var result = Variance.unrelated;
        if (arguments.isNotEmpty) {
          var typeParameters = element.typeParameters;
          for (
            var i = 0;
            i < arguments.length && i < typeParameters.length;
            i++
          ) {
            var typeParameter = typeParameters[i];
            result = result.meet(
              typeParameter.variance.combine(_compute(variable, arguments[i])),
            );
          }
        }
        return result;
      } else if (element is TypeAliasElementImpl) {
        _typeAliasElement(element);

        var result = Variance.unrelated;

        if (arguments.isNotEmpty) {
          var typeParameters = element.typeParameters;
          for (
            var i = 0;
            i < arguments.length && i < typeParameters.length;
            i++
          ) {
            var typeParameter = typeParameters[i];
            var typeParameterVariance = typeParameter.variance;
            result = result.meet(
              typeParameterVariance.combine(_compute(variable, arguments[i])),
            );
          }
        }
        return result;
      }
    } else if (type is FunctionTypeBuilder) {
      return _computeFunctionType(
        variable,
        returnType: type.returnType,
        typeParameters: type.typeParameters,
        formalParameters: type.formalParameters,
      );
    } else if (type is RecordTypeBuilder) {
      var result = Variance.unrelated;
      for (var field in type.node.fields) {
        result = result.meet(_compute(variable, field.type.typeOrThrow));
      }
      return result;
    }
    return Variance.unrelated;
  }

  Variance _computeFunctionType(
    TypeParameterElement variable, {
    required DartType? returnType,
    required List<TypeParameterElement>? typeParameters,
    required List<FormalParameterElement> formalParameters,
  }) {
    var result = Variance.unrelated;

    result = result.meet(_compute(variable, returnType));

    // If [variable] is referenced in a bound at all, it makes the
    // variance of [variable] in the entire type invariant.
    if (typeParameters != null) {
      for (var typeParameter in typeParameters) {
        var bound = typeParameter.bound;
        if (bound != null && _compute(variable, bound) != Variance.unrelated) {
          result = Variance.invariant;
        }
      }
    }

    for (var formalParameter in formalParameters) {
      result = result.meet(
        Variance.contravariant.combine(
          _compute(variable, formalParameter.type),
        ),
      );
    }

    return result;
  }

  void _functionTypeAlias(FunctionTypeAliasImpl node) {
    var parameterList = node.typeParameters;
    if (parameterList == null) {
      return;
    }

    // Recursion detected, recover.
    if (_visit.contains(node)) {
      for (var typeParameter in parameterList.typeParameters) {
        _setVariance(typeParameter, Variance.covariant);
      }
      return;
    }

    // Not being linked, or already linked.
    if (!_pending.remove(node)) {
      return;
    }

    _visit.add(node);
    try {
      for (var typeParameter in parameterList.typeParameters) {
        var variance = _computeFunctionType(
          typeParameter.declaredFragment!.element,
          returnType: node.returnType?.type,
          typeParameters: null,
          formalParameters: FunctionTypeBuilder.getParameters(node.parameters),
        );
        _setVariance(typeParameter, variance);
      }
    } finally {
      _visit.remove(node);
    }
  }

  void _genericTypeAlias(GenericTypeAlias node) {
    var parameterList = node.typeParameters;
    if (parameterList == null) {
      return;
    }

    // Recursion detected, recover.
    if (_visit.contains(node)) {
      for (var typeParameter in parameterList.typeParameters) {
        _setVariance(typeParameter, Variance.covariant);
      }
      return;
    }

    // Not being linked, or already linked.
    if (!_pending.remove(node)) {
      return;
    }

    var type = node.type.type;

    // Not a function type, recover.
    if (type == null) {
      for (var typeParameter in parameterList.typeParameters) {
        _setVariance(typeParameter, Variance.covariant);
      }
    }

    _visit.add(node);
    try {
      for (var typeParameter in parameterList.typeParameters) {
        var variance = _compute(typeParameter.declaredFragment!.element, type);
        _setVariance(typeParameter, variance);
      }
    } finally {
      _visit.remove(node);
    }
  }

  void _typeAliasElement(TypeAliasElementImpl element) {
    var node = _linker.getLinkingNode2(element.firstFragment);
    if (node == null) {
      // Not linking.
    } else if (node is GenericTypeAliasImpl) {
      _genericTypeAlias(node);
    } else if (node is FunctionTypeAliasImpl) {
      _functionTypeAlias(node);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  void _typeParameters(TypeParameterListImpl? parameterList) {
    if (parameterList == null) {
      return;
    }

    for (var typeParameter in parameterList.typeParameters) {
      var varianceKeyword = typeParameter.varianceKeyword;
      if (varianceKeyword != null) {
        var variance = Variance.fromKeywordString(varianceKeyword.lexeme);
        _setVariance(typeParameter, variance);
      }
    }
  }

  static void _setVariance(TypeParameter node, Variance variance) {
    var element = node.declaredFragment!.element as TypeParameterElementImpl;
    element.variance = variance;
  }
}
