// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library serializes the Dart2Js AST into a compact and easy to use
 * [Element] tree useful for code exploration tools such as DartDoc.
 */
library universe_serializer;

import 'dartdoc.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
import 'package:path/path.dart' as path;
import '../../compiler/implementation/mirrors/dart2js_mirror.dart' as dart2js;
import '../../compiler/implementation/mirrors/mirrors.dart';
import '../../compiler/implementation/mirrors/mirrors_util.dart';
import '../../libraries.dart';

String _stripUri(String uri) {
  String prefix = "/dart/";
  int start = uri.indexOf(prefix);
  if (start != -1) {
    return uri.substring(start + prefix.length);
  } else {
    return uri;
  }
}

String _escapeId(String id) {
  return id.replaceAll(new RegExp('[/]'), '#slash');
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
  /** Raw html comment for the Element from MDN. */
  String mdnCommentHtml;
  /**
   * The URL to the page on MDN that content was pulled from for the current
   * type being documented. Will be `null` if the type doesn't use any MDN
   * content.
   */
  String mdnUrl;
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

  // TODO(jacobr): refactor the code so that lookupMdnComment does not need to
  // be passed to every Element constructor.
  Element(Mirror mirror, this.kind, this.name, String id, this.comment,
      MdnComment lookupMdnComment(Mirror))
      : line = mirror.location.line.toString(),
        id = _escapeId(id),
        isPrivate = _optionalBool(mirror.isPrivate),
        uri = _stripUri(mirror.location.sourceUri.toString()) {
    if (lookupMdnComment != null) {
      var mdnComment = lookupMdnComment(mirror);
      if (mdnComment != null) {
        mdnCommentHtml = mdnComment.mdnComment;
        mdnUrl = mdnComment.mdnUrl;
      }
    }
  }

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
 * Helper class to track what members of a library should be included.
 */
class LibrarySubset {
  final LibraryMirror library;
  Set<String> includedChildren;

  LibrarySubset(this.library) : includedChildren = new Set<String>();
}

/**
 * [Element] describing a Dart library.
 */
class LibraryElement extends Element {
  /**
   * Partial versions of LibraryElements containing classes that are extended
   * or implemented by classes in this library.
   */
  List<LibraryElement> dependencies;

  /**
   * Construct a LibraryElement from a [mirror].
   *
   * If [includedChildren] is specified, only elements matching names in
   * [includedChildren] are included and no dependencies are included.
   * [lookupMdnComment] is an optional function that returns the MDN
   * documentation for elements. [dependencies] is an optional map
   * tracking all classes dependend on by this [ClassElement].
   */
  LibraryElement(LibraryMirror mirror,
      {MdnComment lookupMdnComment(Mirror), Set<String> includedChildren})
      : super(mirror, 'library', _libraryName(mirror), mirror.simpleName,
          computeComment(mirror), lookupMdnComment) {
    var requiredDependencies;
    // We don't need to track our required dependencies when generating a
    // filtered version of this library which will be used as a dependency for
    // another library.
    if (includedChildren == null)
      requiredDependencies = new Map<String, LibrarySubset>();
    mirror.functions.forEach((childName, childMirror) {
      if (includedChildren == null || includedChildren.contains(childName))
        addChild(new MethodElement(childName, childMirror, lookupMdnComment));
    });

    mirror.getters.forEach((childName, childMirror) {
      if (includedChildren == null || includedChildren.contains(childName))
        addChild(new GetterElement(childName, childMirror, lookupMdnComment));
    });

    mirror.variables.forEach((childName, childMirror) {
      if (includedChildren == null || includedChildren.contains(childName))
        addChild(new VariableElement(childName, childMirror, lookupMdnComment));
    });

    mirror.classes.forEach((className, classMirror) {
      if (includedChildren == null || includedChildren.contains(className)) {
        if (classMirror is TypedefMirror) {
          addChild(new TypedefElement(className, classMirror));
        } else {
          addChild(new ClassElement(classMirror,
              dependencies: requiredDependencies,
              lookupMdnComment: lookupMdnComment));
        }
      }
    });

    if (requiredDependencies != null && !requiredDependencies.isEmpty) {
      dependencies = requiredDependencies.values.map((librarySubset) =>
          new LibraryElement(
              librarySubset.library,
              lookupMdnComment: lookupMdnComment,
              includedChildren: librarySubset.includedChildren)).toList();
    }
  }

  static String _libraryName(LibraryMirror mirror) {
    if (mirror.uri.scheme == 'file') {
      // TODO(jacobr): this is a hack. Remove once these libraries are removed
      // from the sdk.
      var uri = mirror.uri;
      var uriPath = uri.path;

      var parts = path.split(uriPath);

      // Find either pkg/ or packages/
      var pkgDir = parts.lastIndexOf('pkg');
      var packageDir = parts.lastIndexOf('packages');

      if (pkgDir >= 0) {
        packageDir = pkgDir;
      }

      var libDir = parts.lastIndexOf('lib');
      var rest = parts.sublist(libDir + 1);

      // If there's no lib, we can't find the package.
      if (libDir < 0 || libDir < packageDir) {
        // TODO(jacobr): this is a lousy fallback.
        print("Unable to determine package for $uriPath.");
        return mirror.uri.toString();
      } else if (packageDir >= 0 && rest.length >= 1) {
        // For URI: foo/bar/packages/widget/lib/sprocket.dart will return:
        // 'package:widget/sprocket.dart'
        return 'package:${parts[packageDir + 1]}/${rest.join('/')}';
      }
    } else {
      return mirror.uri.toString();
    }
  }

  void stripDuplicateUris(String parentUri, parentLine) {
    super.stripDuplicateUris(parentUri, parentLine);

    if (dependencies != null) {
      for (var child in dependencies) {
        child.stripDuplicateUris(null, null);
      }
    }
  }
}

/**
 * Returns whether the class implements or extends [Error] or [Exception].
 */
bool _isThrowable(ClassMirror mirror) {
  if (mirror.library.uri.toString() == 'dart:core' &&
      mirror.simpleName == 'Error' || mirror.simpleName == 'Exception')
    return true;
  if (mirror.superclass != null && _isThrowable(mirror.superclass))
    return true;
  return mirror.superinterfaces.any(_isThrowable);
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
  /** Whether the class implements or extends [Error] or [Exception]. */
  bool isThrowable;

  /**
   * Constructs a [ClassElement] from a [ClassMirror].
   *
   * [dependencies] is an optional map updated as a side effect of running
   * this constructor that tracks what classes from other libraries are
   * dependencies of classes in this library.  A class is considered a
   * dependency if it implements or extends another class.
   * [lookupMdnComment] is an optional function that returns the MDN
   * documentation for elements. [dependencies] is an optional map
   * tracking all classes dependend on by this [ClassElement].
   */
  ClassElement(ClassMirror mirror,
      {Map<String, LibrarySubset> dependencies,
       MdnComment lookupMdnComment(Mirror)})
      : super(mirror, 'class', mirror.simpleName, mirror.simpleName, computeComment(mirror),
          lookupMdnComment),
        superclass = _optionalReference(mirror.superclass),
        isAbstract = _optionalBool(mirror.isAbstract),
        isThrowable = _optionalBool(_isThrowable(mirror)){

    addCrossLibraryDependencies(clazz) {
      if (clazz == null) return;

      if (mirror.library != clazz.library) {
        var libraryStub = dependencies.putIfAbsent(clazz.library.simpleName,
            () => new LibrarySubset(clazz.library));
        libraryStub.includedChildren.add(clazz.simpleName);
      }

      for (var interface in clazz.superinterfaces) {
        addCrossLibraryDependencies(interface);
      }
      addCrossLibraryDependencies(clazz.superclass);
    }

    if (dependencies != null) {
      addCrossLibraryDependencies(mirror);
    }

    for (var interface in mirror.superinterfaces) {
      if (this.interfaces == null) {
        this.interfaces = <Reference>[];
      }
      this.interfaces.add(_optionalReference(interface));
    }

    mirror.methods.forEach((childName, childMirror) {
      if (!childMirror.isConstructor && !childMirror.isGetter) {
        addChild(new MethodElement(childName, childMirror, lookupMdnComment));
      }
    });

    mirror.getters.forEach((childName, childMirror) {
      addChild(new GetterElement(childName, childMirror, lookupMdnComment));
    });

    mirror.variables.forEach((childName, childMirror) {
        addChild(new VariableElement(childName, childMirror,
            lookupMdnComment));
    });

    mirror.constructors.forEach((constructorName, methodMirror) {
      addChild(new MethodElement(constructorName, methodMirror,
          lookupMdnComment, 'constructor'));
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

  GetterElement(String name, MethodMirror mirror,
      MdnComment lookupMdnComment(Mirror))
      : super(mirror, 'property', mirror.simpleName, name, computeComment(mirror),
          lookupMdnComment),
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

  MethodElement(String name, MethodMirror mirror,
      MdnComment lookupMdnComment(Mirror), [String kind = 'method'])
      : super(mirror, kind, name, '$name${mirror.parameters.length}()',
              computeComment(mirror), lookupMdnComment),
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

  /**
   * Returns the default value for this parameter.
   */
  final String defaultValue;

  /**
   * Is this parameter optional?
   */
  final bool isOptional;

  /**
   * Is this parameter named?
   */
  final bool isNamed;

  /**
   * Returns the initialized field, if this parameter is an initializing formal.
   */
  final Reference initializedField;

  ParameterElement(ParameterMirror mirror)
      : super(mirror, 'param', mirror.simpleName, mirror.simpleName, null,
          null),
        ref = _optionalReference(mirror.type),
        isOptional = _optionalBool(mirror.isOptional),
        defaultValue = mirror.defaultValue,
        isNamed = _optionalBool(mirror.isNamed),
        initializedField = _optionalReference(mirror.initializedField) {

    if (mirror.type is FunctionTypeMirror) {
      addChild(new FunctionTypeElement(mirror.type));
    }
  }
}

class FunctionTypeElement extends Element {
  final Reference returnType;

  FunctionTypeElement(FunctionTypeMirror mirror)
      : super(mirror, 'functiontype', mirror.simpleName, mirror.simpleName, null, null),
        returnType = _optionalReference(mirror.returnType) {
    for (var param in mirror.parameters) {
      addChild(new ParameterElement(param));
    }
    // TODO(jacobr): can a FunctionTypeElement really have type variables?
    for (var typeVariable in mirror.originalDeclaration.typeVariables) {
      addChild(new TypeParameterElement(typeVariable));
    }
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
  final Reference upperBound;

  TypeParameterElement(TypeMirror mirror)
      : super(mirror, 'typeparam', mirror.simpleName, mirror.simpleName, null,
          null),
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

  VariableElement(String name, VariableMirror mirror,
      MdnComment lookupMdnComment(Mirror))
      : super(mirror, 'variable', mirror.simpleName, name,
          computeComment(mirror), lookupMdnComment),
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
               computeComment(mirror), null),
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
      : name = displayName(mirror),
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

  // TODO(jacobr): compute the referenceId correctly for the general case so
  // that this method can work with all element types not just LibraryElements.
  Reference.fromElement(LibraryElement e) : name = e.name, refId = e.id;

  static String getId(Mirror mirror) {
    String id = _escapeId(mirror.simpleName);
    if (mirror.owner != null) {
      id = '${getId(mirror.owner)}/$id';
    }
    return id;
  }
}
