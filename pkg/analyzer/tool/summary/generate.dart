// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains code to generate serialization/deserialization logic for
/// summaries based on an "IDL" description of the summary format (written in
/// stylized Dart).
///
/// For each class in the "IDL" input, two corresponding classes are generated:
/// - A class with the same name which represents deserialized summary data in
///   memory.  This class has read-only semantics.
/// - A "builder" class which can be used to generate serialized summary data.
///   This class has write-only semantics.
///
/// Each of the "builder" classes has a single `finish` method which writes
/// the entity being built into the given FlatBuffer and returns the `Offset`
/// reference to it.
import 'dart:convert';
import 'dart:io';

import 'package:analysis_tool/tools.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/scanner/token.dart' show Token;

import 'idl_model.dart' as idl_model;
import 'mini_ast.dart';

main(List<String> args) async {
  if (args.length != 1) {
    print('Error: IDL path is required');
    print('usage: dart generate.dart path/to/idl.dart');
  }
  String idlPath = args[0];
  await GeneratedContent.generateAll(
      File(idlPath).parent.path, getAllTargets(idlPath));
}

List<GeneratedContent> getAllTargets(String idlPath) {
  final GeneratedFile formatTarget =
      new GeneratedFile('format.dart', (_) async {
    _CodeGenerator codeGenerator = new _CodeGenerator(idlPath);
    codeGenerator.generateFormatCode();
    return codeGenerator._outBuffer.toString();
  });

  final GeneratedFile schemaTarget = new GeneratedFile('format.fbs', (_) async {
    _CodeGenerator codeGenerator = new _CodeGenerator(idlPath);
    codeGenerator.generateFlatBufferSchema();
    return codeGenerator._outBuffer.toString();
  });

  return <GeneratedContent>[formatTarget, schemaTarget];
}

typedef String _StringToString(String s);

class _BaseGenerator {
  static const String _throwDeprecated =
      "throw new UnimplementedError('attempt to access deprecated field')";

  /// Semantic model of the "IDL" input file.
  final idl_model.Idl _idl;

  /// Buffer in which generated code is accumulated.
  final StringBuffer _outBuffer;

  /// Current indentation level.
  String _indentation = '';

  _BaseGenerator(this._idl, this._outBuffer);

  /// Generate a Dart expression representing the default value for a field
  /// having the given [type], or `null` if there is no default value.
  ///
  /// If [builder] is `true`, the returned type should be appropriate for use in
  /// a builder class.
  String defaultValue(idl_model.FieldType type, bool builder) {
    if (type.isList) {
      if (builder) {
        idl_model.FieldType elementType =
            new idl_model.FieldType(type.typeName, false);
        return '<${encodedType(elementType)}>[]';
      } else {
        return 'const <${idlPrefix(type.typeName)}>[]';
      }
    } else if (_idl.enums.containsKey(type.typeName)) {
      return '${idlPrefix(type.typeName)}.'
          '${_idl.enums[type.typeName].values[0].name}';
    } else if (type.typeName == 'double') {
      return '0.0';
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

  /// Generate a string representing the Dart type which should be used to
  /// represent [type] while building a serialized data structure.
  String encodedType(idl_model.FieldType type) {
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

  /// Add the prefix `idl.` to a type name, unless that type name is the name of
  /// a built-in type.
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

  /// Execute [callback] with two spaces added to [_indentation].
  void indent(void callback()) {
    String oldIndentation = _indentation;
    try {
      _indentation += '  ';
      callback();
    } finally {
      _indentation = oldIndentation;
    }
  }

  /// Add the string [s] to the output as a single line, indenting as
  /// appropriate.
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

  /// Enclose [s] in quotes, escaping as necessary.
  String quoted(String s) {
    return json.encode(s);
  }

  List<String> _computeVariants(idl_model.ClassDeclaration cls) {
    var allVariants = Set<String>();
    for (var field in cls.fields) {
      var logicalFields = field.logicalProperties?.values;
      if (logicalFields != null) {
        for (var logicalField in logicalFields) {
          allVariants.addAll(logicalField.variants);
        }
      }
    }
    return allVariants.toList()..sort();
  }

  String _variantAssertStatement(
    idl_model.ClassDeclaration class_,
    idl_model.LogicalProperty property,
  ) {
    var assertCondition = property.variants
        ?.map((key) => '${class_.variantField} == idl.$key')
        ?.join(' || ');
    return 'assert($assertCondition);';
  }
}

class _BuilderGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;
  List<String> constructorParams = <String>[];

  _BuilderGenerator(idl_model.Idl idl, StringBuffer outBuffer, this.cls)
      : super(idl, outBuffer);

  String get builderName => name + 'Builder';

  String get name => cls.name;

  void generate() {
    String mixinName = '_${name}Mixin';
    var implementsClause =
        cls.isDeprecated ? '' : ' implements ${idlPrefix(name)}';
    out('class $builderName extends Object with $mixinName$implementsClause {');
    indent(() {
      _generateFields();
      _generateGettersSetters();
      _generateConstructors();
      _generateFlushInformative();
      _generateCollectApiSignature();
      _generateToBuffer();
      _generateFinish();
    });
    out('}');
  }

  void _generateCollectApiSignature() {
    out();
    out('/// Accumulate non-[informative] data into [signature].');
    out('void collectApiSignature(api_sig.ApiSignature signature) {');

    void writeField(String name, idl_model.FieldType type, bool isInformative) {
      if (isInformative) {
        return;
      }
      String ref = 'this.$name';
      if (type.isList) {
        out('if ($ref == null) {');
        indent(() {
          out('signature.addInt(0);');
        });
        out('} else {');
        indent(() {
          out('signature.addInt($ref.length);');
          out('for (var x in $ref) {');
          indent(() {
            _generateSignatureCall(type.typeName, 'x', false);
          });
          out('}');
        });
        out('}');
      } else {
        _generateSignatureCall(type.typeName, ref, true);
      }
    }

    indent(() {
      List<idl_model.FieldDeclaration> sortedFields = cls.fields.toList()
        ..sort((idl_model.FieldDeclaration a, idl_model.FieldDeclaration b) =>
            a.id.compareTo(b.id));
      if (cls.variantField != null) {
        var firstVariant = true;
        for (var variant in _computeVariants(cls)) {
          if (firstVariant) {
            firstVariant = false;
          } else {
            out('else');
          }
          out('if (${cls.variantField} == idl.$variant) {');
          indent(() {
            for (var field in sortedFields) {
              var logicalProperties = field.logicalProperties;
              if (logicalProperties != null) {
                for (var logicalName in logicalProperties.keys) {
                  var logicalProperty = logicalProperties[logicalName];
                  if (logicalProperty.variants.contains(variant)) {
                    writeField(
                      logicalName,
                      field.type,
                      logicalProperty.isInformative,
                    );
                  }
                }
              } else {
                writeField(field.name, field.type, field.isInformative);
              }
            }
          });
          out('}');
        }
      } else {
        for (idl_model.FieldDeclaration field in sortedFields) {
          writeField('_${field.name}', field.type, field.isInformative);
        }
      }
    });
    out('}');
  }

  void _generateConstructors() {
    out();
    if (cls.variantField != null) {
      for (var variant in _computeVariants(cls)) {
        var constructorName = variant.split('.')[1];
        out('$builderName.$constructorName({');

        for (var field in cls.fields) {
          if (field.logicalProperties != null) {
            for (var logicalName in field.logicalProperties.keys) {
              var logicalProperty = field.logicalProperties[logicalName];
              if (logicalProperty.variants.contains(variant)) {
                out('${encodedType(field.type)} $logicalName,');
              }
            }
          }
        }

        out('}) : ');

        out('_${cls.variantField} = idl.$variant');

        var separator = ',';
        for (var field in cls.fields) {
          if (field.logicalProperties != null) {
            for (var logicalName in field.logicalProperties.keys) {
              var logicalProperty = field.logicalProperties[logicalName];
              if (logicalProperty.variants.contains(variant)) {
                out('$separator _${field.name} = $logicalName');
                separator = ', ';
              }
            }
          }
        }

        out(';');
        out();
      }
    } else {
      out('$builderName({${constructorParams.join(', ')}})');
      List<idl_model.FieldDeclaration> fields = cls.fields.toList();
      for (int i = 0; i < fields.length; i++) {
        idl_model.FieldDeclaration field = fields[i];
        String prefix = i == 0 ? '  : ' : '    ';
        String suffix = i == fields.length - 1 ? ';' : ',';
        out('${prefix}_${field.name} = ${field.name}$suffix');
      }
    }
  }

  void _generateFields() {
    for (idl_model.FieldDeclaration field in cls.fields) {
      String fieldName = field.name;
      idl_model.FieldType type = field.type;
      String typeStr = encodedType(type);
      out('$typeStr _$fieldName;');
    }
  }

  void _generateFinish() {
    out();
    out('fb.Offset finish(fb.Builder fbBuilder) {');
    indent(() {
      // Write objects and remember Offset(s).
      for (idl_model.FieldDeclaration field in cls.fields) {
        idl_model.FieldType fieldType = field.type;
        String offsetName = 'offset_' + field.name;
        if (fieldType.isList ||
            fieldType.typeName == 'String' ||
            _idl.classes.containsKey(fieldType.typeName)) {
          out('fb.Offset $offsetName;');
        }
      }

      for (idl_model.FieldDeclaration field in cls.fields) {
        idl_model.FieldType fieldType = field.type;
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
            writeCode = '$offsetName = fbBuilder.writeListUint32($valueName);';
          } else if (fieldType.typeName == 'double') {
            writeCode = '$offsetName = fbBuilder.writeListFloat64($valueName);';
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
      for (idl_model.FieldDeclaration field in cls.fields) {
        int index = field.id;
        idl_model.FieldType fieldType = field.type;
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
        } else if (fieldType.typeName == 'double') {
          condition += ' && $valueName != ${defaultValue(fieldType, true)}';
          writeCode = 'fbBuilder.addFloat64($index, $valueName);';
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
  }

  void _generateFlushInformative() {
    out();
    out('/// Flush [informative] data recursively.');
    out('void flushInformative() {');

    void writeField(String name, idl_model.FieldType type, bool isInformative) {
      if (isInformative) {
        out('$name = null;');
      } else if (_idl.classes.containsKey(type.typeName)) {
        if (type.isList) {
          out('$name?.forEach((b) => b.flushInformative());');
        } else {
          out('$name?.flushInformative();');
        }
      }
    }

    indent(() {
      if (cls.variantField != null) {
        var firstVariant = true;
        for (var variant in _computeVariants(cls)) {
          if (firstVariant) {
            firstVariant = false;
          } else {
            out('else');
          }
          out('if (${cls.variantField} == idl.$variant) {');
          indent(() {
            for (var field in cls.fields) {
              var logicalProperties = field.logicalProperties;
              if (logicalProperties != null) {
                for (var logicalName in logicalProperties.keys) {
                  var logicalProperty = logicalProperties[logicalName];
                  if (logicalProperty.variants.contains(variant)) {
                    writeField(
                      logicalName,
                      field.type,
                      logicalProperty.isInformative,
                    );
                  }
                }
              } else {
                writeField(field.name, field.type, field.isInformative);
              }
            }
          });
          out('}');
        }
      } else {
        for (idl_model.FieldDeclaration field in cls.fields) {
          writeField('_${field.name}', field.type, field.isInformative);
        }
      }
    });
    out('}');
  }

  void _generateGettersSetters() {
    for (idl_model.FieldDeclaration field in cls.allFields) {
      String fieldName = field.name;
      idl_model.FieldType fieldType = field.type;
      String typeStr = encodedType(fieldType);
      String def = defaultValue(fieldType, true);
      String defSuffix = def == null ? '' : ' ??= $def';
      out();
      if (field.isDeprecated) {
        out('@override');
        out('Null get $fieldName => ${_BaseGenerator._throwDeprecated};');
      } else {
        if (field.logicalProperties != null) {
          for (var logicalName in field.logicalProperties.keys) {
            var logicalProperty = field.logicalProperties[logicalName];
            out('@override');
            out('$typeStr get $logicalName {');
            indent(() {
              out(_variantAssertStatement(cls, logicalProperty));
              out('return _${field.name}$defSuffix;');
            });
            out('}');
            out();
          }
        } else {
          out('@override');
          out('$typeStr get $fieldName => _$fieldName$defSuffix;');
        }
        out();

        constructorParams.add('$typeStr $fieldName');

        outDoc(field.documentation);

        if (field.logicalProperties != null) {
          for (var logicalName in field.logicalProperties.keys) {
            var logicalProperty = field.logicalProperties[logicalName];
            out('set $logicalName($typeStr value) {');
            indent(() {
              out(_variantAssertStatement(cls, logicalProperty));
              _generateNonNegativeInt(fieldType);
              out('_variantField_${field.id} = value;');
            });
            out('}');
            out();
          }
        } else {
          out('set $fieldName($typeStr value) {');
          indent(() {
            _generateNonNegativeInt(fieldType);
            out('this._$fieldName = value;');
          });
          out('}');
        }
      }
    }
  }

  void _generateNonNegativeInt(idl_model.FieldType fieldType) {
    if (fieldType.typeName == 'int') {
      if (!fieldType.isList) {
        out('assert(value == null || value >= 0);');
      } else {
        out('assert(value == null || value.every((e) => e >= 0));');
      }
    }
  }

  /// Generate a call to the appropriate method of [ApiSignature] for the type
  /// [typeName], using the data named by [ref].  If [couldBeNull] is `true`,
  /// generate code to handle the possibility that [ref] is `null` (substituting
  /// in the appropriate default value).
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

  void _generateToBuffer() {
    if (cls.isTopLevel) {
      out();
      out('List<int> toBuffer() {');
      indent(() {
        out('fb.Builder fbBuilder = new fb.Builder();');
        String fileId =
            cls.fileIdentifier == null ? '' : ', ${quoted(cls.fileIdentifier)}';
        out('return fbBuilder.finish(finish(fbBuilder)$fileId);');
      });
      out('}');
    }
  }
}

class _CodeGenerator {
  /// Buffer in which generated code is accumulated.
  final StringBuffer _outBuffer = new StringBuffer();

  /// Semantic model of the "IDL" input file.
  idl_model.Idl _idl;

  _CodeGenerator(String idlPath) {
    // Parse the input "IDL" file.
    File idlFile = new File(idlPath);
    String idlText =
        idlFile.readAsStringSync().replaceAll(new RegExp('\r\n?'), '\n');
    // Extract a description of the IDL and make sure it is valid.
    var startingToken = scanString(idlText, includeComments: true).tokens;
    var listener = new MiniAstBuilder();
    var parser = new MiniAstParser(listener);
    parser.parseUnit(startingToken);
    extractIdl(listener.compilationUnit);
    checkIdl();
  }

  /// Perform basic sanity checking of the IDL (over and above that done by
  /// [extractIdl]).
  void checkIdl() {
    _idl.classes.forEach((String name, idl_model.ClassDeclaration cls) {
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
      for (idl_model.FieldDeclaration field in cls.allFields) {
        String fieldName = field.name;
        idl_model.FieldType type = field.type;
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

  /// Process the AST in [idlParsed] and store the resulting semantic model in
  /// [_idl].  Also perform some error checking.
  void extractIdl(CompilationUnit idlParsed) {
    _idl = new idl_model.Idl();
    for (CompilationUnitMember decl in idlParsed.declarations) {
      if (decl is ClassDeclaration) {
        bool isTopLevel = false;
        bool isDeprecated = false;
        String fileIdentifier;
        String clsName = decl.name;
        String variantField;
        for (Annotation annotation in decl.metadata) {
          if (annotation.arguments != null &&
              annotation.name == 'TopLevel' &&
              annotation.constructorName == null) {
            isTopLevel = true;
            if (annotation.arguments.length == 1) {
              Expression arg = annotation.arguments[0];
              if (arg is StringLiteral) {
                fileIdentifier = arg.stringValue;
              } else {
                throw new Exception(
                    'Class `$clsName`: TopLevel argument must be a string'
                    ' literal');
              }
            } else if (annotation.arguments.isNotEmpty) {
              throw new Exception(
                  'Class `$clsName`: TopLevel requires 0 or 1 arguments');
            }
          } else if (annotation.arguments == null &&
              annotation.name == 'deprecated' &&
              annotation.constructorName == null) {
            isDeprecated = true;
          } else if (annotation.arguments != null &&
              annotation.name == 'Variant' &&
              annotation.constructorName == null) {
            if (annotation.arguments.length == 1) {
              Expression arg = annotation.arguments[0];
              if (arg is StringLiteral) {
                variantField = arg.stringValue;
              } else {
                throw new Exception(
                  'Class `$clsName`: @Variant argument must be a string literal',
                );
              }
            } else if (annotation.arguments.isNotEmpty) {
              throw Exception(
                'Class `$clsName`: @Variant requires 1 argument',
              );
            }
          }
        }
        idl_model.ClassDeclaration cls = new idl_model.ClassDeclaration(
          documentation: _getNodeDoc(decl),
          name: clsName,
          isTopLevel: isTopLevel,
          fileIdentifier: fileIdentifier,
          isDeprecated: isDeprecated,
          variantField: variantField,
        );
        _idl.classes[clsName] = cls;
        String expectedBase = 'base.SummaryClass';
        if (decl.superclass == null || decl.superclass.name != expectedBase) {
          throw new Exception(
              'Class `$clsName` needs to extend `$expectedBase`');
        }
        for (ClassMember classMember in decl.members) {
          if (classMember is MethodDeclaration && classMember.isGetter) {
            _addFieldForGetter(cls, classMember);
          } else if (classMember is ConstructorDeclaration &&
              classMember.name.endsWith('fromBuffer')) {
            // Ignore `fromBuffer` declarations; they simply forward to the
            // read functions generated by [_generateReadFunction].
          } else {
            throw new Exception('Unexpected class member `$classMember`');
          }
        }
      } else if (decl is EnumDeclaration) {
        String doc = _getNodeDoc(decl);
        idl_model.EnumDeclaration enm =
            new idl_model.EnumDeclaration(doc, decl.name);
        _idl.enums[enm.name] = enm;
        for (EnumConstantDeclaration constDecl in decl.constants) {
          String doc = _getNodeDoc(constDecl);
          enm.values
              .add(new idl_model.EnumValueDeclaration(doc, constDecl.name));
        }
      } else {
        throw new Exception('Unexpected declaration `$decl`');
      }
    }
  }

  /// Entry point to the code generator when generating the "format.fbs" file.
  void generateFlatBufferSchema() {
    outputHeader();
    _FlatBufferSchemaGenerator(_idl, _outBuffer).generate();
  }

  /// Entry point to the code generator when generating the "format.dart" file.
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
    for (idl_model.EnumDeclaration enum_ in _idl.enums.values) {
      _EnumReaderGenerator(_idl, _outBuffer, enum_).generate();
      out();
    }
    for (idl_model.ClassDeclaration cls in _idl.classes.values) {
      if (!cls.isDeprecated) {
        _BuilderGenerator(_idl, _outBuffer, cls).generate();
        out();
      }
      if (cls.isTopLevel) {
        _ReaderGenerator(_idl, _outBuffer, cls).generateReaderFunction();
        out();
      }
      if (!cls.isDeprecated) {
        _ReaderGenerator(_idl, _outBuffer, cls).generateReader();
        out();
        _ImplGenerator(_idl, _outBuffer, cls).generate();
        out();
        _MixinGenerator(_idl, _outBuffer, cls).generate();
        out();
      }
    }
  }

  /// Add the string [s] to the output as a single line.
  void out([String s = '']) {
    _outBuffer.writeln(s);
  }

  void outputHeader() {
    out('// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file');
    out('// for details. All rights reserved. Use of this source code is governed by a');
    out('// BSD-style license that can be found in the LICENSE file.');
    out('//');
    out('// This file has been automatically generated.  Please do not edit it manually.');
    out('// To regenerate the file, use the SDK script');
    out('// "pkg/analyzer/tool/summary/generate.dart \$IDL_FILE_PATH",');
    out('// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.');
    out();
  }

  void _addFieldForGetter(
    idl_model.ClassDeclaration cls,
    MethodDeclaration getter,
  ) {
    var desc = '${cls.name}.${getter.name}';
    if (getter.returnType == null) {
      throw new Exception('Getter needs a type: $desc');
    }

    var type = getter.returnType;

    var isList = false;
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
    List<String> variants;
    bool isDeprecated = false;
    bool isInformative = false;

    for (Annotation annotation in getter.metadata) {
      if (annotation.name == 'Id') {
        if (id != null) {
          throw new Exception('Duplicate @id annotation ($getter)');
        }
        if (annotation.arguments == null) {
          throw Exception('@Id must be passed an argument ($desc)');
        }
        if (annotation.arguments.length != 1) {
          throw Exception('@Id must be passed exactly one argument ($desc)');
        }

        var idExpression = annotation.arguments[0];
        if (idExpression is IntegerLiteral) {
          id = idExpression.value;
        } else {
          throw new Exception(
            '@Id argument must be an integer literal ($desc)',
          );
        }
      } else if (annotation.name == 'deprecated') {
        if (annotation.arguments != null) {
          throw new Exception('@deprecated does not take args ($desc)');
        }
        isDeprecated = true;
      } else if (annotation.name == 'informative') {
        isInformative = true;
      } else if (annotation.name == 'VariantId') {
        if (id != null) {
          throw Exception('Cannot specify both @Id and @VariantId ($getter)');
        }
        if (variants != null) {
          throw Exception('Duplicate @VariantId annotation ($getter)');
        }

        if (annotation.arguments == null) {
          throw Exception('@VariantId must be given arguments ($desc)');
        }
        if (annotation.arguments.length != 2) {
          throw Exception(
            '@VariantId must be given exactly two arguments ($desc)',
          );
        }

        var idExpression = annotation.arguments[0];
        if (idExpression is IntegerLiteral) {
          id = idExpression.value;
        } else {
          throw Exception(
            '@VariantId argument must be an integer literal ($desc)',
          );
        }

        var variantExpression = annotation.arguments[1];
        if (variantExpression is NamedExpression) {
          if (variantExpression.name == 'variant') {
            variants = [variantExpression.expression.toCode()];
          } else if (variantExpression.name == 'variantList') {
            variants = (variantExpression.expression as ListLiteral)
                .elements
                .map((e) => e.toCode())
                .toList();
          } else {
            throw Exception(
              'Only "key" or "keyList" expected in @VariantId ($desc)',
            );
          }
        } else {
          throw Exception(
            'The second argument of @VariantId must be named ($desc)',
          );
        }
      }
    }
    if (id == null) {
      throw new Exception('Missing @id annotation ($desc)');
    }

    var fieldType = new idl_model.FieldType(type.name, isList);

    String name = getter.name;
    Map<String, idl_model.LogicalProperty> logicalProperties;
    if (variants != null) {
      var fieldsWithSameId =
          cls.allFields.where((field) => field.id == id).toList();
      if (fieldsWithSameId.isNotEmpty) {
        var existingField = fieldsWithSameId.single;
        if (existingField.logicalProperties == null) {
          throw Exception('$desc: id $id is already used as a non-variant '
              'field: ${existingField.name}');
        }

        var map = existingField.logicalProperties;
        for (var variant in variants) {
          for (var logicalName in map.keys) {
            if (map[logicalName].variants.contains(variant)) {
              throw Exception('$desc: id $id is already used for $logicalName');
            }
          }
        }

        if (existingField.type != fieldType) {
          throw Exception(
            '$desc: id $id is already used with type ${existingField.type}',
          );
        }

        if (map[getter.name] != null) {
          throw Exception(
            '$desc: logical property ${getter.name} is already used',
          );
        }

        map[getter.name] = idl_model.LogicalProperty(
          isDeprecated: isDeprecated,
          isInformative: isInformative,
          variants: variants,
        );
        return;
      } else {
        name = 'variantField_$id';
        logicalProperties = <String, idl_model.LogicalProperty>{
          getter.name: idl_model.LogicalProperty(
            isDeprecated: isDeprecated,
            isInformative: isInformative,
            variants: variants,
          ),
        };
      }
    }

    cls.allFields.add(
      idl_model.FieldDeclaration(
        documentation: _getNodeDoc(getter),
        name: name,
        type: fieldType,
        id: id,
        isDeprecated: isDeprecated,
        isInformative: isInformative,
        logicalProperties: logicalProperties,
      ),
    );
  }

  /// Return the documentation text of the given [node], or `null` if the [node]
  /// does not have a comment.  Each line is `\n` separated.
  String _getNodeDoc(AnnotatedNode node) {
    Comment comment = node.documentationComment;
    if (comment != null && comment.isDocumentation) {
      if (comment.tokens.length == 1 &&
          comment.tokens.first.lexeme.startsWith('/*')) {
        Token token = comment.tokens.first;
        return token.lexeme.split('\n').map((String line) {
          line = line.trimLeft();
          if (line.startsWith('*')) line = ' ' + line;
          return line;
        }).join('\n');
      } else if (comment.tokens
          .every((token) => token.lexeme.startsWith('///'))) {
        return comment.tokens
            .map((token) => token.lexeme.trimLeft())
            .join('\n');
      }
    }
    return null;
  }
}

class _EnumReaderGenerator extends _BaseGenerator {
  final idl_model.EnumDeclaration enum_;

  _EnumReaderGenerator(idl_model.Idl idl, StringBuffer outBuffer, this.enum_)
      : super(idl, outBuffer);

  void generate() {
    String name = enum_.name;
    String readerName = '_${name}Reader';
    String count = '${idlPrefix(name)}.values.length';
    String def = '${idlPrefix(name)}.${enum_.values[0].name}';
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
}

class _FlatBufferSchemaGenerator extends _BaseGenerator {
  _FlatBufferSchemaGenerator(idl_model.Idl idl, StringBuffer outBuffer)
      : super(idl, outBuffer);

  void generate() {
    for (idl_model.EnumDeclaration enm in _idl.enums.values) {
      out();
      outDoc(enm.documentation);
      out('enum ${enm.name} : byte {');
      indent(() {
        for (int i = 0; i < enm.values.length; i++) {
          idl_model.EnumValueDeclaration value = enm.values[i];
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
    for (idl_model.ClassDeclaration cls in _idl.classes.values) {
      out();
      outDoc(cls.documentation);
      out('table ${cls.name} {');
      indent(() {
        for (int i = 0; i < cls.allFields.length; i++) {
          idl_model.FieldDeclaration field = cls.allFields[i];
          if (i != 0) {
            out();
          }
          outDoc(field.documentation);
          List<String> attributes = <String>['id: ${field.id}'];
          if (field.isDeprecated) {
            attributes.add('deprecated');
          }
          String attrText = attributes.join(', ');
          out('${field.name}:${_fbsType(field.type)} ($attrText);');
        }
      });
      out('}');
    }
    out();
    // Standard flatbuffers only support one root type.  We support multiple
    // root types.  For now work around this by forcing PackageBundle to be the
    // root type.  TODO(paulberry): come up with a better solution.
    idl_model.ClassDeclaration rootType = _idl.classes['PackageBundle'];
    out('root_type ${rootType.name};');
    if (rootType.fileIdentifier != null) {
      out();
      out('file_identifier ${quoted(rootType.fileIdentifier)};');
    }
  }

  /// Generate a string representing the FlatBuffer schema type which should be
  /// used to represent [type].
  String _fbsType(idl_model.FieldType type) {
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
}

class _ImplGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;

  _ImplGenerator(idl_model.Idl idl, StringBuffer outBuffer, this.cls)
      : super(idl, outBuffer);

  void generate() {
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
      for (idl_model.FieldDeclaration field in cls.fields) {
        String returnType = _dartType(field.type);
        String fieldName = field.name;
        out('$returnType _$fieldName;');
      }
      // Write getters.
      for (idl_model.FieldDeclaration field in cls.allFields) {
        int index = field.id;
        String fieldName = field.name;
        idl_model.FieldType type = field.type;
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
        } else if (typeName == 'double') {
          readCode = 'const fb.Float64Reader()';
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
        String returnType = _dartType(type);
        if (field.isDeprecated) {
          out('@override');
          out('Null get $fieldName => ${_BaseGenerator._throwDeprecated};');
        } else {
          if (field.logicalProperties != null) {
            for (var logicalName in field.logicalProperties.keys) {
              var logicalProperty = field.logicalProperties[logicalName];
              out('@override');
              out('$returnType get $logicalName {');
              indent(() {
                out(_variantAssertStatement(cls, logicalProperty));
                String readExpr =
                    '$readCode.vTableGet(_bc, _bcOffset, $index, $def)';
                out('_$fieldName ??= $readExpr;');
                out('return _$fieldName;');
              });
              out('}');
              out();
            }
          } else {
            out('@override');
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
      }
    });
    out('}');
  }

  /// Generate a string representing the Dart type which should be used to
  /// represent [type] when deserialized.
  String _dartType(idl_model.FieldType type) {
    String baseType = idlPrefix(type.typeName);
    if (type.isList) {
      return 'List<$baseType>';
    } else {
      return baseType;
    }
  }
}

class _MixinGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;

  _MixinGenerator(idl_model.Idl idl, StringBuffer outBuffer, this.cls)
      : super(idl, outBuffer);

  void generate() {
    String name = cls.name;
    String mixinName = '_${name}Mixin';
    out('abstract class $mixinName implements ${idlPrefix(name)} {');
    indent(() {
      String jsonCondition(idl_model.FieldType type, String name) {
        if (type.isList) {
          return '$name.isNotEmpty';
        } else {
          return '$name != ${defaultValue(type, false)}';
        }
      }

      String jsonStore(idl_model.FieldType type, String name) {
        _StringToString convertItem;
        if (_idl.classes.containsKey(type.typeName)) {
          convertItem = (String name) => '$name.toJson()';
        } else if (_idl.enums.containsKey(type.typeName)) {
          // TODO(paulberry): it would be better to generate a const list of
          // strings so that we don't have to do this kludge.
          convertItem = (String name) => "$name.toString().split('.')[1]";
        } else if (type.typeName == 'double') {
          convertItem =
              (String name) => '$name.isFinite ? $name : $name.toString()';
        }
        String convertField;
        if (convertItem == null) {
          convertField = name;
        } else if (type.isList) {
          convertField = '$name.map((_value) =>'
              ' ${convertItem('_value')}).toList()';
        } else {
          convertField = convertItem(name);
        }
        return '_result[${quoted(name)}] = $convertField';
      }

      // Write toJson().
      out('@override');
      out('Map<String, Object> toJson() {');
      indent(() {
        out('Map<String, Object> _result = <String, Object>{};');

        if (cls.variantField != null) {
          indent(() {
            for (idl_model.FieldDeclaration field in cls.fields) {
              if (field.logicalProperties == null) {
                var condition = jsonCondition(field.type, field.name);
                var storeField = jsonStore(field.type, field.name);
                out('if ($condition) $storeField;');
              }
            }
            for (var variant in _computeVariants(cls)) {
              out('if (${cls.variantField} == idl.$variant) {');
              indent(() {
                for (idl_model.FieldDeclaration field in cls.fields) {
                  var logicalProperties = field.logicalProperties;
                  if (logicalProperties != null) {
                    for (var logicalName in logicalProperties.keys) {
                      var logicalProperty = logicalProperties[logicalName];
                      if (logicalProperty.variants.contains(variant)) {
                        var condition = jsonCondition(field.type, logicalName);
                        var storeField = jsonStore(field.type, logicalName);
                        out('if ($condition) $storeField;');
                      }
                    }
                  }
                }
              });
              out('}');
            }
          });
        } else {
          indent(() {
            for (idl_model.FieldDeclaration field in cls.fields) {
              String condition = jsonCondition(field.type, field.name);
              String storeField = jsonStore(field.type, field.name);
              out('if ($condition) $storeField;');
            }
          });
        }

        out('return _result;');
      });
      out('}');
      out();

      // Write toMap().
      out('@override');
      if (cls.variantField != null) {
        out('Map<String, Object> toMap() {');
        for (var variant in _computeVariants(cls)) {
          out('if (${cls.variantField} == idl.$variant) {');
          indent(() {
            out('return {');
            for (idl_model.FieldDeclaration field in cls.fields) {
              if (field.logicalProperties != null) {
                for (var logicalName in field.logicalProperties.keys) {
                  var logicalProperty = field.logicalProperties[logicalName];
                  if (logicalProperty.variants.contains(variant)) {
                    out('${quoted(logicalName)}: $logicalName,');
                  }
                }
              } else {
                String fieldName = field.name;
                out('${quoted(fieldName)}: $fieldName,');
              }
            }
            out('};');
          });
          out('}');
        }
        out('throw StateError("Unexpected \$${cls.variantField}");');
        out('}');
      } else {
        out('Map<String, Object> toMap() => {');
        indent(() {
          for (idl_model.FieldDeclaration field in cls.fields) {
            String fieldName = field.name;
            out('${quoted(fieldName)}: $fieldName,');
          }
        });
        out('};');
      }
      out();
      // Write toString().
      out('@override');
      out('String toString() => convert.json.encode(toJson());');
    });
    out('}');
  }
}

class _ReaderGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;

  _ReaderGenerator(idl_model.Idl idl, StringBuffer outBuffer, this.cls)
      : super(idl, outBuffer);

  void generateReader() {
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

  void generateReaderFunction() {
    String name = cls.name;
    out('${idlPrefix(name)} read$name(List<int> buffer) {');
    indent(() {
      out('fb.BufferContext rootRef = new fb.BufferContext.fromBytes(buffer);');
      out('return const _${name}Reader().read(rootRef, 0);');
    });
    out('}');
  }
}
