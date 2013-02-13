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

String _stripUri(String uri) {
  String prefix = "/dart/";
  int start = uri.indexOf(prefix);
  if (start != -1) {
    return uri.substring(start + prefix.length);
  } else {
    return uri;
  }
}

/**
 * Base class for all elements in the AST.
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
  /** Whether the element is private. */
  final bool isPrivate;

  /**
   * Uri containing the definition of the element.
   */
  String uri;
  /**
   * Line in the original source file that starts the definition of the element.
   */
  String line;

  Element(Mirror mirror, this.kind, this.name, this.id, this.comment)
      : line = mirror.location.line.toString(),
        isPrivate = _optionalBool(mirror.isPrivate),
        uri = _stripUri(mirror.location.sourceUri.toString());

  void addChild(Element child) {
    if (children == null) {
      children = <Element>[];
    }
    children.add(child);
  }

  /**
   * Remove all URIs that exactly match the parent node's URI.
   * This reduces output file size by about 20%.
   */
  void stripDuplicateUris(String parentUri, parentLine) {
    if (children != null) {
      for (var child in children) {
        child.stripDuplicateUris(uri, line);
      }
    }
    if (parentUri == uri) {
      uri = null;
    }
    if (line == parentLine) {
      line = null;
    }
  }
}

/**
 * Converts false to null.  Useful as the serialization scheme we use
 * omits null values.
 */
bool _optionalBool(bool value) => value == true ? true : null;

Reference _optionalReference(Mirror mirror) {
  return (mirror != null && mirror.simpleName != "Dynamic_" &&
      mirror.simpleName != "dynamic") ?
        new Reference(mirror) : null;
}

/**
 * [Element] describing a Dart library.
 */
class LibraryElement extends Element {
  LibraryElement(String name, LibraryMirror mirror)
      : super(mirror, 'library', name, name, computeComment(mirror)) {

    mirror.functions.forEach((childName, childMirror) {
      addChild(new MethodElement(childName, childMirror));
    });

    mirror.getters.forEach((childName, childMirror) {
      addChild(new GetterElement(childName, childMirror));
    });

    mirror.variables.forEach((childName, childMirror) {
        addChild(new VariableElement(childName, childMirror));
    });

    mirror.classes.forEach((className, classMirror) {
      if (!classMirror.isPrivate) {
        if (classMirror is TypedefMirror) {
          addChild(new TypedefElement(className, classMirror));
        } else {
          addChild(new ClassElement(className, classMirror));
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
  /** Whether the class is abstract. */
  final bool isAbstract;
  /** Interfaces the class implements. */
  List<Reference> interfaces;

  ClassElement(String name, ClassMirror mirror)
      : super(mirror, 'class', mirror.simpleName, name, computeComment(mirror)),
        superclass = _optionalReference(mirror.superclass),
        isAbstract = _optionalBool(mirror.isAbstract) {
    for (var interface in mirror.superinterfaces) {
      if (this.interfaces == null) {
        this.interfaces = <Reference>[];
      }
      this.interfaces.add(_optionalReference(interface));
    }

    mirror.methods.forEach((childName, childMirror) {
      if (!childMirror.isConstructor && !childMirror.isGetter) {
        addChild(new MethodElement(childName, childMirror));
      }
    });

    mirror.getters.forEach((childName, childMirror) {
      addChild(new GetterElement(childName, childMirror));
    });

    mirror.variables.forEach((childName, childMirror) {
        addChild(new VariableElement(childName, childMirror));
    });

    mirror.constructors.forEach((constructorName, methodMirror) {
      addChild(new MethodElement(constructorName, methodMirror, 'constructor'));
    });

    for (var typeVariable in mirror.originalDeclaration.typeVariables) {
      addChild(new TypeParameterElement(typeVariable));
    }
  }
}

/**
 * [Element] describing a getter.
 */
class GetterElement extends Element {
  /** Type of the getter. */
  final Reference ref;
  final bool isStatic;

  GetterElement(String name, MethodMirror mirror)
      : super(mirror, 'property', mirror.simpleName, name, computeComment(mirror)),
        ref = _optionalReference(mirror.returnType),
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

  MethodElement(String name, MethodMirror mirror, [String kind = 'method'])
      : super(mirror, kind, name, '$name${mirror.parameters.length}()',
              computeComment(mirror)),
        returnType = _optionalReference(mirror.returnType),
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
      : super(mirror, 'param', mirror.simpleName, mirror.simpleName, null),
        ref = _optionalReference(mirror.type),
        isOptional = _optionalBool(mirror.isOptional) {
  }
}

/**
 * Element describing a generic type parameter.
 */
class TypeParameterElement extends Element {
  /**
   * Upper bound for the parameter.
   * 
   * In the following code sample, [:Bar:] is an upper bound:
   * [: class Bar<T extends Foo> { } :]
   */
  Reference upperBound;

  TypeParameterElement(TypeMirror mirror)
      : super(mirror, 'typeparam', mirror.simpleName, mirror.simpleName, null),
        upperBound = mirror.upperBound != null && !mirror.upperBound.isObject ?
            new Reference(mirror.upperBound) : null;
}

/**
 * Element describing a variable.
 */
class VariableElement extends Element {
  /** Type of the variable. */
  final Reference ref;
  /** Whether the variable is static. */
  final bool isStatic;
  /** Whether the variable is final. */
  final bool isFinal;

  VariableElement(String name, VariableMirror mirror)
      : super(mirror, 'variable', mirror.simpleName, name, null),
        ref = _optionalReference(mirror.type),
        isStatic = _optionalBool(mirror.isStatic),
        isFinal = _optionalBool(mirror.isFinal);
}

/**
 * Element describing a typedef.
 */

class TypedefElement extends Element {
  /** Return type of the typedef. */
  final Reference returnType;

  TypedefElement(String name, TypedefMirror mirror)
      : super(mirror, 'typedef', mirror.simpleName, name,
               computeComment(mirror)),
        returnType = _optionalReference(mirror.value.returnType) {
    for (var param in mirror.value.parameters) {
      addChild(new ParameterElement(param));
    }
    for (var typeVariable in mirror.originalDeclaration.typeVariables) {
      addChild(new TypeParameterElement(typeVariable));
    }
  }
}

/**
 * Reference to an Element with type argument if the reference is parameterized.
 */
class Reference {
  final String name;
  final String refId;
  List<Reference> arguments;

  Reference(Mirror mirror)
      : name = mirror.displayName,
        refId = getId(mirror) {
    if (mirror is ClassMirror) {
      if (mirror is !TypedefMirror && !mirror.typeArguments.isEmpty) {
        arguments = <Reference>[];
        for (var typeArg in mirror.typeArguments) {
          arguments.add(_optionalReference(typeArg));
        }
      }
    }
  }

  static String getId(Mirror mirror) {
    String id = mirror.simpleName;
    if (mirror.owner != null) {
      id = '${getId(mirror.owner)}/$id';
    }
    return id;
  }
}
