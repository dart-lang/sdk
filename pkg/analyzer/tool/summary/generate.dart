// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file contains code to generate serialization/deserialization logic for
 * summaries based on an "IDL" description of the summary format (written in
 * stylized Dart).
 *
 * For each class in the "IDL" input, two corresponding classes are generated:
 * - A class with the same name which represents deserialized summary data in
 *   memory.  This class has read-only semantics.
 * - A "builder" class which can be used to generate serialized summary data.
 *   This class has write-only semantics.
 *
 * Each of the "builder" classes has a single `finish` method which writes
 * the entity being built into the given FlatBuffer and returns the `Offset`
 * reference to it.
 */
library analyzer.tool.summary.generate;

import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/codegen/tools.dart';
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/scanner/token.dart' show Token;
import 'package:path/path.dart';

import 'idl_model.dart' as idlModel;
import 'mini_ast.dart';

main() async {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = normalize(join(dirname(script), '..', '..'));
  await GeneratedContent.generateAll(pkgPath, allTargets);
}

final List<GeneratedContent> allTargets = <GeneratedContent>[
  formatTarget,
  schemaTarget
];

final GeneratedFile formatTarget =
    new GeneratedFile('lib/src/summary/format.dart', (String pkgPath) async {
  _CodeGenerator codeGenerator = new _CodeGenerator(pkgPath);
  codeGenerator.generateFormatCode();
  return codeGenerator._outBuffer.toString();
});

final GeneratedFile schemaTarget =
    new GeneratedFile('lib/src/summary/format.fbs', (String pkgPath) async {
  _CodeGenerator codeGenerator = new _CodeGenerator(pkgPath);
  codeGenerator.generateFlatBufferSchema();
  return codeGenerator._outBuffer.toString();
});

typedef String _StringToString(String s);

class _CodeGenerator {
  static const String _throwDeprecated =
      "throw new UnimplementedError('attempt to access deprecated field')";

  /**
   * Buffer in which generated code is accumulated.
   */
  final StringBuffer _outBuffer = new StringBuffer();

  /**
   * Current indentation level.
   */
  String _indentation = '';

  /**
   * Semantic model of the "IDL" input file.
   */
  idlModel.Idl _idl;

  _CodeGenerator(String pkgPath) {
    // Parse the input "IDL" file.
    String idlPath = join(pkgPath, 'lib', 'src', 'summary', 'idl.dart');
    File idlFile = new File(idlPath);
    String idlText =
        idlFile.readAsStringSync().replaceAll(new RegExp('\r\n?'), '\n');
    // Extract a description of the IDL and make sure it is valid.
    var scanner = new StringScanner(idlText, includeComments: true);
    var startingToken = scanner.tokenize();
    var listener = new MiniAstBuilder();
    var parser = new MiniAstParser(listener);
    parser.parseUnit(startingToken);
    extractIdl(listener.compilationUnit);
    checkIdl();
  }

  /**
   * Perform basic sanity checking of the IDL (over and above that done by
   * [extractIdl]).
   */
  void checkIdl() {
    _idl.classes.forEach((String name, idlModel.ClassDeclaration cls) {
      if (cls.fileIdentifier != null) {
        if (cls.fileIdentifier.length != 4) {
          throw new Exception('$name: file identifier must be 4 characters');
        }
        for (int i = 0; i < cls.fileIdentifier.length; i++) {
          if (cls.fileIdentifier.codeUnitAt(i) >= 256) {
            throw new Exception(
                '$name: file identifier must be encodable as Latin-1');
          }
        }
      }
      Map<int, String> idsUsed = <int, String>{};
      for (idlModel.FieldDeclaration field in cls.allFields) {
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        if (type.isList) {
          if (_idl.classes.containsKey(type.typeName)) {
            // List of classes is ok
          } else if (_idl.enums.containsKey(type.typeName)) {
            // List of enums is ok
          } else if (type.typeName == 'bool') {
            // List of booleans is ok
          } else if (type.typeName == 'int') {
            // List of ints is ok
          } else if (type.typeName == 'double') {
            // List of doubles is ok
          } else if (type.typeName == 'String') {
            // List of strings is ok
          } else {
            throw new Exception(
                '$name.$fieldName: illegal type (list of ${type.typeName})');
          }
        }
        if (idsUsed.containsKey(field.id)) {
          throw new Exception('$name.$fieldName: id ${field.id} already used by'
              ' ${idsUsed[field.id]}');
        }
        idsUsed[field.id] = fieldName;
      }
      for (int i = 0; i < idsUsed.length; i++) {
        if (!idsUsed.containsKey(i)) {
          throw new Exception('$name: no field uses id $i');
        }
      }
    });
  }

  /**
   * Generate a string representing the Dart type which should be used to
   * represent [type] when deserialized.
   */
  String dartType(idlModel.FieldType type) {
    String baseType = idlPrefix(type.typeName);
    if (type.isList) {
      return 'List<$baseType>';
    } else {
      return baseType;
    }
  }

  /**
   * Generate a Dart expression representing the default value for a field
   * having the given [type], or `null` if there is no default value.
   *
   * If [builder] is `true`, the returned type should be appropriate for use in
   * a builder class.
   */
  String defaultValue(idlModel.FieldType type, bool builder) {
    if (type.isList) {
      if (builder) {
        idlModel.FieldType elementType =
            new idlModel.FieldType(type.typeName, false);
        return '<${encodedType(elementType)}>[]';
      } else {
        return 'const <${idlPrefix(type.typeName)}>[]';
      }
    } else if (_idl.enums.containsKey(type.typeName)) {
      return '${idlPrefix(type.typeName)}.'
          '${_idl.enums[type.typeName].values[0].name}';
    } else if (type.typeName == 'int') {
      return '0';
    } else if (type.typeName == 'String') {
      return "''";
    } else if (type.typeName == 'bool') {
      return 'false';
    } else {
      return null;
    }
  }

  /**
   * Generate a string representing the Dart type which should be used to
   * represent [type] while building a serialized data structure.
   */
  String encodedType(idlModel.FieldType type) {
    String typeStr;
    if (_idl.classes.containsKey(type.typeName)) {
      typeStr = '${type.typeName}Builder';
    } else {
      typeStr = idlPrefix(type.typeName);
    }
    if (type.isList) {
      return 'List<$typeStr>';
    } else {
      return typeStr;
    }
  }

  /**
   * Process the AST in [idlParsed] and store the resulting semantic model in
   * [_idl].  Also perform some error checking.
   */
  void extractIdl(CompilationUnit idlParsed) {
    _idl = new idlModel.Idl();
    for (CompilationUnitMember decl in idlParsed.declarations) {
      if (decl is ClassDeclaration) {
        bool isTopLevel = false;
        String fileIdentifier;
        String clsName = decl.name;
        for (Annotation annotation in decl.metadata) {
          if (annotation.arguments != null &&
              annotation.name == 'TopLevel' &&
              annotation.constructorName == null) {
            isTopLevel = true;
            if (annotation.arguments == null) {
              throw new Exception(
                  'Class `$clsName`: TopLevel requires parenthesis');
            }
            if (annotation.constructorName != null) {
              throw new Exception(
                  "Class `$clsName`: TopLevel doesn't have named constructors");
            }
            if (annotation.arguments.length == 1) {
              Expression arg = annotation.arguments[0];
              if (arg is StringLiteral) {
                fileIdentifier = arg.stringValue;
              } else {
                throw new Exception(
                    'Class `$clsName`: TopLevel argument must be a string'
                    ' literal');
              }
            } else if (annotation.arguments.length != 0) {
              throw new Exception(
                  'Class `$clsName`: TopLevel requires 0 or 1 arguments');
            }
          }
        }
        String doc = _getNodeDoc(decl);
        idlModel.ClassDeclaration cls = new idlModel.ClassDeclaration(
            doc, clsName, isTopLevel, fileIdentifier);
        _idl.classes[clsName] = cls;
        String expectedBase = 'base.SummaryClass';
        if (decl.superclass == null || decl.superclass.name != expectedBase) {
          throw new Exception(
              'Class `$clsName` needs to extend `$expectedBase`');
        }
        for (ClassMember classMember in decl.members) {
          if (classMember is MethodDeclaration && classMember.isGetter) {
            String desc = '$clsName.${classMember.name}';
            if (classMember.returnType == null) {
              throw new Exception('Class member needs a type: $desc');
            }
            TypeName type = classMember.returnType;
            bool isList = false;
            if (type.name == 'List' &&
                type.typeArguments != null &&
                type.typeArguments.length == 1) {
              isList = true;
              type = type.typeArguments[0];
            }
            if (type.typeArguments != null) {
              throw new Exception('Cannot handle type arguments in `$type`');
            }
            int id;
            bool isDeprecated = false;
            bool isInformative = false;
            for (Annotation annotation in classMember.metadata) {
              if (annotation.name == 'Id') {
                if (id != null) {
                  throw new Exception(
                      'Duplicate @id annotation ($classMember)');
                }
                if (annotation.arguments == null) {
                  throw new Exception('@Id must be passed an argument');
                }
                if (annotation.arguments.length != 1) {
                  throw new Exception(
                      '@Id must be passed exactly one argument ($desc)');
                }
                Expression expression = annotation.arguments[0];
                if (expression is IntegerLiteral) {
                  id = expression.value;
                } else {
                  throw new Exception(
                      '@Id parameter must be an integer literal ($desc)');
                }
              } else if (annotation.name == 'deprecated') {
                if (annotation.arguments != null) {
                  throw new Exception('@deprecated does not take args ($desc)');
                }
                isDeprecated = true;
              } else if (annotation.name == 'informative') {
                isInformative = true;
              }
            }
            if (id == null) {
              throw new Exception('Missing @id annotation ($desc)');
            }
            String doc = _getNodeDoc(classMember);
            idlModel.FieldType fieldType =
                new idlModel.FieldType(type.name, isList);
            cls.allFields.add(new idlModel.FieldDeclaration(doc,
                classMember.name, fieldType, id, isDeprecated, isInformative));
          } else if (classMember is ConstructorDeclaration &&
              classMember.name.name.endsWith('fromBuffer')) {
            // Ignore `fromBuffer` declarations; they simply forward to the
            // read functions generated by [_generateReadFunction].
          } else {
            throw new Exception('Unexpected class member `$classMember`');
          }
        }
      } else if (decl is EnumDeclaration) {
        String doc = _getNodeDoc(decl);
        idlModel.EnumDeclaration enm =
            new idlModel.EnumDeclaration(doc, decl.name);
        _idl.enums[enm.name] = enm;
        for (EnumConstantDeclaration constDecl in decl.constants) {
          String doc = _getNodeDoc(constDecl);
          enm.values
              .add(new idlModel.EnumValueDeclaration(doc, constDecl.name));
        }
      } else {
        throw new Exception('Unexpected declaration `$decl`');
      }
    }
  }

  /**
   * Generate a string representing the FlatBuffer schema type which should be
   * used to represent [type].
   */
  String fbsType(idlModel.FieldType type) {
    String typeStr;
    switch (type.typeName) {
      case 'bool':
        typeStr = 'bool';
        break;
      case 'double':
        typeStr = 'double';
        break;
      case 'int':
        typeStr = 'uint';
        break;
      case 'String':
        typeStr = 'string';
        break;
      default:
        typeStr = type.typeName;
        break;
    }
    if (type.isList) {
      // FlatBuffers don't natively support a packed list of booleans, so we
      // treat it as a list of unsigned bytes, which is a compatible data
      // structure.
      if (typeStr == 'bool') {
        typeStr = 'ubyte';
      }
      return '[$typeStr]';
    } else {
      return typeStr;
    }
  }

  /**
   * Entry point to the code generator when generating the "format.fbs" file.
   */
  void generateFlatBufferSchema() {
    outputHeader();
    for (idlModel.EnumDeclaration enm in _idl.enums.values) {
      out();
      outDoc(enm.documentation);
      out('enum ${enm.name} : byte {');
      indent(() {
        for (int i = 0; i < enm.values.length; i++) {
          idlModel.EnumValueDeclaration value = enm.values[i];
          if (i != 0) {
            out();
          }
          String suffix = i < enm.values.length - 1 ? ',' : '';
          outDoc(value.documentation);
          out('${value.name}$suffix');
        }
      });
      out('}');
    }
    for (idlModel.ClassDeclaration cls in _idl.classes.values) {
      out();
      outDoc(cls.documentation);
      out('table ${cls.name} {');
      indent(() {
        for (int i = 0; i < cls.allFields.length; i++) {
          idlModel.FieldDeclaration field = cls.allFields[i];
          if (i != 0) {
            out();
          }
          outDoc(field.documentation);
          List<String> attributes = <String>['id: ${field.id}'];
          if (field.isDeprecated) {
            attributes.add('deprecated');
          }
          String attrText = attributes.join(', ');
          out('${field.name}:${fbsType(field.type)} ($attrText);');
        }
      });
      out('}');
    }
    out();
    // Standard flatbuffers only support one root type.  We support multiple
    // root types.  For now work around this by forcing PackageBundle to be the
    // root type.  TODO(paulberry): come up with a better solution.
    idlModel.ClassDeclaration rootType = _idl.classes['PackageBundle'];
    out('root_type ${rootType.name};');
    if (rootType.fileIdentifier != null) {
      out();
      out('file_identifier ${quoted(rootType.fileIdentifier)};');
    }
  }

  /**
   * Entry point to the code generator when generating the "format.dart" file.
   */
  void generateFormatCode() {
    outputHeader();
    out('library analyzer.src.summary.format;');
    out();
    out("import 'dart:convert' as convert;");
    out();
    out("import 'package:analyzer/src/summary/api_signature.dart' as api_sig;");
    out("import 'package:analyzer/src/summary/flat_buffers.dart' as fb;");
    out();
    out("import 'idl.dart' as idl;");
    out();
    for (idlModel.EnumDeclaration enm in _idl.enums.values) {
      _generateEnumReader(enm);
      out();
    }
    for (idlModel.ClassDeclaration cls in _idl.classes.values) {
      _generateBuilder(cls);
      out();
      if (cls.isTopLevel) {
        _generateReadFunction(cls);
        out();
      }
      _generateReader(cls);
      out();
      _generateImpl(cls);
      out();
      _generateMixin(cls);
      out();
    }
  }

  /**
   * Add the prefix `idl.` to a type name, unless that type name is the name of
   * a built-in type.
   */
  String idlPrefix(String s) {
    switch (s) {
      case 'bool':
      case 'double':
      case 'int':
      case 'String':
        return s;
      default:
        return 'idl.$s';
    }
  }

  /**
   * Execute [callback] with two spaces added to [_indentation].
   */
  void indent(void callback()) {
    String oldIndentation = _indentation;
    try {
      _indentation += '  ';
      callback();
    } finally {
      _indentation = oldIndentation;
    }
  }

  /**
   * Add the string [s] to the output as a single line, indenting as
   * appropriate.
   */
  void out([String s = '']) {
    if (s == '') {
      _outBuffer.writeln('');
    } else {
      _outBuffer.writeln('$_indentation$s');
    }
  }

  void outDoc(String documentation) {
    if (documentation != null) {
      documentation.split('\n').forEach(out);
    }
  }

  void outputHeader() {
    out('// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file');
    out('// for details. All rights reserved. Use of this source code is governed by a');
    out('// BSD-style license that can be found in the LICENSE file.');
    out('//');
    out('// This file has been automatically generated.  Please do not edit it manually.');
    out('// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".');
    out();
  }

  /**
   * Enclose [s] in quotes, escaping as necessary.
   */
  String quoted(String s) {
    return JSON.encode(s);
  }

  void _generateBuilder(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    String builderName = name + 'Builder';
    String mixinName = '_${name}Mixin';
    List<String> constructorParams = <String>[];
    out('class $builderName extends Object with $mixinName '
        'implements ${idlPrefix(name)} {');
    indent(() {
      // Generate fields.
      for (idlModel.FieldDeclaration field in cls.fields) {
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        String typeStr = encodedType(type);
        out('$typeStr _$fieldName;');
      }
      // Generate getters and setters.
      for (idlModel.FieldDeclaration field in cls.allFields) {
        String fieldName = field.name;
        idlModel.FieldType fieldType = field.type;
        String typeStr = encodedType(fieldType);
        String def = defaultValue(fieldType, true);
        String defSuffix = def == null ? '' : ' ??= $def';
        out();
        out('@override');
        if (field.isDeprecated) {
          out('$typeStr get $fieldName => $_throwDeprecated;');
        } else {
          out('$typeStr get $fieldName => _$fieldName$defSuffix;');
          out();
          outDoc(field.documentation);
          constructorParams.add('$typeStr $fieldName');
          out('void set $fieldName($typeStr value) {');
          indent(() {
            String stateFieldName = '_' + fieldName;
            // Validate that int(s) are non-negative.
            if (fieldType.typeName == 'int') {
              if (!fieldType.isList) {
                out('assert(value == null || value >= 0);');
              } else {
                out('assert(value == null || value.every((e) => e >= 0));');
              }
            }
            // Set the value.
            out('this.$stateFieldName = value;');
          });
          out('}');
        }
      }
      // Generate constructor.
      out();
      out('$builderName({${constructorParams.join(', ')}})');
      List<idlModel.FieldDeclaration> fields = cls.fields.toList();
      for (int i = 0; i < fields.length; i++) {
        idlModel.FieldDeclaration field = fields[i];
        String prefix = i == 0 ? '  : ' : '    ';
        String suffix = i == fields.length - 1 ? ';' : ',';
        out('${prefix}_${field.name} = ${field.name}$suffix');
      }
      // Generate flushInformative().
      {
        out();
        out('/**');
        out(' * Flush [informative] data recursively.');
        out(' */');
        out('void flushInformative() {');
        indent(() {
          for (idlModel.FieldDeclaration field in cls.fields) {
            idlModel.FieldType fieldType = field.type;
            String valueName = '_' + field.name;
            if (field.isInformative) {
              out('$valueName = null;');
            } else if (_idl.classes.containsKey(fieldType.typeName)) {
              if (fieldType.isList) {
                out('$valueName?.forEach((b) => b.flushInformative());');
              } else {
                out('$valueName?.flushInformative();');
              }
            }
          }
        });
        out('}');
      }
      // Generate collectApiSignature().
      {
        out();
        out('/**');
        out(' * Accumulate non-[informative] data into [signature].');
        out(' */');
        out('void collectApiSignature(api_sig.ApiSignature signature) {');
        indent(() {
          List<idlModel.FieldDeclaration> sortedFields = cls.fields.toList()
            ..sort((idlModel.FieldDeclaration a, idlModel.FieldDeclaration b) =>
                a.id.compareTo(b.id));
          for (idlModel.FieldDeclaration field in sortedFields) {
            if (field.isInformative) {
              continue;
            }
            String ref = 'this._${field.name}';
            if (field.type.isList) {
              out('if ($ref == null) {');
              indent(() {
                out('signature.addInt(0);');
              });
              out('} else {');
              indent(() {
                out('signature.addInt($ref.length);');
                out('for (var x in $ref) {');
                indent(() {
                  _generateSignatureCall(field.type.typeName, 'x', false);
                });
                out('}');
              });
              out('}');
            } else {
              _generateSignatureCall(field.type.typeName, ref, true);
            }
          }
        });
        out('}');
      }
      // Generate finish.
      if (cls.isTopLevel) {
        out();
        out('List<int> toBuffer() {');
        indent(() {
          out('fb.Builder fbBuilder = new fb.Builder();');
          String fileId = cls.fileIdentifier == null
              ? ''
              : ', ${quoted(cls.fileIdentifier)}';
          out('return fbBuilder.finish(finish(fbBuilder)$fileId);');
        });
        out('}');
      }
      out();
      out('fb.Offset finish(fb.Builder fbBuilder) {');
      indent(() {
        // Write objects and remember Offset(s).
        for (idlModel.FieldDeclaration field in cls.fields) {
          idlModel.FieldType fieldType = field.type;
          String offsetName = 'offset_' + field.name;
          if (fieldType.isList ||
              fieldType.typeName == 'String' ||
              _idl.classes.containsKey(fieldType.typeName)) {
            out('fb.Offset $offsetName;');
          }
        }
        for (idlModel.FieldDeclaration field in cls.fields) {
          idlModel.FieldType fieldType = field.type;
          String valueName = '_' + field.name;
          String offsetName = 'offset_' + field.name;
          String condition;
          String writeCode;
          if (fieldType.isList) {
            condition = ' || $valueName.isEmpty';
            if (_idl.classes.containsKey(fieldType.typeName)) {
              String itemCode = 'b.finish(fbBuilder)';
              String listCode = '$valueName.map((b) => $itemCode).toList()';
              writeCode = '$offsetName = fbBuilder.writeList($listCode);';
            } else if (_idl.enums.containsKey(fieldType.typeName)) {
              String itemCode = 'b.index';
              String listCode = '$valueName.map((b) => $itemCode).toList()';
              writeCode = '$offsetName = fbBuilder.writeListUint8($listCode);';
            } else if (fieldType.typeName == 'bool') {
              writeCode = '$offsetName = fbBuilder.writeListBool($valueName);';
            } else if (fieldType.typeName == 'int') {
              writeCode =
                  '$offsetName = fbBuilder.writeListUint32($valueName);';
            } else if (fieldType.typeName == 'double') {
              writeCode =
                  '$offsetName = fbBuilder.writeListFloat64($valueName);';
            } else {
              assert(fieldType.typeName == 'String');
              String itemCode = 'fbBuilder.writeString(b)';
              String listCode = '$valueName.map((b) => $itemCode).toList()';
              writeCode = '$offsetName = fbBuilder.writeList($listCode);';
            }
          } else if (fieldType.typeName == 'String') {
            writeCode = '$offsetName = fbBuilder.writeString($valueName);';
          } else if (_idl.classes.containsKey(fieldType.typeName)) {
            writeCode = '$offsetName = $valueName.finish(fbBuilder);';
          }
          if (writeCode != null) {
            if (condition == null) {
              out('if ($valueName != null) {');
            } else {
              out('if (!($valueName == null$condition)) {');
            }
            indent(() {
              out(writeCode);
            });
            out('}');
          }
        }
        // Write the table.
        out('fbBuilder.startTable();');
        for (idlModel.FieldDeclaration field in cls.fields) {
          int index = field.id;
          idlModel.FieldType fieldType = field.type;
          String valueName = '_' + field.name;
          String condition = '$valueName != null';
          String writeCode;
          if (fieldType.isList ||
              fieldType.typeName == 'String' ||
              _idl.classes.containsKey(fieldType.typeName)) {
            String offsetName = 'offset_' + field.name;
            condition = '$offsetName != null';
            writeCode = 'fbBuilder.addOffset($index, $offsetName);';
          } else if (fieldType.typeName == 'bool') {
            condition = '$valueName == true';
            writeCode = 'fbBuilder.addBool($index, true);';
          } else if (fieldType.typeName == 'int') {
            condition += ' && $valueName != ${defaultValue(fieldType, true)}';
            writeCode = 'fbBuilder.addUint32($index, $valueName);';
          } else if (_idl.enums.containsKey(fieldType.typeName)) {
            condition += ' && $valueName != ${defaultValue(fieldType, true)}';
            writeCode = 'fbBuilder.addUint8($index, $valueName.index);';
          }
          if (writeCode == null) {
            throw new UnimplementedError('Writing type ${fieldType.typeName}');
          }
          out('if ($condition) {');
          indent(() {
            out(writeCode);
          });
          out('}');
        }
        out('return fbBuilder.endTable();');
      });
      out('}');
    });
    out('}');
  }

  void _generateEnumReader(idlModel.EnumDeclaration enm) {
    String name = enm.name;
    String readerName = '_${name}Reader';
    String count = '${idlPrefix(name)}.values.length';
    String def = '${idlPrefix(name)}.${enm.values[0].name}';
    out('class $readerName extends fb.Reader<${idlPrefix(name)}> {');
    indent(() {
      out('const $readerName() : super();');
      out();
      out('@override');
      out('int get size => 1;');
      out();
      out('@override');
      out('${idlPrefix(name)} read(fb.BufferContext bc, int offset) {');
      indent(() {
        out('int index = const fb.Uint8Reader().read(bc, offset);');
        out('return index < $count ? ${idlPrefix(name)}.values[index] : $def;');
      });
      out('}');
    });
    out('}');
  }

  void _generateImpl(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    String implName = '_${name}Impl';
    String mixinName = '_${name}Mixin';
    out('class $implName extends Object with $mixinName'
        ' implements ${idlPrefix(name)} {');
    indent(() {
      out('final fb.BufferContext _bc;');
      out('final int _bcOffset;');
      out();
      out('$implName(this._bc, this._bcOffset);');
      out();
      // Write cache fields.
      for (idlModel.FieldDeclaration field in cls.fields) {
        String returnType = dartType(field.type);
        String fieldName = field.name;
        out('$returnType _$fieldName;');
      }
      // Write getters.
      for (idlModel.FieldDeclaration field in cls.allFields) {
        int index = field.id;
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        String typeName = type.typeName;
        // Prepare "readCode" + "def"
        String readCode;
        String def = defaultValue(type, false);
        if (type.isList) {
          if (typeName == 'bool') {
            readCode = 'const fb.BoolListReader()';
          } else if (typeName == 'int') {
            readCode = 'const fb.Uint32ListReader()';
          } else if (typeName == 'double') {
            readCode = 'const fb.Float64ListReader()';
          } else if (typeName == 'String') {
            String itemCode = 'const fb.StringReader()';
            readCode = 'const fb.ListReader<String>($itemCode)';
          } else if (_idl.classes.containsKey(typeName)) {
            String itemCode = 'const _${typeName}Reader()';
            readCode = 'const fb.ListReader<${idlPrefix(typeName)}>($itemCode)';
          } else {
            assert(_idl.enums.containsKey(typeName));
            String itemCode = 'const _${typeName}Reader()';
            readCode = 'const fb.ListReader<${idlPrefix(typeName)}>($itemCode)';
          }
        } else if (typeName == 'bool') {
          readCode = 'const fb.BoolReader()';
        } else if (typeName == 'int') {
          readCode = 'const fb.Uint32Reader()';
        } else if (typeName == 'String') {
          readCode = 'const fb.StringReader()';
        } else if (_idl.enums.containsKey(typeName)) {
          readCode = 'const _${typeName}Reader()';
        } else if (_idl.classes.containsKey(typeName)) {
          readCode = 'const _${typeName}Reader()';
        }
        assert(readCode != null);
        // Write the getter implementation.
        out();
        out('@override');
        String returnType = dartType(type);
        if (field.isDeprecated) {
          out('$returnType get $fieldName => $_throwDeprecated;');
        } else {
          out('$returnType get $fieldName {');
          indent(() {
            String readExpr =
                '$readCode.vTableGet(_bc, _bcOffset, $index, $def)';
            out('_$fieldName ??= $readExpr;');
            out('return _$fieldName;');
          });
          out('}');
        }
      }
    });
    out('}');
  }

  void _generateMixin(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    String mixinName = '_${name}Mixin';
    out('abstract class $mixinName implements ${idlPrefix(name)} {');
    indent(() {
      // Write toJson().
      out('@override');
      out('Map<String, Object> toJson() {');
      indent(() {
        out('Map<String, Object> _result = <String, Object>{};');
        for (idlModel.FieldDeclaration field in cls.fields) {
          String condition;
          if (field.type.isList) {
            condition = '${field.name}.isNotEmpty';
          } else {
            condition = '${field.name} != ${defaultValue(field.type, false)}';
          }
          _StringToString convertItem;
          if (_idl.classes.containsKey(field.type.typeName)) {
            convertItem = (String name) => '$name.toJson()';
          } else if (_idl.enums.containsKey(field.type.typeName)) {
            // TODO(paulberry): it would be better to generate a const list of
            // strings so that we don't have to do this kludge.
            convertItem = (String name) => "$name.toString().split('.')[1]";
          } else if (field.type.typeName == 'double') {
            convertItem =
                (String name) => '$name.isFinite ? $name : $name.toString()';
          }
          String convertField;
          if (convertItem == null) {
            convertField = field.name;
          } else if (field.type.isList) {
            convertField = '${field.name}.map((_value) =>'
                ' ${convertItem('_value')}).toList()';
          } else {
            convertField = convertItem(field.name);
          }
          String storeField = '_result[${quoted(field.name)}] = $convertField';
          out('if ($condition) $storeField;');
        }
        out('return _result;');
      });
      out('}');
      out();
      // Write toMap().
      out('@override');
      out('Map<String, Object> toMap() => {');
      indent(() {
        for (idlModel.FieldDeclaration field in cls.fields) {
          String fieldName = field.name;
          out('${quoted(fieldName)}: $fieldName,');
        }
      });
      out('};');
      out();
      // Write toString().
      out('@override');
      out('String toString() => convert.JSON.encode(toJson());');
    });
    out('}');
  }

  void _generateReader(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    String readerName = '_${name}Reader';
    String implName = '_${name}Impl';
    out('class $readerName extends fb.TableReader<$implName> {');
    indent(() {
      out('const $readerName();');
      out();
      out('@override');
      out('$implName createObject(fb.BufferContext bc, int offset) => new $implName(bc, offset);');
    });
    out('}');
  }

  void _generateReadFunction(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    out('${idlPrefix(name)} read$name(List<int> buffer) {');
    indent(() {
      out('fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);');
      out('return const _${name}Reader().read(rootRef, 0);');
    });
    out('}');
  }

  /**
   * Generate a call to the appropriate method of [ApiSignature] for the type
   * [typeName], using the data named by [ref].  If [couldBeNull] is `true`,
   * generate code to handle the possibility that [ref] is `null` (substituting
   * in the appropriate default value).
   */
  void _generateSignatureCall(String typeName, String ref, bool couldBeNull) {
    if (_idl.enums.containsKey(typeName)) {
      if (couldBeNull) {
        out('signature.addInt($ref == null ? 0 : $ref.index);');
      } else {
        out('signature.addInt($ref.index);');
      }
    } else if (_idl.classes.containsKey(typeName)) {
      if (couldBeNull) {
        out('signature.addBool($ref != null);');
      }
      out('$ref?.collectApiSignature(signature);');
    } else {
      switch (typeName) {
        case 'String':
          if (couldBeNull) {
            ref += " ?? ''";
          }
          out("signature.addString($ref);");
          break;
        case 'int':
          if (couldBeNull) {
            ref += ' ?? 0';
          }
          out('signature.addInt($ref);');
          break;
        case 'bool':
          if (couldBeNull) {
            ref += ' == true';
          }
          out('signature.addBool($ref);');
          break;
        case 'double':
          if (couldBeNull) {
            ref += ' ?? 0.0';
          }
          out('signature.addDouble($ref);');
          break;
        default:
          throw "Don't know how to generate signature call for $typeName";
      }
    }
  }

  /**
   * Return the documentation text of the given [node], or `null` if the [node]
   * does not have a comment.  Each line is `\n` separated.
   */
  String _getNodeDoc(AnnotatedNode node) {
    Comment comment = node.documentationComment;
    if (comment != null &&
        comment.isDocumentation &&
        comment.tokens.length == 1 &&
        comment.tokens.first.lexeme.startsWith('/*')) {
      Token token = comment.tokens.first;
      return token.lexeme.split('\n').map((String line) {
        line = line.trimLeft();
        if (line.startsWith('*')) line = ' ' + line;
        return line;
      }).join('\n');
    }
    return null;
  }
}
