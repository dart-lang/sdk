// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library codegen.protocol;

import 'dart:convert';

import 'api.dart';
import 'codegen_tools.dart';
import 'from_html.dart';
import 'implied_types.dart';
import 'to_html.dart';

/**
 * Container for code that can be used to translate a data type from JSON.
 */
abstract class FromJsonCode {
  /**
   * True if the data type is already in JSON form, so the translation is the
   * identity function.
   */
  bool get isIdentity;

  /**
   * Get the translation code in the form of a closure.
   */
  String get asClosure;

  /**
   * Get the translation code in the form of a code snippet, where [jsonPath]
   * is the variable holding the JSON path, and [json] is the variable holding
   * the raw JSON.
   */
  String asSnippet(String jsonPath, String json);
}

/**
 * Representation of FromJsonCode for a function defined elsewhere.
 */
class FromJsonFunction extends FromJsonCode {
  final String asClosure;

  FromJsonFunction(this.asClosure);

  @override
  bool get isIdentity => false;

  @override
  String asSnippet(String jsonPath, String json) =>
      '$asClosure($jsonPath, $json)';
}

typedef String FromJsonSnippetCallback(String jsonPath, String json);

/**
 * Representation of FromJsonCode for a snippet of inline code.
 */
class FromJsonSnippet extends FromJsonCode {
  /**
   * Callback that can be used to generate the code snippet, once the names
   * of the [jsonPath] and [json] variables are known.
   */
  final FromJsonSnippetCallback callback;

  FromJsonSnippet(this.callback);

  @override
  bool get isIdentity => false;

  @override
  String get asClosure =>
      '(String jsonPath, Object json) => ${callback('jsonPath', 'json')}';

  @override
  String asSnippet(String jsonPath, String json) => callback(jsonPath, json);
}

/**
 * Representation of FromJsonCode for the identity transformation.
 */
class FromJsonIdentity extends FromJsonSnippet {
  FromJsonIdentity() : super((String jsonPath, String json) => json);

  @override
  bool get isIdentity => true;
}

/**
 * Container for code that can be used to translate a data type to JSON.
 */
abstract class ToJsonCode {
  /**
   * True if the data type is already in JSON form, so the translation is the
   * identity function.
   */
  bool get isIdentity;

  /**
   * Get the translation code in the form of a closure.
   */
  String get asClosure;

  /**
   * Get the translation code in the form of a code snippet, where [value]
   * is the variable holding the object to be translated.
   */
  String asSnippet(String value);
}

/**
 * Representation of ToJsonCode for a function defined elsewhere.
 */
class ToJsonFunction extends ToJsonCode {
  final String asClosure;

  ToJsonFunction(this.asClosure);

  @override
  bool get isIdentity => false;

  @override
  String asSnippet(String value) => '$asClosure($value)';
}

typedef String ToJsonSnippetCallback(String value);

/**
 * Representation of ToJsonCode for a snippet of inline code.
 */
class ToJsonSnippet extends ToJsonCode {
  /**
   * Callback that can be used to generate the code snippet, once the name
   * of the [value] variable is known.
   */
  final ToJsonSnippetCallback callback;

  /**
   * Dart type of the [value] variable.
   */
  final String type;

  ToJsonSnippet(this.type, this.callback);

  @override
  bool get isIdentity => false;

  @override
  String get asClosure => '($type value) => ${callback('value')}';

  @override
  String asSnippet(String value) => callback(value);
}

/**
 * Representation of FromJsonCode for the identity transformation.
 */
class ToJsonIdentity extends ToJsonSnippet {
  ToJsonIdentity(String type) : super(type, (String value) => value);

  @override
  bool get isIdentity => true;
}

/**
 * Visitor which produces Dart code representing the API.
 */
class CodegenProtocolVisitor extends HierarchicalApiVisitor with CodeGenerator {
  /**
   * Type references in the spec that are named something else in Dart.
   */
  static const Map<String, String> _typeRenames = const {
    'object': 'Object',
  };

  /**
   * Visitor used to produce doc comments.
   */
  final ToHtmlVisitor toHtmlVisitor;

  /**
   * Types implied by the API.  This includes types explicitly named in the
   * API as well as those implied by the definitions of requests, responses,
   * notifications, etc.
   */
  final Map<String, ImpliedType> impliedTypes;

  CodegenProtocolVisitor(Api api)
      : super(api),
        toHtmlVisitor = new ToHtmlVisitor(api),
        impliedTypes = computeImpliedTypes(api);

  @override
  visitApi() {
    outputHeader();
    writeln();
    writeln('part of protocol2;');
    emitClasses();
  }

  /**
   * Translate each type implied by the API to a class.
   */
  void emitClasses() {
    for (ImpliedType impliedType in impliedTypes.values) {
      TypeDecl type = impliedType.type;
      if (type != null) {
        String dartTypeName = capitalize(impliedType.camelName);
        if (type is TypeObject) {
          writeln();
          emitObjectClass(dartTypeName, type, impliedType);
        } else if (type is TypeEnum) {
          writeln();
          emitEnumClass(dartTypeName, type, impliedType);
        }
      }
    }
  }

  /**
   * Emit the class to encapsulate an object type.
   */
  void emitObjectClass(String className, TypeObject type, ImpliedType
      impliedType) {
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(impliedType.humanReadableName);
      });
      if (impliedType.type != null) {
        toHtmlVisitor.showType(null, impliedType.type);
      }
    }));
    writeln('class $className implements HasToJson {');
    indent(() {
      for (TypeObjectField field in type.fields) {
        if (field.value != null) {
          continue;
        }
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(field.html);
        }));
        writeln('${dartType(field.type)} ${field.name};');
        writeln();
      }
      emitObjectConstructor(type, className);
      writeln();
      emitObjectFromJsonConstructor(className, type, impliedType);
      writeln();
      if (emitConvenienceConstructor(className, impliedType)) {
        writeln();
      }
      emitToJsonMember(type);
      writeln();
      if (emitToRequestMember(impliedType)) {
        writeln();
      }
      writeln('@override');
      writeln('String toString() => JSON.encode(toJson());');
      writeln();
      emitObjectEqualsMember(type, className);
      writeln();
      emitObjectHashCode(type);
    });
    writeln('}');
  }

  /**
   * Emit the constructor for an object class.
   */
  void emitObjectConstructor(TypeObject type, String className) {
    List<String> args = <String>[];
    List<String> optionalArgs = <String>[];
    for (TypeObjectField field in type.fields) {
      if (field.value != null) {
        continue;
      }
      String arg = 'this.${field.name}';
      if (field.optional) {
        optionalArgs.add(arg);
      } else {
        args.add(arg);
      }
    }
    if (optionalArgs.isNotEmpty) {
      args.add('{${optionalArgs.join(', ')}}');
    }
    writeln('$className(${args.join(', ')});');
  }

  /**
   * Emit the toJson() code for an object class.
   */
  void emitToJsonMember(TypeObject type) {
    writeln('Map<String, dynamic> toJson() {');
    indent(() {
      writeln('Map<String, dynamic> result = {};');
      for (TypeObjectField field in type.fields) {
        String fieldNameString = literalString(field.name);
        if (field.value != null) {
          writeln('result[$fieldNameString] = ${literalString(field.value)};');
          continue;
        }
        String fieldToJson = toJsonCode(field.type).asSnippet(field.name);
        String populateField = 'result[$fieldNameString] = $fieldToJson;';
        if (field.optional) {
          writeln('if (${field.name} != null) {');
          indent(() {
            writeln(populateField);
          });
          writeln('}');
        } else {
          writeln(populateField);
        }
      }
      writeln('return result;');
    });
    writeln('}');
  }

  /**
   * Emit the toRequest() code for a class, if appropriate.  Returns true if
   * code was emitted.
   */
  bool emitToRequestMember(ImpliedType impliedType) {
    if (impliedType.kind == 'requestParams') {
      writeln('Request toRequest(String id) {');
      indent(() {
        String methodString = literalString((impliedType.apiNode as
            Request).longMethod);
        writeln('return new Request(id, $methodString, toJson());');
      });
      writeln('}');
      return true;
    }
    return false;
  }

  /**
   * Emit the operator== code for an object class.
   */
  void emitObjectEqualsMember(TypeObject type, String className) {
    writeln('@override');
    writeln('bool operator==(other) {');
    indent(() {
      writeln('if (other is $className) {');
      indent(() {
        var comparisons = <String>[];
        for (TypeObjectField field in type.fields) {
          if (field.value != null) {
            continue;
          }
          comparisons.add(compareEqualsCode(field.type, field.name,
              'other.${field.name}'));
        }
        if (comparisons.isEmpty) {
          writeln('return true;');
        } else {
          String concatenated = comparisons.join(' &&\n    ');
          writeln('return $concatenated;');
        }
      });
      writeln('}');
      writeln('return false;');
    });
    writeln('}');
  }

  /**
   * Emit the hashCode getter for an object class.
   */
  void emitObjectHashCode(TypeObject type) {
    writeln('@override');
    writeln('int get hashCode {');
    indent(() {
      writeln('int hash = 0;');
      for (TypeObjectField field in type.fields) {
        String valueToCombine;
        if (field.value != null) {
          valueToCombine = field.value.hashCode.toString();
        } else {
          valueToCombine = '${field.name}.hashCode';
        }
        writeln('hash = _JenkinsSmiHash.combine(hash, $valueToCombine);');
      }
      writeln('return _JenkinsSmiHash.finish(hash);');
    });
    writeln('}');
  }

  /**
   * Emit a class to encapsulate an enum.
   */
  void emitEnumClass(String className, TypeEnum type, ImpliedType impliedType) {
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(impliedType.humanReadableName);
      });
      if (impliedType.type != null) {
        toHtmlVisitor.showType(null, impliedType.type);
      }
    }));
    writeln('class $className {');
    indent(() {
      for (TypeEnumValue value in type.values) {
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(value.html);
        }));
        String valueString = literalString(value.value);
        writeln(
            'static const ${value.value} = const $className._($valueString);');
        writeln();
      }
      writeln('final String name;');
      writeln();
      writeln('const $className._(this.name);');
      writeln();
      emitEnumClassConstructor(className, type);
      writeln();
      emitEnumFromJsonConstructor(className, type, impliedType);
      writeln();
      writeln('@override');
      writeln('String toString() => "$className.\$name";');
      writeln();
      writeln('String toJson() => name;');
    });
    writeln('}');
  }

  /**
   * Emit the constructor for an enum class.
   */
  void emitEnumClassConstructor(String className, TypeEnum type) {
    writeln('factory $className(String name) {');
    indent(() {
      writeln('switch (name) {');
      indent(() {
        for (TypeEnumValue value in type.values) {
          String valueString = literalString(value.value);
          writeln('case $valueString:');
          indent(() {
            writeln('return ${value.value};');
          });
        }
      });
      writeln('}');
      writeln(r"throw new Exception('Illegal enum value: $name');");
    });
    writeln('}');
  }

  /**
   * Compute the code necessary to convert [type] to JSON.
   */
  ToJsonCode toJsonCode(TypeDecl type) {
    TypeDecl resolvedType = resolveTypeReferenceChain(type);
    if (resolvedType is TypeReference) {
      return new ToJsonIdentity(dartType(type));
    } else if (resolvedType is TypeList) {
      ToJsonCode itemCode = toJsonCode(resolvedType.itemType);
      if (itemCode.isIdentity) {
        return new ToJsonIdentity(dartType(type));
      } else {
        return new ToJsonSnippet(dartType(type), (String value) =>
            '$value.map(${itemCode.asClosure}).toList()');
      }
    } else if (resolvedType is TypeMap) {
      ToJsonCode keyCode;
      if (dartType(resolvedType.keyType) != 'String') {
        keyCode = toJsonCode(resolvedType.keyType);
      } else {
        keyCode = new ToJsonIdentity(dartType(resolvedType.keyType));
      }
      ToJsonCode valueCode = toJsonCode(resolvedType.valueType);
      if (keyCode.isIdentity && valueCode.isIdentity) {
        return new ToJsonIdentity(dartType(resolvedType));
      } else {
        return new ToJsonSnippet(dartType(type), (String value) {
          StringBuffer result = new StringBuffer();
          result.write('mapMap($value');
          if (!keyCode.isIdentity) {
            result.write(', keyCallback: ${keyCode.asClosure}');
          }
          if (!valueCode.isIdentity) {
            result.write(', valueCallback: ${valueCode.asClosure}');
          }
          result.write(')');
          return result.toString();
        });
      }
    } else if (resolvedType is TypeUnion) {
      for (TypeDecl choice in resolvedType.choices) {
        if (resolveTypeReferenceChain(choice) is! TypeObject) {
          throw new Exception('Union types must be unions of objects');
        }
      }
      return new ToJsonSnippet(dartType(type), (String value) =>
          '$value.toJson()');
    } else if (resolvedType is TypeObject || resolvedType is TypeEnum) {
      return new ToJsonSnippet(dartType(type), (String value) =>
          '$value.toJson()');
    } else {
      throw new Exception("Can't convert $resolvedType from JSON");
    }
  }

  /**
   * Compute the code necessary to compare two objects for equality.
   */
  String compareEqualsCode(TypeDecl type, String thisVar, String otherVar) {
    TypeDecl resolvedType = resolveTypeReferenceChain(type);
    if (resolvedType is TypeReference || resolvedType is TypeEnum ||
        resolvedType is TypeObject || resolvedType is TypeUnion) {
      return '$thisVar == $otherVar';
    } else if (resolvedType is TypeList) {
      String itemTypeName = dartType(resolvedType.itemType);
      String subComparison = compareEqualsCode(resolvedType.itemType, 'a', 'b');
      String closure = '($itemTypeName a, $itemTypeName b) => $subComparison';
      return '_listEqual($thisVar, $otherVar, $closure)';
    } else if (resolvedType is TypeMap) {
      String valueTypeName = dartType(resolvedType.valueType);
      String subComparison = compareEqualsCode(resolvedType.valueType, 'a', 'b'
          );
      String closure = '($valueTypeName a, $valueTypeName b) => $subComparison';
      return '_mapEqual($thisVar, $otherVar, $closure)';
    }
    throw new Exception("Don't know how to compare for equality: $resolvedType"
        );
  }

  /**
   * Emit the method for decoding an object from JSON.
   */
  void emitObjectFromJsonConstructor(String className, TypeObject
      type, ImpliedType impliedType) {
    String humanReadableNameString = literalString(impliedType.humanReadableName
        );
    writeln(
        'factory $className.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {'
        );
    indent(() {
      writeln('if (json == null) {');
      indent(() {
        writeln('json = {};');
      });
      writeln('}');
      writeln('if (json is Map) {');
      indent(() {
        List<String> args = <String>[];
        List<String> optionalArgs = <String>[];
        for (TypeObjectField field in type.fields) {
          String fieldNameString = literalString(field.name);
          String fieldAccessor = 'json[$fieldNameString]';
          String jsonPath = 'jsonPath + ${literalString('.${field.name}')}';
          if (field.value != null) {
            String valueString = literalString(field.value);
            writeln('if ($fieldAccessor != $valueString) {');
            indent(() {
              writeln(
                  'throw jsonDecoder.mismatch(jsonPath, "equal " + $valueString);');
            });
            writeln('}');
            continue;
          }
          if (field.optional) {
            optionalArgs.add('${field.name}: ${field.name}');
          } else {
            args.add(field.name);
          }
          String fieldDartType = dartType(field.type);
          writeln('$fieldDartType ${field.name};');
          writeln('if (json.containsKey($fieldNameString)) {');
          indent(() {
            String toJson = fromJsonCode(field.type).asSnippet(jsonPath,
                fieldAccessor);
            writeln('${field.name} = $toJson;');
          });
          write('}');
          if (!field.optional) {
            writeln(' else {');
            indent(() {
              writeln(
                  "throw jsonDecoder.missingKey(jsonPath, $fieldNameString);");
            });
            writeln('}');
          } else {
            writeln();
          }
        }
        args.addAll(optionalArgs);
        writeln('return new $className(${args.join(', ')});');
      });
      writeln('} else {');
      indent(() {
        writeln(
            'throw jsonDecoder.mismatch(jsonPath, $humanReadableNameString);');
      });
      writeln('}');
    });
    writeln('}');
  }

  /**
   * Emit the method for decoding an enum from JSON.
   */
  void emitEnumFromJsonConstructor(String className, TypeEnum type, ImpliedType
      impliedType) {
    writeln(
        'factory $className.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {'
        );
    indent(() {
      writeln('if (json is String) {');
      indent(() {
        writeln('try {');
        indent(() {
          writeln('return new $className(json);');
        });
        writeln('} catch(_) {');
        indent(() {
          writeln('// Fall through');
        });
        writeln('}');
      });
      writeln('}');
      String humanReadableNameString = literalString(
          impliedType.humanReadableName);
      writeln('throw jsonDecoder.mismatch(jsonPath, $humanReadableNameString);'
          );
    });
    writeln('}');
  }

  /**
   * Compute the code necessary to translate [type] from JSON.
   */
  FromJsonCode fromJsonCode(TypeDecl type) {
    if (type is TypeReference) {
      TypeDefinition referencedDefinition = api.types[type.typeName];
      if (referencedDefinition != null) {
        TypeDecl referencedType = referencedDefinition.type;
        if (referencedType is TypeObject || referencedType is TypeEnum) {
          return new FromJsonSnippet((String jsonPath, String json) =>
              'new ${dartType(type)}.fromJson(jsonDecoder, $jsonPath, $json)');
        } else {
          return fromJsonCode(referencedType);
        }
      } else {
        switch (type.typeName) {
          case 'String':
            return new FromJsonFunction('jsonDecoder._decodeString');
          case 'bool':
            return new FromJsonFunction('jsonDecoder._decodeBool');
          case 'int':
            return new FromJsonFunction('jsonDecoder._decodeInt');
          case 'object':
            return new FromJsonIdentity();
          default:
            throw new Exception('Unexpected type name ${type.typeName}');
        }
      }
    } else if (type is TypeMap) {
      FromJsonCode keyCode;
      if (dartType(type.keyType) != 'String') {
        keyCode = fromJsonCode(type.keyType);
      } else {
        keyCode = new FromJsonIdentity();
      }
      FromJsonCode valueCode = fromJsonCode(type.valueType);
      if (keyCode.isIdentity && valueCode.isIdentity) {
        return new FromJsonFunction('jsonDecoder._decodeMap');
      } else {
        return new FromJsonSnippet((String jsonPath, String json) {
          StringBuffer result = new StringBuffer();
          result.write('jsonDecoder._decodeMap($jsonPath, $json');
          if (!keyCode.isIdentity) {
            result.write(', keyDecoder: ${keyCode.asClosure}');
          }
          if (!valueCode.isIdentity) {
            result.write(', valueDecoder: ${valueCode.asClosure}');
          }
          result.write(')');
          return result.toString();
        });
      }
    } else if (type is TypeList) {
      FromJsonCode itemCode = fromJsonCode(type.itemType);
      if (itemCode.isIdentity) {
        return new FromJsonFunction('jsonDecoder._decodeList');
      } else {
        return new FromJsonSnippet((String jsonPath, String json) =>
            'jsonDecoder._decodeList($jsonPath, $json, ${itemCode.asClosure})');
      }
    } else if (type is TypeUnion) {
      List<String> decoders = <String>[];
      for (TypeDecl choice in type.choices) {
        TypeDecl resolvedChoice = resolveTypeReferenceChain(choice);
        if (resolvedChoice is TypeObject) {
          TypeObjectField field = resolvedChoice.getField(type.field);
          if (field == null) {
            throw new Exception(
                'Each choice in the union needs a field named ${type.field}');
          }
          if (field.value == null) {
            throw new Exception(
                'Each choice in the union needs a constant value for the field ${type.field}');
          }
          String closure = fromJsonCode(choice).asClosure;
          decoders.add('${literalString(field.value)}: $closure');
        } else {
          throw new Exception('Union types must be unions of objects.');
        }
      }
      return new FromJsonSnippet((String jsonPath, String json) =>
          'jsonDecoder._decodeUnion($jsonPath, $json, ${literalString(type.field)}, {${decoders.join(', ')}})'
          );
    } else {
      throw new Exception("Can't convert $type from JSON");
    }
  }

  /**
   * Emit a convenience constructor for decoding a piece of protocol, if
   * appropriate.  Return true if a constructor was emitted.
   */
  bool emitConvenienceConstructor(String className, ImpliedType impliedType) {
    // The type of object from which this piece of protocol should be decoded.
    String inputType;
    // The name of the input object.
    String inputName;
    // The field within the input object to decode.
    String fieldName;
    // Constructor call to create the JsonDecoder object.
    String makeDecoder;
    // Name of the constructor to create.
    String constructorName;
    // Extra arguments for the constructor.
    List<String> extraArgs = <String>[];
    switch (impliedType.kind) {
      case 'requestParams':
        inputType = 'Request';
        inputName = 'request';
        fieldName = 'params';
        makeDecoder = 'new RequestDecoder(request)';
        constructorName = 'fromRequest';
        break;
      case 'requestResult':
        inputType = 'Response';
        inputName = 'response';
        fieldName = 'result';
        makeDecoder = 'new ResponseDecoder()';
        constructorName = 'fromResponse';
        break;
      case 'notificationParams':
        inputType = 'Notification';
        inputName = 'notification';
        fieldName = 'params';
        makeDecoder = 'new ResponseDecoder()';
        constructorName = 'fromNotification';
        break;
      case 'refactoringFeedback':
        inputType = 'EditGetRefactoringResult';
        inputName = 'refactoringResult';
        fieldName = 'feedback';
        makeDecoder = 'new ResponseDecoder()';
        constructorName = 'fromRefactoringResult';
        break;
      case 'refactoringOptions':
        inputType = 'EditGetRefactoringParams';
        inputName = 'refactoringParams';
        fieldName = 'options';
        makeDecoder = 'new RequestDecoder(request)';
        constructorName = 'fromRefactoringParams';
        extraArgs.add('Request request');
        break;
      default:
        return false;
    }
    List<String> args = ['$inputType $inputName'];
    args.addAll(extraArgs);
    writeln('factory $className.$constructorName(${args.join(', ')}) {');
    indent(() {
      String fieldNameString = literalString(fieldName);
      writeln('return new $className.fromJson(');
      writeln('    $makeDecoder, $fieldNameString, $inputName.$fieldName);');
    });
    writeln('}');
    return true;
  }

  /**
   * Create a string literal that evaluates to [s].
   */
  String literalString(String s) {
    return JSON.encode(s);
  }

  /**
   * Convert the given [TypeDecl] to a Dart type.
   */
  String dartType(TypeDecl type) {
    if (type is TypeReference) {
      String typeName = type.typeName;
      TypeDefinition referencedDefinition = api.types[typeName];
      if (_typeRenames.containsKey(typeName)) {
        return _typeRenames[typeName];
      }
      if (referencedDefinition == null) {
        return typeName;
      }
      TypeDecl referencedType = referencedDefinition.type;
      if (referencedType is TypeObject || referencedType is TypeEnum) {
        return typeName;
      }
      return dartType(referencedType);
    } else if (type is TypeList) {
      return 'List<${dartType(type.itemType)}>';
    } else if (type is TypeMap) {
      return 'Map<${dartType(type.keyType)}, ${dartType(type.valueType)}>';
    } else if (type is TypeUnion) {
      return 'dynamic';
    } else {
      throw new Exception("Can't convert to a dart type");
    }
  }
}

final GeneratedFile target = new GeneratedFile(
    '../../lib/src/generated_protocol.dart', () {
  CodegenProtocolVisitor visitor = new CodegenProtocolVisitor(readApi());
  return visitor.collectCode(visitor.visitApi);
});

/**
 * Translate spec_input.html into protocol_matchers.dart.
 */
main() {
  target.generate();
}
