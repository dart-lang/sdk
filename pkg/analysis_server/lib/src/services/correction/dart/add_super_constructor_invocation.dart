// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddSuperConstructorInvocation extends MultiCorrectionProducer {
  AddSuperConstructorInvocation({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var targetConstructor = node.parent;
    if (targetConstructor is! ConstructorDeclaration) {
      return const [];
    }

    var targetClassNode = targetConstructor.parent;
    if (targetClassNode is! ClassDeclaration) {
      return const [];
    }

    var targetClassElement = targetClassNode.declaredFragment?.element;
    var superType = targetClassElement?.supertype;
    if (superType == null) {
      return const [];
    }

    var initializers = targetConstructor.initializers;
    int insertOffset;
    String prefix;
    if (initializers.isEmpty) {
      insertOffset = targetConstructor.parameters.end;
      prefix = ' : ';
    } else {
      var lastInitializer = initializers[initializers.length - 1];
      insertOffset = lastInitializer.end;
      prefix = ', ';
    }
    var producers = <ResolvedCorrectionProducer>[];
    for (var constructor in superType.constructors) {
      // Only propose public constructors.
      var name = constructor.name;
      if (name != null && !Identifier.isPrivateName(name)) {
        producers.add(
          _AddInvocation(constructor, insertOffset, prefix, context: context),
        );
      }
    }
    return producers;
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddSuperConstructorInvocation] producer.
class _AddInvocation extends ResolvedCorrectionProducer {
  /// The constructor to be invoked.
  final ConstructorElement _constructor;

  /// The offset at which the initializer is to be inserted.
  final int _insertOffset;

  /// The prefix to be added before the actual invocation.
  final String _prefix;

  _AddInvocation(
    this._constructor,
    this._insertOffset,
    this._prefix, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var buffer = StringBuffer();
    buffer.write('super');
    var constructorName = _constructor.name;
    if (constructorName != null && constructorName != 'new') {
      buffer.write('.');
      buffer.write(constructorName);
    }
    buffer.write('(...)');
    return [buffer.toString()];
  }

  @override
  FixKind get fixKind => DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructorName = _constructor.name;
    if (constructorName == null ||
        _constructor.formalParameters.any((p) => p.name == null)) {
      return;
    }
    var currentConstructor = node
        .thisOrAncestorOfType<ConstructorDeclaration>();
    var positionalParameters = 0;
    var namedParameters = <String>{};
    if (currentConstructor case ConstructorDeclaration(:var parameters)) {
      for (var parameter in parameters.parameters) {
        if (parameter case SuperFormalParameter(
          :var isPositional,
        ) when isPositional) {
          positionalParameters++;
        } else if (parameter case DefaultFormalParameter(
          :SuperFormalParameter parameter,
        ) when parameter.isNamed) {
          namedParameters.add(parameter.name.lexeme);
        }
      }
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(_insertOffset, (builder) {
        builder.write(_prefix);
        // add super constructor name
        builder.write('super');
        if (constructorName != 'new') {
          builder.write('.');
          builder.addSimpleLinkedEdit('NAME', constructorName);
        }
        // add arguments
        builder.write('(');
        var firstParameter = true;
        for (var (index, parameter) in _constructor.formalParameters.indexed) {
          // skip non-required parameters
          if (parameter.isOptional) {
            break;
          }
          if (parameter.isNamed && namedParameters.contains(parameter.name)) {
            // skip already initialized named parameters
            continue;
          }
          if (parameter.isPositional && index < positionalParameters) {
            // skip already initialized positional parameters
            continue;
          }

          // comma
          if (firstParameter) {
            firstParameter = false;
          } else {
            builder.write(', ');
          }

          if (parameter.isNamed) {
            builder.write('${parameter.name}: ');
          }
          // A default value to pass as an argument.
          builder.addSimpleLinkedEdit(
            parameter.name!,
            parameter.type.defaultArgumentCode,
          );
        }
        builder.write(')');
      });
    });
  }
}

extension on DartType {
  String get defaultArgumentCode {
    if (isDartCoreBool) {
      return 'false';
    }
    if (isDartCoreInt) {
      return '0';
    }
    if (isDartCoreDouble) {
      return '0.0';
    }
    if (isDartCoreString) {
      return "''";
    }
    // No better guess.
    return 'null';
  }
}
