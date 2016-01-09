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
 * Each of the "builder" classes has a single `finish` method which finalizes
 * the entity being built and returns it as an [Object].  This object should
 * only be passed to other builders (or to [BuilderContext.getBuffer]);
 * otherwise the client should treat it as opaque, since it exposes
 * implementation details of the underlying summary infrastructure.
 */
library analyzer.tool.summary.generate;

import 'dart:convert';
import 'dart:io' hide File;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/codegen/tools.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';

import 'idl_model.dart' as idlModel;

main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = normalize(join(dirname(script), '..', '..'));
  GeneratedContent.generateAll(pkgPath, <GeneratedContent>[target]);
}

final GeneratedFile target =
    new GeneratedFile('lib/src/summary/format.dart', (String pkgPath) {
  // Parse the input "IDL" file and pass it to the [_CodeGenerator].
  PhysicalResourceProvider provider = new PhysicalResourceProvider(
      PhysicalResourceProvider.NORMALIZE_EOL_ALWAYS);
  String idlPath = join(pkgPath, 'tool', 'summary', 'idl.dart');
  File idlFile = provider.getFile(idlPath);
  Source idlSource = provider.getFile(idlPath).createSource();
  String idlText = idlFile.readAsStringSync();
  BooleanErrorListener errorListener = new BooleanErrorListener();
  CharacterReader idlReader = new CharSequenceReader(idlText);
  Scanner scanner = new Scanner(idlSource, idlReader, errorListener);
  Token tokenStream = scanner.tokenize();
  LineInfo lineInfo = new LineInfo(scanner.lineStarts);
  Parser parser = new Parser(idlSource, new BooleanErrorListener());
  CompilationUnit idlParsed = parser.parseCompilationUnit(tokenStream);
  _CodeGenerator codeGenerator = new _CodeGenerator();
  codeGenerator.processCompilationUnit(lineInfo, idlParsed);
  return codeGenerator._outBuffer.toString();
});

class _CodeGenerator {
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

  /**
   * Perform basic sanity checking of the IDL (over and above that done by
   * [extractIdl]).
   */
  void checkIdl() {
    _idl.classes.forEach((String name, idlModel.ClassDeclaration cls) {
      for (idlModel.FieldDeclaration field in cls.fields) {
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        if (type.isList) {
          if (_idl.classes.containsKey(type.typeName)) {
            // List of classes is ok
          } else if (type.typeName == 'int') {
            // List of ints is ok
          } else if (type.typeName == 'String') {
            // List of strings is ok
          } else {
            throw new Exception(
                '$name.$fieldName: illegal type (list of ${type.typeName})');
          }
        }
      }
    });
  }

  /**
   * Generate a string representing the Dart type which should be used to
   * represent [type] when deserialized.
   */
  String dartType(idlModel.FieldType type) {
    if (type.isList) {
      return 'List<${type.typeName}>';
    } else {
      return type.typeName;
    }
  }

  /**
   * Generate a Dart expression representing the default value for a field
   * having the given [type], or `null` if there is no default value.
   */
  String defaultValue(idlModel.FieldType type) {
    if (type.isList) {
      return 'const <${type.typeName}>[]';
    } else if (_idl.enums.containsKey(type.typeName)) {
      return '${type.typeName}.${_idl.enums[type.typeName].values[0]}';
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
      typeStr = type.typeName;
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
  void extractIdl(LineInfo lineInfo, CompilationUnit idlParsed) {
    _idl = new idlModel.Idl();
    for (CompilationUnitMember decl in idlParsed.declarations) {
      if (decl is ClassDeclaration) {
        bool isTopLevel = false;
        for (Annotation annotation in decl.metadata) {
          if (annotation.arguments == null &&
              annotation.name.name == 'topLevel') {
            isTopLevel = true;
          }
        }
        String doc = _getNodeDoc(lineInfo, decl);
        idlModel.ClassDeclaration cls =
            new idlModel.ClassDeclaration(doc, decl.name.name, isTopLevel);
        _idl.classes[cls.name] = cls;
        for (ClassMember classMember in decl.members) {
          if (classMember is FieldDeclaration) {
            TypeName type = classMember.fields.type;
            bool isList = false;
            if (type.name.name == 'List' &&
                type.typeArguments != null &&
                type.typeArguments.arguments.length == 1) {
              isList = true;
              type = type.typeArguments.arguments[0];
            }
            if (type.typeArguments != null) {
              throw new Exception('Cannot handle type arguments in `$type`');
            }
            String doc = _getNodeDoc(lineInfo, classMember);
            idlModel.FieldType fieldType =
                new idlModel.FieldType(type.name.name, isList);
            for (VariableDeclaration field in classMember.fields.variables) {
              cls.fields.add(new idlModel.FieldDeclaration(
                  doc, field.name.name, fieldType));
            }
          } else {
            throw new Exception('Unexpected class member `$classMember`');
          }
        }
      } else if (decl is EnumDeclaration) {
        String doc = _getNodeDoc(lineInfo, decl);
        idlModel.EnumDeclaration enm =
            new idlModel.EnumDeclaration(doc, decl.name.name);
        _idl.enums[enm.name] = enm;
        for (EnumConstantDeclaration constDecl in decl.constants) {
          enm.values.add(constDecl.name.name);
        }
      } else if (decl is TopLevelVariableDeclaration) {
        // Ignore top level variable declarations; they are present just to make
        // the IDL analyze without warnings.
      } else {
        throw new Exception('Unexpected declaration `$decl`');
      }
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

  /**
   * Entry point to the code generator.  Interpret the AST in [idlParsed],
   * generate code, and output it to [_outBuffer].
   */
  void processCompilationUnit(LineInfo lineInfo, CompilationUnit idlParsed) {
    extractIdl(lineInfo, idlParsed);
    checkIdl();
    out('// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file');
    out('// for details. All rights reserved. Use of this source code is governed by a');
    out('// BSD-style license that can be found in the LICENSE file.');
    out('//');
    out('// This file has been automatically generated.  Please do not edit it manually.');
    out('// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".');
    out();
    out('library analyzer.src.summary.format;');
    out();
    out("import 'base.dart' as base;");
    out("import 'flat_buffers.dart' as fb;");
    out();
    _idl.enums.forEach((String name, idlModel.EnumDeclaration enm) {
      outDoc(enm.documentation);
      out('enum $name {');
      indent(() {
        for (String value in enm.values) {
          out('$value,');
        }
      });
      out('}');
      out();
    });
    for (var cls in _idl.classes.values) {
      List<String> builderParams = _generateBuilder(cls);
      out();
      _generateEncodeFunction(cls, builderParams);
      out();
      _generateInterface(cls);
      out();
      _generateReader(cls);
      out();
    }
  }

  /**
   * Enclose [s] in quotes, escaping as necessary.
   */
  String quoted(String s) {
    return JSON.encode(s);
  }

  List<String> _generateBuilder(idlModel.ClassDeclaration cls) {
    String builderName = cls.name + 'Builder';
    List<String> builderParams = <String>[];
    out('class $builderName {');
    indent(() {
      out('bool _finished = false;');
      // Generate fields.
      out();
      for (idlModel.FieldDeclaration field in cls.fields) {
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        String typeStr = encodedType(type);
        out('$typeStr _$fieldName;');
      }
      // Generate constructor.
      out();
      out('$builderName(base.BuilderContext context);');
      // Generate setters.
      for (idlModel.FieldDeclaration field in cls.fields) {
        String fieldName = field.name;
        String typeStr = encodedType(field.type);
        out();
        outDoc(field.documentation);
        builderParams.add('$typeStr $fieldName');
        out('void set $fieldName($typeStr _value) {');
        indent(() {
          String stateFieldName = '_' + fieldName;
          out('assert(!_finished);');
          out('$stateFieldName = _value;');
        });
        out('}');
      }
      // Generate finish.
      if (cls.isTopLevel) {
        out();
        out('List<int> toBuffer() {');
        indent(() {
          out('fb.Builder fbBuilder = new fb.Builder();');
          out('return fbBuilder.finish(finish(fbBuilder));');
        });
        out('}');
      }
      out();
      out('fb.Offset finish(fb.Builder fbBuilder) {');
      indent(() {
        out('assert(!_finished);');
        out('_finished = true;');
        // Write objects and remember Offset(s).
        cls.fields.asMap().forEach((index, idlModel.FieldDeclaration field) {
          idlModel.FieldType fieldType = field.type;
          String offsetName = 'offset_' + field.name;
          if (fieldType.isList ||
              fieldType.typeName == 'String' ||
              _idl.classes.containsKey(fieldType.typeName)) {
            out('fb.Offset $offsetName;');
          }
        });
        cls.fields.asMap().forEach((index, idlModel.FieldDeclaration field) {
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
            } else if (fieldType.typeName == 'int') {
              writeCode = '$offsetName = fbBuilder.writeListInt32($valueName);';
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
        });
        // Write the table.
        out('fbBuilder.startTable();');
        cls.fields.asMap().forEach((index, idlModel.FieldDeclaration field) {
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
            // TODO(scheglov) implement booleans merging?
            condition = '$valueName == true';
            writeCode = 'fbBuilder.addInt8($index, 1);';
          } else if (fieldType.typeName == 'int') {
            condition += ' && $valueName != ${defaultValue(fieldType)}';
            writeCode = 'fbBuilder.addInt32($index, $valueName);';
          } else if (_idl.enums.containsKey(fieldType.typeName)) {
            condition += ' && $valueName != ${defaultValue(fieldType)}';
            writeCode = 'fbBuilder.addInt32($index, $valueName.index);';
          }
          if (writeCode == null) {
            throw new UnimplementedError('Writing type ${fieldType.typeName}');
          }
          out('if ($condition) {');
          indent(() {
            out(writeCode);
          });
          out('}');
        });
        out('return fbBuilder.endTable();');
      });
      out('}');
    });
    out('}');
    return builderParams;
  }

  void _generateEncodeFunction(
      idlModel.ClassDeclaration cls, List<String> builderParams) {
    String className = cls.name;
    String builderName = className + 'Builder';
    out('$builderName encode$className(base.BuilderContext builderContext, {${builderParams.join(', ')}}) {');
    indent(() {
      out('$builderName builder = new $builderName(builderContext);');
      for (idlModel.FieldDeclaration field in cls.fields) {
        String fieldName = field.name;
        out('builder.$fieldName = $fieldName;');
      }
      out('return builder;');
    });
    out('}');
  }

  void _generateInterface(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    outDoc(cls.documentation);
    out('abstract class $name extends base.SummaryClass {');
    indent(() {
      if (cls.isTopLevel) {
        out('factory $name.fromBuffer(List<int> buffer) {');
        indent(() {
          out('fb.BufferPointer rootRef = new fb.BufferPointer.fromBytes(buffer);');
          out('return const _${name}Reader().read(rootRef);');
        });
        out('}');
      }
      cls.fields.asMap().forEach((index, field) {
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        out();
        outDoc(field.documentation);
        out('${dartType(type)} get $fieldName;');
      });
    });
    out('}');
  }

  void _generateReader(idlModel.ClassDeclaration cls) {
    String name = cls.name;
    String readerName = '_${name}Reader';
    out('class $readerName extends fb.TableReader<$readerName> implements $name {');
    indent(() {
      out('final fb.BufferPointer _bp;');
      out();
      out('const $readerName([this._bp]);');
      out();
      out('@override');
      out('$readerName createReader(fb.BufferPointer bp) => new $readerName(bp);');
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
      // Write getters.
      cls.fields.asMap().forEach((index, field) {
        String fieldName = field.name;
        idlModel.FieldType type = field.type;
        String typeName = type.typeName;
        // Prepare "readLines" or "readCode" + "def" + "readSuffix"
        List<String> readLines;
        String readCode;
        String def = defaultValue(type);
        String readSuffix = '';
        if (type.isList) {
          if (typeName == 'int') {
            String itemCode = 'const fb.Int32Reader()';
            readCode = 'const fb.ListReader<int>($itemCode)';
          } else if (typeName == 'String') {
            String itemCode = 'const fb.StringReader()';
            readCode = 'const fb.ListReader<String>($itemCode)';
          } else {
            String itemCode = '$typeName>(const _${typeName}Reader()';
            readCode = 'const fb.ListReader<$itemCode)';
          }
        } else if (typeName == 'bool') {
          // TODO(scheglov) implement booleans merging?
          def = '0';
          readCode = 'const fb.Int8Reader()';
          readSuffix = ' == 1';
        } else if (typeName == 'int') {
          readCode = 'const fb.Int32Reader()';
        } else if (typeName == 'String') {
          readCode = 'const fb.StringReader()';
        } else if (_idl.enums.containsKey(typeName)) {
          readLines = <String>[
            'int index = const fb.Int32Reader().vTableGet(_bp, $index, 0);',
            'return $typeName.values[index];'
          ];
        } else if (_idl.classes.containsKey(typeName)) {
          readCode = 'const _${typeName}Reader()';
        }
        assert(readCode != null || readLines != null);
        // Write the getter implementation.
        out();
        out('@override');
        String returnType = dartType(type);
        if (readLines != null) {
          out('$returnType get $fieldName {');
          indent(() {
            readLines.forEach(out);
          });
          out('}');
        } else {
          String expr = '$readCode.vTableGet(_bp, $index, $def)$readSuffix';
          out('$returnType get $fieldName => $expr;');
        }
      });
    });
    out('}');
  }

  /**
   * Return the documentation text of the given [node], or `null` if the [node]
   * does not have a comment.  Each line is `\n` separated.
   */
  String _getNodeDoc(LineInfo lineInfo, AnnotatedNode node) {
    Comment comment = node.documentationComment;
    if (comment != null &&
        comment.isDocumentation &&
        comment.tokens.length == 1 &&
        comment.tokens.first.type == TokenType.MULTI_LINE_COMMENT) {
      Token token = comment.tokens.first;
      int column = lineInfo.getLocation(token.offset).columnNumber;
      String indent = ' ' * (column - 1);
      return token.lexeme.split('\n').map((String line) {
        if (line.startsWith(indent)) {
          line = line.substring(indent.length);
        }
        return line;
      }).join('\n');
    }
    return null;
  }
}
