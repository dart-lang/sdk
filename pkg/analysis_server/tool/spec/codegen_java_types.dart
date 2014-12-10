// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "AnalysisServer.java".
 */
library java.generator.types;

import 'package:html5lib/dom.dart' as dom;

import 'api.dart';
import 'codegen_java.dart';
import 'codegen_tools.dart';
import 'from_html.dart';
import 'implied_types.dart';

final String pathToGenTypes =
    '../../../../editor/tools/plugins/com.google.dart.server/src/com/google/dart/server/generated/types/';

final GeneratedDirectory targetDir = new GeneratedDirectory(pathToGenTypes, () {
  Api api = readApi();
  Map<String, ImpliedType> impliedTypes = computeImpliedTypes(api);
  Map<String, FileContentsComputer> map =
      new Map<String, FileContentsComputer>();
  for (ImpliedType impliedType in impliedTypes.values) {
    String typeNameInSpec = capitalize(impliedType.camelName);
    bool isRefactoringFeedback = impliedType.kind == 'refactoringFeedback';
    bool isRefactoringOption = impliedType.kind == 'refactoringOptions';
    if (impliedType.kind == 'typeDefinition' ||
        isRefactoringFeedback ||
        isRefactoringOption) {
      TypeDecl type = impliedType.type;
      if (type is TypeObject || type is TypeEnum) {
        // This is for situations such as 'Override' where the name in the spec
        // doesn't match the java object that we generate:
        String typeNameInJava = typeNameInSpec;
        if (_typeRenames.containsKey(typeNameInSpec)) {
          typeNameInJava = _typeRenames[typeNameInSpec];
        }
        map['${typeNameInJava}.java'] = () {
          String superclassName = null;
          if (isRefactoringFeedback) {
            superclassName = 'RefactoringFeedback';
          }
          if (isRefactoringOption) {
            superclassName = 'RefactoringOptions';
          }
          // configure accessors
          bool generateGetters = true;
          bool generateSetters = false;
          if (isRefactoringOption ||
              typeNameInSpec == 'RefactoringMethodParameter') {
            generateSetters = true;
          }
          // create the visitor
          CodegenJavaType visitor = new CodegenJavaType(
              api,
              typeNameInJava,
              superclassName,
              generateGetters,
              generateSetters);
          return visitor.collectCode(() {
            dom.Element doc = type.html;
            if (impliedType.apiNode is TypeDefinition) {
              doc = (impliedType.apiNode as TypeDefinition).html;
            }
            visitor.emitType(type, doc);
          });
        };
      }
    }
  }
  return map;
});

/**
 * A map between the field names and values for the Element object such as:
 *
 * private static final int ABSTRACT = 0x01;
 */
const Map<String, String> _extraFieldsOnElement = const {
  'ABSTRACT': '0x01',
  'CONST': '0x02',
  'FINAL': '0x04',
  'TOP_LEVEL_STATIC': '0x08',
  'PRIVATE': '0x10',
  'DEPRECATED': '0x20',
};

/**
 * A map between the method names and field names to generate additional methods on the Element object:
 *
 * public boolean isFinal() {
 *   return (flags & FINAL) != 0;
 * }
 */
const Map<String, String> _extraMethodsOnElement = const {
  'isAbstract': 'ABSTRACT',
  'isConst': 'CONST',
  'isDeprecated': 'DEPRECATED',
  'isFinal': 'FINAL',
  'isPrivate': 'PRIVATE',
  'isTopLevelOrStatic': 'TOP_LEVEL_STATIC',
};

/**
 * Type references in the spec that are named something else in Java.
 */
const Map<String, String> _typeRenames = const {
  'Override': 'OverrideMember',
};

/**
 * Translate spec_input.html into AnalysisServer.java.
 */
main() {
  targetDir.generate();
}

class CodegenJavaType extends CodegenJavaVisitor {
  final String className;
  final String superclassName;
  final bool generateGetters;
  final bool generateSetters;

  CodegenJavaType(Api api, this.className, this.superclassName,
      this.generateGetters, this.generateSetters)
      : super(api);

  /**
   * Get the name of the consumer class for responses to this request.
   */
  String consumerName(Request request) {
    return camelJoin([request.method, 'consumer'], doCapitalize: true);
  }

  void emitType(TypeDecl type, dom.Element html) {
    outputHeader(javaStyle: true);
    writeln('package com.google.dart.server.generated.types;');
    writeln();
    if (type is TypeObject) {
      _writeTypeObject(type, html);
    } else if (type is TypeEnum) {
      _writeTypeEnum(type, html);
    }
  }

  String _getAsTypeMethodName(TypeDecl typeDecl) {
    String name = javaType(typeDecl, true);
    if (name == 'String') {
      return 'getAsString';
    } else if (name == 'boolean' || name == 'Boolean') {
      return 'getAsBoolean';
    } else if (name == 'int' || name == 'Integer') {
      return 'getAsInt';
    } else if (name == 'long' || name == 'Long') {
      return 'getAsLong';
    } else if (name.startsWith('List')) {
      return 'getAsJsonArray';
    } else {
      // TODO (jwren) cleanup
      return 'getAsJsonArray';
    }
  }

  String _getEqualsLogicForField(TypeObjectField field, String other) {
    String name = javaName(field.name);
    if (isPrimitive(field.type) && !field.optional) {
      return '${other}.${name} == ${name}';
    } else if (isArray(field.type)) {
      return 'Arrays.equals(other.${name}, ${name})';
    } else {
      return 'ObjectUtilities.equals(${other}.${name}, ${name})';
    }
  }

  /**
   * For some [TypeObjectField] return the [String] source for the field value
   * for the toString generation.
   */
  String _getToStringForField(TypeObjectField field) {
    String name = javaName(field.name);
    if (isArray(field.type) || isList(field.type)) {
      return 'StringUtils.join(${name}, ", ")';
    } else {
      return name;
    }
  }

  bool _isTypeFieldInUpdateContentUnionType(String className,
      String fieldName) {
    if ((className == 'AddContentOverlay' ||
        className == 'ChangeContentOverlay' ||
        className == 'RemoveContentOverlay') &&
        fieldName == 'type') {
      return true;
    } else {
      return false;
    }
  }

  /**
   * This method writes extra fields and methods to the Element type.
   */
  void _writeExtraContentInElementType() {
    //
    // Extra fields on the Element type such as:
    // private static final int ABSTRACT = 0x01;
    //
    _extraFieldsOnElement.forEach((String name, String value) {
      publicField(javaName(name), () {
        writeln('private static final int ${name} = ${value};');
      });
    });

    //
    // Extra methods for the Element type such as:
    // public boolean isFinal() {
    //   return (flags & FINAL) != 0;
    // }
    //
    _extraMethodsOnElement.forEach((String methodName, String fieldName) {
      publicMethod(methodName, () {
        writeln('public boolean ${methodName}() {');
        writeln('  return (flags & ${fieldName}) != 0;');
        writeln('}');
      });
    });
  }

  /**
   * For some [TypeObjectField] write out the source that adds the field
   * information to the 'jsonObject'.
   */
  void _writeOutJsonObjectAddStatement(TypeObjectField field) {
    String name = javaName(field.name);
    if (isDeclaredInSpec(field.type)) {
      writeln('jsonObject.add("${name}", ${name}.toJson());');
    } else if (field.type is TypeList) {
      TypeDecl listItemType = (field.type as TypeList).itemType;
      String jsonArrayName = 'jsonArray${capitalize(name)}';
      writeln('JsonArray ${jsonArrayName} = new JsonArray();');
      writeln('for (${javaType(listItemType)} elt : ${name}) {');
      indent(() {
        if (isDeclaredInSpec(listItemType)) {
          writeln('${jsonArrayName}.add(elt.toJson());');
        } else {
          writeln('${jsonArrayName}.add(new JsonPrimitive(elt));');
        }
      });
      writeln('}');
      writeln('jsonObject.add("${name}", ${jsonArrayName});');
    } else {
      writeln('jsonObject.addProperty("${name}", ${name});');
    }
  }

  void _writeTypeEnum(TypeDecl type, dom.Element html) {
    javadocComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.translateHtml(html);
      toHtmlVisitor.br();
      toHtmlVisitor.write('@coverage dart.server.generated.types');
    }));
    makeClass('public class ${className}', () {
      TypeEnum typeEnum = type as TypeEnum;
      List<TypeEnumValue> values = typeEnum.values;
      //
      // enum fields
      //
      for (TypeEnumValue value in values) {
        privateField(javaName(value.value), () {
          javadocComment(toHtmlVisitor.collectHtml(() {
            toHtmlVisitor.translateHtml(value.html);
          }));
          writeln(
              'public static final String ${value.value} = \"${value.value}\";');
        });
      }
    });
  }

  void _writeTypeObject(TypeDecl type, dom.Element html) {
    writeln('import java.util.Arrays;');
    writeln('import java.util.List;');
    writeln('import java.util.Map;');
    writeln('import com.google.common.collect.Lists;');
    writeln('import com.google.dart.server.utilities.general.JsonUtilities;');
    writeln('import com.google.dart.server.utilities.general.ObjectUtilities;');
    writeln('import com.google.gson.JsonArray;');
    writeln('import com.google.gson.JsonElement;');
    writeln('import com.google.gson.JsonObject;');
    writeln('import com.google.gson.JsonPrimitive;');
    writeln('import org.apache.commons.lang3.builder.HashCodeBuilder;');
    writeln('import java.util.ArrayList;');
    writeln('import java.util.Iterator;');
    writeln('import org.apache.commons.lang3.StringUtils;');
    writeln();
    javadocComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.translateHtml(html);
      toHtmlVisitor.br();
      toHtmlVisitor.write('@coverage dart.server.generated.types');
    }));
    writeln('@SuppressWarnings("unused")');
    String header = 'public class ${className}';
    if (superclassName != null) {
      header += ' extends $superclassName';
    }
    makeClass(header, () {
      //
      // fields
      //
      //
      // public static final "EMPTY_ARRAY" field
      //
      publicField(javaName("EMPTY_ARRAY"), () {
        writeln(
            'public static final ${className}[] EMPTY_ARRAY = new ${className}[0];');
      });

      //
      // public static final "EMPTY_LIST" field
      //
      publicField(javaName("EMPTY_LIST"), () {
        writeln(
            'public static final List<${className}> EMPTY_LIST = Lists.newArrayList();');
      });

      //
      // "private static String name;" fields:
      //
      TypeObject typeObject = type as TypeObject;
      List<TypeObjectField> fields = typeObject.fields;
      for (TypeObjectField field in fields) {
        String type = javaFieldType(field);
        String name = javaName(field.name);
        if (!(className == 'Outline' && name == 'children')) {
          privateField(name, () {
            javadocComment(toHtmlVisitor.collectHtml(() {
              toHtmlVisitor.translateHtml(field.html);
            }));
            if (generateSetters) {
              writeln('private $type $name;');
            } else {
              writeln('private final $type $name;');
            }
          });
        }
      }
      if (className == 'Outline') {
        privateField(javaName('parent'), () {
          writeln('private final Outline parent;');
        });
        privateField(javaName('children'), () {
          writeln('private List<Outline> children;');
        });
      }
      if (className == 'NavigationRegion') {
        privateField(javaName('targetObjects'), () {
          writeln('private final List<NavigationTarget> targetObjects = Lists.newArrayList();');
        });
      }
      if (className == 'NavigationTarget') {
        privateField(javaName('file'), () {
          writeln('private String file;');
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
        if (className == 'Outline') {
          parameters.add('Outline parent');
        }
        for (TypeObjectField field in fields) {
          String type = javaFieldType(field);
          String name = javaName(field.name);
          if (!_isTypeFieldInUpdateContentUnionType(className, field.name) &&
              !(className == 'Outline' && name == 'children')) {
            parameters.add('$type $name');
          }
        }
        write(parameters.join(', '));
        writeln(') {');
        // write out the assignments in the body of the constructor
        indent(() {
          if (className == 'Outline') {
            writeln('this.parent = parent;');
          }
          for (TypeObjectField field in fields) {
            String name = javaName(field.name);
            if (!_isTypeFieldInUpdateContentUnionType(className, field.name) &&
                !(className == 'Outline' && name == 'children')) {
              writeln('this.$name = $name;');
            } else if (className == 'AddContentOverlay') {
              writeln('this.type = "add";');
            } else if (className == 'ChangeContentOverlay') {
              writeln('this.type = "change";');
            } else if (className == 'RemoveContentOverlay') {
              writeln('this.type = "remove";');
            }
          }
        });
        writeln('}');
      });

      //
      // getter methods
      //
      if (generateGetters) {
        for (TypeObjectField field in fields) {
          String type = javaFieldType(field);
          String name = javaName(field.name);
          publicMethod('get$name', () {
            javadocComment(toHtmlVisitor.collectHtml(() {
              toHtmlVisitor.translateHtml(field.html);
            }));
            if (type == 'boolean') {
              writeln('public $type $name() {');
            } else {
              writeln('public $type get${capitalize(name)}() {');
            }
            writeln('  return $name;');
            writeln('}');
          });
        }
      }

      //
      // setter methods
      //
      if (generateSetters) {
        for (TypeObjectField field in fields) {
          String type = javaFieldType(field);
          String name = javaName(field.name);
          publicMethod('set$name', () {
            javadocComment(toHtmlVisitor.collectHtml(() {
              toHtmlVisitor.translateHtml(field.html);
            }));
            String setterName = 'set' + capitalize(name);
            writeln('public void $setterName($type $name) {');
            writeln('  this.$name = $name;');
            writeln('}');
          });
        }
      }

      if (className == 'NavigationRegion') {
        publicMethod('lookupTargets', () {
          writeln('public void lookupTargets(List<NavigationTarget> allTargets) {');
          writeln('  for (int i = 0; i < targets.length; i++) {');
          writeln('    int targetIndex = targets[i];');
          writeln('    NavigationTarget target = allTargets.get(targetIndex);');
          writeln('    targetObjects.add(target);');
          writeln('  }');
          writeln('}');
        });
        publicMethod('getTargetObjects', () {
          writeln('public List<NavigationTarget> getTargetObjects() {');
          writeln('  return targetObjects;');
          writeln('}');
        });
      }
      if (className == 'NavigationTarget') {
        publicMethod('lookupFile', () {
          writeln('public void lookupFile(String[] allTargetFiles) {');
          writeln('  file = allTargetFiles[fileIndex];');
          writeln('}');
        });
        publicMethod('getFile', () {
          writeln('public String getFile() {');
          writeln('  return file;');
          writeln('}');
        });
      }

      //
      // fromJson(JsonObject) factory constructor, example:
//      public JsonObject toJson(JsonObject jsonObject) {
//          String x = jsonObject.get("x").getAsString();
//          return new Y(x);
//        }
      if (className != 'Outline') {
        publicMethod('fromJson', () {
          writeln(
              'public static ${className} fromJson(JsonObject jsonObject) {');
          indent(() {
            for (TypeObjectField field in fields) {
              write('${javaFieldType(field)} ${javaName(field.name)} = ');
              if (field.optional) {
                write(
                    'jsonObject.get("${javaName(field.name)}") == null ? null : ');
              }
              if (isDeclaredInSpec(field.type)) {
                write('${javaFieldType(field)}.fromJson(');
                write(
                    'jsonObject.get("${javaName(field.name)}").getAsJsonObject())');
              } else {
                if (isList(field.type)) {
                  if (javaFieldType(field).endsWith('<String>')) {
                    write(
                        'JsonUtilities.decodeStringList(jsonObject.get("${javaName(field.name)}").${_getAsTypeMethodName(field.type)}())');
                  } else {
                    write(
                        '${javaType((field.type as TypeList).itemType)}.fromJsonArray(jsonObject.get("${javaName(field.name)}").${_getAsTypeMethodName(field.type)}())');
                  }
                } else if (isArray(field.type)) {
                  if (javaFieldType(field).startsWith('int')) {
                    write(
                        'JsonUtilities.decodeIntArray(jsonObject.get("${javaName(field.name)}").${_getAsTypeMethodName(field.type)}())');
                  }
                } else {
                  write(
                      'jsonObject.get("${javaName(field.name)}").${_getAsTypeMethodName(field.type)}()');
                }
              }
              writeln(';');
            }
            write('return new ${className}(');
            List<String> parameters = new List();
            for (TypeObjectField field in fields) {
              if (!_isTypeFieldInUpdateContentUnionType(
                  className,
                  field.name)) {
                parameters.add('${javaName(field.name)}');
              }
            }
            write(parameters.join(', '));
            writeln(');');
          });
          writeln('}');
        });
      } else {
        publicMethod('fromJson', () {
          writeln(
              '''public static Outline fromJson(Outline parent, JsonObject outlineObject) {
  JsonObject elementObject = outlineObject.get("element").getAsJsonObject();
  Element element = Element.fromJson(elementObject);
  int offset = outlineObject.get("offset").getAsInt();
  int length = outlineObject.get("length").getAsInt();

  // create outline object
  Outline outline = new Outline(parent, element, offset, length);

  // compute children recursively
  List<Outline> childrenList = Lists.newArrayList();
  JsonElement childrenJsonArray = outlineObject.get("children");
  if (childrenJsonArray instanceof JsonArray) {
    Iterator<JsonElement> childrenElementIterator = ((JsonArray) childrenJsonArray).iterator();
    while (childrenElementIterator.hasNext()) {
      JsonObject childObject = childrenElementIterator.next().getAsJsonObject();
      childrenList.add(fromJson(outline, childObject));
    }
  }
  outline.setChildren(childrenList);
  return outline;
}''');
        });
        publicMethod('setChildren', () {
          writeln('''public void setChildren(List<Outline> children) {
  this.children = children;
}''');
        });
        publicMethod('getParent', () {
          writeln('''public Outline getParent() {
  return parent;
}''');
        });
      }

      //
      // fromJson(JsonArray) factory constructor
      //
      if (className != 'Outline' &&
          className != 'RefactoringFeedback' &&
          className != 'RefactoringOptions') {
        publicMethod('fromJsonArray', () {
          writeln(
              'public static List<${className}> fromJsonArray(JsonArray jsonArray) {');
          indent(() {
            writeln('if (jsonArray == null) {');
            writeln('  return EMPTY_LIST;');
            writeln('}');
            writeln(
                'ArrayList<${className}> list = new ArrayList<${className}>(jsonArray.size());');
            writeln('Iterator<JsonElement> iterator = jsonArray.iterator();');
            writeln('while (iterator.hasNext()) {');
            writeln('  list.add(fromJson(iterator.next().getAsJsonObject()));');
            writeln('}');
            writeln('return list;');
          });
          writeln('}');
        });
      }

      //
      // toJson() method, example:
//      public JsonObject toJson() {
//          JsonObject jsonObject = new JsonObject();
//          jsonObject.addProperty("x", x);
//          jsonObject.addProperty("y", y);
//          return jsonObject;
//        }
      if (className != 'Outline') {
        publicMethod('toJson', () {
          writeln('public JsonObject toJson() {');
          indent(() {
            writeln('JsonObject jsonObject = new JsonObject();');
            for (TypeObjectField field in fields) {
              if (!isObject(field.type)) {
                if (field.optional) {
                  writeln('if (${javaName(field.name)} != null) {');
                  indent(() {
                    _writeOutJsonObjectAddStatement(field);
                  });
                  writeln('}');
                } else {
                  _writeOutJsonObjectAddStatement(field);
                }
              }
            }
            writeln('return jsonObject;');
          });
          writeln('}');
        });
      }

      //
      // equals() method
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
                equalsForField.add(_getEqualsLogicForField(field, 'other'));
              }
              if (equalsForField.isNotEmpty) {
                write(equalsForField.join(' && \n'));
              } else {
                write('true');
              }
            });
            writeln(';');
          });
          writeln('}');
          writeln('return false;');
        });
        writeln('}');
      });

      //
      // containsInclusive(int x)
      //
      if (className == 'HighlightRegion' ||
          className == 'NavigationRegion' ||
          className == 'Outline') {
        publicMethod('containsInclusive', () {
          writeln('public boolean containsInclusive(int x) {');
          indent(() {
            writeln('return offset <= x && x <= offset + length;');
          });
          writeln('}');
        });
      }

      //
      // contains(int x)
      //
      if (className == 'Occurrences') {
        publicMethod('contains', () {
          writeln('public boolean contains(int x) {');
          indent(() {
            writeln('for (int offset : offsets) {');
            writeln('  if (offset <= x && x < offset + length) {');
            writeln('    return true;');
            writeln('  }');
            writeln('}');
            writeln('return false;');
          });
          writeln('}');
        });
      }

      //
      // hashCode
      //
      publicMethod('hashCode', () {
        writeln('@Override');
        writeln('public int hashCode() {');
        indent(() {
          writeln('HashCodeBuilder builder = new HashCodeBuilder();');
          for (int i = 0; i < fields.length; i++) {
            writeln("builder.append(${javaName(fields[i].name)});");
          }
          writeln('return builder.toHashCode();');
        });
        writeln('}');
      });

      //
      // toString
      //
      publicMethod('toString', () {
        writeln('@Override');
        writeln('public String toString() {');
        indent(() {
          writeln('StringBuilder builder = new StringBuilder();');
          writeln('builder.append(\"[\");');
          for (int i = 0; i < fields.length; i++) {
            writeln("builder.append(\"${javaName(fields[i].name)}=\");");
            write("builder.append(${_getToStringForField(fields[i])}");
            if (i + 1 != fields.length) {
              // this is not the last field
              write(' + \", \"');
            }
            writeln(');');
          }
          writeln('builder.append(\"]\");');
          writeln('return builder.toString();');
        });
        writeln('}');
      });

      if (className == 'Element') {
        _writeExtraContentInElementType();
      }

      //
      // getBestName()
      //
      if (className == 'TypeHierarchyItem') {
        publicMethod('getBestName', () {
          writeln('public String getBestName() {');
          indent(() {
            writeln('if (displayName == null) {');
            writeln('  return classElement.getName();');
            writeln('} else {');
            writeln('  return displayName;');
            writeln('}');
          });
          writeln('}');
        });
      }

    });
  }
}
