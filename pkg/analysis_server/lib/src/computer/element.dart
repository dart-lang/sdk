// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.element;

import 'dart:collection';

import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;


/**
 * Information about an element.
 */
class Element {
  static const List<Element> EMPTY_ARRAY = const <Element>[];

  static const int FLAG_ABSTRACT = 0x01;
  static const int FLAG_CONST = 0x02;
  static const int FLAG_DEPRECATED = 0x20;
  static const int FLAG_FINAL = 0x04;
  static const int FLAG_PRIVATE = 0x10;
  static const int FLAG_STATIC = 0x08;

  final bool isAbstract;
  final bool isConst;
  final bool isDeprecated;
  final bool isFinal;
  final bool isPrivate;
  final bool isStatic;

  /**
   * The kind of the element.
   */
  final ElementKind kind;

  /**
   * The length of the name of the element.
   */
  final int length;

  /**
   * The name of the element. This is typically used as the label in the outline.
   */
  final String name;

  /**
   * The offset of the name of the element.
   */
  final int offset;

  /**
   * The parameter list for the element.
   * If the element is not a method or function then `null`.
   * If the element has zero parameters, then `()`.
   */
  final String parameters;

  /**
   * The return type of the element.
   * If the element is not a method or function then `null`.
   * If the element does not have a declared return type, then an empty string.
   */
  final String returnType;

  Element(this.kind, this.name, this.offset, this.length, this.isPrivate,
      this.isDeprecated, {this.parameters, this.returnType, this.isAbstract: false,
      this.isConst: false, this.isFinal: false, this.isStatic: false});

  factory Element.fromEngine(engine.Element element) {
    String name = element.displayName;
    int nameLength = name != null ? name.length : 0;
    String elementParameters = _getParametersString(element);
    String elementReturnType = _getReturnTypeString(element);
    return new Element(ElementKind.valueOfEngine(element.kind), name,
        element.nameOffset, nameLength, element.isPrivate, element.isDeprecated,
        parameters: elementParameters, returnType: elementReturnType, isAbstract:
        _isAbstract(element), isConst: _isConst(element), isFinal: _isFinal(element),
        isStatic: _isStatic(element));
  }

  factory Element.fromJson(HashMap<String, Object> map) {
    ElementKind kind = ElementKind.valueOf(map[KIND]);
    int flags = map[FLAGS];
    return new Element(kind, map[NAME], map[OFFSET], map[LENGTH], _hasFlag(
        flags, FLAG_PRIVATE), _hasFlag(flags, FLAG_DEPRECATED), parameters:
        map[PARAMETERS], returnType: map[RETURN_TYPE], isAbstract: _hasFlag(flags,
        FLAG_ABSTRACT), isConst: _hasFlag(flags, FLAG_CONST), isFinal: _hasFlag(flags,
        FLAG_FINAL), isStatic: _hasFlag(flags, FLAG_STATIC));
  }

  int get flags {
    int flags = 0;
    if (isAbstract) flags |= FLAG_ABSTRACT;
    if (isConst) flags |= FLAG_CONST;
    if (isFinal) flags |= FLAG_FINAL;
    if (isStatic) flags |= FLAG_STATIC;
    if (isPrivate) flags |= FLAG_PRIVATE;
    if (isDeprecated) flags |= FLAG_DEPRECATED;
    return flags;
  }

  HashMap<String, Object> toJson() {
    HashMap<String, Object> json = {
      KIND: kind.name,
      NAME: name,
      OFFSET: offset,
      LENGTH: length,
      FLAGS: flags
    };
    if (parameters != null) {
      json[PARAMETERS] = parameters;
    }
    if (returnType != null) {
      json[RETURN_TYPE] = returnType;
    }
    return json;
  }

  static String _getParametersString(engine.Element element) {
    // TODO(scheglov) expose the corresponding feature from ExecutableElement
    if (element is engine.ExecutableElement) {
      var sb = new StringBuffer();
      String closeOptionalString = '';
      for (var parameter in element.parameters) {
        if (sb.isNotEmpty) {
          sb.write(', ');
        }
        if (closeOptionalString.isEmpty) {
          if (parameter.kind == engine.ParameterKind.NAMED) {
            sb.write('{');
            closeOptionalString = '}';
          }
          if (parameter.kind == engine.ParameterKind.POSITIONAL) {
            sb.write('[');
            closeOptionalString = ']';
          }
        }
        sb.write(parameter.toString());
      }
      sb.write(closeOptionalString);
      return '(' + sb.toString() + ')';
    } else {
      return null;
    }
  }

  static String _getReturnTypeString(engine.Element element) {
    if ((element is engine.ExecutableElement)) {
      return element.returnType.toString();
    } else {
      return null;
    }
  }

  static bool _hasFlag(int flags, int flag) => (flags & flag) != 0;

  static bool _isAbstract(engine.Element element) {
    // TODO(scheglov) add isAbstract to Element API
    if (element is engine.ClassElement) {
      return element.isAbstract;
    }
    if (element is engine.MethodElement) {
      return element.isAbstract;
    }
    if (element is engine.PropertyAccessorElement) {
      return element.isAbstract;
    }
    return false;
  }

  static bool _isConst(engine.Element element) {
    // TODO(scheglov) add isConst to Element API
    if (element is engine.ConstructorElement) {
      return element.isConst;
    }
    if (element is engine.VariableElement) {
      return element.isConst;
    }
    return false;
  }

  static bool _isFinal(engine.Element element) {
    // TODO(scheglov) add isFinal to Element API
    if (element is engine.VariableElement) {
      return element.isFinal;
    }
    return false;
  }

  static bool _isStatic(engine.Element element) {
    // TODO(scheglov) add isStatic to Element API
    if (element is engine.ExecutableElement) {
      return element.isStatic;
    }
    if (element is engine.PropertyInducingElement) {
      return element.isStatic;
    }
    return false;
  }
}


/**
 * An enumeration of the kinds of elements.
 */
class ElementKind {
  static const CLASS = const ElementKind('CLASS');
  static const CLASS_TYPE_ALIAS = const ElementKind('CLASS_TYPE_ALIAS');
  static const COMPILATION_UNIT = const ElementKind('COMPILATION_UNIT');
  static const CONSTRUCTOR = const ElementKind('CONSTRUCTOR');
  static const FIELD = const ElementKind('FIELD');
  static const FUNCTION = const ElementKind('FUNCTION');
  static const FUNCTION_TYPE_ALIAS = const ElementKind('FUNCTION_TYPE_ALIAS');
  static const GETTER = const ElementKind('GETTER');
  static const LIBRARY = const ElementKind('LIBRARY');
  static const METHOD = const ElementKind('METHOD');
  static const SETTER = const ElementKind('SETTER');
  static const TOP_LEVEL_VARIABLE = const ElementKind('TOP_LEVEL_VARIABLE');
  static const UNIT_TEST_CASE = const ElementKind('UNIT_TEST_CASE');
  static const UNIT_TEST_GROUP = const ElementKind('UNIT_TEST_GROUP');
  static const UNKNOWN = const ElementKind('UNKNOWN');

  final String name;

  const ElementKind(this.name);

  @override
  String toString() => name;

  static ElementKind valueOf(String name) {
    if (CLASS.name == name) return CLASS;
    if (CLASS_TYPE_ALIAS.name == name) return CLASS_TYPE_ALIAS;
    if (COMPILATION_UNIT.name == name) return COMPILATION_UNIT;
    if (CONSTRUCTOR.name == name) return CONSTRUCTOR;
    if (FIELD.name == name) return FIELD;
    if (FUNCTION.name == name) return FUNCTION;
    if (FUNCTION_TYPE_ALIAS.name == name) return FUNCTION_TYPE_ALIAS;
    if (GETTER.name == name) return GETTER;
    if (LIBRARY.name == name) return LIBRARY;
    if (METHOD.name == name) return METHOD;
    if (SETTER.name == name) return SETTER;
    if (TOP_LEVEL_VARIABLE.name == name) return TOP_LEVEL_VARIABLE;
    if (UNIT_TEST_CASE.name == name) return UNIT_TEST_CASE;
    if (UNIT_TEST_GROUP.name == name) return UNIT_TEST_GROUP;
    if (UNKNOWN.name == name) return UNKNOWN;
    throw new ArgumentError('Unknown ElementKind: $name');
  }

  static ElementKind valueOfEngine(engine.ElementKind kind) {
    if (kind == engine.ElementKind.CLASS) {
      return CLASS;
    }
    if (kind == engine.ElementKind.COMPILATION_UNIT) {
      return COMPILATION_UNIT;
    }
    if (kind == engine.ElementKind.CONSTRUCTOR) {
      return CONSTRUCTOR;
    }
    if (kind == engine.ElementKind.FIELD) {
      return FIELD;
    }
    if (kind == engine.ElementKind.FUNCTION) {
      return FUNCTION;
    }
    if (kind == engine.ElementKind.FUNCTION_TYPE_ALIAS) {
      return FUNCTION_TYPE_ALIAS;
    }
    if (kind == engine.ElementKind.GETTER) {
      return GETTER;
    }
    if (kind == engine.ElementKind.LIBRARY) {
      return LIBRARY;
    }
    if (kind == engine.ElementKind.METHOD) {
      return METHOD;
    }
    if (kind == engine.ElementKind.SETTER) {
      return SETTER;
    }
    if (kind == engine.ElementKind.TOP_LEVEL_VARIABLE) {
      return TOP_LEVEL_VARIABLE;
    }
    return UNKNOWN;
  }
}
