// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
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
    for (var constructor in superType.constructors2) {
      // Only propose public constructors.
      var name = constructor.name3;
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
  final ConstructorElement2 _constructor;

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
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments {
    var buffer = StringBuffer();
    buffer.write('super');
    var constructorName = _constructor.name3;
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
    var constructorName = _constructor.name3;
    if (constructorName == null ||
        _constructor.formalParameters.any((p) => p.name3 == null)) {
      return;
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
        for (var parameter in _constructor.formalParameters) {
          // skip non-required parameters
          if (parameter.isOptional) {
            break;
          }
          // comma
          if (firstParameter) {
            firstParameter = false;
          } else {
            builder.write(', ');
          }

          if (parameter.isNamed) {
            builder.write('${parameter.name3}: ');
          }
          // A default value to pass as an argument.
          builder.addSimpleLinkedEdit(
            parameter.name3!,
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
