// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class AddKeyToConstructors extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_KEY_TO_CONSTRUCTORS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    var parent = node.parent;
    if (node is SimpleIdentifier && parent is ClassDeclaration) {
      // The lint is on the name of the class when there are no constructors.
      var targetLocation =
          utils.prepareNewConstructorLocation(resolvedResult.session, parent);
      if (targetLocation == null) {
        return;
      }
      var keyType = await _getKeyType();
      if (keyType == null) {
        return;
      }
      var className = node.name;
      var canBeConst = _canBeConst(parent.declaredElement);
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(targetLocation.offset, (builder) {
          builder.write(targetLocation.prefix);
          if (canBeConst) {
            builder.write('const ');
          }
          builder.write(className);
          builder.write('({');
          builder.writeType(keyType);
          builder.write(' key}) : super(key: key);');
          builder.write(targetLocation.suffix);
        });
      });
    } else if (parent is ConstructorDeclaration) {
      // The lint is on a constructor when that constructor doesn't have a `key`
      // parameter.
      var keyType = await _getKeyType();
      if (keyType == null) {
        return;
      }
      var parameterList = parent.parameters;
      var parameters = parameterList.parameters;
      if (parameters.isEmpty) {
        // There are no parameters, so add the first parameter.
        await builder.addDartFileEdit(file, (builder) {
          builder.addInsertion(parameterList.leftParenthesis.end, (builder) {
            builder.write('{');
            builder.writeType(keyType);
            builder.write(' key}');
          });
          _updateSuper(builder, parent);
        });
        return;
      }
      var leftDelimiter = parameterList.leftDelimiter;
      if (leftDelimiter == null) {
        // There are no named parameters, so add the delimiters.
        await builder.addDartFileEdit(file, (builder) {
          builder.addInsertion(parameters.last.end, (builder) {
            builder.write(', {');
            builder.writeType(keyType);
            builder.write(' key}');
          });
          _updateSuper(builder, parent);
        });
      } else if (leftDelimiter.type == TokenType.OPEN_CURLY_BRACKET) {
        // There are other named parameters, so add the new named parameter.
        await builder.addDartFileEdit(file, (builder) {
          builder.addInsertion(leftDelimiter.end, (builder) {
            builder.writeType(keyType);
            builder.write(' key, ');
          });
          _updateSuper(builder, parent);
        });
      }
    }
  }

  /// Return `true` if the [classElement] can be instantiated as a `const`.
  bool _canBeConst(ClassElement? classElement) {
    var currentClass = classElement;
    while (currentClass != null && !currentClass.isDartCoreObject) {
      for (var field in currentClass.fields) {
        if (!field.isSynthetic && !field.isFinal) {
          return false;
        }
      }
      currentClass = currentClass.supertype?.element;
    }
    return true;
  }

  /// Return the type for the class `Key`.
  Future<DartType?> _getKeyType() async {
    var keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
    if (keyClass == null) {
      return null;
    }
    var isNonNullable = resolvedResult.libraryElement.featureSet
        .isEnabled(Feature.non_nullable);
    return keyClass.instantiate(
      typeArguments: const [],
      nullabilitySuffix:
          isNonNullable ? NullabilitySuffix.question : NullabilitySuffix.star,
    );
  }

  void _updateSuper(
      DartFileEditBuilder builder, ConstructorDeclaration constructor) {
    if (constructor.factoryKeyword != null ||
        constructor.redirectedConstructor != null) {
      // Can't have a super constructor invocation.
      // TODO(brianwilkerson) Consider extending the redirected constructor to
      //  also take a key, or finding the constructor invocation in the body of
      //  the factory and updating it.
      return;
    }
    var initializers = constructor.initializers;
    SuperConstructorInvocation? invocation;
    for (var initializer in initializers) {
      if (initializer is SuperConstructorInvocation) {
        invocation = initializer;
      } else if (initializer is RedirectingConstructorInvocation) {
        return;
      }
    }
    if (invocation == null) {
      // There is no super constructor invocation, so add one.
      if (initializers.isEmpty) {
        builder.addSimpleInsertion(
            constructor.parameters.rightParenthesis.end, ' : super(key: key)');
      } else {
        builder.addSimpleInsertion(initializers.last.end, ', super(key: key)');
      }
    } else {
      // There is a super constructor invocation, so update it.
      var argumentList = invocation.argumentList;
      var arguments = argumentList.arguments;
      var existing = arguments.firstWhereOrNull((argument) =>
          argument is NamedExpression && argument.name.label.name == 'key');
      if (existing == null) {
        // There is no 'key' argument, so add it.
        if (arguments.isEmpty) {
          builder.addSimpleInsertion(
              argumentList.leftParenthesis.end, 'key: key');
        } else {
          // This case should never happen because 'key' is the only parameter
          // in the constructors for both `StatelessWidget` and `StatefulWidget`.
          builder.addSimpleInsertion(
              argumentList.leftParenthesis.end, 'key: key, ');
        }
      } else {
        // There is an existing 'key' argument, so we leave it alone.
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddKeyToConstructors newInstance() => AddKeyToConstructors();
}
