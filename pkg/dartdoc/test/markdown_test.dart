// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for markdown.
#library('markdown_tests');

// TODO(rnystrom): Use "package:" URL (#4968).
#import('../lib/markdown.dart');

// TODO(rnystrom): Better path to unittest.
#import('../../unittest/unittest.dart');

/// Most of these tests are based on observing how showdown behaves:
/// http://softwaremaniacs.org/playground/showdown-highlight/
void main() {
  group('Paragraphs', () {
    validate('consecutive lines form a single paragraph', '''
        This is the first line.
        This is the second line.
        ''', '''
        <p>This is the first line.
        This is the second line.</p>
        ''');

    // TODO(rnystrom): The rules here for what happens to lines following a
    // paragraph appear to be completely arbitrary in markdown. If it makes the
    // code significantly cleaner, we should consider ourselves free to change
    // these tests.

    validate('are terminated by a header', '''
        para
        # header
        ''', '''
        <p>para</p>
        <h1>header</h1>
        ''');

    validate('are terminated by a setext header', '''
        para
        header
        ==
        ''', '''
        <p>para</p>
        <h1>header</h1>
        ''');

    validate('are terminated by a hr', '''
        para
        ___
        ''', '''
        <p>para</p>
        <hr />
        ''');

    validate('consume an unordered list', '''
        para
        * list
        ''', '''
        <p>para
        * list</p>
        ''');

    validate('consume an ordered list', '''
        para
        1. list
        ''', '''
        <p>para
        1. list</p>
        ''');
  });

  group('Setext headers', () {
    validate('h1', '''
        text
        ===
        ''', '''
        <h1>text</h1>
        ''');

    validate('h2', '''
        text
        ---
        ''', '''
        <h2>text</h2>
        ''');

    validate('h1 on first line becomes text', '''
        ===
        ''', '''
        <p>===</p>
        ''');

    validate('h2 on first line becomes text', '''
        -
        ''', '''
        <p>-</p>
        ''');

    validate('h1 turns preceding list into text', '''
        - list
        ===
        ''', '''
        <h1>- list</h1>
        ''');

    validate('h2 turns preceding list into text', '''
        - list
        ===
        ''', '''
        <h1>- list</h1>
        ''');

    validate('h1 turns preceding blockquote into text', '''
        > quote
        ===
        ''', '''
        <h1>> quote</h1>
        ''');

    validate('h2 turns preceding blockquote into text', '''
        > quote
        ===
        ''', '''
        <h1>> quote</h1>
        ''');
  });

  group('Headers', () {
    validate('h1', '''
        # header
        ''', '''
        <h1>header</h1>
        ''');

    validate('h2', '''
        ## header
        ''', '''
        <h2>header</h2>
        ''');

    validate('h3', '''
        ### header
        ''', '''
        <h3>header</h3>
        ''');

    validate('h4', '''
        #### header
        ''', '''
        <h4>header</h4>
        ''');

    validate('h5', '''
        ##### header
        ''', '''
        <h5>header</h5>
        ''');

    validate('h6', '''
        ###### header
        ''', '''
        <h6>header</h6>
        ''');

    validate('trailing "#" are removed', '''
        # header ######
        ''', '''
        <h1>header</h1>
        ''');

  });

  group('Unordered lists', () {
    validate('asterisk, plus and hyphen', '''
        * star
        - dash
        + plus
        ''', '''
        <ul>
          <li>star</li>
          <li>dash</li>
          <li>plus</li>
        </ul>
        ''');

    validate('allow numbered lines after first', '''
        * a
        1. b
        ''', '''
        <ul>
          <li>a</li>
          <li>b</li>
        </ul>
        ''');

    validate('allow a tab after the marker', '''
        *\ta
        +\tb
        -\tc
        1.\td
        ''', '''
        <ul>
          <li>a</li>
          <li>b</li>
          <li>c</li>
          <li>d</li>
        </ul>
        ''');

    validate('wrap items in paragraphs if blank lines separate', '''
        * one

        * two
        ''', '''
        <ul>
          <li><p>one</p></li>
          <li><p>two</p></li>
        </ul>
        ''');

    validate('force paragraph on item before and after blank lines', '''
        *   one
        *   two

        *   three
        ''', '''
        <ul>
          <li>one</li>
          <li>
            <p>two</p>
          </li>
          <li>
            <p>three</p>
          </li>
        </ul>
        ''');

    validate('do not force paragraph if item is already block', '''
        * > quote

        * # header
        ''', '''
        <ul>
          <li><blockquote><p>quote</p></blockquote></li>
          <li><h1>header</h1></li>
        </ul>
        ''');

    validate('can contain multiple paragraphs', '''
        *   one

            two

        *   three
        ''', '''
        <ul>
          <li>
            <p>one</p>
            <p>two</p>
          </li>
          <li>
            <p>three</p>
          </li>
        </ul>
        ''');

    // TODO(rnystrom): This is how most other markdown parsers handle
    // this but that seems like a nasty special case. For now, let's not
    // worry about it.
    /*
    validate('can nest using indentation', '''
        *   parent
            *   child
        ''', '''
        <ul>
        <li>parent
        <ul><li>child</li></ul></li>
        </ul>
        ''');
    */
  });

  group('Ordered lists', () {
    validate('start with numbers', '''
        1. one
        45.  two
           12345. three
        ''', '''
        <ol>
          <li>one</li>
          <li>two</li>
          <li>three</li>
        </ol>
        ''');

    validate('allow unordered lines after first', '''
        1. a
        * b
        ''', '''
        <ol>
          <li>a</li>
          <li>b</li>
        </ol>
        ''');
  });

  group('Blockquotes', () {
    validate('single line', '''
        > blah
        ''', '''
        <blockquote>
          <p>blah</p>
        </blockquote>
        ''');

    validate('with two paragraphs', '''
        > first
        >
        > second
        ''', '''
        <blockquote>
          <p>first</p>
          <p>second</p>
        </blockquote>
        ''');

    validate('nested', '''
        > one
        >> two
        > > > three
        ''', '''
        <blockquote>
          <p>one</p>
          <blockquote>
            <p>two</p>
            <blockquote>
              <p>three</p>
            </blockquote>
          </blockquote>
        </blockquote>
        ''');
  });

  group('Code blocks', () {
    validate('single line', '''
            code
        ''', '''
        <pre><code>code</code></pre>
        ''');

    validate('include leading whitespace after indentation', '''
            zero
             one
              two
               three
        ''', '''
        <pre><code>zero
         one
          two
           three</code></pre>
        ''');

    validate('escape HTML characters', '''
            <&>
        ''', '''
        <pre><code>&lt;&amp;&gt;</code></pre>
        ''');
  });

  group('Horizontal rules', () {
    validate('from dashes', '''
        ---
        ''', '''
        <hr />
        ''');

    validate('from asterisks', '''
        ***
        ''', '''
        <hr />
        ''');

    validate('from underscores', '''
        ___
        ''', '''
        <hr />
        ''');

    validate('can include up to two spaces', '''
        _ _  _
        ''', '''
        <hr />
        ''');
  });

  group('Block-level HTML', () {
    validate('single line', '''
        <table></table>
        ''', '''
        <table></table>
        ''');

    validate('multi-line', '''
        <table>
            blah
        </table>
        ''', '''
        <table>
            blah
        </table>
        ''');

    validate('blank line ends block', '''
        <table>
            blah
        </table>

        para
        ''', '''
        <table>
            blah
        </table>
        <p>para</p>
        ''');

    validate('HTML can be bogus', '''
        <bogus>
        blah
        </weird>

        para
        ''', '''
        <bogus>
        blah
        </weird>
        <p>para</p>
        ''');
  });

  group('Strong', () {
    validate('using asterisks', '''
        before **strong** after
        ''', '''
        <p>before <strong>strong</strong> after</p>
        ''');

    validate('using underscores', '''
        before __strong__ after
        ''', '''
        <p>before <strong>strong</strong> after</p>
        ''');

    validate('unmatched asterisks', '''
        before ** after
        ''', '''
        <p>before ** after</p>
        ''');

    validate('unmatched underscores', '''
        before __ after
        ''', '''
        <p>before __ after</p>
        ''');

    validate('multiple spans in one text', '''
        a **one** b __two__ c
        ''', '''
        <p>a <strong>one</strong> b <strong>two</strong> c</p>
        ''');

    validate('multi-line', '''
        before **first
        second** after
        ''', '''
        <p>before <strong>first
        second</strong> after</p>
        ''');
  });

  group('Emphasis and strong', () {
    validate('single asterisks', '''
        before *em* after
        ''', '''
        <p>before <em>em</em> after</p>
        ''');

    validate('single underscores', '''
        before _em_ after
        ''', '''
        <p>before <em>em</em> after</p>
        ''');

    validate('double asterisks', '''
        before **strong** after
        ''', '''
        <p>before <strong>strong</strong> after</p>
        ''');

    validate('double underscores', '''
        before __strong__ after
        ''', '''
        <p>before <strong>strong</strong> after</p>
        ''');

    validate('unmatched asterisk', '''
        before *after
        ''', '''
        <p>before *after</p>
        ''');

    validate('unmatched underscore', '''
        before _after
        ''', '''
        <p>before _after</p>
        ''');

    validate('multiple spans in one text', '''
        a *one* b _two_ c
        ''', '''
        <p>a <em>one</em> b <em>two</em> c</p>
        ''');

    validate('multi-line', '''
        before *first
        second* after
        ''', '''
        <p>before <em>first
        second</em> after</p>
        ''');

    validate('not processed when surrounded by spaces', '''
        a * b * c _ d _ e
        ''', '''
        <p>a * b * c _ d _ e</p>
        ''');

    validate('strong then emphasis', '''
        **strong***em*
        ''', '''
        <p><strong>strong</strong><em>em</em></p>
        ''');

    validate('emphasis then strong', '''
        *em***strong**
        ''', '''
        <p><em>em</em><strong>strong</strong></p>
        ''');

    validate('emphasis inside strong', '''
        **strong *em***
        ''', '''
        <p><strong>strong <em>em</em></strong></p>
        ''');

    validate('mismatched in nested', '''
        *a _b* c_
        ''', '''
        <p><em>a _b</em> c_</p>
        ''');

    validate('cannot nest tags of same type', '''
        *a _b *c* d_ e*
        ''', '''
        <p><em>a _b </em>c<em> d_ e</em></p>
        ''');
  });

  group('Inline code', () {
    validate('simple case', '''
        before `source` after
        ''', '''
        <p>before <code>source</code> after</p>
        ''');

    validate('unmatched backtick', '''
        before ` after
        ''', '''
        <p>before ` after</p>
        ''');
    validate('multiple spans in one text', '''
        a `one` b `two` c
        ''', '''
        <p>a <code>one</code> b <code>two</code> c</p>
        ''');

    validate('multi-line', '''
        before `first
        second` after
        ''', '''
        <p>before <code>first
        second</code> after</p>
        ''');

    validate('double backticks', '''
        before ``can `contain` backticks`` after
        ''', '''
        <p>before <code>can `contain` backticks</code> after</p>
        ''');

    validate('double backticks with spaces', '''
        before `` `tick` `` after
        ''', '''
        <p>before <code>`tick`</code> after</p>
        ''');

    validate('multiline double backticks with spaces', '''
        before ``in `tick`
        another`` after
        ''', '''
        <p>before <code>in `tick`
        another</code> after</p>
        ''');

    validate('ignore markup inside code', '''
        before `*b* _c_` after
        ''', '''
        <p>before <code>*b* _c_</code> after</p>
        ''');

    validate('escape HTML characters', '''
        `<&>`
        ''', '''
        <p><code>&lt;&amp;&gt;</code></p>
        ''');

    validate('escape HTML tags', '''
        '*' `<em>`
        ''', '''
        <p>'*' <code>&lt;em&gt;</code></p>
        ''');
  });

  group('HTML encoding', () {
    validate('less than and ampersand are escaped', '''
        < &
        ''', '''
        <p>&lt; &amp;</p>
        ''');
    validate('greater than is not escaped', '''
        not you >
        ''', '''
        <p>not you ></p>
        ''');
    validate('existing entities are untouched', '''
        &amp;
        ''', '''
        <p>&amp;</p>
        ''');
  });

  group('Autolinks', () {
    validate('basic link', '''
        before <http://foo.com/> after
        ''', '''
        <p>before <a href="http://foo.com/">http://foo.com/</a> after</p>
        ''');
    validate('handles ampersand in url', '''
        <http://foo.com/?a=1&b=2>
        ''', '''
        <p><a href="http://foo.com/?a=1&b=2">http://foo.com/?a=1&amp;b=2</a></p>
        ''');
  });

  group('Reference links', () {
    validate('double quotes for title', '''
        links [are] [a] awesome

        [a]: http://foo.com "woo"
        ''', '''
        <p>links <a href="http://foo.com" title="woo">are</a> awesome</p>
        ''');
    validate('single quoted title', """
        links [are] [a] awesome

        [a]: http://foo.com 'woo'
        """, '''
        <p>links <a href="http://foo.com" title="woo">are</a> awesome</p>
        ''');
    validate('parentheses for title', '''
        links [are] [a] awesome

        [a]: http://foo.com (woo)
        ''', '''
        <p>links <a href="http://foo.com" title="woo">are</a> awesome</p>
        ''');
    validate('no title', '''
        links [are] [a] awesome

        [a]: http://foo.com
        ''', '''
        <p>links <a href="http://foo.com">are</a> awesome</p>
        ''');
    validate('unknown link becomes plaintext', '''
        [not] [known]
        ''', '''
        <p>[not] [known]</p>
        ''');
    validate('can style link contents', '''
        links [*are*] [a] awesome

        [a]: http://foo.com
        ''', '''
        <p>links <a href="http://foo.com"><em>are</em></a> awesome</p>
        ''');
    validate('inline styles after a bad link are processed', '''
        [bad] `code`
        ''', '''
        <p>[bad] <code>code</code></p>
        ''');
    validate('empty reference uses text from link', '''
        links [are][] awesome

        [are]: http://foo.com
        ''', '''
        <p>links <a href="http://foo.com">are</a> awesome</p>
        ''');
    validate('references are case-insensitive', '''
        links [ARE][] awesome

        [are]: http://foo.com
        ''', '''
        <p>links <a href="http://foo.com">ARE</a> awesome</p>
        ''');
  });

  group('Inline links', () {
    validate('double quotes for title', '''
        links [are](http://foo.com "woo") awesome
        ''', '''
        <p>links <a href="http://foo.com" title="woo">are</a> awesome</p>
        ''');
    validate('no title', '''
        links [are] (http://foo.com) awesome
        ''', '''
        <p>links <a href="http://foo.com">are</a> awesome</p>
        ''');
    validate('can style link contents', '''
        links [*are*](http://foo.com) awesome
        ''', '''
        <p>links <a href="http://foo.com"><em>are</em></a> awesome</p>
        ''');
  });
}

/**
 * Removes eight spaces of leading indentation from a multiline string.
 *
 * Note that this is very sensitive to how the literals are styled. They should
 * be:
 *     '''
 *     Text starts on own line. Lines up with subsequent lines.
 *     Lines are indented exactly 8 characters from the left margin.'''
 *
 * This does nothing if text is only a single line.
 */
// TODO(nweiz): Make this auto-detect the indentation level from the first
// non-whitespace line.
String cleanUpLiteral(String text) {
  var lines = text.split('\n');
  if (lines.length <= 1) return text;

  for (var j = 0; j < lines.length; j++) {
    if (lines[j].length > 8) {
      lines[j] = lines[j].substring(8, lines[j].length);
    } else {
      lines[j] = '';
    }
  }

  return Strings.join(lines, '\n');
}

validate(String description, String markdown, String html) {
  test(description, () {
    markdown = cleanUpLiteral(markdown);
    html = cleanUpLiteral(html);

    var result = markdownToHtml(markdown);
    var passed = compareOutput(html, result);

    if (!passed) {
      // Remove trailing newline.
      html = html.substring(0, html.length - 1);

      print('FAIL: $description');
      print('  expect: ${html.replaceAll("\n", "\n          ")}');
      print('  actual: ${result.replaceAll("\n", "\n          ")}');
      print('');
    }

    expect(passed, isTrue);
  });
}

/// Does a loose comparison of the two strings of HTML. Ignores differences in
/// newlines and indentation.
compareOutput(String a, String b) {
  int i = 0;
  int j = 0;

  skipIgnored(String s, int i) {
    // Ignore newlines.
    while ((i < s.length) && (s[i] == '\n')) {
      i++;
      // Ignore indentation.
      while ((i < s.length) && (s[i] == ' ')) i++;
    }

    return i;
  }

  while (true) {
    i = skipIgnored(a, i);
    j = skipIgnored(b, j);

    // If one string runs out of non-ignored strings, the other must too.
    if (i == a.length) return j == b.length;
    if (j == b.length) return i == a.length;

    if (a[i] != b[j]) return false;
    i++;
    j++;
  }
}
