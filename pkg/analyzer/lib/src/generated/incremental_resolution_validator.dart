// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.incremental_resolution_validator;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';

/**
 * Validates that the [actual] and the [expected] units have the same structure
 * and resolution. Throws [IncrementalResolutionMismatch] otherwise.
 */
void assertSameResolution(CompilationUnit actual, CompilationUnit expected,
    {bool validateTypes: false}) {
  _SameResolutionValidator validator =
      new _SameResolutionValidator(validateTypes);
  validator.isEqualNodes(expected, actual);
}

/**
 * This exception is thrown when a mismatch between actual and expected AST
 * or resolution is found.
 */
class IncrementalResolutionMismatch {
  final String message;
  IncrementalResolutionMismatch(this.message);

  @override
  String toString() => "IncrementalResolutionMismatch: $message";
}

/**
 * An [AstVisitor] that compares the structure of two [AstNode]s and their
 * resolution to see whether they are equal.
 */
class _SameResolutionValidator extends AstComparator {
  final bool validateTypes;

  _SameResolutionValidator(this.validateTypes);

  @override
  bool failDifferentLength(List expectedList, List actualList) {
    int expectedLength = expectedList.length;
    int actualLength = actualList.length;
    String message = '';
    message += 'Expected length: $expectedLength\n';
    message += 'but $actualLength found\n';
    message += 'in $actualList';
    _fail(message);
    return false;
  }

  @override
  bool failIfNotNull(Object expected, Object actual) {
    if (actual != null) {
      _fail('Expected null, but found $actual');
      return false;
    }
    return true;
  }

  @override
  bool failIsNull(Object expected, Object actual) {
    _fail('Expected not null, but found null');
    return false;
  }

  @override
  bool failRuntimeType(Object expected, Object actual) {
    _fail('Expected ${expected.runtimeType}, but found ${actual.runtimeType}');
    return false;
  }

  @override
  bool isEqualNodes(AstNode first, AstNode second) {
    super.isEqualNodes(first, second);
    if (first is SimpleIdentifier && second is SimpleIdentifier) {
      int offset = first.offset;
      _verifyElement(
          first.staticElement, second.staticElement, 'staticElement[$offset]');
      _verifyElement(first.propagatedElement, second.propagatedElement,
          'propagatedElement[$offset]');
    } else if (first is Declaration && second is Declaration) {
      int offset = first.offset;
      _verifyElement(first.element, second.element, 'declaration[$offset]');
    } else if (first is Directive && second is Directive) {
      int offset = first.offset;
      _verifyElement(first.element, second.element, 'directive[$offset]');
    } else if (first is Expression && second is Expression) {
      int offset = first.offset;
      _verifyType(first.staticType, second.staticType, 'staticType[$offset]');
      _verifyType(first.propagatedType, second.propagatedType,
          'propagatedType[$offset]');
      _verifyElement(first.staticParameterElement,
          second.staticParameterElement, 'staticParameterElement[$offset]');
      _verifyElement(
          first.propagatedParameterElement,
          second.propagatedParameterElement,
          'propagatedParameterElement[$offset]');
    }
    return true;
  }

  @override
  bool isEqualTokensNotNull(Token expected, Token actual) {
    _verifyEqual('lexeme', expected.lexeme, actual.lexeme);
    _verifyEqual('offset', expected.offset, actual.offset);
    _verifyEqual('offset', expected.length, actual.length);
    return true;
  }

  void _fail(String message) {
    throw new IncrementalResolutionMismatch(message);
  }

  void _verifyElement(Element a, Element b, String desc) {
    if (a is Member && b is Member) {
      a = (a as Member).baseElement;
      b = (b as Member).baseElement;
    }
    String locationA = _getElementLocationWithoutUri(a);
    String locationB = _getElementLocationWithoutUri(b);
    if (locationA != locationB) {
      _fail('$desc\nExpected: $b ($locationB)\n  Actual: $a ($locationA)');
    }
    if (a == null && b == null) {
      return;
    }
    _verifyEqual('nameOffset', a.nameOffset, b.nameOffset);
    if (a is ElementImpl && b is ElementImpl) {
      _verifyEqual('codeOffset', a.codeOffset, b.codeOffset);
      _verifyEqual('codeLength', a.codeLength, b.codeLength);
    }
    if (a is LocalElement && b is LocalElement) {
      _verifyEqual('visibleRange', a.visibleRange, b.visibleRange);
    }
    _verifyEqual(
        'documentationComment', a.documentationComment, b.documentationComment);
  }

  void _verifyEqual(String name, actual, expected) {
    if (actual != expected) {
      _fail('$name\nExpected: $expected\n  Actual: $actual');
    }
  }

  void _verifyType(DartType a, DartType b, String desc) {
    if (!validateTypes) {
      return;
    }
    if (a != b) {
      _fail('$desc\nExpected: $b\n  Actual: $a');
    }
  }

  /**
   * Returns an URI scheme independent version of the [element] location.
   */
  static String _getElementLocationWithoutUri(Element element) {
    if (element == null) {
      return '<null>';
    }
    if (element is UriReferencedElementImpl) {
      return '<ignored>';
    }
    ElementLocation location = element.location;
    List<String> components = location.components;
    String uriPrefix = '';
    Element unit = element is CompilationUnitElement
        ? element
        : element.getAncestor((e) => e is CompilationUnitElement);
    if (unit != null) {
      String libComponent = components[0];
      String unitComponent = components[1];
      components = components.sublist(2);
      uriPrefix = _getShortElementLocationUri(libComponent) +
          ':' +
          _getShortElementLocationUri(unitComponent);
    } else {
      String libComponent = components[0];
      components = components.sublist(1);
      uriPrefix = _getShortElementLocationUri(libComponent);
    }
    return uriPrefix + ':' + components.join(':');
  }

  /**
   * Returns a "short" version of the given [uri].
   *
   * For example:
   *     /User/me/project/lib/my_lib.dart -> my_lib.dart
   *     package:project/my_lib.dart      -> my_lib.dart
   */
  static String _getShortElementLocationUri(String uri) {
    int index = uri.lastIndexOf('/');
    if (index == -1) {
      return uri;
    }
    return uri.substring(index + 1);
  }
}
