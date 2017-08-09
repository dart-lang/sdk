// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/codegen/tools.dart';
import 'package:html/dom.dart' as dom;
import 'package:path/path.dart' as path;

import 'api.dart';
import 'codegen_dart.dart';
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

GeneratedFile target(bool responseRequiresRequestTime) {
  return new GeneratedFile('lib/protocol/protocol_generated.dart',
      (String pkgPath) {
    CodegenProtocolVisitor visitor = new CodegenProtocolVisitor(
        path.basename(pkgPath), responseRequiresRequestTime, readApi(pkgPath));
    return visitor.collectCode(visitor.visitApi);
  });
}

/**
 * Callback type used to represent arbitrary code generation.
 */
typedef void CodegenCallback();

typedef String FromJsonSnippetCallback(String jsonPath, String json);

typedef String ToJsonSnippetCallback(String value);

/**
 * Visitor which produces Dart code representing the API.
 */
class CodegenProtocolVisitor extends DartCodegenVisitor with CodeGenerator {
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
   * The name of the package into which code is being generated.
   */
  final String packageName;

  /**
   * A flag indicating whether the class [Response] requires a `requestTime`
   * parameter.
   */
  final bool responseRequiresRequestTime;

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

  CodegenProtocolVisitor(
      this.packageName, this.responseRequiresRequestTime, Api api)
      : toHtmlVisitor = new ToHtmlVisitor(api),
        impliedTypes = computeImpliedTypes(api),
        super(api) {
    codeGeneratorSettings.commentLineLength = 79;
    codeGeneratorSettings.languageName = 'dart';
  }

  /**
   * Compute the code necessary to compare two objects for equality.
   */
  String compareEqualsCode(TypeDecl type, String thisVar, String otherVar) {
    TypeDecl resolvedType = resolveTypeReferenceChain(type);
    if (resolvedType is TypeReference ||
        resolvedType is TypeEnum ||
        resolvedType is TypeObject ||
        resolvedType is TypeUnion) {
      return '$thisVar == $otherVar';
    } else if (resolvedType is TypeList) {
      String itemTypeName = dartType(resolvedType.itemType);
      String subComparison = compareEqualsCode(resolvedType.itemType, 'a', 'b');
      String closure = '($itemTypeName a, $itemTypeName b) => $subComparison';
      return 'listEqual($thisVar, $otherVar, $closure)';
    } else if (resolvedType is TypeMap) {
      String valueTypeName = dartType(resolvedType.valueType);
      String subComparison =
          compareEqualsCode(resolvedType.valueType, 'a', 'b');
      String closure = '($valueTypeName a, $valueTypeName b) => $subComparison';
      return 'mapEqual($thisVar, $otherVar, $closure)';
    }
    throw new Exception(
        "Don't know how to compare for equality: $resolvedType");
  }

  /**
   * Translate each of the given [types] implied by the API to a class.
   */
  void emitClasses(List<ImpliedType> types) {
    for (ImpliedType impliedType in types) {
      TypeDecl type = impliedType.type;
      String dartTypeName = capitalize(impliedType.camelName);
      if (type == null) {
        writeln();
        emitEmptyObjectClass(dartTypeName, impliedType);
      } else if (type is TypeObject) {
        writeln();
        emitObjectClass(dartTypeName, type, impliedType);
      } else if (type is TypeEnum) {
        writeln();
        emitEnumClass(dartTypeName, type, impliedType);
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
        makeDecoder =
            'new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id))';
        constructorName = 'fromResponse';
        break;
      case 'notificationParams':
        inputType = 'Notification';
        inputName = 'notification';
        fieldName = 'params';
        makeDecoder = 'new ResponseDecoder(null)';
        constructorName = 'fromNotification';
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
      String fieldNameString =
          literalString(fieldName.replaceFirst(new RegExp('^_'), ''));
      if (className == 'EditGetRefactoringParams') {
        writeln('var params = new $className.fromJson(');
        writeln('    $makeDecoder, $fieldNameString, $inputName.$fieldName);');
        writeln('REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind;');
        writeln('return params;');
      } else {
        writeln('return new $className.fromJson(');
        writeln('    $makeDecoder, $fieldNameString, $inputName.$fieldName);');
      }
    });
    writeln('}');
    return true;
  }

  /**
   * Emit a class representing an data structure that doesn't exist in the
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
    write('class $className');
    if (impliedType.kind == 'refactoringFeedback') {
      writeln(' extends RefactoringFeedback implements HasToJson {');
    } else if (impliedType.kind == 'refactoringOptions') {
      writeln(' extends RefactoringOptions implements HasToJson {');
    } else if (impliedType.kind == 'requestParams') {
      writeln(' implements RequestParams {');
    } else if (impliedType.kind == 'requestResult') {
      writeln(' implements ResponseResult {');
    } else {
      writeln(' {');
    }
    indent(() {
      if (impliedType.kind == 'requestResult' ||
          impliedType.kind == 'requestParams') {
        emitEmptyToJsonMember();
        writeln();
      }
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
    writeln('}');
  }

  /**
   * Emit the toJson() code for an empty class.
   */
  void emitEmptyToJsonMember() {
    writeln('@override');
    writeln('Map<String, dynamic> toJson() => <String, dynamic>{};');
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
    writeln('class $className implements Enum {');
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
            'static const $className ${value.value} = const $className._($valueString);');
        writeln();
      }

      writeln('/**');
      writeln(' * A list containing all of the enum values that are defined.');
      writeln(' */');
      write('static const List<');
      write(className);
      write('> VALUES = const <');
      write(className);
      write('>[');
      bool first = true;
      for (TypeEnumValue value in type.values) {
        if (first) {
          first = false;
        } else {
          write(', ');
        }
        write(value.value);
      }
      writeln('];');
      writeln();

      writeln('@override');
      writeln('final String name;');
      writeln();
      writeln('const $className._(this.name);');
      writeln();
      emitEnumClassConstructor(className, type);
      writeln();
      emitEnumFromJsonConstructor(className, type, impliedType);
      writeln();
      if (emitSpecialConstructors(className)) {
        writeln();
      }
      if (emitSpecialGetters(className)) {
        writeln();
      }
      if (emitSpecialMethods(className)) {
        writeln();
      }
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
   * Emit the method for decoding an enum from JSON.
   */
  void emitEnumFromJsonConstructor(
      String className, TypeEnum type, ImpliedType impliedType) {
    writeln(
        'factory $className.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {');
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
      String humanReadableNameString =
          literalString(impliedType.humanReadableName);
      writeln(
          'throw jsonDecoder.mismatch(jsonPath, $humanReadableNameString, json);');
    });
    writeln('}');
  }

  void emitImports() {
    writeln("import 'dart:convert' hide JsonDecoder;");
    writeln();
    writeln("import 'package:analyzer/src/generated/utilities_general.dart';");
    writeln("import 'package:$packageName/protocol/protocol.dart';");
    writeln(
        "import 'package:$packageName/src/protocol/protocol_internal.dart';");
    for (String uri in api.types.importUris) {
      write("import '");
      write(uri);
      writeln("';");
    }
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
    write('class $className');
    if (impliedType.kind == 'refactoringFeedback') {
      writeln(' extends RefactoringFeedback {');
    } else if (impliedType.kind == 'refactoringOptions') {
      writeln(' extends RefactoringOptions {');
    } else if (impliedType.kind == 'requestParams') {
      writeln(' implements RequestParams {');
    } else if (impliedType.kind == 'requestResult') {
      writeln(' implements ResponseResult {');
    } else {
      writeln(' implements HasToJson {');
    }
    indent(() {
      if (emitSpecialStaticMembers(className)) {
        writeln();
      }
      for (TypeObjectField field in type.fields) {
        if (field.value != null) {
          continue;
        }
        writeln('${dartType(field.type)} _${field.name};');
        writeln();
      }
      for (TypeObjectField field in type.fields) {
        if (field.value != null) {
          continue;
        }
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(field.html);
        }));
        writeln('${dartType(field.type)} get ${field.name} => _${field.name};');
        writeln();
        docComment(toHtmlVisitor.collectHtml(() {
          toHtmlVisitor.translateHtml(field.html);
        }));
        writeln('void set ${field.name}(${dartType(field.type)} value) {');
        indent(() {
          if (!field.optional) {
            writeln('assert(value != null);');
          }
          writeln('this._${field.name} = value;');
        });
        writeln('}');
        writeln();
      }
      emitObjectConstructor(type, className);
      writeln();
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
      writeln('@override');
      writeln('String toString() => JSON.encode(toJson());');
      writeln();
      emitObjectEqualsMember(type, className);
      writeln();
      emitObjectHashCode(type, className);
    });
    writeln('}');
  }

  /**
   * Emit the constructor for an object class.
   */
  void emitObjectConstructor(TypeObject type, String className) {
    List<String> args = <String>[];
    List<String> optionalArgs = <String>[];
    List<CodegenCallback> extraInitCode = <CodegenCallback>[];
    for (TypeObjectField field in type.fields) {
      if (field.value != null) {
        continue;
      }
      String arg = '${dartType(field.type)} ${field.name}';
      String setValueFromArg = 'this.${field.name} = ${field.name};';
      if (isOptionalConstructorArg(className, field)) {
        optionalArgs.add(arg);
        if (!field.optional) {
          // Optional constructor arg, but non-optional field.  If no arg is
          // given, the constructor should populate with the empty list.
          TypeDecl fieldType = field.type;
          if (fieldType is TypeList) {
            extraInitCode.add(() {
              writeln('if (${field.name} == null) {');
              indent(() {
                writeln(
                    'this.${field.name} = <${dartType(fieldType.itemType)}>[];');
              });
              writeln('} else {');
              indent(() {
                writeln(setValueFromArg);
              });
              writeln('}');
            });
          } else {
            throw new Exception(
                "Don't know how to create default field value.");
          }
        } else {
          extraInitCode.add(() {
            writeln(setValueFromArg);
          });
        }
      } else {
        args.add(arg);
        extraInitCode.add(() {
          writeln(setValueFromArg);
        });
      }
    }
    if (optionalArgs.isNotEmpty) {
      args.add('{${optionalArgs.join(', ')}}');
    }
    write('$className(${args.join(', ')})');
    if (extraInitCode.isEmpty) {
      writeln(';');
    } else {
      writeln(' {');
      indent(() {
        for (CodegenCallback callback in extraInitCode) {
          callback();
        }
      });
      writeln('}');
    }
  }

  /**
   * Emit the operator== code for an object class.
   */
  void emitObjectEqualsMember(TypeObject type, String className) {
    writeln('@override');
    writeln('bool operator ==(other) {');
    indent(() {
      writeln('if (other is $className) {');
      indent(() {
        var comparisons = <String>[];
        if (type != null) {
          for (TypeObjectField field in type.fields) {
            if (field.value != null) {
              continue;
            }
            comparisons.add(compareEqualsCode(
                field.type, field.name, 'other.${field.name}'));
          }
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
   * Emit the method for decoding an object from JSON.
   */
  void emitObjectFromJsonConstructor(
      String className, TypeObject type, ImpliedType impliedType) {
    String humanReadableNameString =
        literalString(impliedType.humanReadableName);
    if (className == 'RefactoringFeedback') {
      writeln('factory RefactoringFeedback.fromJson(JsonDecoder jsonDecoder, '
          'String jsonPath, Object json, Map responseJson) {');
      indent(() {
        writeln('return refactoringFeedbackFromJson(jsonDecoder, jsonPath, '
            'json, responseJson);');
      });
      writeln('}');
      return;
    }
    if (className == 'RefactoringOptions') {
      writeln('factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, '
          'String jsonPath, Object json, RefactoringKind kind) {');
      indent(() {
        writeln('return refactoringOptionsFromJson(jsonDecoder, jsonPath, '
            'json, kind);');
      });
      writeln('}');
      return;
    }
    writeln(
        'factory $className.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {');
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
                  'throw jsonDecoder.mismatch(jsonPath, "equal " + $valueString, json);');
            });
            writeln('}');
            continue;
          }
          if (isOptionalConstructorArg(className, field)) {
            optionalArgs.add('${field.name}: ${field.name}');
          } else {
            args.add(field.name);
          }
          TypeDecl fieldType = field.type;
          String fieldDartType = dartType(fieldType);
          writeln('$fieldDartType ${field.name};');
          writeln('if (json.containsKey($fieldNameString)) {');
          indent(() {
            String fromJson =
                fromJsonCode(fieldType).asSnippet(jsonPath, fieldAccessor);
            writeln('${field.name} = $fromJson;');
          });
          write('}');
          if (!field.optional) {
            writeln(' else {');
            indent(() {
              writeln(
                  "throw jsonDecoder.mismatch(jsonPath, $fieldNameString);");
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
            'throw jsonDecoder.mismatch(jsonPath, $humanReadableNameString, json);');
      });
      writeln('}');
    });
    writeln('}');
  }

  /**
   * Emit the hashCode getter for an object class.
   */
  void emitObjectHashCode(TypeObject type, String className) {
    writeln('@override');
    writeln('int get hashCode {');
    indent(() {
      if (type == null) {
        writeln('return ${className.hashCode};');
      } else {
        writeln('int hash = 0;');
        for (TypeObjectField field in type.fields) {
          String valueToCombine;
          if (field.value != null) {
            valueToCombine = field.value.hashCode.toString();
          } else {
            valueToCombine = '${field.name}.hashCode';
          }
          writeln('hash = JenkinsSmiHash.combine(hash, $valueToCombine);');
        }
        writeln('return JenkinsSmiHash.finish(hash);');
      }
    });
    writeln('}');
  }

  /**
   * If the class named [className] requires special constructors, emit them
   * and return true.
   */
  bool emitSpecialConstructors(String className) {
    switch (className) {
      case 'LinkedEditGroup':
        docComment([new dom.Text('Construct an empty LinkedEditGroup.')]);
        writeln(
            'LinkedEditGroup.empty() : this(<Position>[], 0, <LinkedEditSuggestion>[]);');
        return true;
      case 'RefactoringProblemSeverity':
        docComment([
          new dom.Text(
              'Returns the [RefactoringProblemSeverity] with the maximal severity.')
        ]);
        writeln(
            'static RefactoringProblemSeverity max(RefactoringProblemSeverity a, RefactoringProblemSeverity b) =>');
        writeln('    maxRefactoringProblemSeverity(a, b);');
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
          writeln(
              'bool get ${camelJoin(['is', name])} => (flags & $flag) != 0;');
        }
        return true;
      case 'SourceEdit':
        docComment([new dom.Text('The end of the region to be modified.')]);
        writeln('int get end => offset + length;');
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
        writeln('void addPosition(Position position, int length) {');
        indent(() {
          writeln('positions.add(position);');
          writeln('this.length = length;');
        });
        writeln('}');
        writeln();
        docComment([new dom.Text('Add a new suggestion.')]);
        writeln('void addSuggestion(LinkedEditSuggestion suggestion) {');
        indent(() {
          writeln('suggestions.add(suggestion);');
        });
        writeln('}');
        return true;
      case 'SourceChange':
        docComment([
          new dom.Text('Adds [edit] to the [FileEdit] for the given [file].')
        ]);
        writeln('void addEdit(String file, int fileStamp, SourceEdit edit) =>');
        writeln('    addEditToSourceChange(this, file, fileStamp, edit);');
        writeln();
        docComment([new dom.Text('Adds the given [FileEdit].')]);
        writeln('void addFileEdit(SourceFileEdit edit) {');
        indent(() {
          writeln('edits.add(edit);');
        });
        writeln('}');
        writeln();
        docComment([new dom.Text('Adds the given [LinkedEditGroup].')]);
        writeln('void addLinkedEditGroup(LinkedEditGroup linkedEditGroup) {');
        indent(() {
          writeln('linkedEditGroups.add(linkedEditGroup);');
        });
        writeln('}');
        writeln();
        docComment([
          new dom.Text(
              'Returns the [FileEdit] for the given [file], maybe `null`.')
        ]);
        writeln('SourceFileEdit getFileEdit(String file) =>');
        writeln('    getChangeFileEdit(this, file);');
        return true;
      case 'SourceEdit':
        docComment([
          new dom.Text(
              'Get the result of applying the edit to the given [code].')
        ]);
        writeln('String apply(String code) => applyEdit(code, this);');
        return true;
      case 'SourceFileEdit':
        docComment([new dom.Text('Adds the given [Edit] to the list.')]);
        writeln('void add(SourceEdit edit) => addEditForSource(this, edit);');
        writeln();
        docComment([new dom.Text('Adds the given [Edit]s.')]);
        writeln('void addAll(Iterable<SourceEdit> edits) =>');
        writeln('    addAllEditsForSource(this, edits);');
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
          writeln('static const int $flag = $value;');
          makeFlagsArgs.add('$camelName: false');
          makeFlagsStatements.add('if ($camelName) flags |= $flag;');
        });
        writeln();
        writeln('static int makeFlags({${makeFlagsArgs.join(', ')}}) {');
        indent(() {
          writeln('int flags = 0;');
          for (String statement in makeFlagsStatements) {
            writeln(statement);
          }
          writeln('return flags;');
        });
        writeln('}');
        return true;
      case 'SourceEdit':
        docComment([
          new dom.Text('Get the result of applying a set of ' +
              '[edits] to the given [code].  Edits are applied in the order ' +
              'they appear in [edits].')
        ]);
        writeln(
            'static String applySequence(String code, Iterable<SourceEdit> edits) =>');
        writeln('    applySequenceOfEdits(code, edits);');
        return true;
      default:
        return false;
    }
  }

  /**
   * Emit the toJson() code for an object class.
   */
  void emitToJsonMember(TypeObject type) {
    writeln('@override');
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
   * Emit the toNotification() code for a class, if appropriate.  Returns true
   * if code was emitted.
   */
  bool emitToNotificationMember(ImpliedType impliedType) {
    if (impliedType.kind == 'notificationParams') {
      writeln('Notification toNotification() {');
      indent(() {
        String eventString =
            literalString((impliedType.apiNode as Notification).longEvent);
        String jsonPart = impliedType.type != null ? 'toJson()' : 'null';
        writeln('return new Notification($eventString, $jsonPart);');
      });
      writeln('}');
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
      writeln('@override');
      writeln('Request toRequest(String id) {');
      indent(() {
        String methodString =
            literalString((impliedType.apiNode as Request).longMethod);
        String jsonPart = impliedType.type != null ? 'toJson()' : 'null';
        writeln('return new Request(id, $methodString, $jsonPart);');
      });
      writeln('}');
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
      writeln('@override');
      if (responseRequiresRequestTime) {
        writeln('Response toResponse(String id, int requestTime) {');
      } else {
        writeln('Response toResponse(String id) {');
      }
      indent(() {
        String jsonPart = impliedType.type != null ? 'toJson()' : 'null';
        if (responseRequiresRequestTime) {
          writeln('return new Response(id, requestTime, result: $jsonPart);');
        } else {
          writeln('return new Response(id, result: $jsonPart);');
        }
      });
      writeln('}');
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
        if (referencedType is TypeObject || referencedType is TypeEnum) {
          return new FromJsonSnippet((String jsonPath, String json) {
            String typeName = dartType(type);
            if (typeName == 'RefactoringFeedback') {
              return 'new $typeName.fromJson(jsonDecoder, $jsonPath, $json, json)';
            } else if (typeName == 'RefactoringOptions') {
              return 'new $typeName.fromJson(jsonDecoder, $jsonPath, $json, kind)';
            } else {
              return 'new $typeName.fromJson(jsonDecoder, $jsonPath, $json)';
            }
          });
        } else {
          return fromJsonCode(referencedType);
        }
      } else {
        switch (type.typeName) {
          case 'String':
            return new FromJsonFunction('jsonDecoder.decodeString');
          case 'bool':
            return new FromJsonFunction('jsonDecoder.decodeBool');
          case 'int':
          case 'long':
            return new FromJsonFunction('jsonDecoder.decodeInt');
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
        return new FromJsonFunction('jsonDecoder.decodeMap');
      } else {
        return new FromJsonSnippet((String jsonPath, String json) {
          StringBuffer result = new StringBuffer();
          result.write('jsonDecoder.decodeMap($jsonPath, $json');
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
        return new FromJsonFunction('jsonDecoder.decodeList');
      } else {
        return new FromJsonSnippet((String jsonPath, String json) =>
            'jsonDecoder.decodeList($jsonPath, $json, ${itemCode.asClosure})');
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
          'jsonDecoder.decodeUnion($jsonPath, $json, ${literalString(type.field)}, {${decoders.join(', ')}})');
    } else {
      throw new Exception("Can't convert $type from JSON");
    }
  }

  /**
   * Return a list of the classes to be emitted.
   */
  List<ImpliedType> getClassesToEmit() {
    List<ImpliedType> types = impliedTypes.values.where((ImpliedType type) {
      ApiNode node = type.apiNode;
      return !(node is TypeDefinition && node.isExternal);
    }).toList();
    types.sort((first, second) =>
        capitalize(first.camelName).compareTo(capitalize(second.camelName)));
    return types;
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
      return new ToJsonIdentity(dartType(type));
    } else if (resolvedType is TypeList) {
      ToJsonCode itemCode = toJsonCode(resolvedType.itemType);
      if (itemCode.isIdentity) {
        return new ToJsonIdentity(dartType(type));
      } else {
        return new ToJsonSnippet(dartType(type),
            (String value) => '$value.map(${itemCode.asClosure}).toList()');
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
      return new ToJsonSnippet(
          dartType(type), (String value) => '$value.toJson()');
    } else if (resolvedType is TypeObject || resolvedType is TypeEnum) {
      return new ToJsonSnippet(
          dartType(type), (String value) => '$value.toJson()');
    } else {
      throw new Exception("Can't convert $resolvedType from JSON");
    }
  }

  @override
  visitApi() {
    outputHeader(year: '2017');
    writeln();
    emitImports();
    emitClasses(getClassesToEmit());
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
  String asSnippet(String jsonPath, String json);
}

/**
 * Representation of FromJsonCode for a function defined elsewhere.
 */
class FromJsonFunction extends FromJsonCode {
  @override
  final String asClosure;

  FromJsonFunction(this.asClosure);

  @override
  bool get isIdentity => false;

  @override
  String asSnippet(String jsonPath, String json) =>
      '$asClosure($jsonPath, $json)';
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
      '(String jsonPath, Object json) => ${callback('jsonPath', 'json')}';

  @override
  bool get isIdentity => false;

  @override
  String asSnippet(String jsonPath, String json) => callback(jsonPath, json);
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
  @override
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
  ToJsonIdentity(String type) : super(type, (String value) => value);

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
