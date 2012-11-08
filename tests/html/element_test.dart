// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

expectLargeRect(ClientRect rect) {
  expect(rect.top, 0);
  expect(rect.left, 0);
  expect(rect.width, greaterThan(100));
  expect(rect.height, greaterThan(100));
  expect(rect.bottom, rect.top + rect.height);
  expect(rect.right, rect.left + rect.width);
}

void testEventHelper(EventListenerList listenerList, String type,
    [Function registerOnEventListener = null]) {
  testMultipleEventHelper(listenerList, [type], registerOnEventListener);
}
// Allows testing where we polyfill different browsers firing different events.
void testMultipleEventHelper(EventListenerList listenerList, List<String> types,
    [Function registerOnEventListener = null]) {
  bool firedWhenAddedToListenerList = false;
  bool firedOnEvent = false;
  listenerList.add((e) {
    firedWhenAddedToListenerList = true;
  });
  if (registerOnEventListener != null) {
    registerOnEventListener((e) {
      firedOnEvent = true;
    });
  }
  for (var type in types) {
    final event = new Event(type);
    listenerList.dispatch(event);
  }

  expect(firedWhenAddedToListenerList, isTrue);
  if (registerOnEventListener != null) {
    expect(firedOnEvent, isTrue);
  }
}

void testConstructorHelper(String tag, String htmlSnippet,
    String expectedText, Function isExpectedClass) {
  expect(isExpectedClass(new Element.tag(tag)), isTrue);
  final elementFromSnippet = new Element.html(htmlSnippet);
  expect(isExpectedClass(elementFromSnippet), isTrue);
  expect(elementFromSnippet.text, expectedText);
}

main() {
  useHtmlConfiguration();

  var isHRElement = predicate((x) => x is HRElement, 'is a HRElement');
  var isBRElement = predicate((x) => x is BRElement, 'is a BRElement');
  var isInputElement =
      predicate((x) => x is InputElement, 'is an InputElement');
  var isImageElement =
      predicate((x) => x is ImageElement, 'is an ImageElement');
  var isSpanElement = predicate((x) => x is SpanElement, 'is a SpanElement');
  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');
  var isElementList =
      predicate((x) => x is List<Element>, 'is a List<Element>');
  var isHeadingElement =
      predicate((x) => x is HeadingElement, 'is a HeadingElement');

  Element makeElement() => new Element.tag('div');

  Element makeElementWithChildren() =>
    new Element.html("<div><br/><img/><input/></div>");

  test('computedStyle', () {
    final element = document.body;
    element.computedStyle.then(expectAsync1((style) {
      expect(style.getPropertyValue('left'), 'auto');
    }));
  });

  test('rect', () {
    final container = new Element.tag("div");
    container.style.position = 'absolute';
    container.style.top = '8px';
    container.style.left = '8px';
    final element = new Element.tag("div");
    element.style.width = '200px';
    element.style.height = '200px';
    container.elements.add(element);
    document.body.elements.add(container);

    element.rect.then(expectAsync1((rect) {
      expectLargeRect(rect.client);
      expectLargeRect(rect.offset);
      expectLargeRect(rect.scroll);
      expect(rect.bounding.left, 8);
      expect(rect.bounding.top, 8);
      expect(rect.clientRects.length, greaterThan(0));
      container.remove();
    }));
  });

  test('client position synchronous', () {
    final container = new Element.tag("div");
    container.style.position = 'absolute';
    container.style.top = '8px';
    container.style.left = '8px';
    final element = new Element.tag("div");
    element.style.width = '200px';
    element.style.height = '200px';
    container.elements.add(element);
    document.body.elements.add(container);

    expect(element.clientWidth, greaterThan(100));
    expect(element.clientHeight, greaterThan(100));
    expect(element.offsetWidth, greaterThan(100));
    expect(element.offsetHeight, greaterThan(100));
    expect(element.scrollWidth, greaterThan(100));
    expect(element.scrollHeight, greaterThan(100));
    expect(element.getBoundingClientRect().left, 8);
    expect(element.getBoundingClientRect().top, 8);
    container.remove();
  });

  group('constructors', () {
    test('error', () {
      expect(() => new Element.html('<br/><br/>'), throwsArgumentError);
    });

    test('.html has no parent', () =>
        expect(new Element.html('<br/>').parent, isNull));

    test('a', () => testConstructorHelper('a', '<a>foo</a>', 'foo',
        (element) => element is AnchorElement));
    test('area', () => testConstructorHelper('area', '<area>foo</area>', '',
        (element) => element is AreaElement));
    // TODO(jacobr): audio tags cause tests to segfault when using dartium.
    // b/5522106.
    // test('audio', () => testConstructorHelper('audio',
    //     '<audio>foo</audio>', 'foo',
    //     (element) => element is AudioElement));
    test('br', () => testConstructorHelper('br', '<br>', '',
        (element) => element is BRElement));
    test('base', () => testConstructorHelper('base', '<base>foo</base>', '',
        (element) => element is BaseElement));
    test('blockquote', () => testConstructorHelper('blockquote',
        '<blockquote>foo</blockquote>', 'foo',
        (element) => element is QuoteElement));
    test('body', () => testConstructorHelper('body',
        '<body><div>foo</div></body>', 'foo',
        (element) => element is BodyElement));
    test('button', () => testConstructorHelper('button',
        '<button>foo</button>', 'foo',
        (element) => element is ButtonElement));
    test('canvas', () => testConstructorHelper('canvas',
        '<canvas>foo</canvas>', 'foo',
        (element) => element is CanvasElement));
    test('dl', () => testConstructorHelper('dl', '<dl>foo</dl>', 'foo',
        (element) => element is DListElement));
    // TODO(jacobr): WebKit doesn't yet support the DataList class.
    // test('datalist', () => testConstructorHelper('datalist',
    //     '<datalist>foo</datalist>', 'foo',
    //     (element) => element is DataListElement));
    test('div', () => testConstructorHelper('div', '<div>foo</div>', 'foo',
        (element) => element is DivElement));
    test('fieldset', () => testConstructorHelper('fieldset',
        '<fieldset>foo</fieldset>', 'foo',
        (element) => element is FieldSetElement));
    test('font', () => testConstructorHelper('font', '<font>foo</font>', 'foo',
        (element) => element is FontElement));
    test('form', () => testConstructorHelper('form', '<form>foo</form>', 'foo',
        (element) => element is FormElement));
    test('hr', () => testConstructorHelper('hr', '<hr>', '',
        (element) => element is HRElement));
    test('head', () => testConstructorHelper('head',
        '<head><script>foo;</script></head>', 'foo;',
        (element) => element is HeadElement));
    test('h1', () => testConstructorHelper('h1', '<h1>foo</h1>', 'foo',
        (element) => element is HeadingElement));
    test('h2', () => testConstructorHelper('h2', '<h2>foo</h2>', 'foo',
        (element) => element is HeadingElement));
    test('h3', () => testConstructorHelper('h3', '<h3>foo</h3>', 'foo',
        (element) => element is HeadingElement));
    test('h4', () => testConstructorHelper('h4', '<h4>foo</h4>', 'foo',
        (element) => element is HeadingElement));
    test('h5', () => testConstructorHelper('h5', '<h5>foo</h5>', 'foo',
        (element) => element is HeadingElement));
    test('h6', () => testConstructorHelper('h6', '<h6>foo</h6>', 'foo',
        (element) => element is HeadingElement));
    test('iframe', () => testConstructorHelper('iframe',
        '<iframe>foo</iframe>', 'foo',
        (element) => element is IFrameElement));
    test('img', () => testConstructorHelper('img', '<img>', '',
        (element) => element is ImageElement));
    test('input', () => testConstructorHelper('input', '<input/>', '',
        (element) => element is InputElement));
    test('li', () => testConstructorHelper('li', '<li>foo</li>', 'foo',
        (element) => element is LIElement));
    test('label', () => testConstructorHelper('label',
        '<label>foo</label>', 'foo',
        (element) => element is LabelElement));
    test('legend', () => testConstructorHelper('legend',
        '<legend>foo</legend>', 'foo',
        (element) => element is LegendElement));
    test('link', () => testConstructorHelper('link', '<link>', '',
        (element) => element is LinkElement));
    test('map', () => testConstructorHelper('map', '<map>foo</map>', 'foo',
        (element) => element is MapElement));
    test('menu', () => testConstructorHelper('menu', '<menu>foo</menu>', 'foo',
        (element) => element is MenuElement));
    test('meta', () => testConstructorHelper('meta', '<meta>', '',
        (element) => element is MetaElement));
    test('del', () => testConstructorHelper('del', '<del>foo</del>', 'foo',
        (element) => element is ModElement));
    test('ins', () => testConstructorHelper('ins', '<ins>foo</ins>', 'foo',
        (element) => element is ModElement));
    test('ol', () => testConstructorHelper('ol', '<ol>foo</ol>', 'foo',
        (element) => element is OListElement));
    test('optgroup', () => testConstructorHelper('optgroup',
        '<optgroup>foo</optgroup>', 'foo',
        (element) => element is OptGroupElement));
    test('option', () => testConstructorHelper('option',
        '<option>foo</option>', 'foo',
        (element) => element is OptionElement));
    test('output', () => testConstructorHelper('output',
        '<output>foo</output>', 'foo',
        (element) => element is OutputElement));
    test('p', () => testConstructorHelper('p', '<p>foo</p>', 'foo',
        (element) => element is ParagraphElement));
    test('param', () => testConstructorHelper('param', '<param>', '',
        (element) => element is ParamElement));
    test('pre', () => testConstructorHelper('pre', '<pre>foo</pre>', 'foo',
        (element) => element is PreElement));
    test('progress', () => testConstructorHelper('progress',
        '<progress>foo</progress>', 'foo',
        (element) => element is ProgressElement));
    test('q', () => testConstructorHelper('q', '<q>foo</q>', 'foo',
        (element) => element is QuoteElement));
    test('script', () => testConstructorHelper('script',
        '<script>foo</script>', 'foo',
        (element) => element is ScriptElement));
    test('select', () => testConstructorHelper('select',
        '<select>foo</select>', 'foo',
        (element) => element is SelectElement));
    // TODO(jacobr): audio tags cause tests to segfault when using dartium.
    // b/5522106.
    // test('source', () => testConstructorHelper('source', '<source>', '',
    //                      (element) => element is SourceElement));
    test('span', () => testConstructorHelper('span', '<span>foo</span>', 'foo',
        (element) => element is SpanElement));
    test('style', () => testConstructorHelper('style',
        '<style>foo</style>', 'foo',
        (element) => element is StyleElement));
    test('caption', () => testConstructorHelper('caption',
        '<caption>foo</caption>', 'foo',
        (element) => element is TableCaptionElement));
    test('td', () => testConstructorHelper('td', '<td>foo</td>', 'foo',
        (element) => element is TableCellElement));
    test('colgroup', () => testConstructorHelper('colgroup',
        '<colgroup></colgroup>', '',
        (element) => element is TableColElement));
    test('col', () => testConstructorHelper('col', '<col></col>', '',
        (element) => element is TableColElement));
    test('table', () => testConstructorHelper('table',
        '<table><caption>foo</caption></table>', 'foo',
        (element) => element is TableElement));
    test('tr', () => testConstructorHelper('tr',
        '<tr><td>foo</td></tr>', 'foo',
        (element) => element is TableRowElement));
    test('tbody', () => testConstructorHelper('tbody',
        '<tbody><tr><td>foo</td></tr></tbody>', 'foo',
        (element) => element is TableSectionElement));
    test('tfoot', () => testConstructorHelper('tfoot',
        '<tfoot><tr><td>foo</td></tr></tfoot>', 'foo',
        (element) => element is TableSectionElement));
    test('thead', () => testConstructorHelper('thead',
        '<thead><tr><td>foo</td></tr></thead>', 'foo',
        (element) => element is TableSectionElement));
    test('textarea', () => testConstructorHelper('textarea',
        '<textarea>foo</textarea>', 'foo',
        (element) => element is TextAreaElement));
    test('title', () => testConstructorHelper('title',
        '<title>foo</title>', 'foo',
        (element) => element is TitleElement));
    // TODO(jacobr): audio tags cause tests to segfault when using dartium.
    // b/5522106.
    // test('track', () => testConstructorHelper('track', '<track>', '',
    //                      (element) => element is TrackElement));
    test('ul', () => testConstructorHelper('ul', '<ul>foo</ul>', 'foo',
        (element) => element is UListElement));
    // TODO(jacobr): video tags cause tests to segfault when using dartium.
    // b/5522106.
    // test('video', () => testConstructorHelper('video',
    //     '<video>foo</video>', 'foo',
    //     (element) => element is VideoElement));
    // TODO(jacobr): this test is broken until Dartium fixes b/5521083
    // test('someunknown', () => testConstructorHelper('someunknown',
    //     '<someunknown>foo</someunknown>', 'foo',
    //     (element) => element is UnknownElement));
  });

  test('eventListeners', () {
    final element = new Element.tag('div');
    final on = element.on;

    testEventHelper(on.abort, 'abort',
        (listener) => Testing.addEventListener(
            element, 'abort', listener, true));
    testEventHelper(on.beforeCopy, 'beforecopy',
        (listener) => Testing.addEventListener(
            element, 'beforecopy', listener, true));
    testEventHelper(on.beforeCut, 'beforecut',
        (listener) => Testing.addEventListener(
            element, 'beforecut', listener, true));
    testEventHelper(on.beforePaste, 'beforepaste',
        (listener) => Testing.addEventListener(
            element, 'beforepaste', listener, true));
    testEventHelper(on.blur, 'blur',
        (listener) => Testing.addEventListener(
            element, 'blur', listener, true));
    testEventHelper(on.change, 'change',
        (listener) => Testing.addEventListener(
            element, 'change', listener, true));
    testEventHelper(on.click, 'click',
        (listener) => Testing.addEventListener(
            element, 'click', listener, true));
    testEventHelper(on.contextMenu, 'contextmenu',
        (listener) => Testing.addEventListener(
            element, 'contextmenu', listener, true));
    testEventHelper(on.copy, 'copy',
        (listener) => Testing.addEventListener(
            element, 'copy', listener, true));
    testEventHelper(on.cut, 'cut',
        (listener) => Testing.addEventListener(
            element, 'cut', listener, true));
    testEventHelper(on.doubleClick, 'dblclick',
        (listener) => Testing.addEventListener(
            element, 'dblclick', listener, true));
    testEventHelper(on.drag, 'drag',
        (listener) => Testing.addEventListener(
            element, 'drag', listener, true));
    testEventHelper(on.dragEnd, 'dragend',
        (listener) => Testing.addEventListener(
            element, 'dragend', listener, true));
    testEventHelper(on.dragEnter, 'dragenter',
        (listener) => Testing.addEventListener(
            element, 'dragenter', listener, true));
    testEventHelper(on.dragLeave, 'dragleave',
        (listener) => Testing.addEventListener(
            element, 'dragleave', listener, true));
    testEventHelper(on.dragOver, 'dragover',
        (listener) => Testing.addEventListener(
            element, 'dragover', listener, true));
    testEventHelper(on.dragStart, 'dragstart',
        (listener) => Testing.addEventListener(
            element, 'dragstart', listener, true));
    testEventHelper(on.drop, 'drop',
        (listener) => Testing.addEventListener(
            element, 'drop', listener, true));
    testEventHelper(on.error, 'error',
        (listener) => Testing.addEventListener(
            element, 'error', listener, true));
    testEventHelper(on.focus, 'focus',
        (listener) => Testing.addEventListener(
            element, 'focus', listener, true));
    testEventHelper(on.input, 'input',
        (listener) => Testing.addEventListener(
            element, 'input', listener, true));
    testEventHelper(on.invalid, 'invalid',
        (listener) => Testing.addEventListener(
            element, 'invalid', listener, true));
    testEventHelper(on.keyDown, 'keydown',
        (listener) => Testing.addEventListener(
            element, 'keydown', listener, true));
    testEventHelper(on.keyPress, 'keypress',
        (listener) => Testing.addEventListener(
            element, 'keypress', listener, true));
    testEventHelper(on.keyUp, 'keyup',
        (listener) => Testing.addEventListener(
            element, 'keyup', listener, true));
    testEventHelper(on.load, 'load',
        (listener) => Testing.addEventListener(
            element, 'load', listener, true));
    testEventHelper(on.mouseDown, 'mousedown',
        (listener) => Testing.addEventListener(
            element, 'mousedown', listener, true));
    testEventHelper(on.mouseMove, 'mousemove',
        (listener) => Testing.addEventListener(
            element, 'mousemove', listener, true));
    testEventHelper(on.mouseOut, 'mouseout',
        (listener) => Testing.addEventListener(
            element, 'mouseout', listener, true));
    testEventHelper(on.mouseOver, 'mouseover',
        (listener) => Testing.addEventListener(
            element, 'mouseover', listener, true));
    testEventHelper(on.mouseUp, 'mouseup',
        (listener) => Testing.addEventListener(
            element, 'mouseup', listener, true));
    // Browsers have different events that they use, so fire all variants.
    testMultipleEventHelper(on.mouseWheel,
        ['mousewheel', 'wheel', 'DOMMouseScroll'],
        (listener) => Testing.addEventListener(
            element, 'mousewheel', listener, true));
    testEventHelper(on.paste, 'paste',
        (listener) => Testing.addEventListener(
            element, 'paste', listener, true));
    testEventHelper(on.reset, 'reset',
        (listener) => Testing.addEventListener(
            element, 'reset', listener, true));
    testEventHelper(on.scroll, 'scroll',
        (listener) => Testing.addEventListener(
            element, 'scroll', listener, true));
    testEventHelper(on.search, 'search',
        (listener) => Testing.addEventListener(
            element, 'search', listener, true));
    testEventHelper(on.select, 'select',
        (listener) => Testing.addEventListener(
            element, 'select', listener, true));
    testEventHelper(on.selectStart, 'selectstart',
        (listener) => Testing.addEventListener(
            element, 'selectstart', listener, true));
    testEventHelper(on.submit, 'submit',
        (listener) => Testing.addEventListener(
            element, 'submit', listener, true));
    testEventHelper(on.touchCancel, 'touchcancel',
        (listener) => Testing.addEventListener(
            element, 'touchcancel', listener, true));
    testEventHelper(on.touchEnd, 'touchend',
        (listener) => Testing.addEventListener(
            element, 'touchend', listener, true));
    testEventHelper(on.touchLeave, 'touchleave');
    testEventHelper(on.touchMove, 'touchmove',
        (listener) => Testing.addEventListener(
            element, 'touchmove', listener, true));
    testEventHelper(on.touchStart, 'touchstart',
        (listener) => Testing.addEventListener(
            element, 'touchstart', listener, true));
  });

  group('attributes', () {
      test('manipulation', () {
        final element = new Element.html(
            '''<div class="foo" style="overflow: hidden" data-foo="bar"
                   data-foo2="bar2" dir="rtl">
               </div>''');
        final attributes = element.attributes;
        expect(attributes['class'], 'foo');
        expect(attributes['style'], 'overflow: hidden');
        expect(attributes['data-foo'], 'bar');
        expect(attributes['data-foo2'], 'bar2');
        expect(attributes.length, 5);
        expect(element.dataAttributes.length, 2);
        element.dataAttributes['foo'] = 'baz';
        expect(element.dataAttributes['foo'], 'baz');
        expect(attributes['data-foo'], 'baz');
        attributes['data-foo2'] = 'baz2';
        expect(attributes['data-foo2'], 'baz2');
        expect(element.dataAttributes['foo2'], 'baz2');
        expect(attributes['dir'], 'rtl');

        final dataAttributes = element.dataAttributes;
        dataAttributes.remove('foo2');
        expect(attributes.length, 4);
        expect(dataAttributes.length, 1);
        attributes.remove('style');
        expect(attributes.length, 3);
        dataAttributes['foo3'] = 'baz3';
        expect(dataAttributes.length, 2);
        expect(attributes.length, 4);
        attributes['style'] = 'width: 300px;';
        expect(attributes.length, 5);
      });

      test('coercion', () {
        final element = new Element.tag('div');
        element.attributes['foo'] = 42;
        element.attributes['bar'] = 3.1;
        expect(element.attributes['foo'], '42');
        expect(element.attributes['bar'], '3.1');
      });
  });

  group('elements', () {
    test('is a subset of nodes', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      expect(el.nodes.length, 3);
      expect(el.elements.length, 2);
      expect(el.nodes[1], el.elements[0]);
      expect(el.nodes[2], el.elements[1]);
    });

    test('changes when an element is added to nodes', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      el.nodes.add(new Element.tag('hr'));
      expect(el.elements.length, 3);
      expect(el.elements[2], isHRElement);
      expect(el.nodes[3], el.elements[2]);
    });

    test('changes nodes when an element is added', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      el.elements.add(new Element.tag('hr'));
      expect(el.nodes.length, 4);
      expect(el.nodes[3], isHRElement);
      expect(el.elements[2], el.nodes[3]);
    });

    test('last', () {
      var el = makeElementWithChildren();
      expect(el.elements.last, isInputElement);
    });

    test('forEach', () {
      var els = [];
      var el = makeElementWithChildren();
      el.elements.forEach((n) => els.add(n));
      expect(els[0], isBRElement);
      expect(els[1], isImageElement);
      expect(els[2], isInputElement);
    });

    test('filter', () {
      var filtered = makeElementWithChildren().elements.
        filter((n) => n is ImageElement);
      expect(1, filtered.length);
      expect(filtered[0], isImageElement);
      expect(filtered, isElementList);
    });

    test('every', () {
      var el = makeElementWithChildren();
      expect(el.elements.every((n) => n is Element), isTrue);
      expect(el.elements.every((n) => n is InputElement), isFalse);
    });

    test('some', () {
      var el = makeElementWithChildren();
      expect(el.elements.some((n) => n is InputElement), isTrue);
      expect(el.elements.some((n) => n is SVGElement), isFalse);
    });

    test('isEmpty', () {
      expect(makeElement().elements.isEmpty, isTrue);
      expect(makeElementWithChildren().elements.isEmpty, isFalse);
    });

    test('length', () {
      expect(makeElement().elements.length, 0);
      expect(makeElementWithChildren().elements.length, 3);
    });

    test('[]', () {
      var el = makeElementWithChildren();
      expect(el.elements[0], isBRElement);
      expect(el.elements[1], isImageElement);
      expect(el.elements[2], isInputElement);
    });

    test('[]=', () {
      var el = makeElementWithChildren();
      el.elements[1] = new Element.tag('hr');
      expect(el.elements[0], isBRElement);
      expect(el.elements[1], isHRElement);
      expect(el.elements[2], isInputElement);
    });

    test('add', () {
      var el = makeElement();
      el.elements.add(new Element.tag('hr'));
      expect(el.elements.last, isHRElement);
    });

    test('addLast', () {
      var el = makeElement();
      el.elements.addLast(new Element.tag('hr'));
      expect(el.elements.last, isHRElement);
    });

    test('iterator', () {
      var els = [];
      var el = makeElementWithChildren();
      for (var subel in el.elements) {
        els.add(subel);
      }
      expect(els[0], isBRElement);
      expect(els[1], isImageElement);
      expect(els[2], isInputElement);
    });

    test('addAll', () {
      var el = makeElementWithChildren();
      el.elements.addAll([
        new Element.tag('span'),
        new Element.tag('a'),
        new Element.tag('h1')
      ]);
      expect(el.elements[0], isBRElement);
      expect(el.elements[1], isImageElement);
      expect(el.elements[2], isInputElement);
      expect(el.elements[3], isSpanElement);
      expect(el.elements[4], isAnchorElement);
      expect(el.elements[5], isHeadingElement);
    });

    test('clear', () {
      var el = makeElementWithChildren();
      el.elements.clear();
      expect(el.elements, equals([]));
    });

    test('removeLast', () {
      var el = makeElementWithChildren();
      expect(el.elements.removeLast(), isInputElement);
      expect(el.elements.length, 2);
      expect(el.elements.removeLast(), isImageElement);
      expect(el.elements.length, 1);
    });

    test('getRange', () {
      var el = makeElementWithChildren();
      expect(el.elements.getRange(1, 1), isElementList);
    });
  });

  group('queryAll', () {
    List<Element> getQueryAll() {
      return new Element.html("""
<div>
  <hr/>
  <a class='q' href='http://dartlang.org'>Dart!</a>
  <p>
    <span class='q'>Hello</span>,
    <em>world</em>!
  </p>
  <hr class='q'/>
</div>
""").queryAll('.q');
    }

    List<Element> getEmptyQueryAll() => new Element.tag('div').queryAll('img');

    void testUnsupported(String name, void f()) {
      test(name, () {
        expect(f, throwsUnsupportedError);
      });
    }

    test('last', () {
      expect(getQueryAll().last, isHRElement);
    });

    test('forEach', () {
      var els = [];
      getQueryAll().forEach((el) => els.add(el));
      expect(els[0], isAnchorElement);
      expect(els[1], isSpanElement);
      expect(els[2], isHRElement);
    });

    test('map', () {
      var texts = getQueryAll().map((el) => el.text);
      expect(texts, equals(['Dart!', 'Hello', '']));
    });

    test('filter', () {
      var filtered = getQueryAll().filter((n) => n is SpanElement);
      expect(filtered.length, 1);
      expect(filtered[0], isSpanElement);
      expect(filtered, isElementList);
    });

    test('every', () {
      var el = getQueryAll();
      expect(el.every((n) => n is Element), isTrue);
      expect(el.every((n) => n is SpanElement), isFalse);
    });

    test('some', () {
      var el = getQueryAll();
      expect(el.some((n) => n is SpanElement), isTrue);
      expect(el.some((n) => n is SVGElement), isFalse);
    });

    test('isEmpty', () {
      expect(getEmptyQueryAll().isEmpty, isTrue);
      expect(getQueryAll().isEmpty, isFalse);
    });

    test('length', () {
      expect(getEmptyQueryAll().length, 0);
      expect(getQueryAll().length, 3);
    });

    test('[]', () {
      var els = getQueryAll();
      expect(els[0], isAnchorElement);
      expect(els[1], isSpanElement);
      expect(els[2], isHRElement);
    });

    test('iterator', () {
      var els = [];
      for (var subel in getQueryAll()) {
        els.add(subel);
      }
      expect(els[0], isAnchorElement);
      expect(els[1], isSpanElement);
      expect(els[2], isHRElement);
    });

    test('getRange', () {
      expect(getQueryAll().getRange(1, 1) is List<Element>, isTrue);
    });

    testUnsupported('[]=', () => getQueryAll()[1] = new Element.tag('br'));
    testUnsupported('add', () => getQueryAll().add(new Element.tag('br')));
    testUnsupported('addLast', () =>
        getQueryAll().addLast(new Element.tag('br')));

    testUnsupported('addAll', () {
      getQueryAll().addAll([
        new Element.tag('span'),
        new Element.tag('a'),
        new Element.tag('h1')
      ]);
    });

    testUnsupported('sort', () => getQueryAll().sort((a1, a2) => true));

    testUnsupported('setRange', () => getQueryAll().setRange(0, 0, []));

    testUnsupported('removeRange', () => getQueryAll().removeRange(0, 1));

    testUnsupported('insertangeRange', () => getQueryAll().insertRange(0, 1));

    testUnsupported('clear', () => getQueryAll().clear());

    testUnsupported('removeLast', () => getQueryAll().removeLast());
  });

  group('_ElementList', () {
    List<Element> makeElList() => makeElementWithChildren().elements;

    test('filter', () {
      var filtered = makeElList().filter((n) => n is ImageElement);
      expect(filtered.length, 1);
      expect(filtered[0], isImageElement);
      expect(filtered, isElementList);
    });

    test('getRange', () {
      var range = makeElList().getRange(1, 2);
      expect(range, isElementList);
      expect(range[0], isImageElement);
      expect(range[1], isInputElement);
    });
  });
}
