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

import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;

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

/// Index of all the qualified names documented. 
Set<String> qualifiedNameIndex = new Set<String>();

/**
 * Docgen constructor initializes the link resolver for markdown parsing.
 * Also initializes the command line arguments.
 *
 * [packageRoot] is the packages directory of the directory being analyzed.
 * If [includeSdk] is `true`, then any SDK libraries explicitly imported will
 * also be documented.
 * If [parseSdk] is `true`, then all Dart SDK libraries will be documented.
 * This option is useful when only the SDK libraries are needed.
 *
 * Returns `true` if docgen sucessfuly completes.
 */
Future<bool> docgen(List<String> files, {String packageRoot,
    bool outputToYaml: true, bool includePrivate: false, bool includeSdk: false,
    bool parseSdk: false}) {
  if (packageRoot == null && !parseSdk) {
    // TODO(janicejl): At the moment, if a single file is passed it, it is
    // assumed that it does not have a package root unless it is passed in by
    // the user. In future, find a better way to find the packageRoot and also
    // fully test finding the packageRoot.
    if (FileSystemEntity.typeSync(files.first)
        == FileSystemEntityType.DIRECTORY) {
      packageRoot = _findPackageRoot(files.first);
    }
  }
  logger.info('Package Root: ${packageRoot}');

  linkResolver = (name) =>
      fixReference(name, _currentLibrary, _currentClass, _currentMember);

  return getMirrorSystem(files, packageRoot: packageRoot, parseSdk: parseSdk)
    .then((MirrorSystem mirrorSystem) {
      if (mirrorSystem.libraries.isEmpty) {
        throw new StateError('No library mirrors were created.');
      }
      _documentLibraries(mirrorSystem.libraries.values,
          includeSdk: includeSdk, includePrivate: includePrivate,
          outputToYaml: outputToYaml);

      return true;
    });
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
  return libraries;
}

List<String> _listDartFromDir(String args) {
  var files = listDir(args, recursive: true);
  // To avoid anaylzing package files twice, only files with paths not
  // containing '/packages' will be added. The only exception is if the file to
  // analyze already has a '/package' in its path.
  return files.where((f) => f.endsWith('.dart') &&
      (!f.contains('${path.separator}packages') || 
          args.contains('${path.separator}packages'))).toList()
      ..forEach((lib) => logger.info('Added to libraries: $lib'));
}

String _findPackageRoot(String directory) {
  var files = listDir(directory, recursive: true);
  // Return '' means that there was no pubspec.yaml and therefor no packageRoot.
  String packageRoot = files.firstWhere((f) =>
      f.endsWith('${path.separator}pubspec.yaml'), orElse: () => '');
  if (packageRoot != '') {
    packageRoot = path.join(path.dirname(packageRoot), 'packages');
  }
  return packageRoot;
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
Future<MirrorSystem> getMirrorSystem(List<String> args, {String packageRoot,
    bool parseSdk:false}) {
  var libraries = !parseSdk ? _listLibraries(args) : _listSdk();
  if (libraries.isEmpty) throw new StateError('No Libraries.');
  // DART_SDK should be set to the root of the SDK library.
  var sdkRoot = Platform.environment['DART_SDK'];
  if (sdkRoot != null) {
    logger.info('Using DART_SDK to find SDK at $sdkRoot');
  } else {
    // If DART_SDK is not defined in the environment,
    // assuming the dart executable is from the Dart SDK folder inside bin.
    sdkRoot = path.join(path.dirname(path.dirname(path.dirname(path.dirname(
        path.absolute(new Options().script))))), 'sdk');
    logger.info('SDK Root: ${sdkRoot}');
  }
  return _analyzeLibraries(libraries, sdkRoot, packageRoot: packageRoot);
}

/**
 * Analyzes set of libraries and provides a mirror system which can be used
 * for static inspection of the source code.
 */
Future<MirrorSystem> _analyzeLibraries(List<String> libraries,
      String libraryRoot, {String packageRoot}) {
  SourceFileProvider provider = new SourceFileProvider();
  api.DiagnosticHandler diagnosticHandler =
        new FormattingDiagnosticHandler(provider).diagnosticHandler;
  Uri libraryUri = new Uri(scheme: 'file', path: appendSlash(libraryRoot));
  Uri packageUri = null;
  if (packageRoot != null) {
    packageUri = new Uri(scheme: 'file', path: appendSlash(packageRoot)); 
  }
  List<Uri> librariesUri = <Uri>[];
  libraries.forEach((library) {
    librariesUri.add(currentDirectory.resolve(library));
  });
  return dart2js.analyze(librariesUri, libraryUri, packageUri,
      provider.readStringFromUri, diagnosticHandler,
      ['--preserve-comments', '--categories=Client,Server'])
      ..catchError((error) {
        logger.severe('Error: Failed to create mirror system. ');
        // TODO(janicejl): Use the stack trace package when bug is resolved.
        // Currently, a string is thrown when it fails to create a mirror
        // system, and it is not possible to use the stack trace. BUG(#11622)
        // To avoid printing the stack trace.
        exit(1);
      });
}

/**
 * Creates documentation for filtered libraries.
 */
void _documentLibraries(List<LibraryMirror> libraries,
    {bool includeSdk:false, bool includePrivate:false, bool
     outputToYaml:true}) {
  libraries.forEach((lib) {
    // Files belonging to the SDK have a uri that begins with 'dart:'.
    if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
      var library = generateLibrary(lib, includePrivate: includePrivate);
      _writeLibraryToFile(library, outputToYaml);
    }
  });
  // Outputs a text file with a list of files available after creating all
  // the libraries. This will help the viewer know what files are available
  // to read in.
  _writeToFile(listDir('docs').join('\n').replaceAll('docs/', ''),
      'library_list.txt');
  // Outputs all the qualified names documented. This will help generate search
  // results. 
  _writeToFile(qualifiedNameIndex.join('\n'), 'index.txt');
}

Library generateLibrary(dart2js.Dart2JsLibraryMirror library,
  {bool includePrivate:false}) {
  _currentLibrary = library;
  var result = new Library(library.qualifiedName, _getComment(library),
      _getVariables(library.variables, includePrivate),
      _getMethods(library.functions, includePrivate),
      _getClasses(library.classes, includePrivate));
  logger.fine('Generated library for ${result.name}');
  return result;
}

void _writeLibraryToFile(Library result, bool outputToYaml) {
  if (outputToYaml) {
    _writeToFile(getYamlString(result.toMap()), '${result.name}.yaml');
  } else {
    _writeToFile(stringify(result.toMap()), '${result.name}.json');
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
      markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver);
  return commentText;
}

/**
 * Converts all [foo] references in comments to <a>libraryName.foo</a>.
 */
markdown.Node fixReference(String name, LibraryMirror currentLibrary,
    ClassMirror currentClass, MemberMirror currentMember) {
  var reference;
  var memberScope = currentMember == null ?
      null : currentMember.lookupInScope(name);
  if (memberScope != null) reference = memberScope.qualifiedName;
  else {
    var classScope = currentClass == null ?
        null : currentClass.lookupInScope(name);
    reference = classScope != null ? classScope.qualifiedName : name;
  }
  return new markdown.Element.text('a', reference);
}

/**
 * Returns a map of [Variable] objects constructed from [mirrorMap].
 */
Map<String, Variable> _getVariables(Map<String, VariableMirror> mirrorMap,
    bool includePrivate) {
  var data = {};
  // TODO(janicejl): When map to map feature is created, replace the below with
  // a filter. Issue(#9590).
  mirrorMap.forEach((String mirrorName, VariableMirror mirror) {
    if (includePrivate || !mirror.isPrivate) {
      _currentMember = mirror;
      data[mirrorName] = new Variable(mirrorName, mirror.isFinal, 
          mirror.isStatic, mirror.isConst, _type(mirror.type),
          _getComment(mirror), _getAnnotations(mirror), mirror.qualifiedName);
    }
  });
  return data;
}

/**
 * Returns a map of [Method] objects constructed from [mirrorMap].
 */
Map<String, Map<String, Method>> _getMethods
    (Map<String, MethodMirror> mirrorMap, bool includePrivate) {

  var setters = {};
  var getters = {};
  var constructors = {};
  var operators = {};
  var methods = {};
  
  mirrorMap.forEach((String mirrorName, MethodMirror mirror) {
    if (includePrivate || !mirror.isPrivate) {
      var method = new Method(mirrorName, mirror.isStatic, mirror.isAbstract,
          mirror.isConstConstructor, _type(mirror.returnType), 
          _getComment(mirror), _getParameters(mirror.parameters), 
          _getAnnotations(mirror), mirror.qualifiedName);
      _currentMember = mirror;
      if (mirror.isSetter) {
        setters[mirrorName] = method;
      } else if (mirror.isGetter) {
        getters[mirrorName] = method;
      } else if (mirror.isConstructor) {
        constructors[mirrorName] = method;
      } else if (mirror.isOperator) {
        operators[mirrorName] = method;
      } else if (mirror.isRegularMethod) {
         methods[mirrorName] = method;
      } else {
        throw new ArgumentError('$mirrorName - no method type match');
      }
    }
  });
  return {
    'setters': setters,
    'getters': getters,
    'constructors': constructors,
    'operators': operators,
    'methods': methods
  };
} 

/**
 * Returns a map of [Class] objects constructed from [mirrorMap].
 */
Map<String, Class> _getClasses(Map<String, ClassMirror> mirrorMap,
    bool includePrivate) {
  
  var abstractClasses = {};
  var classes = {};
  var typedefs = {};
  var errors = {};
  
  mirrorMap.forEach((String mirrorName, ClassMirror mirror) {    
    if (includePrivate || !mirror.isPrivate) {
      var superclass = (mirror.superclass != null) ?
          mirror.superclass.qualifiedName : '';
      var interfaces =
          mirror.superinterfaces.map((interface) => interface.qualifiedName);
      var clazz = new Class(mirrorName, superclass, _getComment(mirror), 
          interfaces.toList(), _getVariables(mirror.variables, includePrivate),
          _getMethods(mirror.methods, includePrivate),
          _getAnnotations(mirror), _getGenerics(mirror), mirror.qualifiedName);
      _currentClass = mirror;
      
      if (isError(mirror.qualifiedName)) {
        errors[mirrorName] = clazz;
      } else if (mirror.isTypedef) {
        typedefs[mirrorName] = new Typedef(mirrorName, 
            mirror.value.returnType.qualifiedName,  _getComment(mirror), 
            _getGenerics(mirror), _getParameters(mirror.value.parameters),
            _getAnnotations(mirror), mirror.qualifiedName);
      } else if (mirror.isAbstract) {
        abstractClasses[mirrorName] = clazz;
      } else if (mirror.isClass) {
        classes[mirrorName] = clazz;
      } else {
        throw new ArgumentError('$mirrorName - no class type match. ');
      }
    }
  });
  return {
    'abstract': abstractClasses, 
    'class': classes,
    'typedef': typedefs,
    'error': errors
  };
}

/**
 * Returns a map of [Parameter] objects constructed from [mirrorList].
 */
Map<String, Parameter> _getParameters(List<ParameterMirror> mirrorList) {
  var data = {};
  mirrorList.forEach((ParameterMirror mirror) {
    _currentMember = mirror;
    data[mirror.simpleName] = new Parameter(mirror.simpleName, 
        mirror.isOptional, mirror.isNamed, mirror.hasDefaultValue, 
        _type(mirror.type), mirror.defaultValue, 
        _getAnnotations(mirror));
  });
  return data;
}

/**
 * Returns a map of [Generic] objects constructed from the class mirror. 
 */
Map<String, Generic> _getGenerics(ClassMirror mirror) {
  return new Map.fromIterable(mirror.typeVariables, 
      key: (e) => e.toString(), 
      value: (e) => new Generic(e.toString(), e.upperBound.qualifiedName));
}

/**
 * Returns a single [Type] object constructed from the Method.returnType 
 * Type mirror. 
 */
Type _type(TypeMirror mirror) {
  return new Type(mirror.qualifiedName, _typeGenerics(mirror));
}

/**
 * Returns a list of [Type] objects constructed from TypeMirrors. 
 */
List<Type> _typeGenerics(TypeMirror mirror) {
  if (mirror is ClassMirror && !mirror.isTypedef) {
    var innerList = [];
    mirror.typeArguments.forEach((e) {
      innerList.add(new Type(e.qualifiedName, _typeGenerics(e)));
    });
    return innerList;
  }
  return [];
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
    if (value is Map) {
      outputMap[key] = recurseMap(value);
    } else {
      outputMap[key] = value.toMap();
    }
  });
  return outputMap;
}

bool isError(String qualifiedName) {
  return qualifiedName.toLowerCase().contains('error') || 
      qualifiedName.toLowerCase().contains('exception');
}

/**
 * A class representing all programming constructs, like library or class. 
 */
class Indexable {
  String name;
  String qualifiedName;
  
  /// Documentation comment with converted markdown.
  String comment;
  
  Indexable(this.name, this.comment, String qualifiedName) {
    this.qualifiedName = qualifiedName;
    qualifiedNameIndex.add(qualifiedName);
  }
}

/**
 * A class containing contents of a Dart library.
 */
class Library extends Indexable {

  /// Top-level variables in the library.
  Map<String, Variable> variables;

  /// Top-level functions in the library.
  Map<String, Map<String, Method>> functions;
  
  /// Classes defined within the library
  Map<String, Class> classes;

  Library(String name, String comment, this.variables,
      this.functions, this.classes) : super(name, comment, name) {}

  /// Generates a map describing the [Library] object.
  Map toMap() => {
      'name': name,
      'qualifiedname': qualifiedName,
      'comment': comment,
      'variables': recurseMap(variables),
      'functions': recurseMap(functions),
      'classes': recurseMap(classes)
    };
}

/**
 * A class containing contents of a Dart class.
 */
class Class extends Indexable {

  /// List of the names of interfaces that this class implements.
  List<String> interfaces;

  /// Top-level variables in the class.
  Map<String, Variable> variables;

  /// Methods in the class.
  Map<String, Map<String, Method>> methods;
  
  /// Generic infomation about the class. 
  Map<String, Generic> generics;
  
  String superclass;

  /// List of the meta annotations on the class.
  List<String> annotations;
  
  Class(String name, this.superclass, String comment, this.interfaces, 
      this.variables, this.methods, this.annotations, this.generics,
      String qualifiedName) : super(name, comment, qualifiedName) {}

  /// Generates a map describing the [Class] object.
  Map toMap() => {
      'name': name,
      'qualifiedname': qualifiedName,
      'comment': comment,
      'superclass': superclass,
      'implements': new List.from(interfaces),
      'variables': recurseMap(variables),
      'methods': recurseMap(methods),
      'annotations': new List.from(annotations),
      'generics': recurseMap(generics)
    };
}

class Typedef extends Indexable {
  String returnType;
  
  Map<String, Parameter> parameters;
  
  /// Generic information about the typedef. 
  Map<String, Generic> generics;
  
  /// List of the meta annotations on the typedef. 
  List<String> annotations;
  
  Typedef(String name, this.returnType, String comment, this.generics, 
      this.parameters, this.annotations,
      String qualifiedName) : super(name, comment, qualifiedName) {}
  
  Map toMap() => {
      'name': name,
      'qualifiedname': qualifiedName,
      'comment': comment,
      'return': returnType,
      'parameters': recurseMap(parameters),
      'annotations': new List.from(annotations),
      'generics': recurseMap(generics)
    };
}

/**
 * A class containing properties of a Dart variable.
 */
class Variable extends Indexable {

  bool isFinal;
  bool isStatic;
  bool isConst;
  Type type;

  /// List of the meta annotations on the variable.
  List<String> annotations;
  
  Variable(String name, this.isFinal, this.isStatic, this.isConst, this.type, 
      String comment, this.annotations, String qualifiedName) : super(name, 
          comment, qualifiedName);
  
  /// Generates a map describing the [Variable] object.
  Map toMap() => {
      'name': name,
      'qualifiedname': qualifiedName,
      'comment': comment,
      'final': isFinal.toString(),
      'static': isStatic.toString(),
      'constant': isConst.toString(),
      'type': new List.filled(1, type.toMap()),
      'annotations': new List.from(annotations)
    };
}

/**
 * A class containing properties of a Dart method.
 */
class Method extends Indexable {

  /// Parameters for this method.
  Map<String, Parameter> parameters;

  bool isStatic;
  bool isAbstract;
  bool isConst;
  Type returnType;
  
  /// List of the meta annotations on the method.
  List<String> annotations;
  
  Method(String name, this.isStatic, this.isAbstract, this.isConst, 
      this.returnType, String comment, this.parameters, this.annotations,
      String qualifiedName) 
      : super(name, comment, qualifiedName);
  
  /// Generates a map describing the [Method] object.
  Map toMap() => {
      'name': name,
      'qualifiedname': qualifiedName,
      'comment': comment,
      'static': isStatic.toString(),
      'abstract': isAbstract.toString(),
      'constant': isConst.toString(),
      'return': new List.filled(1, returnType.toMap()),
      'parameters': recurseMap(parameters),
      'annotations': new List.from(annotations)
    };
}

/**
 * A class containing properties of a Dart method/function parameter.
 */
class Parameter {

  String name;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  Type type;
  String defaultValue;

  /// List of the meta annotations on the parameter.
  List<String> annotations;
  
  Parameter(this.name, this.isOptional, this.isNamed, this.hasDefaultValue, 
      this.type, this.defaultValue, this.annotations);
  
  /// Generates a map describing the [Parameter] object.
  Map toMap() => {
      'name': name,
      'optional': isOptional.toString(),
      'named': isNamed.toString(),
      'default': hasDefaultValue.toString(),
      'type': new List.filled(1, type.toMap()),
      'value': defaultValue,
      'annotations': new List.from(annotations)
    };
}

/**
 * A class containing properties of a Generic. 
 */
class Generic {
  String name;
  String type;
  
  Generic(this.name, this.type);
  
  Map toMap() => {
      'name': name,
      'type': type
    };
}

/**
 * Holds the name of a return type, and its generic type parameters.
 * 
 * Return types are of a form [outer]<[inner]>.
 * If there is no [inner] part, [inner] will be an empty list. 
 * 
 * For example:
 *        int size()  
 *          "return" : 
 *            - "outer" : "dart.core.int"
 *              "inner" :
 * 
 *        List<String> toList()
 *          "return" :
 *            - "outer" : "dart.core.List"
 *              "inner" : 
 *                - "outer" : "dart.core.String"
 *                  "inner" :
 *        
 *        Map<String, List<int>>
 *          "return" : 
 *            - "outer" : "dart.core.Map"
 *              "inner" :
 *                - "outer" : "dart.core.String"
 *                  "inner" :
 *                - "outer" : "dart.core.List"
 *                  "inner" :
 *                    - "outer" : "dart.core.int"
 *                      "inner" :
 */
class Type {
  String outer;
  List<Type> inner;
  
  Type(this.outer, this.inner);
  
  Map toMap() => {
      'outer': outer,
      'inner': new List.from(inner.map((e) => e.toMap()))
    };
}