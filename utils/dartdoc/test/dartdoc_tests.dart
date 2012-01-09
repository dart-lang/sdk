// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for dartdoc.
#library('dartdoc_tests');

#import('../dartdoc.dart');
#import('../markdown.dart', prefix: 'md');

// TODO(rnystrom): Better path to unittest.
#import('../../../client/testing/unittest/unittest_node.dart');
#import('../../../frog/lang.dart');
#import('../../../frog/file_system_node.dart');

main() {
  var files = new NodeFileSystem();
  parseOptions('../../frog', [], files);
  initializeWorld(files);

  group('countOccurrences', () {
    test('empty text returns 0', () {
      expect(countOccurrences('', 'needle')).equals(0);
    });

    test('one occurrence', () {
      expect(countOccurrences('bananarama', 'nara')).equals(1);
    });

    test('multiple occurrences', () {
      expect(countOccurrences('bananarama', 'a')).equals(5);
    });

    test('overlapping matches do not count', () {
      expect(countOccurrences('bananarama', 'ana')).equals(1);
    });
  });

  group('repeat', () {
    test('zero times returns an empty string', () {
      expect(repeat('ba', 0)).equals('');
    });

    test('one time returns the string', () {
      expect(repeat('ba', 1)).equals('ba');
    });

    test('multiple times', () {
      expect(repeat('ba', 3)).equals('bababa');
    });

    test('multiple times with a separator', () {
      expect(repeat('ba', 3, separator: ' ')).equals('ba ba ba');
    });
  });

  group('isAbsolute', () {
    test('returns false if there is no scheme', () {
      expect(isAbsolute('index.html')).isFalse();
      expect(isAbsolute('foo/index.html')).isFalse();
      expect(isAbsolute('foo/bar/index.html')).isFalse();
    });

    test('returns true if there is a scheme', () {
      expect(isAbsolute('http://google.com')).isTrue();
      expect(isAbsolute('hTtPs://google.com')).isTrue();
      expect(isAbsolute('mailto:fake@email.com')).isTrue();
    });
  });

  group('relativePath', () {
    test('absolute path is unchanged', () {
      startFile('dir/sub/file.html');
      expect(relativePath('http://google.com')).equals('http://google.com');
    });

    test('from root to root', () {
      startFile('root.html');
      expect(relativePath('other.html')).equals('other.html');
    });

    test('from root to directory', () {
      startFile('root.html');
      expect(relativePath('dir/file.html')).equals('dir/file.html');
    });

    test('from root to nested', () {
      startFile('root.html');
      expect(relativePath('dir/sub/file.html')).equals('dir/sub/file.html');
    });

    test('from directory to root', () {
      startFile('dir/file.html');
      expect(relativePath('root.html')).equals('../root.html');
    });

    test('from nested to root', () {
      startFile('dir/sub/file.html');
      expect(relativePath('root.html')).equals('../../root.html');
    });

    test('from dir to dir with different path', () {
      startFile('dir/file.html');
      expect(relativePath('other/file.html')).equals('../other/file.html');
    });

    test('from nested to nested with different path', () {
      startFile('dir/sub/file.html');
      expect(relativePath('other/sub/file.html')).equals(
          '../../other/sub/file.html');
    });

    test('from nested to directory with different path', () {
      startFile('dir/sub/file.html');
      expect(relativePath('other/file.html')).equals(
          '../../other/file.html');
    });
  });

  group('name reference', () {
    var doc = new Dartdoc();
    doc.document('test/dummy.dart');
    var dummy = world.libraries['test/dummy.dart'];
    var klass = dummy.findTypeByName('Class');
    var method = klass.getMember('method');

    String render(md.Node node) => md.renderToHtml([node]);

    test('to a parameter of the current method', () {
      expect(render(doc.resolveNameReference('param', currentMember: method))).
        equals('<span class="param">param</span>');
    });

    test('to a member of the current type', () {
      expect(render(doc.resolveNameReference('method', currentType: klass))).
        equals('<a href="../../dummy/Class.html#method" class="crossref">' +
            'method</a>');
    });

    test('to a property with only a getter links to the getter', () {
      expect(render(doc.resolveNameReference('getterOnly',
                  currentType: klass))).
        equals('<a href="../../dummy/Class.html#get:getterOnly" ' +
            'class="crossref">getterOnly</a>');
    });

    test('to a property with only a setter links to the setter', () {
      expect(render(doc.resolveNameReference('setterOnly',
                  currentType: klass))).
        equals('<a href="../../dummy/Class.html#set:setterOnly" ' +
            'class="crossref">setterOnly</a>');
    });

    test('to a property with a getter and setter links to the getter', () {
      expect(render(doc.resolveNameReference('getterAndSetter',
                  currentType: klass))).
        equals('<a href="../../dummy/Class.html#get:getterAndSetter" ' +
            'class="crossref">getterAndSetter</a>');
    });

    test('to a type in the current library', () {
      expect(render(doc.resolveNameReference('Class', currentLibrary: dummy))).
        equals('<a href="../../dummy/Class.html" class="crossref">Class</a>');
    });

    test('to a top-level member in the current library', () {
      expect(render(doc.resolveNameReference('topLevelMethod',
                  currentLibrary: dummy))).
        equals('<a href="../../dummy.html#topLevelMethod" class="crossref">' +
            'topLevelMethod</a>');
    });

    test('to an unknown name', () {
      expect(render(doc.resolveNameReference('unknownName',
                  currentLibrary: dummy, currentType: klass,
                  currentMember: method))).
        equals('<code>unknownName</code>');
    });
  });
}
