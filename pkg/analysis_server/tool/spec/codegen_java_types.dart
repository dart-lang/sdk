// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "AnalysisServer.java".
 */
library java.generator.types;

import 'api.dart';
import 'codegen_java.dart';
import 'codegen_tools.dart';
import 'from_html.dart';


/**
 * Type references in the spec that are named something else in Java.
 */
const Map<String, String> _typeRenames = const {
  'Override': 'OverrideMember',
};

class CodegenJavaType extends CodegenJavaVisitor {

  String className;
  TypeDefinition typeDef;

  CodegenJavaType(Api api, String className)
      : super(api),
        this.className = className;

  @override
  void visitTypeDefinition(TypeDefinition typeDef) {
    outputHeader(javaStyle: true);
    writeln('package com.google.dart.server.generated.types;');
    writeln();
    // Currently non TypeObjects aren't being passed this visitor, but it may soon to generate enums or classes
    // that hold onto the values of a particular enum from the spec.
    if (typeDef.type is TypeObject) {
      writeln('import java.util.Arrays;');
      writeln('import java.util.List;');
      writeln('import java.util.Map;');
      writeln('import com.google.dart.server.utilities.general.ObjectUtilities;');
      writeln('import org.apache.commons.lang3.StringUtils;');
      writeln();
      javadocComment(toHtmlVisitor.collectHtml(() {
        toHtmlVisitor.translateHtml(typeDef.html);
        toHtmlVisitor.br();
        toHtmlVisitor.write('@coverage dart.server.generated.types');
      }));
      writeln('@SuppressWarnings("unused")');
      makeClass('public class ${className}', () {
        TypeObject type = typeDef.type as TypeObject;
        List<TypeObjectField> fields = type.fields;
        // TODO (jwren) we need to possibly remove fields such as "type" in
        // these objects: AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay
        // TODO (jwren) In this case, we don't want to sort the ordering of the
        // fields, the order from the spec would be better.
        //
        // fields
        //
        for (TypeObjectField field in fields) {
          privateField(javaName(field.name), () {
            javadocComment(toHtmlVisitor.collectHtml(() {
              toHtmlVisitor.translateHtml(field.html);
            }));
            writeln('private final ${javaType(field.type)} ${javaName(field.name)};');
          });
        }
        //
        // constructor
        //
        constructor(className, () {
          javadocComment(toHtmlVisitor.collectHtml(() {
            toHtmlVisitor.write('Constructor for {@link ${className}}.');
          }));
          write('public ${className}(');
          // write out parameters to constructor
          List<String> parameters = new List();
          for (TypeObjectField field in fields) {
            parameters.add('${javaType(field.type)} ${javaName(field.name)}');
          }
          write(parameters.join(', '));
          writeln(') {');
          // write out the assignments in the body of the constructor
          for (TypeObjectField field in fields) {
            writeln('  this.${javaName(field.name)} = ${javaName(field.name)};');
          }
          writeln('}');
        });
        //
        // getter methods
        //
        for (TypeObjectField field in fields) {
          publicMethod('get${javaName(field.name)}', () {
            javadocComment(toHtmlVisitor.collectHtml(() {
              toHtmlVisitor.translateHtml(field.html);
            }));
            writeln('public ${javaType(field.type)} get${capitalize(javaName(field.name))}() {');
            writeln('  return ${javaName(field.name)};');
            writeln('}');
          });
        }
        //
        // equals method
        //
        publicMethod('equals', () {
          writeln('@Override');
          writeln('public boolean equals(Object obj) {');
          indent(() {
            writeln('if (obj instanceof ${className}) {');
            indent(() {
              writeln('${className} other = (${className}) obj;');
              writeln('return');
              indent(() {
                List<String> equalsForField = new List<String>();
                for (TypeObjectField field in fields) {
                  equalsForField.add(_equalsLogicForField(field, 'other'));
                }
                write(equalsForField.join(' && \n'));
              });
              writeln(';');
            });
            writeln('}');
            writeln('return false;');
          });
          writeln('}');
        });
        //
        // hashCode
        //
        // TODO (jwren) have hashCode written out
        //
        // toString
        //
        publicMethod('toString', () {
          writeln('@Override');
          writeln('public String toString() {');
          indent(() {
            writeln('StringBuilder builder = new StringBuilder();');
            writeln('builder.append(\"[\");');
            for (TypeObjectField field in fields) {
              // TODO (jwren) nit: don't print the last ", "
              writeln("builder.append(\"${javaName(field.name)}=\");");
              writeln("builder.append(${_toStringForField(field)} + \", \");");
            }
            writeln('builder.append(\"]\");');
            writeln('return builder.toString();');
          });
          writeln('}');
          writeln();
        });
      });
    }
  }

  String _equalsLogicForField(TypeObjectField field, String other) {
    String name = javaName(field.name);
    if (isPrimitive(field.type)) {
      return 'other.${name} == ${name}';
    } else if (isArray(field.type)) {
      return 'Arrays.equals(other.${name}, ${name})';
    } else {
      return 'ObjectUtilities.equals(other.${name}, ${name})';
    }
  }

  String _toStringForField(TypeObjectField field) {
    // TODO (jwren) if the field is a type String, we don't need to append
    // ".toString()"
    String name = javaName(field.name);
    if (isPrimitive(field.type)) {
      return name;
    } else if (isArray(field.type) || isList(field.type)) {
      return 'StringUtils.join(${name}, ", ")';
    } else {
      return '${name}.toString()';
    }
  }

  /**
   * Get the name of the consumer class for responses to this request.
   */
  String consumerName(Request request) {
    return camelJoin([request.method, 'consumer'], doCapitalize: true);
  }
}

final String pathToGenTypes = '../../../../editor/tools/plugins/com.google.dart.server/src/com/google/dart/server/generated/types/';

final GeneratedDirectory targetDir = new GeneratedDirectory(pathToGenTypes, () {
  Api api = readApi();
  Map<String, FileContentsComputer> map = new Map<String, FileContentsComputer>();
  for (String typeNameInSpec in api.types.keys) {
    TypeDefinition typeDef = api.types[typeNameInSpec];
    if (typeDef.type is TypeObject) {
      // for situations such as 'Override' where the name in the spec doesn't match the java object that we generate:
      String typeNameInJava = typeNameInSpec;
      if (_typeRenames.containsKey(typeNameInSpec)) {
        typeNameInJava = _typeRenames[typeNameInSpec];
      }
      map['${typeNameInJava}.java'] = () {
        // create the visitor
        CodegenJavaType visitor = new CodegenJavaType(api, typeNameInJava);
        return visitor.collectCode(() {visitor.visitTypeDefinition(typeDef);});
      };
    }
  }
  return map;
});

/**
 * Translate spec_input.html into AnalysisServer.java.
 */
main() {
  targetDir.generate();
}
