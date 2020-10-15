// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:meta/meta.dart';

class VarianceBuilder {
  final Set<TypeAlias> _pending = Set.identity();
  final Set<TypeAlias> _visit = Set.identity();

  void perform(Linker linker) {
    for (var builder in linker.builders.values) {
      for (var unitContext in builder.context.units) {
        for (var node in unitContext.unit.declarations) {
          if (node is FunctionTypeAlias || node is GenericTypeAlias) {
            _pending.add(node);
          }
        }
      }
    }

    for (var builder in linker.builders.values) {
      for (var unitContext in builder.context.units) {
        for (var node in unitContext.unit.declarations) {
          if (node is ClassTypeAlias) {
            _typeParameters(node.typeParameters);
          } else if (node is ClassDeclaration) {
            _typeParameters(node.typeParameters);
          } else if (node is FunctionTypeAlias) {
            _functionTypeAlias(node);
          } else if (node is GenericTypeAlias) {
            _genericTypeAlias(node);
          } else if (node is MixinDeclaration) {
            _typeParameters(node.typeParameters);
          }
        }
      }
    }
  }

  Variance _compute(TypeParameterElement variable, DartType type) {
    if (type is TypeParameterType) {
      var element = type.element;
      if (element is TypeParameterElement) {
        if (element == variable) {
          return Variance.covariant;
        } else {
          return Variance.unrelated;
        }
      }
    } else if (type is NamedTypeBuilder) {
      var element = type.element;
      if (element is ClassElement) {
        var result = Variance.unrelated;
        if (type.arguments.isNotEmpty) {
          var parameters = element.typeParameters;
          for (int i = 0; i < type.arguments.length; ++i) {
            var parameter = parameters[i] as TypeParameterElementImpl;
            result = result.meet(
              parameter.variance.combine(
                _compute(variable, type.arguments[i]),
              ),
            );
          }
        }
        return result;
      } else if (element is FunctionTypeAliasElementImpl) {
        _functionTypeAliasElement(element);

        var result = Variance.unrelated;

        if (type.arguments.isNotEmpty) {
          var parameters = element.typeParameters;
          for (var i = 0; i < type.arguments.length; ++i) {
            var parameter = parameters[i] as TypeParameterElementImpl;
            var parameterVariance = parameter.variance;
            result = result.meet(
              parameterVariance.combine(
                _compute(variable, type.arguments[i]),
              ),
            );
          }
        }
        return result;
      }
    } else if (type is FunctionTypeBuilder) {
      return _computeFunctionType(
        variable,
        returnType: type.returnType,
        typeFormals: type.typeFormals,
        parameters: type.parameters,
      );
    }
    return Variance.unrelated;
  }

  Variance _computeFunctionType(
    TypeParameterElement variable, {
    @required DartType returnType,
    @required List<TypeParameterElement> typeFormals,
    @required List<ParameterElement> parameters,
  }) {
    var result = Variance.unrelated;

    if (result != null) {
      result = result.meet(
        _compute(variable, returnType),
      );
    }

    // If [variable] is referenced in a bound at all, it makes the
    // variance of [variable] in the entire type invariant.
    if (typeFormals != null) {
      for (var parameter in typeFormals) {
        var bound = parameter.bound;
        if (bound != null && _compute(variable, bound) != Variance.unrelated) {
          result = Variance.invariant;
        }
      }
    }

    for (var parameter in parameters) {
      result = result.meet(
        Variance.contravariant.combine(
          _compute(variable, parameter.type),
        ),
      );
    }

    return result;
  }

  void _functionTypeAlias(FunctionTypeAlias node) {
    var parameterList = node.typeParameters;
    if (parameterList == null) {
      return;
    }

    // Recursion detected, recover.
    if (_visit.contains(node)) {
      for (var parameter in parameterList.typeParameters) {
        LazyAst.setVariance(parameter, Variance.covariant);
      }
      return;
    }

    // Not being linked, or already linked.
    if (!_pending.remove(node)) {
      return;
    }

    _visit.add(node);
    try {
      for (var parameter in parameterList.typeParameters) {
        var variance = _computeFunctionType(
          parameter.declaredElement,
          returnType: node.returnType?.type,
          typeFormals: null,
          parameters: FunctionTypeBuilder.getParameters(
            false,
            node.parameters,
          ),
        );
        LazyAst.setVariance(parameter, variance);
      }
    } finally {
      _visit.remove(node);
    }
  }

  void _functionTypeAliasElement(FunctionTypeAliasElementImpl element) {
    var node = element.linkedNode;
    if (node is GenericTypeAlias) {
      _genericTypeAlias(node);
    } else if (node is FunctionTypeAlias) {
      _functionTypeAlias(node);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  void _genericTypeAlias(GenericTypeAlias node) {
    var parameterList = node.typeParameters;
    if (parameterList == null) {
      return;
    }

    // Recursion detected, recover.
    if (_visit.contains(node)) {
      for (var parameter in parameterList.typeParameters) {
        LazyAst.setVariance(parameter, Variance.covariant);
      }
      return;
    }

    // Not being linked, or already linked.
    if (!_pending.remove(node)) {
      return;
    }

    var type = node.functionType?.type;

    // Not a function type, recover.
    if (type == null) {
      for (var parameter in parameterList.typeParameters) {
        LazyAst.setVariance(parameter, Variance.covariant);
      }
    }

    _visit.add(node);
    try {
      for (var parameter in parameterList.typeParameters) {
        var variance = _compute(parameter.declaredElement, type);
        LazyAst.setVariance(parameter, variance);
      }
    } finally {
      _visit.remove(node);
    }
  }

  void _typeParameters(TypeParameterList parameterList) {
    if (parameterList == null) {
      return;
    }

    for (var parameter in parameterList.typeParameters) {
      var parameterImpl = parameter as TypeParameterImpl;
      var varianceKeyword = parameterImpl.varianceKeyword;
      if (varianceKeyword != null) {
        var variance = Variance.fromKeywordString(varianceKeyword.lexeme);
        LazyAst.setVariance(parameter, variance);
      }
    }
  }
}
