// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library codegen.python.protocol;

import 'dart:convert';

import 'package:analyzer/src/codegen/tools.dart';
import 'package:html/dom.dart' as dom;

import 'api.dart';
import 'codegen_python.dart';
import 'from_html.dart';
import 'implied_types.dart';
import 'to_html.dart';

/**
 * Special flags that need to be inserted into the declaration of the Element
 * class.
 */
const Map<String, String> specialElementFlags = const {
  'abstract': '0x01',
  'const': '0x02',
  'final': '0x04',
  'static': '0x08',
  'private': '0x10',
  'deprecated': '0x20'
};

final GeneratedFile target = new GeneratedFile(
    'tool/spec/generated_python/api.py', (String pkgPath) {
  CodegenProtocolVisitor visitor = new CodegenProtocolVisitor(readApi(pkgPath));
  return visitor.collectCode(visitor.visitApi);
});

/**
 * Callback type used to represent arbitrary code generation.
 */
typedef void CodegenCallback();

typedef String FromJsonSnippetCallback(String json);

typedef String ToJsonSnippetCallback(String value);

/**
 * Visitor which produces Python code representing the API.
 */
class CodegenProtocolVisitor extends PythonCodegenVisitor with CodeGenerator {
  /**
   * Class members for which the constructor argument should be optional, even
   * if the member is not an optional part of the protocol.  For list types,
   * the constructor will default the member to the empty list.
   */
  static const Map<String, List<String>> _optionalConstructorArguments = const {
    'AnalysisErrorFixes': const ['fixes'],
    'SourceChange': const ['edits', 'linkedEditGroups'],
    'SourceFileEdit': const ['edits'],
    'TypeHierarchyItem': const ['interfaces', 'mixins', 'subclasses'],
  };

  /**
   * The disclaimer added to the documentation comment for each of the classes
   * that are generated.
   */
  static const String disclaimer =
      'Clients may not extend, implement or mix-in this class.';

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
        impliedTypes = computeImpliedTypes(api) {
    codeGeneratorSettings.commentLineLength = 79;
    codeGeneratorSettings.languageName = 'python';
    // TODO: Don't write start/end markers.
    codeGeneratorSettings.docCommentStartMarker = null;
    codeGeneratorSettings.docCommentEndMarker = null;
    codeGeneratorSettings.docCommentLineLeader = '# ';
    codeGeneratorSettings.indent = '    ';
  }

  // TODO for Python
  /**
   * Compute the code necessary to compare two objects for equality.
   */
//  String compareEqualsCode(TypeDecl type, String thisVar, String otherVar) {
//    TypeDecl resolvedType = resolveTypeReferenceChain(type);
//    if (resolvedType is TypeReference ||
//        resolvedType is TypeEnum ||
//        resolvedType is TypeObject ||
//        resolvedType is TypeUnion) {
//      return '$thisVar == $otherVar';
//    } else if (resolvedType is TypeList) {
//      String itemTypeName = pythonType(resolvedType.itemType);
//      String subComparison = compareEqualsCode(resolvedType.itemType, 'a', 'b');
//      String closure = '($itemTypeName a, $itemTypeName b) => $subComparison';
//      return 'listEqual($thisVar, $otherVar, $closure)';
//    } else if (resolvedType is TypeMap) {
//      String valueTypeName = pythonType(resolvedType.valueType);
//      String subComparison =
//          compareEqualsCode(resolvedType.valueType, 'a', 'b');
//      String closure = '($valueTypeName a, $valueTypeName b) => $subComparison';
//      return 'mapEqual($thisVar, $otherVar, $closure)';
//    }
//    throw new Exception(
//        "Don't know how to compare for equality: $resolvedType");
//  }

  /**
   * Translate each type implied by the API to a class.
   */
  void emitClasses() {
    for (ImpliedType impliedType in impliedTypes.values) {
      TypeDecl type = impliedType.type;
      String pythonTypeName = capitalize(impliedType.camelName);
      if (type == null) {
        emitEmptyObjectClass(pythonTypeName, impliedType);
      } else if (type is TypeObject) {
        writeln();
        emitObjectClass(pythonTypeName, type, impliedType);
      } else if (type is TypeEnum) {
        writeln();
        emitEnumClass(pythonTypeName, type, impliedType);
      }
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
    // Name of the constructor to create.
    String constructorName;
    // Extra arguments for the constructor.
    List<String> extraArgs = <String>[];
    switch (impliedType.kind) {
      case 'requestParams':
        inputType = 'Request';
        inputName = 'request';
        fieldName = '_params';
        constructorName = 'from_request';
        break;
      case 'requestResult':
        inputType = 'Response';
        inputName = 'response';
        fieldName = '_result';
        constructorName = 'from_response';
        break;
      case 'notificationParams':
        inputType = 'Notification';
        inputName = 'notification';
        fieldName = '_params';
        constructorName = 'from_notification';
        break;
      case 'refactoringOptions':
        inputType = 'EditGetRefactoringParams';
        inputName = 'refactoringParams';
        fieldName = 'options';
        constructorName = 'fromRefactoringParams';
        extraArgs.add('request');
        break;
      default:
        return false;
    }
    List<String> args = ['$inputName'];
    args.addAll(extraArgs);
    writeln('@staticmethod');
    writeln('def $constructorName(${args.join(', ')}):');
    indent(() {
      String fieldNameString =
          literalString(fieldName.replaceFirst(new RegExp('^_'), ''));
      if (className == 'EditGetRefactoringParams') {
        writeln('params = $className.from_json(');
        writeln('    $fieldNameString, $inputName.$fieldName)');
        writeln('REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind');
        writeln('return params');
      } else {
        write('return $className.from_json(');
        writeln('$inputName.$fieldName)');
      }
    });
    return true;
  }

  /**
   * Emit a class representing a data structure that doesn't exist in the
   * protocol because it is empty (e.g. the "params" object for a request that
   * doesn't have any parameters).
   */
  void emitEmptyObjectClass(String className, ImpliedType impliedType) {
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(impliedType.humanReadableName);
      });
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(disclaimer);
      });
    }));
    writeln('class $className(object):');
    indent(() {
      if (emitToRequestMember(impliedType)) {
        writeln();
      }
      if (emitToResponseMember(impliedType)) {
        writeln();
      }
      if (emitToNotificationMember(impliedType)) {
        writeln();
      }
      emitObjectEqualsMember(null, className);
      writeln();
      emitObjectHashCode(null, className);
    });
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
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(disclaimer);
      });
    }));
    writeln('class $className:');
    indent(() {
      if (emitSpecialStaticMembers(className)) {
        writeln();
      }
      for (TypeEnumValue value in type.values) {
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(value.html);
        }));
        String valueString = literalString(value.value);
        writeln(
            "${value.value} = ${valueString.toUpperCase()}");
      }
    });
  }

  /**
   * Emit the class to encapsulate an object type.
   */
  void emitObjectClass(
      String className, TypeObject type, ImpliedType impliedType) {
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(impliedType.humanReadableName);
      });
      if (impliedType.type != null) {
        toHtmlVisitor.showType(null, impliedType.type);
      }
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(disclaimer);
      });
    }));
    write('class $className(');
    if (impliedType.kind == 'refactoringFeedback') {
      write('RefactoringFeedback, ');
    }
    if (impliedType.kind == 'refactoringOptions') {
      write('RefactoringOptions, ');
    }
    // TODO: For Python, we probably don't need this?
    writeln('HasToJson):');
    writeln();
    indent(() {
      if (emitSpecialStaticMembers(className)) {
        writeln();
      }
      write('def __init__(');
      var initArgs = <String>[];
      var optionalArgs = <String>[];
      initArgs.add('self');
      for (TypeObjectField field in type.fields) {
        if (field.value != null) {
          continue;
        }
        if (isOptionalConstructorArg(className, field)) {
          optionalArgs.add('${field.name}=None');
        } else {        
          // TODO: use appropriate zero value.
          initArgs.add(field.name);
        }
      }
      initArgs.addAll(optionalArgs);
      writeln('${initArgs.join(', ')}):');
      indent(() {
        for (TypeObjectField field in type.fields) {
          if (field.value != null) {
            continue;
          }
          // TODO: use appropriate zero value.
          writeln('self._${field.name} = ${field.name}');
        }
        if (initArgs.length == 1) {
          writeln('pass');
          writeln();
        }
      });
      for (TypeObjectField field in type.fields) {
        if (field.value != null) {
          continue;
        }
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(field.html);
        }));
        writeln('@property');
        writeln('def ${field.name}(self):');
        indent(() {
          writeln('return self._${field.name}');
        });
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(field.html);
        }));
        writeln('@${field.name}.setter');
        writeln('def ${field.name}(self, value):');
        indent(() {
          if (!field.optional) {
            writeln('assert value is not None');
          }
          writeln('self._${field.name} = value');
        });
        writeln();
      }
      emitObjectFromJsonConstructor(className, type, impliedType);
      writeln();
      if (emitConvenienceConstructor(className, impliedType)) {
        writeln();
      }
      if (emitSpecialConstructors(className)) {
        writeln();
      }
      if (emitSpecialGetters(className)) {
        writeln();
      }
      emitToJsonMember(type);
      writeln();
      if (emitToRequestMember(impliedType)) {
        writeln();
      }
      if (emitToResponseMember(impliedType)) {
        writeln();
      }
      if (emitToNotificationMember(impliedType)) {
        writeln();
      }
      if (emitSpecialMethods(className)) {
        writeln();
      }
      writeln('def __str__(self):');
      indent(() {
        writeln('return json.dumps(self.to_json())');
      });
      writeln();
      emitObjectEqualsMember(type, className);
      writeln();
      emitObjectHashCode(type, className);
    });
  }

  /**
   * Emit the operator== code for an object class.
   */
  void emitObjectEqualsMember(TypeObject type, String className) {
    writeln('def __eq__(self, other):');
    indent(() {
      // TODO: implement this
      writeln('# TODO: implement this');
      writeln('pass');
//      writeln('if other is $className:');
//      indent(() {
//        var comparisons = <String>[];
//        if (type != null) {
//          for (TypeObjectField field in type.fields) {
//            if (field.value != null) {
//              continue;
//            }
//            comparisons.add(compareEqualsCode(
//                field.type, field.name, 'other.${field.name}'));
//          }
//        }
//        if (comparisons.isEmpty) {
//          writeln('return True');
//        } else {
//          String concatenated = comparisons.join(' and\n    ');
//          writeln('return $concatenated');
//        }
//      });
//      writeln('return False');
    });
  }

  /**
   * Emit the method for decoding an object from JSON.
   */
  void emitObjectFromJsonConstructor(
      String className, TypeObject type, ImpliedType impliedType) {
    // TODO: For Python.
    // String humanReadableNameString =
    //    literalString(impliedType.humanReadableName);
    // if (className == 'RefactoringFeedback') {
    //   writeln('factory RefactoringFeedback.fromJson(JsonDecoder jsonDecoder, '
    //       'String jsonPath, Object json, Map responseJson) {');
    //   indent(() {
    //     writeln('return refactoringFeedbackFromJson(jsonDecoder, jsonPath, '
    //         'json, responseJson);');
    //   });
    //   writeln('}');
    //   return;
    // }
    // if (className == 'RefactoringOptions') {
    //   writeln('factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, '
    //       'String jsonPath, Object json, RefactoringKind kind) {');
    //   indent(() {
    //     writeln('return refactoringOptionsFromJson(jsonDecoder, jsonPath, '
    //         'json, kind);');
    //   });
    //   writeln('}');
    //   return;
    // }
    writeln('@classmethod');
    writeln('def from_json(cls, json_data):');
    indent(() {
      writeln('if json_data is None:');
      indent(() {
        writeln('json_data = {}');
      });
      writeln('if isinstance(json_data, dict):');
      indent(() {
        List<String> args = <String>[];
        List<String> optionalArgs = <String>[];
        for (TypeObjectField field in type.fields) {
          String fieldNameString = literalString(field.name);
          String fieldAccessor = 'json_data[$fieldNameString]';
          if (field.value != null) {
            String valueString = literalString(field.value);
            writeln('if $fieldAccessor != $valueString:');
            indent(() {
              writeln(
                  'raise ValueError("equal " + $valueString + " " + str(json_data))');
            });
            continue;
          }
          if (isOptionalConstructorArg(className, field)) {
            optionalArgs.add('${field.name}=${field.name}');
          } else {
            args.add(field.name);
          }
          writeln('${field.name} = None');
          writeln('if $fieldNameString in json_data:');
          indent(() {
            var jsonCode = fromJsonCode(field.type);
            writeln('${field.name} = ${jsonCode.asSnippet('json_data[$fieldNameString]')}');
          });
          if (!field.optional) {
            writeln('else:');
            indent(() {
              writeln("raise Exception('missing key: $fieldNameString')");
            });
          } else {
            writeln();
          }
        }
        args.addAll(optionalArgs);
        writeln('return $className(${args.join(', ')})');
      });
      writeln('else:');
      indent(() {
        writeln('raise ValueError("wrong type: %s" % json_data)');
      });
    });
  }

  /**
   * Emit the hashCode getter for an object class.
   */
  void emitObjectHashCode(TypeObject type, String className) {
    writeln('def __hash__(self):');
    indent(() {
      // TODO: implement this
      writeln('# TODO: implement this');
      writeln('pass');
//      if (type == null) {
//        writeln('return ${className.hashCode}');
//      } else {
//        writeln('hash = 0');
//        for (TypeObjectField field in type.fields) {
//          String valueToCombine;
//          if (field.value != null) {
//            valueToCombine = field.value.hashCode.toString();
//          } else {
//            valueToCombine = '${field.name}.hashCode';
//          }
//          writeln('hash = JenkinsSmiHash.combine(hash, $valueToCombine)');
//        }
//        writeln('return JenkinsSmiHash.finish(hash)');
//      }
    });
  }

  /**
   * If the class named [className] requires special constructors, emit them
   * and return true.
   */
  bool emitSpecialConstructors(String className) {
    switch (className) {
      case 'LinkedEditGroup':
        docComment([new dom.Text('Construct an empty LinkedEditGroup.')]);
        writeln('''@staticmethod
def empty():
    return $className([], 0, [])''');
        return true;
      case 'RefactoringProblemSeverity':
        docComment([
          new dom.Text(
              'Returns the [RefactoringProblemSeverity] with the maximal severity.')
        ]);
        // TODO: Implement this.
        writeln('''@staticmethod
def max(a, b):
    raise NotImplementedError() 
''');
        //    'static RefactoringProblemSeverity max(RefactoringProblemSeverity a, RefactoringProblemSeverity b) =>');
        // writeln('    maxRefactoringProblemSeverity(a, b);');
        return true;
      default:
        return false;
    }
  }

  /**
   * If the class named [className] requires special getters, emit them and
   * return true.
   */
  bool emitSpecialGetters(String className) {
    switch (className) {
      case 'Element':
        for (String name in specialElementFlags.keys) {
          String flag = 'FLAG_${name.toUpperCase()}';
          writeln('''@property
def ${camelJoin(['is', name])}(self):
    return (this.flags & $className.$flag) != 0''');
          writeln();
        }
        return true;
      case 'SourceEdit':
        docComment([new dom.Text('The end of the region to be modified.')]);
        writeln('@property');
        writeln('def end(self):');
        writeln('    return self.offset + self.length');
        return true;
      default:
        return false;
    }
  }

  /**
   * If the class named [className] requires special methods, emit them and
   * return true.
   */
  bool emitSpecialMethods(String className) {
    switch (className) {
      case 'LinkedEditGroup':
        docComment([new dom.Text('Add a new position and change the length.')]);
        writeln('def add_position(self, position, length):');
        indent(() {
          writeln('self.positions.append(position)');
          writeln('self.length = length;');
        });
        writeln();
        docComment([new dom.Text('Add a new suggestion.')]);
        writeln('def add_suggestion(self, suggestion):');
        indent(() {
          writeln('self.suggestions.append(suggestion);');
        });
        return true;
      case 'SourceChange':
        docComment([
          new dom.Text('Adds [edit] to the [FileEdit] for the given [file].')
        ]);
        writeln('def add_edit(self, file, fileStamp, edit):');
        indent(() {
            // TODO: where does this come from?
            writeln('add_edit_to_source_change(self, file, fileStamp, edit)');
            writeln();
        });
        docComment([new dom.Text('Adds the given [FileEdit].')]);
        writeln('def add_file_edit(edit):');
        indent(() {
          writeln('self.edits.append(edit);');
        });
        writeln();
        docComment([new dom.Text('Adds the given [LinkedEditGroup].')]);
        writeln('def add_linked_edit_group(linkedEditGroup):');
        indent(() {
          writeln('self.linkedEditGroups.append(linkedEditGroup)');
        });
        writeln();
        docComment([
          new dom.Text(
              'Returns the [FileEdit] for the given [file], maybe `null`.')
        ]);
        writeln('def get_file_edit(self, file):');
        writeln('    return get_change_file_edit(self, file)');
        return true;
      case 'SourceEdit':
        docComment([
          new dom.Text(
              'Get the result of applying the edit to the given [code].')
        ]);

        // TODO: What's this for?
        writeln('def apply(self, code):');
        writeln('    return self.apply_edit(code, self)');
        return true;
      case 'SourceFileEdit':
        docComment([new dom.Text('Adds the given [Edit] to the list.')]);
        writeln('def add(self, edit):');
        writeln('    self.add_edit_for_source(self, edit)');
        writeln();
        docComment([new dom.Text('Adds the given [Edit]s.')]);
        writeln('def add_all(self, edits):');
        writeln('    self.add_all_edits_for_source(self, edits);');
        return true;
      default:
        return false;
    }
  }

  /**
   * If the class named [className] requires special static members, emit them
   * and return true.
   */
  bool emitSpecialStaticMembers(String className) {
    switch (className) {
      case 'Element':
        List<String> makeFlagsArgs = <String>[];
        List<String> makeFlagsStatements = <String>[];
        specialElementFlags.forEach((String name, String value) {
          String flag = 'FLAG_${name.toUpperCase()}';
          String camelName = camelJoin(['is', name]);
          writeln('$flag = $value');
          makeFlagsArgs.add('$camelName=False');
          makeFlagsStatements.add('if ($camelName): flags |= $className.$flag');
        });
        writeln();
        writeln('def make_flags(${makeFlagsArgs.join(', ')}):');
        indent(() {
          writeln('flags = 0');
          for (String statement in makeFlagsStatements) {
            writeln(statement);
          }
          writeln('return flags');
        });
        return true;
      case 'SourceEdit':
        docComment([
          new dom.Text('Get the result of applying a set of ' +
              '[edits] to the given [code].  Edits are applied in the order ' +
              'they appear in [edits].')
        ]);
        writeln('@staticmethod');
        writeln(
            'def apply_sequence(code, edits):');
        writeln('    return self.apply_Sequence_of_edits(code, edits)');
        return true;
      default:
        return false;
    }
  }

  /**
   * Emit the toJson() code for an object class.
   */
  void emitToJsonMember(TypeObject type) {
    writeln('def to_json(self):');
    indent(() {
      writeln('result = {}');
      for (TypeObjectField field in type.fields) {
        String fieldNameString = literalString(field.name);
        if (field.value != null) {
          writeln('result[$fieldNameString] = ${literalString(field.value)}');
          continue;
        }
        String fieldToJson = toJsonCode(field.type).asSnippet(field.name);
        String populateField = 'result[$fieldNameString] = $fieldToJson';
        if (field.optional) {
          writeln('if self.${field.name} is not None:');
          indent(() {
            writeln(populateField);
          });
        } else {
          writeln(populateField);
        }
      }
      writeln('return result');
    });
  }

  /**
   * Emit the toNotification() code for a class, if appropriate.  Returns true
   * if code was emitted.
   */
  bool emitToNotificationMember(ImpliedType impliedType) {
    if (impliedType.kind == 'notificationParams') {
      writeln('def to_notification(self):');
      indent(() {
        String eventString =
            literalString((impliedType.apiNode as Notification).longEvent);
        String jsonPart = impliedType.type != null ? 'self.to_json()' : 'None';
        writeln('return Notification($eventString, $jsonPart);');
      });
      return true;
    }
    return false;
  }

  /**
   * Emit the toRequest() code for a class, if appropriate.  Returns true if
   * code was emitted.
   */
  bool emitToRequestMember(ImpliedType impliedType) {
    if (impliedType.kind == 'requestParams') {
      writeln('def to_request(self, id):');
      indent(() {
        String methodString =
            literalString((impliedType.apiNode as Request).longMethod);
        String jsonPart = impliedType.type != null ? 'self.to_json()' : 'None';
        writeln('return Request(id, $methodString, $jsonPart)');
      });
      return true;
    }
    return false;
  }

  /**
   * Emit the toResponse() code for a class, if appropriate.  Returns true if
   * code was emitted.
   */
  bool emitToResponseMember(ImpliedType impliedType) {
    if (impliedType.kind == 'requestResult') {
      writeln('def to_response(self, id):');
      indent(() {
        String jsonPart = impliedType.type != null ? 'self.to_json()' : 'None';
        writeln('return Response(id, result=$jsonPart)');
      });
      return true;
    }
    return false;
  }

  /**
   * Compute the code necessary to translate [type] from JSON.
   */
  FromJsonCode fromJsonCode(TypeDecl type) {
    if (type is TypeReference) {
      TypeDefinition referencedDefinition = api.types[type.typeName];
      if (referencedDefinition != null) {
        TypeDecl referencedType = referencedDefinition.type;
        if (referencedType is TypeObject) {
          return new FromJsonSnippet((String json) {
            String typeName = pythonType(type);
            if (typeName == 'RefactoringFeedback') {
              return '$typeName.from_json($json, json)';
            } else if (typeName == 'RefactoringOptions') {
              return '$typeName.from_json($json, kind)';
            } else {
              return '$typeName.from_json($json)';
            }
          });
        } else if (referencedType is TypeEnum) {
          return new FromJsonIdentity();
        } else {
          return fromJsonCode(referencedType);
        }
      } else {
        switch (type.typeName) {
          case 'String':
          case 'bool':
          case 'int':
          case 'long':
            return new FromJsonFunction('');
          case 'object':
            return new FromJsonIdentity();
          default:
            throw new Exception('Unexpected type name ${type.typeName}');
        }
      }
    } else if (type is TypeMap) {
      FromJsonCode keyCode;
      if (pythonType(type.keyType) != 'str') {
        keyCode = fromJsonCode(type.keyType);
      } else {
        keyCode = new FromJsonIdentity();
      }
      FromJsonCode valueCode = fromJsonCode(type.valueType);
      if (keyCode.isIdentity && valueCode.isIdentity) {
        return new FromJsonFunction('jsonDecoder.decodeMap');
      } else {
        return new FromJsonSnippet((String json) {
          StringBuffer result = new StringBuffer();
          result.write('{ ');
          if (!keyCode.isIdentity) {
            result.write('${keyCode.asClosure}: ');
          } else {
            result.write('k: ');
          }
          if (!valueCode.isIdentity) {
            result.write('${valueCode.asSnippet('v')}');
          } else {
            result.write('v ');
          }
          result.write(' for k, v in $json.items() }');
          return result.toString();
        });
      }
    } else if (type is TypeList) {
      FromJsonCode itemCode = fromJsonCode(type.itemType);
      if (itemCode.isIdentity) {
        return new FromJsonIdentity();
      } else {
        return new FromJsonSnippet((String json) =>
            '[${itemCode.asSnippet('item')} for item in $json]');
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
          decoders.add('${literalString(field.value)}: lambda json: $closure');
        } else {
          throw new Exception('Union types must be unions of objects.');
        }
      }
      return new FromJsonSnippet((String json) =>
          'decode_union($json, ${literalString(type.field)}, {${decoders.join(', ')}}) ');
    } else {
      throw new Exception("Can't convert $type from JSON");
    }
  }

  /**
   * True if the constructor argument for the given field should be optional.
   */
  bool isOptionalConstructorArg(String className, TypeObjectField field) {
    if (field.optional) {
      return true;
    }
    List<String> forceOptional = _optionalConstructorArguments[className];
    if (forceOptional != null && forceOptional.contains(field.name)) {
      return true;
    }
    return false;
  }

  /**
   * Create a string literal that evaluates to [s].
   */
  String literalString(String s) {
    return JSON.encode(s);
  }

  /**
   * Compute the code necessary to convert [type] to JSON.
   */
  ToJsonCode toJsonCode(TypeDecl type) {
    TypeDecl resolvedType = resolveTypeReferenceChain(type);
    if (resolvedType is TypeReference) {
      return new ToJsonIdentity(pythonType(type));
    } else if (resolvedType is TypeList) {
      ToJsonCode itemCode = toJsonCode(resolvedType.itemType);
      if (itemCode.isIdentity || impliedTypes[resolvedType.itemType.typeName].type is TypeEnum) {
        return new ToJsonIdentity(pythonType(type));
      } else {
        return new ToJsonSnippet(pythonType(type),
            (String value) => '[x.to_json() for x in self.$value]');
      }
    } else if (resolvedType is TypeMap) {
      ToJsonCode keyCode;
      if (pythonType(resolvedType.keyType) != 'str') {
        keyCode = toJsonCode(resolvedType.keyType);
      } else {
        keyCode = new ToJsonIdentity(pythonType(resolvedType.keyType));
      }
      ToJsonCode valueCode = toJsonCode(resolvedType.valueType);
      if (keyCode.isIdentity && valueCode.isIdentity) {
        return new ToJsonIdentity(pythonType(resolvedType));
      } else {
        return new ToJsonSnippet(pythonType(type), (String value) {
          StringBuffer result = new StringBuffer();
          result.write('{ ');
          if (!keyCode.isIdentity && impliedTypes[resolvedType.keyType.typeName].type is! TypeEnum) {
            result.write('k.to_json(): ');
          } else {
            result.write('k: ');
          }
          if (resolvedType.valueType is TypeUnion || (!valueCode.isIdentity && impliedTypes[resolvedType.valueType.typeName].type is! TypeEnum)) {
            result.write('v.to_json()');
          } else {
            result.write('v');
          }
          result.write(' for k, v in self.$value }');
          return result.toString();
        });
      }
    } else if (resolvedType is TypeUnion) {
      for (TypeDecl choice in resolvedType.choices) {
        if (resolveTypeReferenceChain(choice) is! TypeObject) {
          throw new Exception('Union types must be unions of objects');
        }
      }
      return new ToJsonSnippet(
          pythonType(type), (String value) => '$value.to_json()');
    } else if (resolvedType is TypeObject || resolvedType is TypeEnum) {
      return new ToJsonSnippet(
          pythonType(type), (String value) => '$value.to_json()');
    } else {
      throw new Exception("Can't convert $resolvedType from JSON");
    }
  }

  @override
  visitApi() {
    outputHeader();
    writeln();
    writeln('import json');
    writeln('from .core import *');
    writeln();
    writeln();
    writeln('def decode_union(data, discriminator, choices):');
    indent(() {
      writeln('return choices[data[discriminator]]');
    });
    writeln();
    emitClasses();
  }
}

/**
 * Container for code that can be used to translate a data type from JSON.
 */
abstract class FromJsonCode {
  /**
   * Get the translation code in the form of a closure.
   */
  String get asClosure;

  /**
   * True if the data type is already in JSON form, so the translation is the
   * identity function.
   */
  bool get isIdentity;

  /**
   * Get the translation code in the form of a code snippet, where [jsonPath]
   * is the variable holding the JSON path, and [json] is the variable holding
   * the raw JSON.
   */
  String asSnippet(String json);
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
  String asSnippet(String json) =>
      '$asClosure($json)';
}

/**
 * Representation of FromJsonCode for the identity transformation.
 */
class FromJsonIdentity extends FromJsonSnippet {
  FromJsonIdentity() : super((String json) => json);

  @override
  bool get isIdentity => true;
}

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
  String get asClosure =>
      '${callback('json')}';

  @override
  bool get isIdentity => false;

  @override
  String asSnippet(String json) => callback(json);
}

/**
 * Container for code that can be used to translate a data type to JSON.
 */
abstract class ToJsonCode {
  /**
   * Get the translation code in the form of a closure.
   */
  String get asClosure;

  /**
   * True if the data type is already in JSON form, so the translation is the
   * identity function.
   */
  bool get isIdentity;

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

/**
 * Representation of FromJsonCode for the identity transformation.
 */
class ToJsonIdentity extends ToJsonSnippet {
  ToJsonIdentity(String type) : super(type, (String value) => "self.$value");

  @override
  bool get isIdentity => true;
}

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
  String get asClosure => '($type value) => ${callback('value')}';

  @override
  bool get isIdentity => false;

  @override
  String asSnippet(String value) => callback(value);
}
