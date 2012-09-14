// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('ElementTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

expectLargeRect(ClientRect rect) {
  Expect.equals(rect.top, 0);
  Expect.equals(rect.left, 0);
  Expect.isTrue(rect.width > 100);
  Expect.isTrue(rect.height > 100);
  Expect.equals(rect.bottom, rect.top + rect.height);
  Expect.equals(rect.right, rect.left + rect.width);
}

void testEventHelper(EventListenerList listenerList, String type,
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
  final event = new Event(type);
  listenerList.dispatch(event);

  Expect.isTrue(firedWhenAddedToListenerList);
  if (registerOnEventListener != null) {
    Expect.isTrue(firedOnEvent);
  }
}

void testConstructorHelper(String tag, String htmlSnippet,
    String expectedText, Function isExpectedClass) {
  Expect.isTrue(isExpectedClass(new Element.tag(tag)));
  final elementFromSnippet = new Element.html(htmlSnippet);
  Expect.isTrue(isExpectedClass(elementFromSnippet));
  Expect.equals(expectedText, elementFromSnippet.text);
}

main() {
  useHtmlConfiguration();

  Element makeElement() => new Element.tag('div');

  Element makeElementWithChildren() =>
    new Element.html("<div><br/><img/><input/></div>");

  test('computedStyle', () {
    final element = document.body;
    element.computedStyle.then(expectAsync1((style) {
      Expect.equals(style.getPropertyValue('left'), 'auto');
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
      Expect.equals(rect.bounding.left, 8);
      Expect.equals(rect.bounding.top, 8);
      Expect.isTrue(rect.clientRects.length > 0);
      container.remove();
    }));
  });

  group('constructors', () {
    test('error', () {
      Expect.throws(() => new Element.html('<br/><br/>'),
          (e) => e is IllegalArgumentException);
    });

    test('.html has no parent', () =>
        Expect.isNull(new Element.html('<br/>').parent));

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
    test('details', () => testConstructorHelper('details',
        '<details>foo</details>', 'foo',
        (element) => element is DetailsElement));
    test('div', () => testConstructorHelper('div', '<div>foo</div>', 'foo',
        (element) => element is DivElement));
    test('embed', () => testConstructorHelper('embed',
        '<embed>foo</embed>', '',
        (element) => element is EmbedElement));
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
    test('keygen', () => testConstructorHelper('keygen', '<keygen>', '',
        (element) => element is KeygenElement));
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
    test('marquee', () => testConstructorHelper('marquee',
        '<marquee>foo</marquee>', 'foo',
        (element) => element is MarqueeElement));
    test('menu', () => testConstructorHelper('menu', '<menu>foo</menu>', 'foo',
        (element) => element is MenuElement));
    test('meta', () => testConstructorHelper('meta', '<meta>', '',
        (element) => element is MetaElement));
    test('meter', () => testConstructorHelper('meter',
        '<meter>foo</meter>', 'foo',
        (element) => element is MeterElement));
    test('del', () => testConstructorHelper('del', '<del>foo</del>', 'foo',
        (element) => element is ModElement));
    test('ins', () => testConstructorHelper('ins', '<ins>foo</ins>', 'foo',
        (element) => element is ModElement));
    test('ol', () => testConstructorHelper('ol', '<ol>foo</ol>', 'foo',
        (element) => element is OListElement));
    test('object', () => testConstructorHelper('object',
        '<object>foo</object>', 'foo',
        (element) => element is ObjectElement));
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
    testEventHelper(on.mouseWheel, 'mousewheel',
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
    testEventHelper(on.transitionEnd, 'webkitTransitionEnd');
    testEventHelper(on.fullscreenChange, 'webkitfullscreenchange',
        (listener) => Testing.addEventListener(element,
            'webkitfullscreenchange', listener, true));
  });

  group('attributes', () {
      test('manipulation', () {
        final element = new Element.html(
            '''<div class="foo" style="overflow: hidden" data-foo="bar"
                   data-foo2="bar2" dir="rtl">
               </div>''');
        final attributes = element.attributes;
        Expect.equals(attributes['class'], 'foo');
        Expect.equals(attributes['style'], 'overflow: hidden');
        Expect.equals(attributes['data-foo'], 'bar');
        Expect.equals(attributes['data-foo2'], 'bar2');
        Expect.equals(attributes.length, 5);
        Expect.equals(element.dataAttributes.length, 2);
        element.dataAttributes['foo'] = 'baz';
        Expect.equals(element.dataAttributes['foo'], 'baz');
        Expect.equals(attributes['data-foo'], 'baz');
        attributes['data-foo2'] = 'baz2';
        Expect.equals(attributes['data-foo2'], 'baz2');
        Expect.equals(element.dataAttributes['foo2'], 'baz2');
        Expect.equals(attributes['dir'], 'rtl');

        final dataAttributes = element.dataAttributes;
        dataAttributes.remove('foo2');
        Expect.equals(attributes.length, 4);
        Expect.equals(dataAttributes.length, 1);
        attributes.remove('style');
        Expect.equals(attributes.length, 3);
        dataAttributes['foo3'] = 'baz3';
        Expect.equals(dataAttributes.length, 2);
        Expect.equals(attributes.length, 4);
        attributes['style'] = 'width: 300px;';
        Expect.equals(attributes.length, 5);
      });

      test('coercion', () {
        final element = new Element.tag('div');
        element.attributes['foo'] = 42;
        element.attributes['bar'] = 3.1;
        Expect.equals(element.attributes['foo'], '42');
        Expect.equals(element.attributes['bar'], '3.1');
      });
  });

  group('elements', () {
    test('is a subset of nodes', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      Expect.equals(3, el.nodes.length);
      Expect.equals(2, el.elements.length);
      Expect.equals(el.nodes[1], el.elements[0]);
      Expect.equals(el.nodes[2], el.elements[1]);
    });

    test('changes when an element is added to nodes', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      el.nodes.add(new Element.tag('hr'));
      Expect.equals(3, el.elements.length);
      Expect.isTrue(el.elements[2] is HRElement);
      Expect.equals(el.nodes[3], el.elements[2]);
    });

    test('changes nodes when an element is added', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      el.elements.add(new Element.tag('hr'));
      Expect.equals(4, el.nodes.length);
      Expect.isTrue(el.nodes[3] is HRElement);
      Expect.equals(el.elements[2], el.nodes[3]);
    });

    test('first', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements.first is BRElement);
    });

    test('last', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements.last() is InputElement);
    });

    test('forEach', () {
      var els = [];
      var el = makeElementWithChildren();
      el.elements.forEach((n) => els.add(n));
      Expect.isTrue(els[0] is BRElement);
      Expect.isTrue(els[1] is ImageElement);
      Expect.isTrue(els[2] is InputElement);
    });

    test('filter', () {
      var filtered = makeElementWithChildren().elements.
        filter((n) => n is ImageElement);
      Expect.equals(1, filtered.length);
      Expect.isTrue(filtered[0] is ImageElement);
      Expect.isTrue(filtered is ElementList);
    });

    test('every', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements.every((n) => n is Element));
      Expect.isFalse(el.elements.every((n) => n is InputElement));
    });

    test('some', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements.some((n) => n is InputElement));
      Expect.isFalse(el.elements.some((n) => n is SVGElement));
    });

    test('isEmpty', () {
      Expect.isTrue(makeElement().elements.isEmpty());
      Expect.isFalse(makeElementWithChildren().elements.isEmpty());
    });

    test('length', () {
      Expect.equals(0, makeElement().elements.length);
      Expect.equals(3, makeElementWithChildren().elements.length);
    });

    test('[]', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements[0] is BRElement);
      Expect.isTrue(el.elements[1] is ImageElement);
      Expect.isTrue(el.elements[2] is InputElement);
    });

    test('[]=', () {
      var el = makeElementWithChildren();
      el.elements[1] = new Element.tag('hr');
      Expect.isTrue(el.elements[0] is BRElement);
      Expect.isTrue(el.elements[1] is HRElement);
      Expect.isTrue(el.elements[2] is InputElement);
    });

    test('add', () {
      var el = makeElement();
      el.elements.add(new Element.tag('hr'));
      Expect.isTrue(el.elements.last() is HRElement);
    });

    test('addLast', () {
      var el = makeElement();
      el.elements.addLast(new Element.tag('hr'));
      Expect.isTrue(el.elements.last() is HRElement);
    });

    test('iterator', () {
      var els = [];
      var el = makeElementWithChildren();
      for (var subel in el.elements) {
        els.add(subel);
      }
      Expect.isTrue(els[0] is BRElement);
      Expect.isTrue(els[1] is ImageElement);
      Expect.isTrue(els[2] is InputElement);
    });

    test('addAll', () {
      var el = makeElementWithChildren();
      el.elements.addAll([
        new Element.tag('span'),
        new Element.tag('a'),
        new Element.tag('h1')
      ]);
      Expect.isTrue(el.elements[0] is BRElement);
      Expect.isTrue(el.elements[1] is ImageElement);
      Expect.isTrue(el.elements[2] is InputElement);
      Expect.isTrue(el.elements[3] is SpanElement);
      Expect.isTrue(el.elements[4] is AnchorElement);
      Expect.isTrue(el.elements[5] is HeadingElement);
    });

    test('clear', () {
      var el = makeElementWithChildren();
      el.elements.clear();
      Expect.listEquals([], el.elements);
    });

    test('removeLast', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements.removeLast() is InputElement);
      Expect.equals(2, el.elements.length);
      Expect.isTrue(el.elements.removeLast() is ImageElement);
      Expect.equals(1, el.elements.length);
    });

    test('getRange', () {
      var el = makeElementWithChildren();
      Expect.isTrue(el.elements.getRange(1, 1) is ElementList);
    });
  });

  group('queryAll', () {
    ElementList getQueryAll() {
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

    ElementList getEmptyQueryAll() => new Element.tag('div').queryAll('img');

    void testUnsupported(String name, void f()) {
      test(name, () {
        Expect.throws(f, (e) => e is UnsupportedOperationException);
      });
    }

    test('first', () {
      Expect.isTrue(getQueryAll().first is AnchorElement);
    });

    test('last', () {
      Expect.isTrue(getQueryAll().last() is HRElement);
    });

    test('forEach', () {
      var els = [];
      getQueryAll().forEach((el) => els.add(el));
      Expect.isTrue(els[0] is AnchorElement);
      Expect.isTrue(els[1] is SpanElement);
      Expect.isTrue(els[2] is HRElement);
    });

    test('map', () {
      var texts = getQueryAll().map((el) => el.text);
      Expect.listEquals(['Dart!', 'Hello', ''], texts);
    });

    test('filter', () {
      var filtered = getQueryAll().filter((n) => n is SpanElement);
      Expect.equals(1, filtered.length);
      Expect.isTrue(filtered[0] is SpanElement);
      Expect.isTrue(filtered is ElementList);
    });

    test('every', () {
      var el = getQueryAll();
      Expect.isTrue(el.every((n) => n is Element));
      Expect.isFalse(el.every((n) => n is SpanElement));
    });

    test('some', () {
      var el = getQueryAll();
      Expect.isTrue(el.some((n) => n is SpanElement));
      Expect.isFalse(el.some((n) => n is SVGElement));
    });

    test('isEmpty', () {
      Expect.isTrue(getEmptyQueryAll().isEmpty());
      Expect.isFalse(getQueryAll().isEmpty());
    });

    test('length', () {
      Expect.equals(0, getEmptyQueryAll().length);
      Expect.equals(3, getQueryAll().length);
    });

    test('[]', () {
      var els = getQueryAll();
      Expect.isTrue(els[0] is AnchorElement);
      Expect.isTrue(els[1] is SpanElement);
      Expect.isTrue(els[2] is HRElement);
    });

    test('iterator', () {
      var els = [];
      for (var subel in getQueryAll()) {
        els.add(subel);
      }
      Expect.isTrue(els[0] is AnchorElement);
      Expect.isTrue(els[1] is SpanElement);
      Expect.isTrue(els[2] is HRElement);
    });

    test('getRange', () {
      Expect.isTrue(getQueryAll().getRange(1, 1) is ElementList);
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
    ElementList makeElList() => makeElementWithChildren().elements;

    test('first', () {
      var els = makeElList();
      Expect.isTrue(els.first is BRElement);
    });

    test('filter', () {
      var filtered = makeElList().filter((n) => n is ImageElement);
      Expect.equals(1, filtered.length);
      Expect.isTrue(filtered[0] is ImageElement);
      Expect.isTrue(filtered is ElementList);
    });

    test('getRange', () {
      var range = makeElList().getRange(1, 2);
      Expect.isTrue(range is ElementList);
      Expect.isTrue(range[0] is ImageElement);
      Expect.isTrue(range[1] is InputElement);
    });
  });
}
