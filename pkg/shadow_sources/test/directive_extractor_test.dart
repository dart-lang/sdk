// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shadow_sources/src/directive_extractor.dart';
import 'package:test/test.dart';

void main() {
  group('DirectiveOccurrence model', () {
    test('reports kind and helper getters correctly', () {
      final importOcc = DirectiveOccurrence(
        kind: .import,
        uri: 'package:foo/foo.dart',
        offset: 10,
        length: 22,
        rawLexeme: "'package:foo/foo.dart'",
      );
      expect(importOcc.isImport, isTrue);
      expect(importOcc.isExport, isFalse);
      expect(importOcc.isPart, isFalse);
      expect(importOcc.isPartOf, isFalse);
      expect(
        importOcc.toString(),
        equals(
          'DirectiveOccurrence(DirectiveKind.import: package:foo/foo.dart, offset: 10, len: 22)',
        ),
      );

      final exportOcc = DirectiveOccurrence(
        kind: .export,
        uri: 'package:foo/foo.dart',
        offset: 0,
        length: 22,
        rawLexeme: "'package:foo/foo.dart'",
      );
      expect(exportOcc.isExport, isTrue);
      expect(exportOcc.isImport, isFalse);

      final partOcc = DirectiveOccurrence(
        kind: .part,
        uri: 'src/part.dart',
        offset: 0,
        length: 15,
        rawLexeme: "'src/part.dart'",
      );
      expect(partOcc.isPart, isTrue);

      final partOfOcc = DirectiveOccurrence(
        kind: .partOf,
        uri: 'parent.dart',
        offset: 0,
        length: 13,
        rawLexeme: "'parent.dart'",
      );
      expect(partOfOcc.isPartOf, isTrue);
    });
  });

  group('extractDirectives', () {
    test(
      'extracts imports, exports, parts, and part-ofs with token offsets',
      () {
        const code = '''
import 'package:collection/collection.dart';
export 'src/helper.dart' show foo;
part 'src/part_file.dart';
part of 'src/parent.dart';

void main() {}
''';
        final directives = extractDirectives(code);
        expect(directives.length, equals(4));

        expect(directives[0].isImport, isTrue);
        expect(directives[0].uri, equals('package:collection/collection.dart'));
        expect(
          directives[0].rawLexeme,
          equals("'package:collection/collection.dart'"),
        );
        expect(
          code.substring(
            directives[0].offset,
            directives[0].offset + directives[0].length,
          ),
          equals(directives[0].rawLexeme),
        );

        expect(directives[1].isExport, isTrue);
        expect(directives[1].uri, equals('src/helper.dart'));
        expect(directives[1].rawLexeme, equals("'src/helper.dart'"));
        expect(
          code.substring(
            directives[1].offset,
            directives[1].offset + directives[1].length,
          ),
          equals(directives[1].rawLexeme),
        );

        expect(directives[2].isPart, isTrue);
        expect(directives[2].uri, equals('src/part_file.dart'));
        expect(directives[2].rawLexeme, equals("'src/part_file.dart'"));

        expect(directives[3].isPartOf, isTrue);
        expect(directives[3].uri, equals('src/parent.dart'));
        expect(directives[3].rawLexeme, equals("'src/parent.dart'"));
      },
    );

    test(
      'handles imports and exports with aliases, combinators, and deferred',
      () {
        const code = '''
import 'package:collection/collection.dart' as col show min, max;
export 'package:collection/collection.dart' hide binarySearch;
import 'package:async/async.dart' deferred as a_sync;
''';
        final directives = extractDirectives(code);
        expect(directives.length, equals(3));
        expect(directives[0].isImport, isTrue);
        expect(directives[0].uri, equals('package:collection/collection.dart'));
        expect(directives[1].isExport, isTrue);
        expect(directives[1].uri, equals('package:collection/collection.dart'));
        expect(directives[2].isImport, isTrue);
        expect(directives[2].uri, equals('package:async/async.dart'));
      },
    );

    test('handles single, double, triple, and raw quotes correctly', () {
      const code = """
import 'package:single/single.dart';
import "package:double/double.dart";
import '''package:triple_single/ts.dart''';
import \"\"\"package:triple_double/td.dart\"\"\";
import r'package:raw_single/rs.dart';
import r"package:raw_double/rd.dart";
import r'''package:raw_triple_single/rts.dart''';
import r\"\"\"package:raw_triple_double/rtd.dart\"\"\";
""";
      final directives = extractDirectives(code);
      expect(directives.length, equals(8));
      expect(directives[0].uri, equals('package:single/single.dart'));
      expect(directives[1].uri, equals('package:double/double.dart'));
      expect(directives[2].uri, equals('package:triple_single/ts.dart'));
      expect(directives[3].uri, equals('package:triple_double/td.dart'));
      expect(directives[4].uri, equals('package:raw_single/rs.dart'));
      expect(directives[5].uri, equals('package:raw_double/rd.dart'));
      expect(directives[6].uri, equals('package:raw_triple_single/rts.dart'));
      expect(directives[7].uri, equals('package:raw_triple_double/rtd.dart'));
    });

    test('handles conditional imports and exports', () {
      const code = '''
import 'package:foo/foo.dart'
  if (dart.library.io) 'package:foo/foo_io.dart'
  if (dart.library.js_interop == 'true') 'package:foo/foo_web.dart';
export 'package:bar/bar.dart'
  if (dart.library.html) 'package:bar/bar_html.dart';
''';
      final directives = extractDirectives(code);
      expect(directives.length, equals(5));
      expect(directives[0].isImport, isTrue);
      expect(directives[0].uri, equals('package:foo/foo.dart'));
      expect(directives[1].isImport, isTrue);
      expect(directives[1].uri, equals('package:foo/foo_io.dart'));
      expect(directives[2].isImport, isTrue);
      expect(directives[2].uri, equals('package:foo/foo_web.dart'));
      expect(directives[3].isExport, isTrue);
      expect(directives[3].uri, equals('package:bar/bar.dart'));
      expect(directives[4].isExport, isTrue);
      expect(directives[4].uri, equals('package:bar/bar_html.dart'));
    });

    test('does not extract string literals outside top-level directives', () {
      const code = '''
import 'package:foo/foo.dart';

const str = 'package:not_a_directive/test.dart';
void main() {
  final map = {'key': "value"};
  print('Hello world');
}
''';
      final directives = extractDirectives(code);
      expect(directives.length, equals(1));
      expect(directives[0].uri, equals('package:foo/foo.dart'));
    });

    test('ignores named part of directive without string URI', () {
      const code = '''
part of my_library;

void foo() {}
''';
      final directives = extractDirectives(code);
      expect(directives, isEmpty);
    });
  });

  group('rewriteLexeme', () {
    test('preserves quotation formats', () {
      expect(
        rewriteLexeme("'package:old/old.dart'", 'package:new/new.dart'),
        equals("'package:new/new.dart'"),
      );
      expect(
        rewriteLexeme('"package:old/old.dart"', 'package:new/new.dart'),
        equals('"package:new/new.dart"'),
      );
      expect(
        rewriteLexeme("'''package:old/old.dart'''", 'package:new/new.dart'),
        equals("'''package:new/new.dart'''"),
      );
      expect(
        rewriteLexeme('"""package:old/old.dart"""', 'package:new/new.dart'),
        equals('"""package:new/new.dart"""'),
      );
      expect(
        rewriteLexeme("r'package:old/old.dart'", 'package:new/new.dart'),
        equals("r'package:new/new.dart'"),
      );
      expect(
        rewriteLexeme('r"package:old/old.dart"', 'package:new/new.dart'),
        equals('r"package:new/new.dart"'),
      );
      expect(
        rewriteLexeme("r'''package:old/old.dart'''", 'package:new/new.dart'),
        equals("r'''package:new/new.dart'''"),
      );
      expect(
        rewriteLexeme('r"""package:old/old.dart"""', 'package:new/new.dart'),
        equals('r"""package:new/new.dart"""'),
      );
    });
  });

  group('rewriteDirective', () {
    test(
      'rewrites directive token within content without touching surroundings',
      () {
        const code = '''
// Header comment
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

void main() {}
''';
        final directives = extractDirectives(code);
        final collectionDirective = directives[0];
        final rewritten = rewriteDirective(
          code,
          collectionDirective,
          Uri.parse('package:collection/shadowed_collection.dart'),
        );

        expect(
          rewritten,
          equals('''
// Header comment
import 'package:collection/shadowed_collection.dart';
import 'package:meta/meta.dart';

void main() {}
'''),
        );
      },
    );
  });
}
