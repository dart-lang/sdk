// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddSuperConstructorInvocation extends MultiCorrectionProducer {
  @override
  Iterable<CorrectionProducer> get producers sync* {
    if (node.parent is! ConstructorDeclaration ||
        node.parent.parent is! ClassDeclaration) {
      return;
    }
    var targetConstructor = node.parent as ConstructorDeclaration;
    var targetClassNode = targetConstructor.parent as ClassDeclaration;
    var targetClassElement = targetClassNode.declaredElement;
    var superType = targetClassElement.supertype;
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
    for (var constructor in superType.constructors) {
      // Only propose public constructors.
      if (!Identifier.isPrivateName(constructor.name)) {
        yield _AddInvocation(constructor, insertOffset, prefix);
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddSuperConstructorInvocation newInstance() =>
      AddSuperConstructorInvocation();
}

/// A correction processor that can make one of the possible change computed by
/// the [AddSuperConstructorInvocation] producer.
class _AddInvocation extends CorrectionProducer {
  /// The constructor to be invoked.
  final ConstructorElement _constructor;

  /// The offset at which the initializer is to be inserted.
  final int _insertOffset;

  /// The prefix to be added before the actual invocation.
  final String _prefix;

  _AddInvocation(this._constructor, this._insertOffset, this._prefix);

  @override
  List<Object> get fixArguments {
    var buffer = StringBuffer();
    buffer.write('super');
    var constructorName = _constructor.displayName;
    if (constructorName.isNotEmpty) {
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
    var constructorName = _constructor.displayName;
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(_insertOffset, (builder) {
        builder.write(_prefix);
        // add super constructor name
        builder.write('super');
        if (!isEmpty(constructorName)) {
          builder.write('.');
          builder.addSimpleLinkedEdit('NAME', constructorName);
        }
        // add arguments
        builder.write('(');
        var firstParameter = true;
        for (var parameter in _constructor.parameters) {
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
          // default value
          builder.addSimpleLinkedEdit(
              parameter.name, getDefaultValueCode(parameter.type));
        }
        builder.write(')');
      });
    });
  }
}
