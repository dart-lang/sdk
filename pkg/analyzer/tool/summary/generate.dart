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
    out("import 'dart:convert';");
    out("import 'base.dart' as base;");
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
    _idl.classes.forEach((String name, idlModel.ClassDeclaration cls) {
      outDoc(cls.documentation);
      out('class $name extends base.SummaryClass {');
      indent(() {
        for (idlModel.FieldDeclaration field in cls.fields) {
          String fieldName = field.name;
          idlModel.FieldType type = field.type;
          out('${dartType(type)} _$fieldName;');
        }
        out();
        out('$name.fromJson(Map json)');
        indent(() {
          List<String> initializers = <String>[];
          for (idlModel.FieldDeclaration field in cls.fields) {
            String fieldName = field.name;
            idlModel.FieldType type = field.type;
            String convert = 'json[${quoted(fieldName)}]';
            if (type.isList) {
              if (type.typeName == 'int' || type.typeName == 'String') {
                // No conversion necessary.
              } else {
                convert =
                    '$convert?.map((x) => new ${type.typeName}.fromJson(x))?.toList()';
              }
            } else if (_idl.classes.containsKey(type.typeName)) {
              convert =
                  '$convert == null ? null : new ${type.typeName}.fromJson($convert)';
            } else if (_idl.enums.containsKey(type.typeName)) {
              convert =
                  '$convert == null ? null : ${type.typeName}.values[$convert]';
            }
            initializers.add('_$fieldName = $convert');
          }
          for (int i = 0; i < initializers.length; i++) {
            String prefix = i == 0 ? ': ' : '  ';
            String suffix = i == initializers.length - 1 ? ';' : ',';
            out('$prefix${initializers[i]}$suffix');
          }
        });
        out();
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
        if (cls.isTopLevel) {
          out('$name.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));');
          out();
        }
        cls.fields.asMap().forEach((index, field) {
          String fieldName = field.name;
          idlModel.FieldType type = field.type;
          if (index != 0) {
            out();
          }
          String def = defaultValue(type);
          String defaultSuffix = def == null ? '' : ' ?? $def';
          outDoc(field.documentation);
          out('${dartType(type)} get $fieldName => _$fieldName$defaultSuffix;');
        });
      });
      out('}');
      out();
      List<String> builderParams = <String>[];
      out('class ${name}Builder {');
      indent(() {
        out('final Map _json = {};');
        out();
        out('bool _finished = false;');
        out();
        out('${name}Builder(base.BuilderContext context);');
        for (idlModel.FieldDeclaration field in cls.fields) {
          String fieldName = field.name;
          idlModel.FieldType type = field.type;
          out();
          outDoc(field.documentation);
          String conversion = '_value';
          String condition = '';
          if (type.isList) {
            if (_idl.classes.containsKey(type.typeName)) {
              conversion = '$conversion.map((b) => b.finish()).toList()';
            } else {
              conversion = '$conversion.toList()';
            }
            condition = ' || _value.isEmpty';
          } else if (_idl.enums.containsKey(type.typeName)) {
            conversion = '$conversion.index';
            condition = ' || _value == ${defaultValue(type)}';
          } else if (_idl.classes.containsKey(type.typeName)) {
            conversion = '$conversion.finish()';
          }
          builderParams.add('${encodedType(type)} $fieldName');
          out('void set $fieldName(${encodedType(type)} _value) {');
          indent(() {
            out('assert(!_finished);');
            out('assert(!_json.containsKey(${quoted(fieldName)}));');
            if (condition.isEmpty) {
              out('if (_value != null) {');
            } else {
              out('if (!(_value == null$condition)) {');
            }
            indent(() {
              out('_json[${quoted(fieldName)}] = $conversion;');
            });
            out('}');
          });
          out('}');
        }
        if (cls.isTopLevel) {
          out();
          out('List<int> toBuffer() => UTF8.encode(JSON.encode(finish()));');
        }
        out();
        out('Map finish() {');
        indent(() {
          out('assert(!_finished);');
          out('_finished = true;');
          out('return _json;');
        });
        out('}');
      });
      out('}');
      out();
      out('${name}Builder encode$name(base.BuilderContext builderContext, {${builderParams.join(', ')}}) {');
      indent(() {
        out('${name}Builder builder = new ${name}Builder(builderContext);');
        for (idlModel.FieldDeclaration field in cls.fields) {
          String fieldName = field.name;
          out('builder.$fieldName = $fieldName;');
        }
        out('return builder;');
      });
      out('}');
      out();
    });
  }

  /**
   * Enclose [s] in quotes, escaping as necessary.
   */
  String quoted(String s) {
    return JSON.encode(s);
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
