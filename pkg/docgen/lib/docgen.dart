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

import 'dart2yaml.dart';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart'
    as dart2js;
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';

var logger = new Logger("Docgen");

/// Counter used to provide unique IDs for each distinct item.  
int _nextID = 0;

int get nextID => _nextID++;

const String usage = "Usage: dart docgen.dart [OPTIONS] [fooDir/barFile]";

List<Path> listLibraries(List<String> args) {
  if (args.length != 1) {
    throw new UnsupportedError(usage);
  }
  var libraries = new List<Path>();
  var type = FileSystemEntity.typeSync(args[0]);
  
  if (type == FileSystemEntityType.NOT_FOUND) { 
    throw new UnsupportedError("File does not exist. $usage");
  } else if (type == FileSystemEntityType.LINK) {
    libraries.addAll(listLibrariesFromDir(new Link(args[0]).targetSync()));
  } else if (type == FileSystemEntityType.FILE) {
    libraries.add(new Path(args[0]));
    logger.info("Added to libraries: ${libraries.last.toString()}");
  } else if (type == FileSystemEntityType.DIRECTORY) {
    libraries.addAll(listLibrariesFromDir(args[0]));
  }
  return libraries;
}

List<Path> listLibrariesFromDir(String path) {
  var libraries = new List<Path>();
  new Directory(path).listSync(recursive: true, 
      followLinks: true).forEach((file) {
        if (new Path(file.path).extension == "dart") {
          if (!file.path.contains("/packages/")) {
            libraries.add(new Path(file.path));
            logger.info("Added to libraries: ${libraries.last.toString()}");
          }
        }
      });
  return libraries;
}

/**
 * This class documents a list of libraries.
 */
class Docgen {

  /// Libraries to be documented.
  List<LibraryMirror> _libraries;
  
  /// Current library being documented to be used for comment links.
  LibraryMirror _currentLibrary;
  
  /// Current class being documented to be used for comment links.
  ClassMirror _currentClass;
  
  /// Current member being documented to be used for comment links.
  MemberMirror _currentMember;
  
  /// Resolves reference links
  markdown.Resolver linkResolver;
  
  bool outputToYaml;
  bool outputToJson;
  bool includePrivate;
  /// State for whether or not the SDK libraries should also be outputted.
  bool includeSdk;

  /**
   * Docgen constructor initializes the link resolver for markdown parsing.
   * Also initializes the command line arguments. 
   */
  Docgen(ArgResults argResults) {  
    if (argResults["output-format"] == null) {
      outputToYaml = 
          (argResults["yaml"] == false && argResults["json"] == false) ?
              true : argResults["yaml"];
    } else {
      if ((argResults["output-format"] == "yaml" && 
          argResults["json"] == true) || 
          (argResults["output-format"] == "json" && 
          argResults["yaml"] == true)) {
        throw new UnsupportedError("Cannot have contradictory output flags.");
      }
      outputToYaml = argResults["output-format"] == "yaml" ? true : false;
    }
    outputToJson = !outputToYaml;
    includePrivate = argResults["include-private"];
    includeSdk = argResults["include-sdk"];
    
    this.linkResolver = (name) => 
        fixReference(name, _currentLibrary, _currentClass, _currentMember);
  }
  
  /**
   * Analyzes set of libraries by getting a mirror system and triggers the 
   * documentation of the libraries. 
   */
  void analyze(List<Path> libraries) {
    // DART_SDK should be set to the root of the SDK library. 
    var sdkRoot = Platform.environment["DART_SDK"];
    if (sdkRoot != null) {
      logger.info("Using DART_SDK to find SDK at $sdkRoot");
      sdkRoot = new Path(sdkRoot);
    } else {
      // If DART_SDK is not defined in the environment, 
      // assuming the dart executable is from the Dart SDK folder inside bin. 
      sdkRoot = new Path(new Options().executable).directoryPath
          .directoryPath;
      logger.info("SDK Root: ${sdkRoot.toString()}");
    }
    
    Path packageDir = libraries.last.directoryPath.append("packages");
    logger.info("Package Root: ${packageDir.toString()}");
    getMirrorSystem(libraries, sdkRoot, 
        packageRoot: packageDir).then((MirrorSystem mirrorSystem) {
          if (mirrorSystem.libraries.values.isEmpty) {
            throw new UnsupportedError("No Library Mirrors.");
          } 
          this.libraries = mirrorSystem.libraries.values;
          documentLibraries();
        });
  }
  
  /**
   * Analyzes set of libraries and provides a mirror system which can be used 
   * for static inspection of the source code.
   */
  Future<MirrorSystem> getMirrorSystem(List<Path> libraries,
        Path libraryRoot, {Path packageRoot}) {
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
      librariesUri.add(currentDirectory.resolve(library.toString()));
    });
    return dart2js.analyze(librariesUri, libraryUri, packageUri,
        provider.readStringFromUri, diagnosticHandler,
        ['--preserve-comments', '--categories=Client,Server']);
  }
  
  /**
   * Creates documentation for filtered libraries.
   */
  void documentLibraries() {
    _libraries.forEach((library) {
      // Files belonging to the SDK have a uri that begins with "dart:".
      if (includeSdk || !library.uri.toString().startsWith("dart:")) {
        _currentLibrary = library;
        var result = new Library(library.qualifiedName, _getComment(library),
            _getVariables(library.variables), _getMethods(library.functions),
            _getClasses(library.classes), nextID);
        if (outputToJson) {
          _writeToFile(stringify(result.toMap()), "${result.name}.json");
        } 
        if (outputToYaml) {
          _writeToFile(getYamlString(result.toMap()), "${result.name}.yaml");
        }
     }
    });
   }
  
  /// Saves list of libraries for Docgen object.
  void set libraries(value){
    _libraries = value;
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
    commentText = commentText == null ? "" : 
        markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver)
        .replaceAll("\n", "");
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
        data[mirrorName] = new Variable(mirrorName, mirror.isFinal,
            mirror.isStatic, mirror.type.toString(), _getComment(mirror), 
            nextID);
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
        data[mirrorName] = new Method(mirrorName, mirror.isSetter,
            mirror.isGetter, mirror.isConstructor, mirror.isOperator, 
            mirror.isStatic, mirror.returnType.toString(), _getComment(mirror),
            _getParameters(mirror.parameters), nextID);
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
            mirror.superclass.qualifiedName : "";
        var interfaces = 
            mirror.superinterfaces.map((interface) => interface.qualifiedName);
        data[mirrorName] = new Class(mirrorName, superclass, mirror.isAbstract,
            mirror.isTypedef, _getComment(mirror), interfaces.toList(),
            _getVariables(mirror.variables), _getMethods(mirror.methods), 
            nextID);
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
          mirror.isOptional, mirror.isNamed, mirror.hasDefaultValue, 
          mirror.type.toString(), mirror.defaultValue, nextID);
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
  
  /// Unique ID number for resolving links. 
  int id;
  
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
      this.functions, this.classes, this.id);
  
  /// Generates a map describing the [Library] object.
  Map toMap() {
    var libraryMap = {};
    libraryMap["id"] = id;
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
  
  /// Unique ID number for resolving links. 
  int id;
  
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
      this.comment, this.interfaces, this.variables, this.methods, this.id);
  
  /// Generates a map describing the [Class] object.
  Map toMap() {
    var classMap = {};
    classMap["id"] = id;
    classMap["name"] = name;
    classMap["comment"] = comment;
    classMap["superclass"] = superclass;
    classMap["abstract"] = isAbstract.toString();
    classMap["typedef"] = isTypedef.toString();
    classMap["implements"] = new List.from(interfaces);
    classMap["variables"] = recurseMap(variables);
    classMap["methods"] = recurseMap(methods);
    return classMap;
  }
}

/**
 * A class containing properties of a Dart variable.
 */
class Variable {
  
  /// Unique ID number for resolving links. 
  int id;
  
  /// Documentation comment with converted markdown.
  String comment;
  
  String name;
  bool isFinal;
  bool isStatic;
  String type;
  
  Variable(this.name, this.isFinal, this.isStatic, this.type, 
      this.comment, this.id);
  
  /// Generates a map describing the [Variable] object.
  Map toMap() {
    var variableMap = {};
    variableMap["id"] = id;
    variableMap["name"] = name;
    variableMap["comment"] = comment;
    variableMap["final"] = isFinal.toString();
    variableMap["static"] = isStatic.toString();
    variableMap["type"] = type;
    return variableMap;
  }
}

/**
 * A class containing properties of a Dart method.
 */
class Method {
  
  /// Unique ID number for resolving links. 
  int id;
  
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
      this.parameters, this.id);
  
  /// Generates a map describing the [Method] object.
  Map toMap() {
    var methodMap = {};
    methodMap["id"] = id;
    methodMap["name"] = name;
    methodMap["comment"] = comment;
    methodMap["type"] = isSetter ? "setter" : isGetter ? "getter" :
      isOperator ? "operator" : isConstructor ? "constructor" : "method";
    methodMap["static"] = isStatic.toString();
    methodMap["return"] = returnType;
    methodMap["parameters"] = recurseMap(parameters);
    return methodMap;
  }  
}

/**
 * A class containing properties of a Dart method/function parameter.
 */
class Parameter {
  
  /// Unique ID number for resolving links. 
  int id;
  
  String name;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  String type;
  String defaultValue;
  
  Parameter(this.name, this.isOptional, this.isNamed, this.hasDefaultValue,
      this.type, this.defaultValue, this.id);
  
  /// Generates a map describing the [Parameter] object.
  Map toMap() {
    var parameterMap = {};
    parameterMap["id"] = id;
    parameterMap["name"] = name;
    parameterMap["optional"] = isOptional.toString();
    parameterMap["named"] = isNamed.toString();
    parameterMap["default"] = hasDefaultValue.toString();
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
  if (!file.existsSync()) {
    file.createSync();
  }
  file.openSync();
  file.writeAsString(text);
}