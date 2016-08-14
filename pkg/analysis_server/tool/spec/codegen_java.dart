// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tools for Java code generation.
 */
library CodegenJava;

import 'package:analyzer/src/codegen/tools.dart';
import 'package:html/dom.dart' as dom;

import 'api.dart';
import 'from_html.dart';
import 'to_html.dart';

/**
 * Create a [GeneratedFile] that creates Java code and outputs it to [path].
 * [path] uses Posix-style path separators regardless of the OS.
 */
GeneratedFile javaGeneratedFile(
    String path, CodegenJavaVisitor createVisitor(Api api)) {
  return new GeneratedFile(path, (String pkgPath) {
    CodegenJavaVisitor visitor = createVisitor(readApi(pkgPath));
    return visitor.collectCode(visitor.visitApi);
  });
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
 * Common code for all Java code generation.
 */
class CodegenJavaVisitor extends HierarchicalApiVisitor with CodeGenerator {
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
    'int': 'int',
    'ExecutionContextId': 'String',
    'FilePath': 'String',
    'DebugContextId': 'String',
    'object': 'Object',
    'Override': 'OverrideMember',
  };

  _CodegenJavaState _state;

  /**
   * Visitor used to produce doc comments.
   */
  final ToHtmlVisitor toHtmlVisitor;

  CodegenJavaVisitor(Api api)
      : toHtmlVisitor = new ToHtmlVisitor(api),
        super(api);

  /**
   * Create a constructor, using [callback] to create its contents.
   */
  void constructor(String name, void callback()) {
    _state.constructors[name] = collectCode(callback);
  }

  /**
   * Return true iff the passed [TypeDecl] will represent an array in Java.
   */
  bool isArray(TypeDecl type) {
    return type is TypeList && isPrimitive(type.itemType);
  }

  /**
   * Return true iff the passed [TypeDecl] is a type declared in the spec_input.
   */
  bool isDeclaredInSpec(TypeDecl type) {
//    TypeReference resolvedType = super.resolveTypeReferenceChain(type);
//    if(resolvedType is TypeObject) {
//      return truye;
//    }
    if (type is TypeReference) {
      return api.types.containsKey(type.typeName) && javaType(type) != 'String';
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
   * Return true iff the passed [TypeDecl] will represent a Map in type.
   */
  bool isMap(TypeDecl type) {
    return type is TypeMap;
  }

  /**
   * Return true iff the passed [TypeDecl] will be represented as Object in Java.
   */
  bool isObject(TypeDecl type) {
    String typeStr = javaType(type);
    return typeStr == 'Object';
  }

  /**
   * Return true iff the passed [TypeDecl] will represent a primitive Java type.
   */
  bool isPrimitive(TypeDecl type) {
    if (type is TypeReference) {
      String typeStr = javaType(type);
      return typeStr == 'boolean' || typeStr == 'int' || typeStr == 'long';
    }
    return false;
  }

  /**
   * Convenience method for subclasses for calling docComment.
   */
  void javadocComment(List<dom.Node> docs) {
    docComment(docs);
  }

  /**
   * Return a Java type for the given [TypeObjectField].
   */
  String javaFieldType(TypeObjectField field) {
    return javaType(field.type, field.optional);
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

  /**
   * Convert the given [TypeDecl] to a Java type.
   */
  String javaType(TypeDecl type, [bool optional = false]) {
    if (type is TypeReference) {
      TypeReference resolvedType = resolveTypeReferenceChain(type);
      String typeName = resolvedType.typeName;
      if (_typeRenames.containsKey(typeName)) {
        typeName = _typeRenames[typeName];
        if (optional) {
          if (typeName == 'boolean') {
            typeName = 'Boolean';
          } else if (typeName == 'int') {
            typeName = 'Integer';
          }
        }
      }
      return typeName;
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
        List<String> allFields = _state.publicFields.values.toList();
        allFields.addAll(_state.privateFields.values.toList());
        for (String field in allFields) {
          writeln();
          write(field);
        }

        // constructors
        List<String> allConstructors = _state.constructors.values.toList();
        for (String constructor in allConstructors) {
          writeln();
          write(constructor);
        }

        // methods (ordered by method name)
        List<String> allMethods =
            _valuesSortedByKey(_state.publicMethods).toList();
        allMethods.addAll(_valuesSortedByKey(_state.privateMethods));
        for (String method in allMethods) {
          writeln();
          write(method);
        }
        writeln();
      });
      writeln('}');
    } finally {
      _state = oldState;
    }
  }

  /**
   * Create a private field, using [callback] to create its contents.
   */
  void privateField(String fieldName, void callback()) {
    _state.privateFields[fieldName] = collectCode(callback);
  }

  /**
   * Create a private method, using [callback] to create its contents.
   */
  void privateMethod(String methodName, void callback()) {
    _state.privateMethods[methodName] = collectCode(callback);
  }

  /**
   * Create a public field, using [callback] to create its contents.
   */
  void publicField(String fieldName, void callback()) {
    _state.publicFields[fieldName] = collectCode(callback);
  }

  /**
   * Create a public method, using [callback] to create its contents.
   */
  void publicMethod(String methodName, void callback()) {
    _state.publicMethods[methodName] = collectCode(callback);
  }

  @override
  TypeDecl resolveTypeReferenceChain(TypeDecl type) {
    TypeDecl typeDecl = super.resolveTypeReferenceChain(type);
    if (typeDecl is TypeEnum) {
      return new TypeReference('String', null);
    }
    return type;
  }
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
   * Temporary storage for public fields.
   */
  Map<String, String> publicFields = <String, String>{};

  /**
   * Temporary storage for private fields.
   */
  Map<String, String> privateFields = <String, String>{};

  /**
   * Temporary storage for constructors.
   */
  Map<String, String> constructors = <String, String>{};
}
