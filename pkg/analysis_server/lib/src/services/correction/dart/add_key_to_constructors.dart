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
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class AddKeyToConstructors extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.ADD_KEY_TO_CONSTRUCTORS;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_KEY_TO_CONSTRUCTORS_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    var parent = node.parent;
    if (node is ClassDeclaration) {
      await _computeClassDeclaration(builder, node);
    } else if (node is ConstructorDeclaration) {
      await _computeConstructorDeclaration(builder, node);
    } else if (parent is ConstructorDeclaration) {
      await _computeConstructorDeclaration(builder, parent);
    }
  }

  /// Return `true` if the [classDeclaration] can be instantiated as a `const`.
  bool _canBeConst(ClassDeclaration classDeclaration,
      List<ConstructorElement> constructors) {
    for (var constructor in constructors) {
      if (constructor.isDefaultConstructor && !constructor.isConst) {
        return false;
      }
    }

    for (var member in classDeclaration.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        if (!member.fields.isFinal) {
          return false;
        }
        for (var variableDeclaration in member.fields.variables) {
          var initializer = variableDeclaration.initializer;
          if (initializer is InstanceCreationExpression &&
              !initializer.isConst) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// The lint is on the name of the class when there are no constructors.
  Future<void> _computeClassDeclaration(
      ChangeBuilder builder, ClassDeclaration node) async {
    var targetLocation =
        utils.prepareNewConstructorLocation(unitResult.session, node);
    if (targetLocation == null) {
      return;
    }
    var keyType = await _getKeyType();
    if (keyType == null) {
      return;
    }
    var className = node.name.lexeme;
    var constructors = node.declaredElement?.supertype?.constructors;
    if (constructors == null) {
      return;
    }

    var canBeConst = _canBeConst(node, constructors);
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        if (canBeConst) {
          builder.write('const ');
        }
        builder.write(className);
        builder.write('({');
        if (libraryElement.featureSet.isEnabled(Feature.super_parameters)) {
          builder.write('super.key});');
        } else {
          builder.writeType(keyType);
          builder.write(' key}) : super(key: key);');
        }
        builder.write(targetLocation.suffix);
      });
    });
  }

  /// The lint is on a constructor when that constructor doesn't have a `key`
  /// parameter.
  Future<void> _computeConstructorDeclaration(
      ChangeBuilder builder, ConstructorDeclaration node) async {
    var keyType = await _getKeyType();
    if (keyType == null) {
      return;
    }
    var superParameters =
        libraryElement.featureSet.isEnabled(Feature.super_parameters);

    void writeKey(DartEditBuilder builder) {
      if (superParameters) {
        builder.write('super.key');
      } else {
        builder.writeType(keyType);
        builder.write(' key');
      }
    }

    var parameterList = node.parameters;
    var parameters = parameterList.parameters;
    if (parameters.isEmpty) {
      // There are no parameters, so add the first parameter.
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(parameterList.leftParenthesis.end, (builder) {
          builder.write('{');
          writeKey(builder);
          builder.write('}');
        });
        _updateSuper(builder, node, superParameters);
      });
      return;
    }
    var leftDelimiter = parameterList.leftDelimiter;
    if (leftDelimiter == null) {
      // There are no named parameters, so add the delimiters.
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(parameters.last.end, (builder) {
          builder.write(', {');
          writeKey(builder);
          builder.write('}');
        });
        _updateSuper(builder, node, superParameters);
      });
    } else if (leftDelimiter.type == TokenType.OPEN_CURLY_BRACKET) {
      // There are other named parameters, so add the new named parameter.
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(leftDelimiter.end, (builder) {
          writeKey(builder);
          builder.write(', ');
        });
        _updateSuper(builder, node, superParameters);
      });
    }
  }

  /// Return the type for the class `Key`.
  Future<DartType?> _getKeyType() async {
    var keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
    if (keyClass == null) {
      return null;
    }
    var isNonNullable =
        unitResult.libraryElement.featureSet.isEnabled(Feature.non_nullable);
    return keyClass.instantiate(
      typeArguments: const [],
      nullabilitySuffix:
          isNonNullable ? NullabilitySuffix.question : NullabilitySuffix.star,
    );
  }

  void _updateSuper(DartFileEditBuilder builder,
      ConstructorDeclaration constructor, bool superParameters) {
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
    if (superParameters) {
      if (invocation != null && invocation.argumentList.arguments.isEmpty) {
        final invocationIndex = initializers.indexOf(invocation);
        if (initializers.length == 1) {
          builder.addDeletion(
            range.endStart(
              constructor.parameters,
              constructor.body,
            ),
          );
        } else if (invocationIndex == 0) {
          builder.addDeletion(
            range.startStart(
              invocation,
              initializers[invocationIndex + 1],
            ),
          );
        } else {
          builder.addDeletion(
            range.endEnd(
              initializers[invocationIndex - 1],
              invocation,
            ),
          );
        }
      }
      return;
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
        var namedArguments = arguments.whereType<NamedExpression>();
        var firstNamed = namedArguments.firstOrNull;
        var token = firstNamed?.beginToken ?? argumentList.endToken;
        var comma = token.previous?.type == TokenType.COMMA;

        builder.addInsertion(token.offset, (builder) {
          if (arguments.length != namedArguments.length) {
            // there are unnamed arguments
            if (!comma) {
              builder.write(',');
            }
            builder.write(' ');
          }
          builder.write('key: key');
          if (firstNamed != null) {
            builder.write(', ');
          } else if (comma) {
            builder.write(',');
          }
        });
      } else {
        // There is an existing 'key' argument, so we leave it alone.
      }
    }
  }
}
