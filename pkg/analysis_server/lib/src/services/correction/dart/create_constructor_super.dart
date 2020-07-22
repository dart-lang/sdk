// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateConstructorSuper extends MultiCorrectionProducer {
  @override
  Iterable<CorrectionProducer> get producers sync* {
    var targetClassNode = node.thisOrAncestorOfType<ClassDeclaration>();
    var targetClassElement = targetClassNode.declaredElement;
    var superType = targetClassElement.supertype;
    // add proposals for all super constructors
    for (var constructor in superType.constructors) {
      // Only propose public constructors.
      if (!Identifier.isPrivateName(constructor.name)) {
        var targetLocation =
            utils.prepareNewConstructorLocation(targetClassNode);
        yield _CreateConstructor(
            constructor, targetLocation, targetClassElement.name);
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateConstructorSuper newInstance() => CreateConstructorSuper();
}

/// A correction processor that can make one of the possible change computed by
/// the [CreateConstructorSuper] producer.
class _CreateConstructor extends CorrectionProducer {
  /// The constructor to be invoked.
  final ConstructorElement _constructor;

  /// An indication of where the new constructor should be added.
  final ClassMemberLocation _targetLocation;

  /// The name of the class in which the constructor will be added.
  final String _targetClassName;

  _CreateConstructor(
      this._constructor, this._targetLocation, this._targetClassName);

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
  FixKind get fixKind => DartFixKind.CREATE_CONSTRUCTOR_SUPER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructorName = _constructor.name;
    var requiredParameters = _constructor.parameters
        .where((parameter) => parameter.isRequiredPositional);
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(_targetLocation.offset, (builder) {
        void writeParameters(bool includeType) {
          var firstParameter = true;
          for (var parameter in requiredParameters) {
            if (firstParameter) {
              firstParameter = false;
            } else {
              builder.write(', ');
            }
            var parameterName = parameter.displayName;
            if (parameterName.length > 1 && parameterName.startsWith('_')) {
              parameterName = parameterName.substring(1);
            }
            if (includeType && builder.writeType(parameter.type)) {
              builder.write(' ');
            }
            builder.write(parameterName);
          }
        }

        builder.write(_targetLocation.prefix);
        builder.write(_targetClassName);
        if (constructorName.isNotEmpty) {
          builder.write('.');
          builder.addSimpleLinkedEdit('NAME', constructorName);
        }
        builder.write('(');
        writeParameters(true);
        builder.write(') : super');
        if (constructorName.isNotEmpty) {
          builder.write('.');
          builder.addSimpleLinkedEdit('NAME', constructorName);
        }
        builder.write('(');
        writeParameters(false);
        builder.write(');');
        builder.write(_targetLocation.suffix);
      });
    });
  }
}
