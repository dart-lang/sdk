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
  Stream<CorrectionProducer> get producers async* {
    var targetClassNode = node.thisOrAncestorOfType<ClassDeclaration>();
    if (targetClassNode == null) {
      return;
    }

    var targetClassElement = targetClassNode.declaredElement!;
    var superType = targetClassElement.supertype;
    if (superType == null) {
      return;
    }

    // add proposals for all super constructors
    for (var constructor in superType.constructors) {
      // Only propose public constructors.
      if (!Identifier.isPrivateName(constructor.name)) {
        var targetLocation = utils.prepareNewConstructorLocation(
            resolvedResult.session, targetClassNode);
        if (targetLocation != null) {
          yield _CreateConstructor(
              constructor, targetLocation, targetClassElement.name);
        }
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
    var requiredPositionalParameters = _constructor.parameters
        .where((parameter) => parameter.isRequiredPositional);
    var requiredNamedParameters =
        _constructor.parameters.where((parameter) => parameter.isRequiredNamed);
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(_targetLocation.offset, (builder) {
        void writeParameters(bool isDefinition) {
          void writeParameter(ParameterElement parameter) {
            var parameterName = parameter.displayName;
            var includeType = isDefinition;
            var includeRequired = isDefinition && parameter.isRequiredNamed;
            var includeLabel = !isDefinition && parameter.isRequiredNamed;

            if (parameterName.length > 1 && parameterName.startsWith('_')) {
              parameterName = parameterName.substring(1);
            }
            if (includeRequired) {
              builder.write('required ');
            }
            if (includeType && builder.writeType(parameter.type)) {
              builder.write(' ');
            }
            if (includeLabel) {
              builder.write('$parameterName: ');
            }
            builder.write(parameterName);
          }

          var firstParameter = true;
          void writeComma() {
            if (firstParameter) {
              firstParameter = false;
            } else {
              builder.write(', ');
            }
          }

          for (var parameter in requiredPositionalParameters) {
            writeComma();
            writeParameter(parameter);
          }
          if (requiredNamedParameters.isNotEmpty) {
            var includeBraces = isDefinition;
            if (includeBraces) {
              writeComma();
              firstParameter = true; // Reset since we just included a comma.
              builder.write('{');
            }
            for (var parameter in requiredNamedParameters) {
              writeComma();
              writeParameter(parameter);
            }
            if (includeBraces) {
              builder.write('}');
            }
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
