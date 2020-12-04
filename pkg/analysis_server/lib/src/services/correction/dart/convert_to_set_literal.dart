// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToSetLiteral extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SET_LITERAL;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_SET_LITERAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Check whether this is an invocation of `toSet` on a list literal.
    //
    var invocation = _findInvocationOfToSet();
    if (invocation != null) {
      //
      // Extract the information needed to build the edit.
      //
      var target = invocation.target as ListLiteral;
      var hasTypeArgs = target.typeArguments != null;
      var openRange = range.token(target.leftBracket);
      var closeRange = range.startEnd(target.rightBracket, invocation);
      //
      // Build the change and return the assist.
      //
      await builder.addDartFileEdit(file, (builder) {
        if (hasTypeArgs || _listHasUnambiguousElement(target)) {
          builder.addSimpleReplacement(openRange, '{');
        } else {
          builder.addSimpleReplacement(openRange, '<dynamic>{');
        }
        builder.addSimpleReplacement(closeRange, '}');
      });
      return;
    }
    //
    // Check whether this is one of the constructors defined on `Set`.
    //
    var creation = _findSetCreation();
    if (creation != null) {
      //
      // Extract the information needed to build the edit.
      //
      var name = creation.constructorName.name;
      var constructorTypeArguments =
          creation.constructorName.type.typeArguments;
      TypeArgumentList elementTypeArguments;
      SourceRange elementsRange;
      if (name == null) {
        // Handle an invocation of the default constructor `Set()`.
      } else if (name.name == 'from' || name.name == 'of') {
        // Handle an invocation of the constructor `Set.from()` or `Set.of()`.
        var arguments = creation.argumentList.arguments;
        if (arguments.length != 1) {
          return;
        }
        if (arguments[0] is ListLiteral) {
          var elements = arguments[0] as ListLiteral;
          elementTypeArguments = elements.typeArguments;
          elementsRange =
              range.endStart(elements.leftBracket, elements.rightBracket);
        } else {
          // TODO(brianwilkerson) Consider handling other iterables. Literal
          //  sets could be treated like lists, and arbitrary iterables by using
          //  a spread.
          return;
        }
      } else {
        // Invocation of an unhandled constructor.
        return;
      }
      //
      // Build the edit.
      //
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(creation), (builder) {
          if (constructorTypeArguments != null) {
            builder.write(utils.getNodeText(constructorTypeArguments));
          } else if (elementTypeArguments != null) {
            builder.write(utils.getNodeText(elementTypeArguments));
          } else if (!_setWouldBeInferred(creation)) {
            builder.write('<dynamic>');
          }
          builder.write('{');
          if (elementsRange != null) {
            builder.write(utils.getRangeText(elementsRange));
          }
          builder.write('}');
        });
      });
    }
  }

  /// Return the invocation of `List.toSet` that is to be converted, or `null`
  /// if the cursor is not inside a invocation of `List.toSet`.
  MethodInvocation _findInvocationOfToSet() {
    var invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null ||
        node.offset > invocation.argumentList.offset ||
        invocation.methodName.name != 'toSet' ||
        invocation.target is! ListLiteral) {
      return null;
    }
    return invocation;
  }

  /// Return the invocation of a `Set` constructor that is to be converted, or
  /// `null` if the cursor is not inside the invocation of a constructor.
  InstanceCreationExpression _findSetCreation() {
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    // TODO(brianwilkerson) Consider also accepting uses of LinkedHashSet.
    if (creation == null ||
        node.offset > creation.argumentList.offset ||
        creation.staticType.element != typeProvider.setElement) {
      return null;
    }
    return creation;
  }

  /// Return `true` if the instance [creation] contains at least one unambiguous
  /// element that would cause a set to be inferred.
  bool _hasUnambiguousElement(InstanceCreationExpression creation) {
    var arguments = creation.argumentList.arguments;
    if (arguments == null || arguments.isEmpty) {
      return false;
    }
    return _listHasUnambiguousElement(arguments[0]);
  }

  /// Return `true` if the [element] is sufficient to lexically make the
  /// enclosing literal a set literal rather than a map.
  bool _isUnambiguousElement(CollectionElement element) {
    if (element is ForElement) {
      return _isUnambiguousElement(element.body);
    } else if (element is IfElement) {
      return _isUnambiguousElement(element.thenElement) ||
          _isUnambiguousElement(element.elseElement);
    } else if (element is Expression) {
      return true;
    }
    return false;
  }

  /// Return `true` if the given [node] is a list literal whose elements, if
  /// placed inside curly braces, would lexically make the resulting literal a
  /// set literal rather than a map literal.
  bool _listHasUnambiguousElement(AstNode node) {
    if (node is ListLiteral && node.elements.isNotEmpty) {
      for (var element in node.elements) {
        if (_isUnambiguousElement(element)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Return `true` if a set would be inferred if the literal replacing the
  /// instance [creation] did not have explicit type arguments.
  bool _setWouldBeInferred(InstanceCreationExpression creation) {
    var parent = creation.parent;
    if (parent is VariableDeclaration) {
      var parent2 = parent.parent;
      if (parent2 is VariableDeclarationList &&
          parent2.type?.type?.element == typeProvider.setElement) {
        return true;
      }
    } else if (parent.parent is InvocationExpression) {
      var parameterElement = creation.staticParameterElement;
      if (parameterElement?.type?.element == typeProvider.setElement) {
        return true;
      }
    }
    return _hasUnambiguousElement(creation);
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToSetLiteral newInstance() => ConvertToSetLiteral();
}
