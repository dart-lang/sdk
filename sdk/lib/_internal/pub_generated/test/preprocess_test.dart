// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.test.preprocess_test;

import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';

import '../lib/src/preprocess.dart';
import 'test_pub.dart';

main() {
  initConfig();

  test("does nothing on a file without preprocessor directives", () {
    var text = '''
some text
// normal comment
// #
 //# not beginning of line
''';

    expect(_preprocess(text), equals(text));
  });

  test("allows bare insert directive", () {
    expect(_preprocess('//> foo'), equals('foo'));
  });

  test("allows empty insert directive", () {
    expect(_preprocess('''
//> foo
//>
//> bar
'''), equals('foo\n\nbar\n'));
  });

  group("if", () {
    group("with a version range", () {
      test("removes sections with non-matching versions", () {
        expect(_preprocess('''
before
//# if barback <1.0.0
inside
//# end
after
'''), equals('''
before
after
'''));
      });

      test("doesn't insert section with non-matching versions", () {
        expect(_preprocess('''
before
//# if barback <1.0.0
//> inside
//# end
after
'''), equals('''
before
after
'''));
      });

      test("doesn't remove sections with matching versions", () {
        expect(_preprocess('''
before
//# if barback >1.0.0
inside
//# end
after
'''), equals('''
before
inside
after
'''));
      });

      test("inserts sections with matching versions", () {
        expect(_preprocess('''
before
//# if barback >1.0.0
//> inside
//# end
after
'''), equals('''
before
inside
after
'''));
      });

      test("allows multi-element version ranges", () {
        expect(_preprocess('''
before
//# if barback >=1.0.0 <2.0.0
inside 1
//# end
//# if barback >=0.9.0 <1.0.0
inside 2
//# end
after
'''), equals('''
before
inside 1
after
'''));
      });
    });

    group("with a package name", () {
      test("removes sections for a nonexistent package", () {
        expect(_preprocess('''
before
//# if fblthp
inside
//# end
after
'''), equals('''
before
after
'''));
      });

      test("doesn't insert sections for a nonexistent package", () {
        expect(_preprocess('''
before
//# if fblthp
//> inside
//# end
after
'''), equals('''
before
after
'''));
      });

      test("doesn't remove sections with an existent package", () {
        expect(_preprocess('''
before
//# if barback
inside
//# end
after
'''), equals('''
before
inside
after
'''));
      });

      test("inserts sections with an existent package", () {
        expect(_preprocess('''
before
//# if barback
//> inside
//# end
after
'''), equals('''
before
inside
after
'''));
      });
    });
  });

  group("else", () {
    test("removes non-matching sections", () {
      expect(_preprocess('''
before
//# if barback >1.0.0
inside 1
//# else
inside 2
//# end
after
'''), equals('''
before
inside 1
after
'''));
    });

    test("doesn't insert non-matching sections", () {
      expect(_preprocess('''
before
//# if barback >1.0.0
inside 1
//# else
//> inside 2
//# end
after
'''), equals('''
before
inside 1
after
'''));
    });

    test("doesn't remove matching sections", () {
      expect(_preprocess('''
before
//# if barback <1.0.0
inside 1
//# else
inside 2
//# end
after
'''), equals('''
before
inside 2
after
'''));
    });

    test("inserts matching sections", () {
      expect(_preprocess('''
before
//# if barback <1.0.0
inside 1
//# else
//> inside 2
//# end
after
'''), equals('''
before
inside 2
after
'''));
    });
  });

  group("errors", () {
    test("disallows unknown statements", () {
      expect(() => _preprocess('//# foo bar\n//# end'), throwsFormatException);
    });

    test("disallows insert directive without space", () {
      expect(() => _preprocess('//>foo'), throwsFormatException);
    });

    group("if", () {
      test("disallows if with no arguments", () {
        expect(() => _preprocess('//# if\n//# end'), throwsFormatException);
      });

      test("disallows if with no package", () {
        expect(
            () => _preprocess('//# if <=1.0.0\n//# end'),
            throwsFormatException);
      });

      test("disallows invalid version constraint", () {
        expect(
            () => _preprocess('//# if barback >=1.0\n//# end'),
            throwsFormatException);
      });

      test("disallows dangling end", () {
        expect(() => _preprocess('//# end'), throwsFormatException);
      });

      test("disallows if without end", () {
        expect(
            () => _preprocess('//# if barback >=1.0.0'),
            throwsFormatException);
      });

      test("disallows nested if", () {
        expect(() => _preprocess('''
//# if barback >=1.0.0
//# if barback >= 1.5.0
//# end
//# end
'''), throwsFormatException);
      });
    });

    group("else", () {
      test("disallows else without if", () {
        expect(() => _preprocess('//# else\n//# end'), throwsFormatException);
      });

      test("disallows else without end", () {
        expect(
            () => _preprocess('//# if barback >=1.0.0\n//# else'),
            throwsFormatException);
      });

      test("disallows else with an argument", () {
        expect(() => _preprocess('''
//# if barback >=1.0.0
//# else barback <0.5.0
//# end
'''), throwsFormatException);
      });
    });
  });
}

String _preprocess(String input) => preprocess(input, {
  'barback': new Version.parse("1.2.3")
}, 'source/url');
