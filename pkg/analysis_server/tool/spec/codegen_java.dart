// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tools for Java code generation.
 */
library CodegenJava;

import 'package:html5lib/dom.dart' as dom;
import 'api.dart';
import 'codegen_tools.dart';
import 'from_html.dart';
import 'to_html.dart';

/**
 * Common code for all Java code generation.
 */
class CodegenJavaVisitor extends HierarchicalApiVisitor with CodeGenerator {
  _CodegenJavaState _state;

  /**
   * Variable names which must be changed in order to avoid conflict with
   * reserved words in Java.
   */
  static const Map<String, String> _variableRenames = const {
    'default': 'defaultSdk'
  };

  /**
   * Type references in the spec that are named something else in Java.
   */
  static const Map<String, String> _typeRenames = const {
    'bool': 'boolean',
    'FilePath': 'String',
    'DebugContextId': 'String',
    'object': 'Object',
    'Override': 'OverrideMember',
  };

  /**
   * Visitor used to produce doc comments.
   */
  final ToHtmlVisitor toHtmlVisitor;

  CodegenJavaVisitor(Api api)
      : super(api),
        toHtmlVisitor = new ToHtmlVisitor(api);

  /**
   * Convenience method for subclasses for calling docComment.
   */
  void javadocComment(List<dom.Node> docs) {
    docComment(docs, width: 99, javadocStyle: true);
  }

  /**
   * Create a private field, using [callback] to create its contents.
   */
  void privateField(String fieldName, void callback()) {
    _state.privateFields[fieldName] = collectCode(callback);
  }

  /**
   * Create a constructor, using [callback] to create its contents.
   */
  void constructor(String name, void callback()) {
    _state.constructors[name] = collectCode(callback);
  }

  /**
   * Create a private method, using [callback] to create its contents.
   */
  void privateMethod(String methodName, void callback()) {
    _state.privateMethods[methodName] = collectCode(callback);
  }

  /**
   * Create a public method, using [callback] to create its contents.
   */
  void publicMethod(String methodName, void callback()) {
    _state.publicMethods[methodName] = collectCode(callback);
  }

  /**
   * Execute [callback], collecting any methods that are output using
   * [privateMethod] or [publicMethod], and insert the class (with methods
   * sorted).  [header] is the part of the class declaration before the
   * opening brace.
   */
  void makeClass(String header, void callback()) {
    _CodegenJavaState oldState = _state;
    try {
      _state = new _CodegenJavaState();
      callback();
      writeln('$header {');
      indent(() {
        // fields
        List<String> allFields =
            _valuesSortedByKey(_state.privateFields).toList();
        for (String field in allFields) {
          writeln();
          write(field);
        }

        // constructors
        List<String> allConstructors =
            _valuesSortedByKey(_state.constructors).toList();
        for (String constructor in allConstructors) {
          writeln();
          write(constructor);
        }

        // methods
        List<String> allMethods =
            _valuesSortedByKey(_state.publicMethods).toList();
        allMethods.addAll(_valuesSortedByKey(_state.privateMethods));
        for (String method in allMethods) {
          writeln();
          write(method);
        }
      });
      writeln('}');
    } finally {
      _state = oldState;
    }
  }

  /**
   * Convert the given [TypeDecl] to a Java type.
   */
  String javaType(TypeDecl type) {
    if (type is TypeReference) {
      TypeReference resolvedType = resolveTypeReferenceChain(type);
      String typeName = resolvedType.typeName;
      if (_typeRenames.containsKey(typeName)) {
        return _typeRenames[typeName];
      } else {
        return typeName;
      }
    } else if (type is TypeList) {
      if (isPrimitive(type.itemType)) {
        return '${javaType(type.itemType)}[]';
      } else {
        return 'List<${javaType(type.itemType)}>';
      }
    } else if (type is TypeMap) {
      return 'Map<${javaType(type.keyType)}, ${javaType(type.valueType)}>';
    } else if (type is TypeUnion) {
      return 'Object';
    } else {
      throw new Exception("Can't make type buildable");
    }
  }

  /**
   * Return true iff the passed [TypeDecl] will represent a primitive Java type.
   */
  bool isPrimitive(TypeDecl type) {
    if (type is TypeReference) {
      String typeStr = javaType(type);
      return typeStr == 'int' || typeStr == 'boolean';
    }
    return false;
  }

  /**
   * Return true iff the passed [TypeDecl] will represent an array in Java.
   */
  bool isList(TypeDecl type) {
    return type is TypeList && !isPrimitive(type.itemType);
  }

  /**
   * Return true iff the passed [TypeDecl] will represent an array in Java.
   */
  bool isArray(TypeDecl type) {
    return type is TypeList && isPrimitive(type.itemType);
  }

  /**
   * Return true iff the passed [TypeDecl] will represent a Map in type.
   */
  bool isMap(TypeDecl type) {
    return type is TypeMap;
  }

  /**
   * Return a suitable representation of [name] as the name of a Java variable.
   */
  String javaName(String name) {
    if (_variableRenames.containsKey(name)) {
      return _variableRenames[name];
    }
    return name;
  }

  @override
  TypeReference resolveTypeReferenceChain(TypeReference type) {
    TypeDecl typeDecl = super.resolveTypeReferenceChain(type);
    if (typeDecl is TypeEnum) {
      return new TypeReference('String', null);
    }
    return type;
  }
}

/**
 * Iterate through the values in [map] in the order of increasing keys.
 */
Iterable<String> _valuesSortedByKey(Map<String, String> map) {
  List<String> keys = map.keys.toList();
  keys.sort();
  return keys.map((String key) => map[key]);
}

/**
 * State used by [CodegenJavaVisitor].
 */
class _CodegenJavaState {
  /**
   * Temporary storage for public methods.
   */
  Map<String, String> publicMethods = <String, String>{};

  /**
   * Temporary storage for private methods.
   */
  Map<String, String> privateMethods = <String, String>{};

  /**
   * Temporary storage for private fields.
   */
  Map<String, String> privateFields = <String, String>{};

  /**
   * Temporary storage for constructors.
   */
  Map<String, String> constructors = <String, String>{};
}

/**
 * Create a [GeneratedFile] that creates Java code and outputs it to [path].
 * [path] uses Posix-style path separators regardless of the OS.
 */
GeneratedFile javaGeneratedFile(String path, CodegenJavaVisitor
    createVisitor(Api api)) {
  return new GeneratedFile(path, () {
    CodegenJavaVisitor visitor = createVisitor(readApi());
    return visitor.collectCode(visitor.visitApi);
  });
}
