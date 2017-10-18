// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';

List<String> _KNOWN_METHOD_NAME_PREFIXES = ['get', 'is', 'to'];

/**
 * Returns all variants of names by removing leading words one by one.
 */
List<String> getCamelWordCombinations(String name) {
  List<String> result = [];
  List<String> parts = getCamelWords(name);
  for (int i = 0; i < parts.length; i++) {
    var s1 = parts[i].toLowerCase();
    var s2 = parts.skip(i + 1).join();
    String suggestion = '$s1$s2';
    result.add(suggestion);
  }
  return result;
}

/**
 * Returns possible names for a variable with the given expected type and
 * expression assigned.
 */
List<String> getVariableNameSuggestionsForExpression(
    DartType expectedType, Expression assignedExpression, Set<String> excluded,
    {bool isMethod: false}) {
  String prefix;

  if (isMethod) {
    // If we're in a build() method, use 'build' as the name prefix.
    MethodDeclaration method =
        assignedExpression.getAncestor((n) => n is MethodDeclaration);
    if (method != null) {
      String enclosingName = method.name?.name;
      if (enclosingName != null && enclosingName.startsWith('build')) {
        prefix = 'build';
      }
    }
  }

  Set<String> res = new Set();
  // use expression
  if (assignedExpression != null) {
    String nameFromExpression = _getBaseNameFromExpression(assignedExpression);
    if (nameFromExpression != null) {
      nameFromExpression = removeStart(nameFromExpression, '_');
      _addAll(excluded, res, getCamelWordCombinations(nameFromExpression),
          prefix: prefix);
    }
    String nameFromParent =
        _getBaseNameFromLocationInParent(assignedExpression);
    if (nameFromParent != null) {
      _addAll(excluded, res, getCamelWordCombinations(nameFromParent));
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
      _addAll(excluded, res, getCamelWordCombinations(typeName));
    }
    res.remove(typeName);
  }
  // done
  return new List.from(res);
}

/**
 * Returns possible names for a [String] variable with [text] value.
 */
List<String> getVariableNameSuggestionsForText(
    String text, Set<String> excluded) {
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
  _addAll(excluded, res, getCamelWordCombinations(text));
  return new List.from(res);
}

/**
 * Adds [toAdd] items which are not excluded.
 */
void _addAll(Set<String> excluded, Set<String> result, Iterable<String> toAdd,
    {String prefix}) {
  for (String item in toAdd) {
    // add name based on "item", but not "excluded"
    for (int suffix = 1;; suffix++) {
      // prepare name, just "item" or "item2", "item3", etc
      String name = item;
      if (suffix > 1) {
        name += suffix.toString();
      }
      // add once found not excluded
      if (!excluded.contains(name)) {
        result.add(prefix == null ? name : '$prefix${capitalize(name)}');
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
  if (expression is AsExpression) {
    return _getBaseNameFromExpression(expression.expression);
  } else if (expression is ParenthesizedExpression) {
    return _getBaseNameFromExpression(expression.expression);
  }
  return _getBaseNameFromUnwrappedExpression(expression);
}

String _getBaseNameFromLocationInParent(Expression expression) {
  // value in named expression
  if (expression.parent is NamedExpression) {
    NamedExpression namedExpression = expression.parent as NamedExpression;
    if (namedExpression.expression == expression) {
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

String _getBaseNameFromUnwrappedExpression(Expression expression) {
  String name = null;
  // analyze expressions
  if (expression is SimpleIdentifier) {
    return expression.name;
  } else if (expression is PrefixedIdentifier) {
    return expression.identifier.name;
  } else if (expression is PropertyAccess) {
    return expression.propertyName.name;
  } else if (expression is MethodInvocation) {
    name = expression.methodName.name;
  } else if (expression is InstanceCreationExpression) {
    ConstructorName constructorName = expression.constructorName;
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
  } else if (expression is IndexExpression) {
    name = _getBaseNameFromExpression(expression.realTarget);
    if (name.endsWith('s')) {
      name = name.substring(0, name.length - 1);
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
