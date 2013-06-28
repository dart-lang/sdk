// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * **docgen** is a tool for creating machine readable representations of Dart 
 * code metadata, including: classes, members, comments and annotations.
 * 
 * docgen is run on a `.dart` file or a directory containing `.dart` files. 
 * 
 *      $ dart docgen.dart [OPTIONS] [FILE/DIR]
 *
 * This creates files called `docs/<library_name>.yaml` in your current 
 * working directory.
 */
library docgen;

import 'dart:io';
import 'dart:json';
import 'dart:async';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:pathos/path.dart' as path;

import 'dart2yaml.dart';
import 'src/io.dart';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart'
    as dart2js;
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../sdk/lib/_internal/libraries.dart';

var logger = new Logger('Docgen');

const String USAGE = 'Usage: dart docgen.dart [OPTIONS] [fooDir/barFile]';

/// Current library being documented to be used for comment links.
LibraryMirror _currentLibrary;

/// Current class being documented to be used for comment links.
ClassMirror _currentClass;

/// Current member being documented to be used for comment links.
MemberMirror _currentMember;

/// Resolves reference links in doc comments. 
markdown.Resolver linkResolver;

/// Package directory of directory being analyzed. 
String packageDir;

bool outputToYaml;
bool outputToJson;
bool includePrivate;
/// State for whether imported SDK libraries should also be outputted.
bool includeSdk;
/// State for whether all SDK libraries should be outputted. 
bool parseSdk;

/**
 * Docgen constructor initializes the link resolver for markdown parsing.
 * Also initializes the command line arguments. 
 */
void docgen(ArgResults argResults) {  
  _setCommandLineArguments(argResults);
  
  linkResolver = (name) => 
      fixReference(name, _currentLibrary, _currentClass, _currentMember);
  
  getMirrorSystem(argResults.rest).then((MirrorSystem mirrorSystem) {
    if (mirrorSystem.libraries.values.isEmpty) {
      throw new StateError('No Library Mirrors.');
    }
    _documentLibraries(mirrorSystem.libraries.values);
  });
}

void _setCommandLineArguments(ArgResults argResults) {
  outputToYaml = argResults['yaml'] || argResults['output-format'] == 'yaml';
  outputToJson = argResults['json'] || argResults['output-format'] == 'json';
  if (outputToYaml && outputToJson) {
    throw new ArgumentError('Cannot have contradictory output flags.');
  }
  outputToYaml = outputToYaml || !outputToJson;
  includePrivate = argResults['include-private'];
  parseSdk = argResults['parse-sdk'];
  includeSdk = parseSdk || argResults['include-sdk'];
}

List<String> _listLibraries(List<String> args) {
  // TODO(janicejl): At the moment, only have support to have either one file,
  // or one directory. This is because there can only be one package directory
  // since only one docgen is created per run. 
  if (args.length != 1) throw new UnsupportedError(USAGE);
  var libraries = new List<String>();
  var type = FileSystemEntity.typeSync(args[0]);
  
  if (type == FileSystemEntityType.FILE) {
    libraries.add(path.absolute(args[0]));
    logger.info('Added to libraries: ${libraries.last}');
  } else {
    libraries.addAll(_listDartFromDir(args[0]));
  } 
  logger.info('Package Directory: $packageDir');
  return libraries;
}

List<String> _listDartFromDir(String args) {
  var files = listDir(args, recursive: true);
  packageDir = files.firstWhere((f) => 
      f.endsWith('/pubspec.yaml'), orElse: () => '');
  if (packageDir != '') packageDir = path.dirname(packageDir) + '/packages';
  return files.where((f) => 
      f.endsWith('.dart') && !f.contains('/packages')).toList()
      ..forEach((lib) => logger.info('Added to libraries: $lib'));
}

List<String> _listSdk() {
  var sdk = new List<String>();
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) { 
      sdk.add('dart:$name');
      logger.info('Add to SDK: ${sdk.last}');
    }
  });
  return sdk;
}

/**
 * Analyzes set of libraries by getting a mirror system and triggers the 
 * documentation of the libraries. 
 */
Future<MirrorSystem> getMirrorSystem(List<String> args) {
  var libraries = !parseSdk ? _listLibraries(args) : _listSdk();
  if (libraries.isEmpty) throw new StateError('No Libraries.');
  // DART_SDK should be set to the root of the SDK library. 
  var sdkRoot = Platform.environment['DART_SDK'];
  if (sdkRoot != null) {
    logger.info('Using DART_SDK to find SDK at $sdkRoot');
  } else {
    // If DART_SDK is not defined in the environment, 
    // assuming the dart executable is from the Dart SDK folder inside bin. 
    sdkRoot = path.dirname(path.dirname(new Options().executable));
    logger.info('SDK Root: ${sdkRoot}');
  }
  
  return _getMirrorSystemHelper(libraries, sdkRoot, packageRoot: packageDir);
}

/**
 * Analyzes set of libraries and provides a mirror system which can be used 
 * for static inspection of the source code.
 */
Future<MirrorSystem> _getMirrorSystemHelper(List<String> libraries,
      String libraryRoot, {String packageRoot}) {
  SourceFileProvider provider = new SourceFileProvider();
  api.DiagnosticHandler diagnosticHandler =
        new FormattingDiagnosticHandler(provider).diagnosticHandler;
  Uri libraryUri = currentDirectory.resolve(appendSlash('$libraryRoot'));
  Uri packageUri = null;
  if (packageRoot != null) {
    packageUri = currentDirectory.resolve(appendSlash('$packageRoot'));
  }
  List<Uri> librariesUri = <Uri>[];
  libraries.forEach((library) {
    librariesUri.add(currentDirectory.resolve(library));
  });
  return dart2js.analyze(librariesUri, libraryUri, packageUri,
      provider.readStringFromUri, diagnosticHandler,
      ['--preserve-comments', '--categories=Client,Server']);
}

/**
 * Creates documentation for filtered libraries.
 */
void _documentLibraries(List<LibraryMirror> libraries) {
  libraries.forEach((lib) {
    // Files belonging to the SDK have a uri that begins with 'dart:'.
    if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
      var library = generateLibrary(lib);
      _outputLibrary(library);
    }
  });
  // Outputs a text file with a list of files available after creating all 
  // the libraries. This will help the viewer know what files are available 
  // to read in. 
  _writeToFile(listDir("docs").join('\n'), 'library_list.txt');
}

Library generateLibrary(dart2js.Dart2JsLibraryMirror library) {
  _currentLibrary = library;
  var result = new Library(library.qualifiedName, _getComment(library),
      _getVariables(library.variables), _getMethods(library.functions),
      _getClasses(library.classes));
  logger.fine('Generated library for ${result.name}');
  return result;
}

void _outputLibrary(Library result) {
  if (outputToJson) {
    _writeToFile(stringify(result.toMap()), '${result.name}.json');
  } 
  if (outputToYaml) {
    _writeToFile(getYamlString(result.toMap()), '${result.name}.yaml');
  }
}

/**
 * Returns a list of meta annotations assocated with a mirror. 
 */
List<String> _getAnnotations(DeclarationMirror mirror) {
  var annotations = mirror.metadata.where((e) => 
      e is dart2js.Dart2JsConstructedConstantMirror);
  return annotations.map((e) => e.type.qualifiedName).toList();
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
          commentText = '$commentText ${comment.trimmedText}';
        }
      } 
    }
  });
  commentText = commentText == null ? '' : 
      markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver)
      .replaceAll('\n', ' ');
  return commentText;
}

/**
 * Converts all [_] references in comments to <code>_</code>.
 */
// TODO(tmandel): Create proper links for [_] style markdown based
// on scope once layout of viewer is finished.
markdown.Node fixReference(String name, LibraryMirror currentLibrary, 
    ClassMirror currentClass, MemberMirror currentMember) {
  return new markdown.Element.text('code', name);
}

/**
 * Returns a map of [Variable] objects constructed from inputted mirrors.
 */
Map<String, Variable> _getVariables(Map<String, VariableMirror> mirrorMap) {
  var data = {};
  mirrorMap.forEach((String mirrorName, VariableMirror mirror) {
    if (includePrivate || !mirror.isPrivate) {
      _currentMember = mirror;
      data[mirrorName] = new Variable(mirrorName, mirror.qualifiedName, 
          mirror.isFinal, mirror.isStatic, mirror.type.qualifiedName, 
          _getComment(mirror), _getAnnotations(mirror));
    }
  });
  return data;
}

/**
 * Returns a map of [Method] objects constructed from inputted mirrors.
 */
Map<String, Method> _getMethods(Map<String, MethodMirror> mirrorMap) {
  var data = {};
  mirrorMap.forEach((String mirrorName, MethodMirror mirror) {
    if (includePrivate || !mirror.isPrivate) {
      _currentMember = mirror;
      data[mirrorName] = new Method(mirrorName, mirror.qualifiedName, 
          mirror.isSetter, mirror.isGetter, mirror.isConstructor, 
          mirror.isOperator, mirror.isStatic, mirror.returnType.qualifiedName, 
          _getComment(mirror), _getParameters(mirror.parameters), 
          _getAnnotations(mirror));
    }
  });
  return data;
} 

/**
 * Returns a map of [Class] objects constructed from inputted mirrors.
 */
Map<String, Class> _getClasses(Map<String, ClassMirror> mirrorMap) {
  var data = {};
  mirrorMap.forEach((String mirrorName, ClassMirror mirror) {
    if (includePrivate || !mirror.isPrivate) {
      _currentClass = mirror;
      var superclass = (mirror.superclass != null) ? 
          mirror.superclass.qualifiedName : '';
      var interfaces = 
          mirror.superinterfaces.map((interface) => interface.qualifiedName);
      data[mirrorName] = new Class(mirrorName, mirror.qualifiedName, 
          superclass, mirror.isAbstract, mirror.isTypedef, 
          _getComment(mirror), interfaces.toList(),
          _getVariables(mirror.variables), _getMethods(mirror.methods), 
          _getAnnotations(mirror));
    }
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
        mirror.qualifiedName, mirror.isOptional, mirror.isNamed, 
        mirror.hasDefaultValue, mirror.type.qualifiedName, 
        mirror.defaultValue, _getAnnotations(mirror));
  });
  return data;
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
  if (!file.existsSync()) {
    file.createSync();
  }
  file.openSync();
  file.writeAsString(text);
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
    libraryMap['name'] = name;
    libraryMap['comment'] = comment;
    libraryMap['variables'] = recurseMap(variables);
    libraryMap['functions'] = recurseMap(functions);
    libraryMap['classes'] = recurseMap(classes);
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
  String qualifiedName;
  String superclass;
  bool isAbstract;
  bool isTypedef;
  
  /// List of the meta annotations on the class. 
  List<String> annotations;
 
  Class(this.name, this.qualifiedName, this.superclass, this.isAbstract, 
      this.isTypedef, this.comment, this.interfaces, this.variables, 
      this.methods, this.annotations);
  
  /// Generates a map describing the [Class] object.
  Map toMap() {
    var classMap = {};
    classMap['name'] = name;
    classMap['qualifiedname'] = qualifiedName;
    classMap['comment'] = comment;
    classMap['superclass'] = superclass;
    classMap['abstract'] = isAbstract.toString();
    classMap['typedef'] = isTypedef.toString();
    classMap['implements'] = new List.from(interfaces);
    classMap['variables'] = recurseMap(variables);
    classMap['methods'] = recurseMap(methods);
    classMap['annotations'] = new List.from(annotations);
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
  String qualifiedName;
  bool isFinal;
  bool isStatic;
  String type;

  /// List of the meta annotations on the variable. 
  List<String> annotations;
  
  Variable(this.name, this.qualifiedName, this.isFinal, this.isStatic, 
      this.type, this.comment, this.annotations);
  
  /// Generates a map describing the [Variable] object.
  Map toMap() {
    var variableMap = {};
    variableMap['name'] = name;
    variableMap['qualifiedname'] = qualifiedName;
    variableMap['comment'] = comment;
    variableMap['final'] = isFinal.toString();
    variableMap['static'] = isStatic.toString();
    variableMap['type'] = type;
    variableMap['annotations'] = new List.from(annotations);
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
  String qualifiedName;
  bool isSetter;
  bool isGetter;
  bool isConstructor;
  bool isOperator;
  bool isStatic;
  String returnType;
  
  /// List of the meta annotations on the method.  
  List<String> annotations;
  
  Method(this.name, this.qualifiedName, this.isSetter, this.isGetter, 
      this.isConstructor, this.isOperator, this.isStatic, this.returnType, 
      this.comment, this.parameters, this.annotations);
  
  /// Generates a map describing the [Method] object.
  Map toMap() {
    var methodMap = {};
    methodMap['name'] = name;
    methodMap['qualifiedname'] = qualifiedName;
    methodMap['comment'] = comment;
    methodMap['type'] = isSetter ? 'setter' : isGetter ? 'getter' :
      isOperator ? 'operator' : isConstructor ? 'constructor' : 'method';
    methodMap['static'] = isStatic.toString();
    methodMap['return'] = returnType;
    methodMap['parameters'] = recurseMap(parameters);
    methodMap['annotations'] = new List.from(annotations);
    return methodMap;
  }  
}

/**
 * A class containing properties of a Dart method/function parameter.
 */
class Parameter {
  
  String name;
  String qualifiedName;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  String type;
  String defaultValue;
  
  /// List of the meta annotations on the parameter. 
  List<String> annotations;
  
  Parameter(this.name, this.qualifiedName, this.isOptional, this.isNamed, 
      this.hasDefaultValue, this.type, this.defaultValue, this.annotations);
  
  /// Generates a map describing the [Parameter] object.
  Map toMap() {
    var parameterMap = {};
    parameterMap['name'] = name;
    parameterMap['qualifiedname'] = qualifiedName;
    parameterMap['optional'] = isOptional.toString();
    parameterMap['named'] = isNamed.toString();
    parameterMap['default'] = hasDefaultValue.toString();
    parameterMap['type'] = type;
    parameterMap['value'] = defaultValue;
    parameterMap['annotations'] = new List.from(annotations);
    return parameterMap;
  } 
}
