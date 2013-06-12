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
import 'lib/src/dart2js_mirrors.dart';
import 'lib/dart2yaml.dart';
import '../../../../pkg/args/lib/args.dart';
import '../compiler/implementation/mirrors/mirrors.dart';
import '../compiler/implementation/mirrors/mirrors_util.dart';

/**
 * Entry function to create YAML documentation from Dart files.
 */
void main() {
  // TODO(tmandel): Use args library once flags are clear.
  Options opts = new Options();
  
  if (opts.arguments.length > 0) {
    List<Path> libraries = [new Path(opts.arguments[0])];
    Path sdkDirectory = new Path("../../../");
    var workingMirrors = analyze(libraries, sdkDirectory, 
        options: ['--preserve-comments', '--categories=Client,Server']);
    workingMirrors.then( (MirrorSystem mirrorSystem) {
      var mirrors = mirrorSystem.libraries;
      if (mirrors.isEmpty) {
        print("no LibraryMirrors");
      } else {
        mirrors.values.forEach( (library) {
          // TODO(tmandel): Use flags to filter libraries.
          if (library.uri.scheme != "dart") {
            String result = _getDocumentation(library);
            if (result != null) {
              _writeToFile(result, "${library.qualifiedName}.yaml");
            }
          }
        });
      }
    });
  }
}

/**
 *  Creates YAML output from relevant libraries.
 */
//TODO(tmandel): Also allow for output to JSON based on flags
String _getDocumentation(LibraryMirror library) {
  Map libMap = new Map();
  String libraryName = library.qualifiedName;
  
  // Get library top-level information.
  libMap[libraryName] = new Map();
  
  libMap[libraryName]["variables"] = new Map();
  _getVariables(libMap[libraryName]["variables"], library.variables);
  
  libMap[libraryName]["functions"] = new Map();
  _getMethods(libMap[libraryName]["functions"], library.functions);
  
  String comment = _getComment(library);
  libMap[libraryName]["comment"] = comment != null ? comment.trim() : null;
  
  // Get specific information about each class.
  Map classes = new Map();
  library.classes.forEach( (String cName, ClassMirror mir) {
    
    classes[cName] = new Map();
    _getMethods(classes[cName], mir.methods);
    
    classes[cName]["variables"] = new Map();
    _getVariables(classes[cName]["variables"], mir.variables);
    
    classes[cName]["superclass"] = mir.superclass;
    classes[cName]["interfaces"] = mir.superinterfaces;
    classes[cName]["abstract"]   = mir.isAbstract;
    
    String comment = _getComment(mir);
    classes[cName]["comment"] = comment != null ? comment.trim() : null;

  });
  libMap[libraryName]["classes"] = classes;
  return getYamlString(libMap);
}

/**
 * Returns any documentation comments associated with a mirror.
 */
// TODO(tmandel): Handle reference links in comments.
String _getComment(DeclarationMirror mirror) {
  String commentText;
  mirror.metadata.forEach( (metadata) {
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
  return commentText;
}
  
/**
 * Populates an input Map with characteristics of variables.
 */
void _getVariables(Map data, Map<String, VariableMirror> mirrorMap) {
  mirrorMap.forEach( (String name, VariableMirror mirror) {
    data[name] = new Map();
    data[name]["final"] = mirror.isFinal.toString();
    data[name]["static"] = mirror.isStatic.toString();
    data[name]["type"] = mirror.type.toString();
    
    String comment = _getComment(mirror);
    data[name]["comment"] = comment != null ? comment.trim() : null;  
  });
}

/**
 * Populates an input Map with characteristics of methods.
 */
void _getMethods(Map data, Map<String, MethodMirror> mirrorMap) {
  mirrorMap.forEach( (String mirrorName, MethodMirror mirror) {
    String category = mirror.isSetter ? "setters" : 
        mirror.isGetter ? "getters" :
        mirror.isConstructor ? "constructors" : 
        mirror.isTopLevel ? "functions" : "methods";
    
    if (data[category] == null) {
      data[category] = new Map();
    }
    data[category][mirrorName] = new Map();
    data[category][mirrorName]["operator"] = mirror.isOperator;
    data[category][mirrorName]["static"] = mirror.isStatic;
    data[category][mirrorName]["rtype"] = mirror.returnType;
    data[category][mirrorName]["parameters"] = new Map();
    List parameters = mirror.parameters;
    parameters.forEach( (ParameterMirror param) {
      String pName = param.simpleName;
      data[category][mirrorName]
        ["parameters"][pName] = new Map();
      data[category][mirrorName]
        ["parameters"][pName]["optional"] = param.isOptional;
      data[category][mirrorName]
        ["parameters"][pName]["default"] = param.defaultValue;
      data[category][mirrorName]
        ["parameters"][pName]["type"] = param.type.toString();
    });  
    String comment = _getComment(mirror);
    data[category][mirrorName]["comment"] = 
        comment != null ? comment.trim() : null;
  });
}

/**
 * Writes documentation for a library to a file.
 */
//TODO(tmandel): Use flags to put files in specific directory if supported.
void _writeToFile(String text, String filename) {
  File file = new File(filename);
  if (!file.exists()) {
    file.createSync();
  }
  file.openSync();
  file.writeAsString(text);
}