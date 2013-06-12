/**
 * The docgen tool takes in a library as input and produces documentation
 * for the library as well as all libraries it imports and uses. The tool can
 * be run by passing in the path to a .dart file like this:
 *
 *   ./dart docgen.dart path/to/file.dart
 *
 * This outputs information about all classes, variables, functions, and
 * methods defined in the library and its imported libraries.
 */
library docgen;

import 'dart:io';
import 'dart:async';
import '../lib/dart2yaml.dart';
import '../lib/src/dart2js_mirrors.dart';
import 'package:markdown/markdown.dart' as markdown;
import '../../args/lib/args.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';

/**
 * Entry function to create YAML documentation from Dart files.
 */
void main() {
  // TODO(tmandel): Use args library once flags are clear.
  Options opts = new Options();
  Docgen docgen = new Docgen();
  
  if (opts.arguments.length > 0) {
    List<Path> libraries = [new Path(opts.arguments[0])];
    Path sdkDirectory = new Path("../../../sdk/");
    var workingMirrors = analyze(libraries, sdkDirectory, 
        options: ['--preserve-comments', '--categories=Client,Server']);
    workingMirrors.then( (MirrorSystem mirrorSystem) {
      var mirrors = mirrorSystem.libraries.values;
      if (mirrors.isEmpty) {
        print("no LibraryMirrors");
      } else {
        docgen.libraries = mirrors;
        docgen.documentLibraries();
      }
    });
  }
}

/**
 * This class documents a list of libraries.
 */
class Docgen {

  /// Libraries to be documented.
  List<LibraryMirror> _libraries;
  
  /// Saves list of libraries for Docgen object.
  void set libraries(value) => _libraries = value;
  
  /// Current library being documented to be used for comment links.
  LibraryMirror _currentLibrary;
  
  /// Current class being documented to be used for comment links.
  ClassMirror _currentClass;
  
  /// Current member being documented to be used for comment links.
  MemberMirror _currentMember;
  
  /**
   * Creates documentation for filtered libraries.
   */
  void documentLibraries() {
    //TODO(tmandel): Filter libraries and determine output type using flags.
    _libraries.forEach((library) {
      _currentLibrary = library;
      var result = new Library(library.qualifiedName, _getComment(library),
          _getVariables(library.variables), _getMethods(library.functions),
          _getClasses(library.classes));
      _writeToFile(getYamlString(result.toMap()), "${result.name}.yaml");
    });
   }
  
  /**
   * Returns any documentation comments associated with a mirror with
   * simple markdown converted to html.
   */
  String _getComment(DeclarationMirror mirror) {
    String commentText;
    mirror.metadata.forEach((metadata) {
      if (metadata is CommentInstanceMirror) {
        CommentInstanceMirror comment = metadata;
        if (comment.isDocComment) {
          if (commentText == null) {
            commentText = comment.trimmedText;
          } else {
            commentText = "$commentText ${comment.trimmedText}";
          }
        } 
      }
    });
    // TODO(tmandel): Resolve links to members in markdown using _currentClass,
    // _currentMember, and _currentLibrary.
    return commentText == null ? "" : 
      markdown.markdownToHtml(commentText.trim());
  }
  
  /**
   * Returns a map of [Variable] objects constructed from inputted mirrors.
   */
  Map<String, Variable> _getVariables(Map<String, VariableMirror> mirrorMap) {
    var data = {};
    mirrorMap.forEach((String mirrorName, VariableMirror mirror) {
      _currentMember = mirror;
      data[mirrorName] = new Variable(mirrorName, mirror.isFinal,
          mirror.isStatic, mirror.type.toString(), _getComment(mirror));
    });
    return data;
  }
  
  /**
   * Returns a map of [Method] objects constructed from inputted mirrors.
   */
  Map<String, Method> _getMethods(Map<String, MethodMirror> mirrorMap) {
    var data = {};
    mirrorMap.forEach((String mirrorName, MethodMirror mirror) {
      _currentMember = mirror;
      data[mirrorName] = new Method(mirrorName, mirror.isSetter,
          mirror.isGetter, mirror.isConstructor, mirror.isOperator, 
          mirror.isStatic, mirror.returnType.toString(), _getComment(mirror),
          _getParameters(mirror.parameters));
    });
    return data;
  } 
  
  /**
   * Returns a map of [Class] objects constructed from inputted mirrors.
   */
  Map<String, Class> _getClasses(Map<String, ClassMirror> mirrorMap) {
    var data = {};
    mirrorMap.forEach((String mirrorName, ClassMirror mirror) {
      _currentClass = mirror;
      var superclass;
      if (mirror.superclass != null) {
        superclass = mirror.superclass.qualifiedName;
      }
      var interfaces = 
          mirror.superinterfaces.map((interface) => interface.qualifiedName);
      data[mirrorName] = new Class(mirrorName, superclass, mirror.isAbstract,
          mirror.isTypedef, _getComment(mirror), interfaces,
          _getVariables(mirror.variables), _getMethods(mirror.methods));
    });
    return data;
  }
  
  /**
   * Returns a map of [Parameter] objects constructed from inputted mirrors.
   */
  Map<String, Parameter> _getParameters(List<ParameterMirror> mirrorList) {
    var data = {};
    mirrorList.forEach((ParameterMirror mirror) {
      _currentMember = mirror;
      data[mirror.simpleName] = new Parameter(mirror.simpleName, 
          mirror.isOptional, mirror.isNamed, mirror.hasDefaultValue, 
          mirror.type.toString(), mirror.defaultValue);
    });
    return data;
  }
}

/**
 * Transforms the map by calling toMap on each value in it.
 */
Map recurseMap(Map inputMap) {
  var outputMap = {};
  inputMap.forEach((key, value) {
    outputMap[key] = value.toMap();
  });
  return outputMap;
}

/**
 * A class containing contents of a Dart library.
 */
class Library {
  
  /// Documentation comment with converted markdown.
  String comment;
  
  /// Top-level variables in the library.
  Map<String, Variable> variables;
  
  /// Top-level functions in the library.
  Map<String, Method> functions;
  
  /// Classes defined within the library
  Map<String, Class> classes;
  
  String name;
  
  Library(this.name, this.comment, this.variables, 
      this.functions, this.classes);
  
  /// Generates a map describing the [Library] object.
  Map toMap() {
    var libraryMap = {};
    libraryMap["name"] = name;
    libraryMap["comment"] = comment;
    libraryMap["variables"] = recurseMap(variables);
    libraryMap["functions"] = recurseMap(functions);
    libraryMap["classes"] = recurseMap(classes);
    return libraryMap;
  }
}

/**
 * A class containing contents of a Dart class.
 */
// TODO(tmandel): Figure out how to do typedefs (what is needed)
class Class {
  
  /// Documentation comment with converted markdown.
  String comment;
  
  /// List of the names of interfaces that this class implements.
  List<String> interfaces;
  
  /// Top-level variables in the class.
  Map<String, Variable> variables;
  
  /// Methods in the class.
  Map<String, Method> methods;
  
  String name;
  String superclass;
  bool isAbstract;
  bool isTypedef;
 
  Class(this.name, this.superclass, this.isAbstract, this.isTypedef,
      this.comment, this.interfaces, this.variables, this.methods); 
  
  /// Generates a map describing the [Class] object.
  Map toMap() {
    var classMap = {};
    classMap["name"] = name;
    classMap["comment"] = comment;
    classMap["superclass"] = superclass;
    classMap["abstract"] = isAbstract;
    classMap["typedef"] = isTypedef;
    classMap["implements"] = interfaces;
    classMap["variables"] = recurseMap(variables);
    classMap["methods"] = recurseMap(methods);
    return classMap;
  }
}

/**
 * A class containing properties of a Dart variable.
 */
class Variable {
  
  /// Documentation comment with converted markdown.
  String comment;
  
  String name;
  bool isFinal;
  bool isStatic;
  String type;
  
  Variable(this.name, this.isFinal, this.isStatic, this.type, this.comment);
  
  /// Generates a map describing the [Variable] object.
  Map toMap() {
    var variableMap = {};
    variableMap["name"] = name;
    variableMap["comment"] = comment;
    variableMap["final"] = isFinal;
    variableMap["static"] = isStatic;
    variableMap["type"] = type;
    return variableMap;
  }
}

/**
 * A class containing properties of a Dart method.
 */
class Method {
  
  /// Documentation comment with converted markdown.
  String comment;
  
  /// Parameters for this method.
  Map<String, Parameter> parameters;
  
  String name;
  bool isSetter;
  bool isGetter;
  bool isConstructor;
  bool isOperator;
  bool isStatic;
  String returnType;
  
  Method(this.name, this.isSetter, this.isGetter, this.isConstructor,
      this.isOperator, this.isStatic, this.returnType, this.comment,
      this.parameters);
  
  /// Generates a map describing the [Method] object.
  Map toMap() {
    var methodMap = {};
    methodMap["name"] = name;
    methodMap["comment"] = comment;
    methodMap["type"] = isSetter ? "Setter" : isGetter ? "Getter" :
      isOperator ? "Operator" : isConstructor ? "Constructor" : "Method";
    methodMap["static"] = isStatic;
    methodMap["return"] = returnType;
    methodMap["parameters"] = recurseMap(parameters);
    return methodMap;
  }  
}

/**
 * A class containing properties of a Dart method/function parameter.
 */
class Parameter {
  
  String name;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  String type;
  String defaultValue;
  
  Parameter(this.name, this.isOptional, this.isNamed, this.hasDefaultValue,
      this.type, this.defaultValue);
  
  /// Generates a map describing the [Parameter] object.
  Map toMap() {
    var parameterMap = {};
    parameterMap["name"] = name;
    parameterMap["optional"] = isOptional;
    parameterMap["default"] = hasDefaultValue;
    parameterMap["type"] = type;
    parameterMap["value"] = defaultValue;
    return parameterMap;
  } 
}

/**
 * Writes text to a file in the 'docs' directory.
 */
void _writeToFile(String text, String filename) {
  Directory dir = new Directory('docs');
  if (!dir.existsSync()) {
    dir.createSync();
  }
  File file = new File('docs/$filename');
  if (!file.exists()) {
    file.createSync();
  }
  file.openSync();
  file.writeAsString(text);
}