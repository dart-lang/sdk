// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SemanticTokensTest);
  });
}

@reflectiveTest
class SemanticTokensTest extends AbstractLspAnalysisServerTest {
  /// Decode tokens according to the LSP spec and pair with relevant file contents.
  List<_Token> decodeSemanticTokens(String content, SemanticTokens tokens) {
    final contentLines = content.split('\n').map((line) => '$line\n').toList();
    final results = <_Token>[];

    var lastLine = 0;
    var lastColumn = 0;
    for (var i = 0; i < tokens.data.length; i += 5) {
      final lineDelta = tokens.data[i];
      final columnDelta = tokens.data[i + 1];
      final length = tokens.data[i + 2];
      final tokenTypeIndex = tokens.data[i + 3];
      final modifierBitmask = tokens.data[i + 4];

      // Calculate the actual line/col from the deltas.
      final line = lastLine + lineDelta;
      final column = lineDelta == 0 ? lastColumn + columnDelta : columnDelta;

      final tokenContent =
          contentLines[line].substring(column, column + length);
      results.add(_Token(
        tokenContent,
        semanticTokenLegend.typeForIndex(tokenTypeIndex),
        semanticTokenLegend.modifiersForBitmask(modifierBitmask),
      ));

      lastLine = line;
      lastColumn = column;
    }

    return results;
  }

  Future<void> test_class() async {
    final content = '''
    /// class docs
    class MyClass<T> {
      // class comment
    }

    // Trailing comment
    ''';

    final expected = [
      _Token('/// class docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('T', SemanticTokenTypes.typeParameter),
      _Token('// class comment', SemanticTokenTypes.comment),
      _Token('// Trailing comment', SemanticTokenTypes.comment),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_class_fields() async {
    final content = '''
    class MyClass {
      /// field docs
      String myField = 'FieldVal';
      /// static field docs
      static String myStaticField = 'StaticFieldVal';
    }

    main() {
      final a = MyClass();
      print(a.myField);
      MyClass.myStaticField = 'a';
    }
    ''';

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('/// field docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('myField', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token("'FieldVal'", SemanticTokenTypes.string),
      _Token('/// static field docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('String', SemanticTokenTypes.class_),
      _Token('myStaticField', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token("'StaticFieldVal'", SemanticTokenTypes.string),
      _Token('main', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myField', SemanticTokenTypes.property),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('myStaticField', SemanticTokenTypes.property,
          [SemanticTokenModifiers.static]),
      _Token("'a'", SemanticTokenTypes.string),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_class_getterSetter() async {
    final content = '''
    class MyClass {
      /// getter docs
      String get myGetter => 'GetterVal';
      /// setter docs
      set mySetter(String v) {};
      /// static getter docs
      static String get myStaticGetter => 'StaticGetterVal';
      /// static setter docs
      static set myStaticSetter(String staticV) {};
    }

    main() {
      final a = MyClass();
      print(a.myGetter);
      a.mySetter = 'a';
    }
    ''';

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('/// getter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('get', SemanticTokenTypes.keyword),
      _Token('myGetter', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'GetterVal'", SemanticTokenTypes.string),
      _Token('/// setter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('set', SemanticTokenTypes.keyword),
      _Token('mySetter', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('v', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('/// static getter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('String', SemanticTokenTypes.class_),
      _Token('get', SemanticTokenTypes.keyword),
      _Token('myStaticGetter', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token("'StaticGetterVal'", SemanticTokenTypes.string),
      _Token('/// static setter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('set', SemanticTokenTypes.keyword),
      _Token('myStaticSetter', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('staticV', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('main', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myGetter', SemanticTokenTypes.property),
      _Token('a', SemanticTokenTypes.variable),
      _Token('mySetter', SemanticTokenTypes.property),
      _Token("'a'", SemanticTokenTypes.string),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_class_method() async {
    final content = '''
    class MyClass {
      /// method docs
      @override
      void myMethod() {}
      /// static method docs
      static void myStaticMethod() {
        // static method comment
      }
    }

    main() {
      final a = MyClass();
      a.myMethod();
      MyClass.myStaticMethod();
    }
    ''';

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('/// method docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('override', SemanticTokenTypes.property),
      _Token('void', SemanticTokenTypes.keyword),
      _Token('myMethod', SemanticTokenTypes.method,
          [SemanticTokenModifiers.declaration]),
      _Token('/// static method docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('void', SemanticTokenTypes.keyword),
      _Token('myStaticMethod', SemanticTokenTypes.method,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('// static method comment', SemanticTokenTypes.comment),
      _Token('main', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myMethod', SemanticTokenTypes.method),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('myStaticMethod', SemanticTokenTypes.method,
          [SemanticTokenModifiers.static]),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_directives() async {
    final content = '''
    import 'package:flutter/material.dart';
    export 'package:flutter/widgets.dart';
    import '../file.dart';

    library foo;
    ''';

    final expected = [
      _Token('import', SemanticTokenTypes.keyword),
      _Token("'package:flutter/material.dart'", SemanticTokenTypes.string),
      _Token('export', SemanticTokenTypes.keyword),
      _Token("'package:flutter/widgets.dart'", SemanticTokenTypes.string),
      _Token('import', SemanticTokenTypes.keyword),
      _Token("'../file.dart'", SemanticTokenTypes.string),
      _Token('library', SemanticTokenTypes.keyword),
      _Token('foo', SemanticTokenTypes.namespace),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_fromPlugin() async {
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    final pluginAnalyzedFileUri = Uri.file(pluginAnalyzedFilePath);
    final content = 'CLASS STRING VARIABLE';

    final expected = [
      _Token('CLASS', SemanticTokenTypes.class_),
      _Token('STRING', SemanticTokenTypes.string),
      _Token('VARIABLE', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
    ];

    await initialize();
    await openFile(pluginAnalyzedFileUri, withoutMarkers(content));

    final pluginResult = plugin.AnalysisHighlightsParams(
      pluginAnalyzedFilePath,
      [
        plugin.HighlightRegion(plugin.HighlightRegionType.CLASS, 0, 5),
        plugin.HighlightRegion(plugin.HighlightRegionType.LITERAL_STRING, 6, 6),
        plugin.HighlightRegion(
            plugin.HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION, 13, 8),
      ],
    );
    configureTestPlugin(notification: pluginResult.toNotification());

    final tokens = await getSemanticTokens(pluginAnalyzedFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_invalidSyntax() async {
    final content = '''
    /// class docs
    class MyClass {
      // class comment
    }

    this is not valid code.

    /// class docs 2
    class MyClass2 {
      // class comment 2
    }
    ''';

    // Expect toe correct tokens for the valid code before/after but don't
    // check the the tokens for the invalid code as thre are no concrete
    // expectations for them.
    final expected1 = [
      _Token('/// class docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('// class comment', SemanticTokenTypes.comment),
    ];
    final expected2 = [
      _Token('/// class docs 2', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass2', SemanticTokenTypes.class_),
      _Token('// class comment 2', SemanticTokenTypes.comment),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);

    // Remove the tokens between the two expected sets.
    decoded.removeRange(expected1.length, decoded.length - expected2.length);

    expect(decoded, equals([...expected1, ...expected2]));
  }

  Future<void> test_lastLine_code() async {
    final content = 'String var;';

    final expected = [
      _Token('String', SemanticTokenTypes.class_),
      _Token('var', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_lastLine_comment() async {
    final content = '// Trailing comment';

    final expected = [
      _Token('// Trailing comment', SemanticTokenTypes.comment),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_lastLine_multilineComment() async {
    final content = '''/**
 * Trailing comment
 */''';

    final expected = [
      _Token('/**', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('* Trailing comment', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('*/', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_manyImports_sortBug() async {
    // This test is for a bug where some "import" tokens would not be highlighted
    // correctly. Imports are made up of a DIRECTIVE token that spans a
    // BUILT_IN ("import") and LITERAL_STRING. The original code sorted by only
    // offset when handling overlapping tokens, which for certain lists (such as
    // the one created for the code below) would result in the BUILTIN coming before
    // the DIRECTIVE, which resulted in the DIRECTIVE overwriting it.
    final content = '''
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
    ''';

    final expected = [
      for (var i = 0; i < 13; i++) ...[
        _Token('import', SemanticTokenTypes.keyword),
        _Token("'dart:async'", SemanticTokenTypes.string),
      ],
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_multilineRegions() async {
    final content = '''
    /**
     * This is my class comment
     *
     * There are
     * multiple lines
     */
    class MyClass {}
    ''';

    final expected = [
      _Token('/**', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('* This is my class comment', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('*', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('* There are', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('* multiple lines', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('*/', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_strings() async {
    final content = r'''
    String foo(String c) => c;
    const string1 = 'test';
    const string2 = 'test1 $string1 test2 ${foo('test3')}';
    const string3 = r'$string1 ${string1.length}';
    ''';

    final expected = [
      _Token('String', SemanticTokenTypes.class_),
      _Token('foo', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('c', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('c', SemanticTokenTypes.parameter),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('string1', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token("'test'", SemanticTokenTypes.string),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('string2', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token(r"'test1 ", SemanticTokenTypes.string),
      _Token('string1', SemanticTokenTypes.property),
      _Token(' test2 ', SemanticTokenTypes.string),
      _Token('foo', SemanticTokenTypes.function),
      _Token("'test3'", SemanticTokenTypes.string),
      _Token("'", SemanticTokenTypes.string),
      _Token('const', SemanticTokenTypes.keyword),
      // string3 is raw and should be treated as a single string.
      _Token('string3', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token(r"r'$string1 ${string1.length}'", SemanticTokenTypes.string),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_topLevel() async {
    final content = '''
    /// strings docs
    const strings = <String>["test", 'test', r'test', \'''test\'''];

    /// func docs
    func(String a) => print(a);

    /// abc docs
    bool get abc => true;
    ''';

    final expected = [
      _Token('/// strings docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('strings', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('"test"', SemanticTokenTypes.string),
      _Token("'test'", SemanticTokenTypes.string),
      _Token("r'test'", SemanticTokenTypes.string),
      _Token("'''test'''", SemanticTokenTypes.string),
      _Token('/// func docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('func', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.parameter),
      _Token('/// abc docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('bool', SemanticTokenTypes.class_),
      _Token('get', SemanticTokenTypes.keyword),
      _Token('abc', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('true', CustomSemanticTokenTypes.boolean),
    ];

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }
}

class _Token {
  final String content;
  final SemanticTokenTypes type;
  final List<SemanticTokenModifiers> modifiers;

  _Token(this.content, this.type, [this.modifiers = const []]);

  @override
  int get hashCode => content.hashCode;

  @override
  bool operator ==(Object o) =>
      o is _Token &&
      o.content == content &&
      o.type == type &&
      listEqual(
          // Treat nulls the same as empty lists for convenience when comparing.
          o.modifiers ?? <SemanticTokenModifiers>[],
          modifiers ?? <SemanticTokenModifiers>[],
          (SemanticTokenModifiers a, SemanticTokenModifiers b) => a == b);

  @override
  String toString() => '$content (${[type, ...?modifiers]})';
}
