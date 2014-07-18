// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.correction.name_suggestion;

import 'package:analysis_services/src/correction/strings.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';


List<String> _KNOWN_METHOD_NAME_PREFIXES = ['get', 'is', 'to'];

/**
 * Returns possible names for a [String] variable with [text] value.
 *
 * TODO(scheglov) rename
 */
List<String> getVariableNameSuggestions(String text, Set<String> excluded) {
  // filter out everything except of letters and white spaces
  {
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < text.length; i++) {
      int c = text.codeUnitAt(i);
      if (isLetter(c) || isWhitespace(c)) {
        sb.writeCharCode(c);
      }
    }
    text = sb.toString();
  }
  // make single camel-case text
  {
    List<String> words = text.split(' ');
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (i > 0) {
        word = capitalize(word);
      }
      sb.write(word);
    }
    text = sb.toString();
  }
  // split camel-case into separate suggested names
  Set<String> res = new Set();
  _addAll(excluded, res, _getVariableNameSuggestions(text));
  return new List.from(res);
}

/**
 * Returns possible names for a variable with given expected type and expression.
 *
 * TODO(scheglov) rename
 */
List<String> getVariableNameSuggestions2(DartType expectedType,
    Expression assignedExpression, Set<String> excluded) {
  Set<String> res = new Set();
  // use expression
  if (assignedExpression != null) {
    String nameFromExpression = _getBaseNameFromExpression(assignedExpression);
    if (nameFromExpression != null) {
      nameFromExpression = removeStart(nameFromExpression, '_');
      _addAll(excluded, res, _getVariableNameSuggestions(nameFromExpression));
    }
    String nameFromParent =
        _getBaseNameFromLocationInParent(assignedExpression);
    if (nameFromParent != null) {
      _addAll(excluded, res, _getVariableNameSuggestions(nameFromParent));
    }
  }
  // use type
  if (expectedType != null && !expectedType.isDynamic) {
    String typeName = expectedType.name;
    if ('int' == typeName) {
      _addSingleCharacterName(excluded, res, 0x69);
    } else if ('double' == typeName) {
      _addSingleCharacterName(excluded, res, 0x64);
    } else if ('String' == typeName) {
      _addSingleCharacterName(excluded, res, 0x73);
    } else {
      _addAll(excluded, res, _getVariableNameSuggestions(typeName));
    }
    res.remove(typeName);
  }
  // done
  return new List.from(res);
}

/**
 * Adds [toAdd] items which are not excluded.
 */
void _addAll(Set<String> excluded, Set<String> result, Iterable<String> toAdd) {
  for (String item in toAdd) {
    // add name based on "item", but not "excluded"
    for (int suffix = 1; ; suffix++) {
      // prepare name, just "item" or "item2", "item3", etc
      String name = item;
      if (suffix > 1) {
        name += suffix.toString();
      }
      // add once found not excluded
      if (!excluded.contains(name)) {
        result.add(name);
        break;
      }
    }
  }
}

/**
 * Adds to [result] either [c] or the first ASCII character after it.
 */
void _addSingleCharacterName(Set<String> excluded, Set<String> result, int c) {
  while (c < 0x7A) {
    String name = new String.fromCharCode(c);
    // may be done
    if (!excluded.contains(name)) {
      result.add(name);
      break;
    }
    // next character
    c = c + 1;
  }
}

String _getBaseNameFromExpression(Expression expression) {
  String name = null;
  // e as Type
  if (expression is AsExpression) {
    AsExpression asExpression = expression as AsExpression;
    expression = asExpression.expression;
  }
  // analyze expressions
  if (expression is SimpleIdentifier) {
    SimpleIdentifier node = expression;
    return node.name;
  } else if (expression is PrefixedIdentifier) {
    PrefixedIdentifier node = expression;
    return node.identifier.name;
  } else if (expression is MethodInvocation) {
    name = expression.methodName.name;
  } else if (expression is InstanceCreationExpression) {
    InstanceCreationExpression creation = expression;
    ConstructorName constructorName = creation.constructorName;
    TypeName typeName = constructorName.type;
    if (typeName != null) {
      Identifier typeNameIdentifier = typeName.name;
      // new ClassName()
      if (typeNameIdentifier is SimpleIdentifier) {
        return typeNameIdentifier.name;
      }
      // new prefix.name();
      if (typeNameIdentifier is PrefixedIdentifier) {
        PrefixedIdentifier prefixed = typeNameIdentifier;
        // new prefix.ClassName()
        if (prefixed.prefix.staticElement is PrefixElement) {
          return prefixed.identifier.name;
        }
        // new ClassName.constructorName()
        return prefixed.prefix.name;
      }
    }
  }
  // strip known prefixes
  if (name != null) {
    for (int i = 0; i < _KNOWN_METHOD_NAME_PREFIXES.length; i++) {
      String curr = _KNOWN_METHOD_NAME_PREFIXES[i];
      if (name.startsWith(curr)) {
        if (name == curr) {
          return null;
        } else if (isUpperCase(name.codeUnitAt(curr.length))) {
          return name.substring(curr.length);
        }
      }
    }
  }
  // done
  return name;
}

String _getBaseNameFromLocationInParent(Expression expression) {
  // value in named expression
  if (expression.parent is NamedExpression) {
    NamedExpression namedExpression = expression.parent as NamedExpression;
    if (identical(namedExpression.expression, expression)) {
      return namedExpression.name.label.name;
    }
  }
  // positional argument
  {
    ParameterElement parameter = expression.propagatedParameterElement;
    if (parameter == null) {
      parameter = expression.staticParameterElement;
    }
    if (parameter != null) {
      return parameter.displayName;
    }
  }
  // unknown
  return null;
}

/**
 * REturns all variants of names by removing leading words one by one.
 */
List<String> _getVariableNameSuggestions(String name) {
  List<String> result = [];
  List<String> parts =
      name.split('(?<!(^|[A-Z]))(?=[A-Z])|(?<!^)(?=[A-Z][a-z])');
  for (int i = 0; i < parts.length; i++) {
    var s1 = parts[i].toLowerCase();
    var s2 = parts.skip(i + 1).join();
    String suggestion = '$s1$s2';
    result.add(suggestion);
  }
  return result;
}
