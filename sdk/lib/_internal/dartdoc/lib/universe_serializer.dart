// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library serializes the Dart2Js AST into a compact and easy to use
 * [Element] tree useful for code exploration tools such as DartDoc.
 */
library universe_serializer;

import '../../compiler/implementation/mirrors/mirrors.dart';
import '../../compiler/implementation/mirrors/mirrors_util.dart';
import '../../compiler/implementation/mirrors/dart2js_mirror.dart' as dart2js;
import '../../libraries.dart';
import 'dartdoc.dart';

/**
 * Base class for all nodes.
 */
class Element {
  /** Human readable type name for the node. */
  final String kind;
  /** Human readable name for the element. */
  final String name;
  /** Id for the node that is unique within its parent's children. */
  final String id;
  /** Raw text of the comment associated with the Element if any. */
  final String comment;
  /** Children of the node. */
  List<Element> children;

  Element(this.kind, this.name, this.id, this.comment);

  void addChild(Element child) {
    if (children == null) {
      children = <Element>[];
    }
    children.add(child);
  }
}

/**
 * Converts false to null.  Useful as the serialization scheme we use
 * omits null values.
 */
bool _optionalBool(bool value) => value == true ? true : null;

/**
 * [Element] describing a Dart library.
 */
class LibraryElement extends Element {
  LibraryElement(String name, LibraryMirror mirror, CommentMap comments)
      : super('library', name, mirror.uri.toString(),
              comments.findLibrary(mirror.location)) {

    mirror.functions.forEach((childName, childMirror) {
      addChild(new MethodElement(childName, childMirror, comments));
    });

    mirror.getters.forEach((childName, childMirror) {
      addChild(new GetterElement(childName, childMirror, comments));
    });

    mirror.variables.forEach((childName, childMirror) {
        addChild(new VariableElement(childName, childMirror));
    });

    mirror.classes.forEach((className, classMirror) {
      if (!classMirror.isPrivate) {
        if (classMirror is TypedefMirror) {
          addChild(new TypedefElement(className, classMirror, comments));
        } else {
          addChild(new ClassElement(className, classMirror, comments));
        }
      }
    });
  }
}

/**
 * [Element] describing a Dart class.
 */
class ClassElement extends Element {
  /** Base class.*/
  final Reference superclass;
  /** Interfaces the class implements. */
  List<Reference> interfaces;

  ClassElement(String name, ClassMirror mirror, CommentMap comments)
      : super('class', mirror.simpleName, name,
              comments.find(mirror.location)),
        superclass = mirror.superclass != null ?
            new Reference(mirror.superclass) : null {
    for (var interface in mirror.superinterfaces) {
      if (this.interfaces == null) {
        this.interfaces = <Reference>[];
      }
      this.interfaces.add(new Reference(interface));
    }

    mirror.methods.forEach((childName, childMirror) {
      addChild(new MethodElement(childName, childMirror, comments));
    });

    mirror.getters.forEach((childName, childMirror) {
      addChild(new GetterElement(childName, childMirror, comments));
    });

    mirror.variables.forEach((childName, childMirror) {
        addChild(new VariableElement(childName, childMirror));
    });

    mirror.constructors.forEach((constructorName, methodMirror) {
      addChild(new MethodElement(constructorName, methodMirror, comments, 'constructor'));
    });
  }
}

/**
 * [Element] describing a getter.
 */
class GetterElement extends Element {
  /** Type of the getter. */
  final Reference ref;
  final bool isStatic;

  GetterElement(String name, MethodMirror mirror, CommentMap comments)
      : super('property', mirror.simpleName, name,
              comments.find(mirror.location)),
        ref = mirror.returnType != null ?
            new Reference(mirror.returnType) : null,
        isStatic = _optionalBool(mirror.isStatic);
}

/**
 * [Element] describing a method which may be a regular method, a setter, or an
 * operator.
 */
class MethodElement extends Element {
  final Reference returnType;
  final bool isSetter;
  final bool isOperator;
  final bool isStatic;

  MethodElement(String name, MethodMirror mirror, CommentMap comments, [String kind = 'method'])
      : super(kind, name, '$name${mirror.parameters.length}()',
              comments.find(mirror.location)),
        returnType = mirror.returnType != null ?
            new Reference(mirror.returnType) : null,
        isSetter = _optionalBool(mirror.isSetter),
        isOperator = _optionalBool(mirror.isOperator),
        isStatic = _optionalBool(mirror.isStatic) {

    for (var param in mirror.parameters) {
      addChild(new ParameterElement(param));
    }
  }
}

/**
 * Element describing a parameter.
 */
class ParameterElement extends Element {
  /** Type of the parameter. */
  final Reference ref;
  /** Whether the parameter is optional. */
  final bool isOptional;

  ParameterElement(ParameterMirror mirror)
      : super('param', mirror.simpleName, mirror.simpleName, null),
        ref = new Reference(mirror.type),
        isOptional = _optionalBool(mirror.isOptional) {
  }
}

/**
 * Element describing a variable.
 */
class VariableElement extends Element {
  /** Type of the variable. */
  final Reference ref;
  final bool isStatic;

  VariableElement(String name, VariableMirror mirror)
      : super('property', mirror.simpleName, name, null),
        ref = new Reference(mirror.type),
        isStatic = _optionalBool(mirror.isStatic);
}
// TODO(jacobr): this seems incomplete.
/**
 * Element describing a typedef element.
 */
class TypedefElement extends Element {
  TypedefElement(String name, TypedefMirror mirror, CommentMap comments)
      : super('typedef', mirror.simpleName, name,
              comments.find(mirror.location));
}

/**
 * Reference to an Element with type argument if the reference is parameterized.
 */
class Reference {
  final String name;
  final String refId;
  List<Reference> arguments;

  Reference(Mirror mirror)
      : name = mirror.simpleName,
        refId = getId(mirror) {
    if (mirror is ClassMirror) {
      if (mirror is !TypedefMirror
          && mirror.typeArguments.length > 0) {
        arguments = <Reference>[];
        for (var typeArg in mirror.typeArguments) {
          arguments.add(new Reference(typeArg));
        }
      }
    }
  }

  static String getId(Mirror mirror) {
    String id = mirror.simpleName;
    if (mirror is MemberMirror) {
      MemberMirror memberMirror = mirror;
      if (memberMirror.owner != null) {
        id = '${getId(memberMirror.owner)}/$id';
      }
    }
    return id;
  }
}
