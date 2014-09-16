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

import 'package:html5lib/dom.dart' as dom;

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

/**
 * Callback type used to represent arbitrary code generation.
 */
typedef void CodegenCallback();

/**
 * Visitor which produces Dart code representing the API.
 */
class CodegenProtocolVisitor extends HierarchicalApiVisitor with CodeGenerator {
  /**
   * Type references in the spec that are named something else in Dart.
   */
  static const Map<String, String> _typeRenames = const {
    'long': 'int',
    'object': 'Map',
  };

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
    writeln('part of protocol;');
    emitClasses();
  }

  /**
   * Translate each type implied by the API to a class.
   */
  void emitClasses() {
    for (ImpliedType impliedType in impliedTypes.values) {
      TypeDecl type = impliedType.type;
      String dartTypeName = capitalize(impliedType.camelName);
      if (type == null) {
        emitEmptyObjectClass(dartTypeName, impliedType);
      } else if (type is TypeObject || type == null) {
        writeln();
        emitObjectClass(dartTypeName, type, impliedType);
      } else if (type is TypeEnum) {
        writeln();
        emitEnumClass(dartTypeName, type, impliedType);
      }
    }
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
    }));
    writeln('class $className {');
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
    writeln('}');
  }

  /**
   * Emit the class to encapsulate an object type.
   */
  void emitObjectClass(String className, TypeObject type,
      ImpliedType impliedType) {
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(impliedType.humanReadableName);
      });
      if (impliedType.type != null) {
        toHtmlVisitor.showType(null, impliedType.type);
      }
    }));
    write('class $className');
    if (impliedType.kind == 'refactoringFeedback') {
      write(' extends RefactoringFeedback');
    }
    if (impliedType.kind == 'refactoringOptions') {
      write(' extends RefactoringOptions');
    }
    writeln(' implements HasToJson {');
    indent(() {
      if (emitSpecialStaticMembers(className)) {
        writeln();
      }
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
   * If the class named [className] requires special static members, emit them
   * and return true.
   */
  bool emitSpecialStaticMembers(String className) {
    switch (className) {
      case 'AnalysisError':
        docComment(
            [
                new dom.Text(
                    'Returns a list of AnalysisErrors ' +
                        'correponding to the given list of Engine errors.')]);
        writeln(
            'static List<AnalysisError> listFromEngine(engine.LineInfo lineInfo, List<engine.AnalysisError> errors) =>');
        writeln('    _analysisErrorListFromEngine(lineInfo, errors);');
        return true;
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
        docComment(
            [
                new dom.Text(
                    'Get the result of applying a set of ' +
                        '[edits] to the given [code].  Edits are applied in the order ' +
                        'they appear in [edits].')]);
        writeln(
            'static String applySequence(String code, Iterable<SourceEdit> edits) =>');
        writeln('    _applySequence(code, edits);');
        return true;
      default:
        return false;
    }
  }

  /**
   * If the class named [className] requires special constructors, emit them
   * and return true.
   */
  bool emitSpecialConstructors(String className) {
    switch (className) {
      case 'AnalysisError':
        docComment(
            [
                new dom.Text(
                    'Construct based on error information from the analyzer engine.')]);
        writeln(
            'factory AnalysisError.fromEngine(engine.LineInfo lineInfo, engine.AnalysisError error) =>');
        writeln('    _analysisErrorFromEngine(lineInfo, error);');
        return true;
      case 'CompletionSuggestionKind':
        docComment(
            [new dom.Text('Construct from an analyzer engine element kind.')]);
        writeln(
            'factory CompletionSuggestionKind.fromElementKind(engine.ElementKind kind) =>');
        writeln('    _completionSuggestionKindFromElementKind(kind);');
        return true;
      case 'Element':
        docComment(
            [new dom.Text('Construct based on a value from the analyzer engine.')]);
        writeln('factory Element.fromEngine(engine.Element element) =>');
        writeln('    elementFromEngine(element);');
        return true;
      case 'ElementKind':
        docComment(
            [new dom.Text('Construct based on a value from the analyzer engine.')]);
        writeln('factory ElementKind.fromEngine(engine.ElementKind kind) =>');
        writeln('    _elementKindFromEngine(kind);');
        return true;
      case 'LinkedEditGroup':
        docComment([new dom.Text('Construct an empty LinkedEditGroup.')]);
        writeln(
            'LinkedEditGroup.empty() : this(<Position>[], 0, <LinkedEditSuggestion>[]);');
        return true;
      case 'Location':
        docComment(
            [new dom.Text('Create a Location based on an [engine.Element].')]);
        writeln('factory Location.fromElement(engine.Element element) =>');
        writeln('    _locationFromElement(element);');
        writeln();
        docComment(
            [new dom.Text('Create a Location based on an [engine.SearchMatch].')]);
        writeln('factory Location.fromMatch(engine.SearchMatch match) =>');
        writeln('    _locationFromMatch(match);');
        writeln();
        docComment(
            [new dom.Text('Create a Location based on an [engine.AstNode].')]);
        writeln('factory Location.fromNode(engine.AstNode node) =>');
        writeln('    _locationFromNode(node);');
        writeln();
        docComment(
            [new dom.Text('Create a Location based on an [engine.CompilationUnit].')]);
        writeln(
            'factory Location.fromUnit(engine.CompilationUnit unit, engine.SourceRange range) =>');
        writeln('    _locationFromUnit(unit, range);');
        return true;
      case 'OverriddenMember':
        docComment(
            [new dom.Text('Construct based on an element from the analyzer engine.')]);
        writeln(
            'factory OverriddenMember.fromEngine(engine.Element member) =>');
        writeln('    _overriddenMemberFromEngine(member);');
        return true;
      case 'RefactoringProblemSeverity':
        docComment(
            [
                new dom.Text(
                    'Returns the [RefactoringProblemSeverity] with the maximal severity.')]);
        writeln(
            'static RefactoringProblemSeverity max(RefactoringProblemSeverity a, RefactoringProblemSeverity b) =>');
        writeln('    _maxRefactoringProblemSeverity(a, b);');
        return true;
      case 'SearchResult':
        docComment(
            [new dom.Text('Construct based on a value from the search engine.')]);
        writeln('factory SearchResult.fromMatch(engine.SearchMatch match) =>');
        writeln('    searchResultFromMatch(match);');
        return true;
      case 'SearchResultKind':
        docComment(
            [new dom.Text('Construct based on a value from the search engine.')]);
        writeln(
            'factory SearchResultKind.fromEngine(engine.MatchKind kind) =>');
        writeln('    _searchResultKindFromEngine(kind);');
        return true;
      case 'SourceEdit':
        docComment([new dom.Text('Construct based on a SourceRange.')]);
        writeln(
            'SourceEdit.range(engine.SourceRange range, String replacement, {String id})');
        writeln('    : this(range.offset, range.length, replacement, id: id);');
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
      case 'AnalysisErrorFixes':
        docComment([new dom.Text('Add a [Fix]')]);
        writeln('void addFix(Fix fix) {');
        indent(() {
          writeln('fixes.add(fix.change);');
        });
        writeln('}');
        return true;
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
        docComment(
            [new dom.Text('Adds [edit] to the [FileEdit] for the given [file].')]);
        writeln('void addEdit(String file, int fileStamp, SourceEdit edit) =>');
        writeln('    _addEditToSourceChange(this, file, fileStamp, edit);');
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
        docComment(
            [new dom.Text('Returns the [FileEdit] for the given [file], maybe `null`.')]);
        writeln('SourceFileEdit getFileEdit(String file) =>');
        writeln('    _getChangeFileEdit(this, file);');
        return true;
      case 'SourceEdit':
        docComment(
            [new dom.Text('Get the result of applying the edit to the given [code].')]);
        writeln('String apply(String code) => _applyEdit(code, this);');
        return true;
      case 'SourceFileEdit':
        docComment([new dom.Text('Adds the given [Edit] to the list.')]);
        writeln('void add(SourceEdit edit) => _addEditForSource(this, edit);');
        writeln();
        docComment([new dom.Text('Adds the given [Edit]s.')]);
        writeln('void addAll(Iterable<SourceEdit> edits) =>');
        writeln('    _addAllEditsForSource(this, edits);');
        return true;
      default:
        return false;
    }
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
      String arg = 'this.${field.name}';
      if (isOptionalConstructorArg(className, field)) {
        optionalArgs.add(arg);
        TypeDecl fieldType = field.type;
        if (fieldType is TypeList) {
          extraInitCode.add(() {
            writeln('if (${field.name} == null) {');
            indent(() {
              writeln('${field.name} = <${dartType(fieldType.itemType)}>[];');
            });
            writeln('}');
          });
        }
      } else {
        args.add(arg);
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
          String condition;
          if (field.type is TypeList) {
            condition = '${field.name}.isNotEmpty';
          } else {
            condition = '${field.name} != null';
          }
          writeln('if ($condition) {');
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
      writeln('Response toResponse(String id) {');
      indent(() {
        String jsonPart = impliedType.type != null ? 'toJson()' : 'null';
        writeln('return new Response(id, result: $jsonPart);');
      });
      writeln('}');
      return true;
    }
    return false;
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
   * Emit the operator== code for an object class.
   */
  void emitObjectEqualsMember(TypeObject type, String className) {
    writeln('@override');
    writeln('bool operator==(other) {');
    indent(() {
      writeln('if (other is $className) {');
      indent(() {
        var comparisons = <String>[];
        if (type != null) {
          for (TypeObjectField field in type.fields) {
            if (field.value != null) {
              continue;
            }
            comparisons.add(
                compareEqualsCode(field.type, field.name, 'other.${field.name}'));
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
          writeln('hash = _JenkinsSmiHash.combine(hash, $valueToCombine);');
        }
        writeln('return _JenkinsSmiHash.finish(hash);');
      }
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
      if (emitSpecialStaticMembers(className)) {
        writeln();
      }
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
        return new ToJsonSnippet(
            dartType(type),
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
          dartType(type),
          (String value) => '$value.toJson()');
    } else if (resolvedType is TypeObject || resolvedType is TypeEnum) {
      return new ToJsonSnippet(
          dartType(type),
          (String value) => '$value.toJson()');
    } else {
      throw new Exception("Can't convert $resolvedType from JSON");
    }
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
      return '_listEqual($thisVar, $otherVar, $closure)';
    } else if (resolvedType is TypeMap) {
      String valueTypeName = dartType(resolvedType.valueType);
      String subComparison =
          compareEqualsCode(resolvedType.valueType, 'a', 'b');
      String closure = '($valueTypeName a, $valueTypeName b) => $subComparison';
      return '_mapEqual($thisVar, $otherVar, $closure)';
    }
    throw new Exception(
        "Don't know how to compare for equality: $resolvedType");
  }

  /**
   * Emit the method for decoding an object from JSON.
   */
  void emitObjectFromJsonConstructor(String className, TypeObject type,
      ImpliedType impliedType) {
    String humanReadableNameString =
        literalString(impliedType.humanReadableName);
    if (className == 'RefactoringFeedback') {
      writeln('factory RefactoringFeedback.fromJson(JsonDecoder jsonDecoder, '
          'String jsonPath, Object json, Map responseJson) {');
      indent(() {
        writeln('return _refactoringFeedbackFromJson(jsonDecoder, jsonPath, '
            'json, responseJson);');
      });
      writeln('}');
      return;
    }
    if (className == 'RefactoringOptions') {
      writeln('factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, '
          'String jsonPath, Object json, RefactoringKind kind) {');
      indent(() {
        writeln('return _refactoringOptionsFromJson(jsonDecoder, jsonPath, '
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
                  'throw jsonDecoder.mismatch(jsonPath, "equal " + $valueString);');
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
                  "throw jsonDecoder.missingKey(jsonPath, $fieldNameString);");
            });
            writeln('}');
          } else if (fieldType is TypeList) {
            writeln(' else {');
            indent(() {
              writeln('${field.name} = <${dartType(fieldType.itemType)}>[];');
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
  void emitEnumFromJsonConstructor(String className, TypeEnum type,
      ImpliedType impliedType) {
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
          'throw jsonDecoder.mismatch(jsonPath, $humanReadableNameString);');
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
          return new FromJsonSnippet(
              (String jsonPath, String json) {
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
            return new FromJsonFunction('jsonDecoder._decodeString');
          case 'bool':
            return new FromJsonFunction('jsonDecoder._decodeBool');
          case 'int':
          case 'long':
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
        return new FromJsonSnippet(
            (String jsonPath, String json) =>
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
      return new FromJsonSnippet(
          (String jsonPath, String json) =>
              'jsonDecoder._decodeUnion($jsonPath, $json, ${literalString(type.field)}, {${decoders.join(', ')}})');
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
        fieldName = '_params';
        makeDecoder = 'new RequestDecoder(request)';
        constructorName = 'fromRequest';
        break;
      case 'requestResult':
        inputType = 'Response';
        inputName = 'response';
        fieldName = '_result';
        makeDecoder = 'new ResponseDecoder(response)';
        constructorName = 'fromResponse';
        break;
      case 'notificationParams':
        inputType = 'Notification';
        inputName = 'notification';
        fieldName = '_params';
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

final GeneratedFile target =
    new GeneratedFile('../../lib/src/generated_protocol.dart', () {
  CodegenProtocolVisitor visitor = new CodegenProtocolVisitor(readApi());
  return visitor.collectCode(visitor.visitApi);
});

/**
 * Translate spec_input.html into protocol_matchers.dart.
 */
main() {
  target.generate();
}
