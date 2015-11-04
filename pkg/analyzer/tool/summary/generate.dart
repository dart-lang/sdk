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
 * Each of the "builder" classess has a single `finish` method which finalizes
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
  Parser parser = new Parser(idlSource, new BooleanErrorListener());
  CompilationUnit idlParsed = parser.parseCompilationUnit(tokenStream);
  _CodeGenerator codeGenerator = new _CodeGenerator();
  codeGenerator.processCompilationUnit(idlParsed);
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
      cls.fields.forEach((String fieldName, idlModel.FieldType type) {
        if (type.isList) {
          if (_idl.classes.containsKey(type.typeName)) {
            // List of classes is ok
          } else if (type.typeName == 'int') {
            // List of ints is ok
          } else {
            throw new Exception(
                '$name.$fieldName: illegal type (list of ${type.typeName})');
          }
        }
      });
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
    if (type.isList) {
      if (type.typeName == 'int') {
        return 'List<int>';
      } else {
        return 'List<Object>';
      }
    } else if (_idl.classes.containsKey(type.typeName)) {
      return 'Object';
    } else {
      return dartType(type);
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
        idlModel.ClassDeclaration cls = new idlModel.ClassDeclaration();
        _idl.classes[decl.name.name] = cls;
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
            idlModel.FieldType fieldType =
                new idlModel.FieldType(type.name.name, isList);
            for (VariableDeclaration field in classMember.fields.variables) {
              cls.fields[field.name.name] = fieldType;
            }
          } else {
            throw new Exception('Unexpected class member `$classMember`');
          }
        }
      } else if (decl is EnumDeclaration) {
        idlModel.EnumDeclaration enm = new idlModel.EnumDeclaration();
        _idl.enums[decl.name.name] = enm;
        for (EnumConstantDeclaration constDecl in decl.constants) {
          enm.values.add(constDecl.name.name);
        }
      } else if (decl is TopLevelVariableDeclaration) {
        // Ignore top leve variable declarations; they are present just to make
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

  /**
   * Entry point to the code generator.  Interpret the AST in [idlParsed],
   * generate code, and output it to [_outBuffer].
   */
  void processCompilationUnit(CompilationUnit idlParsed) {
    extractIdl(idlParsed);
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
    out("import 'builder.dart' as builder;");
    out();
    _idl.enums.forEach((String name, idlModel.EnumDeclaration enm) {
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
      out('class $name {');
      indent(() {
        cls.fields.forEach((String fieldName, idlModel.FieldType type) {
          out('${dartType(type)} _$fieldName;');
        });
        out();
        out('$name.fromJson(Map json)');
        indent(() {
          List<String> initializers = <String>[];
          cls.fields.forEach((String fieldName, idlModel.FieldType type) {
            String convert = 'json[${quoted(fieldName)}]';
            if (type.isList && type.typeName == 'int') {
              // No conversion necessary.
            } else if (type.isList) {
              convert =
                  '$convert?.map((x) => new ${type.typeName}.fromJson(x))?.toList()';
            } else if (_idl.classes.containsKey(type.typeName)) {
              convert =
                  '$convert == null ? null : new ${type.typeName}.fromJson($convert)';
            } else if (_idl.enums.containsKey(type.typeName)) {
              convert =
                  '$convert == null ? null : ${type.typeName}.values[$convert]';
            }
            initializers.add('_$fieldName = $convert');
          });
          for (int i = 0; i < initializers.length; i++) {
            String prefix = i == 0 ? ': ' : '  ';
            String suffix = i == initializers.length - 1 ? ';' : ',';
            out('$prefix${initializers[i]}$suffix');
          }
        });
        out();
        cls.fields.forEach((String fieldName, idlModel.FieldType type) {
          String def = defaultValue(type);
          String defaultSuffix = def == null ? '' : ' ?? $def';
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
        out('${name}Builder(builder.BuilderContext context);');
        cls.fields.forEach((String fieldName, idlModel.FieldType type) {
          out();
          String conversion = '_value';
          String condition = '';
          if (type.isList) {
            conversion = '$conversion.toList()';
            condition = ' || _value.isEmpty';
          } else if (_idl.enums.containsKey(type.typeName)) {
            conversion = '$conversion.index';
            condition = ' || _value == ${defaultValue(type)}';
          }
          builderParams.add('${encodedType(type)} $fieldName');
          out('void set $fieldName(${encodedType(type)} _value) {');
          indent(() {
            out('assert(!_json.containsKey(${quoted(fieldName)}));');
            out('if (_value != null$condition) {');
            indent(() {
              out('_json[${quoted(fieldName)}] = $conversion;');
            });
            out('}');
          });
          out('}');
        });
        out();
        out('Object finish() => _json;');
      });
      out('}');
      out();
      out('Object encode$name(builder.BuilderContext builderContext, {${builderParams.join(', ')}}) {');
      indent(() {
        out('${name}Builder builder = new ${name}Builder(builderContext);');
        cls.fields.forEach((String fieldName, idlModel.FieldType type) {
          out('builder.$fieldName = $fieldName;');
        });
        out('return builder.finish();');
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
}
