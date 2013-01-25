// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:svg' as svg;

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

main() {
  useHtmlIndividualConfiguration();

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
  var isElementIterable =
      predicate((x) => x is Iterable<Element>, 'is an Iterable<Element>');
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

  test('client position synchronous', () {
    final container = new Element.tag("div");
    container.style.position = 'absolute';
    container.style.top = '8px';
    container.style.left = '8px';
    final element = new Element.tag("div");
    element.style.width = '200px';
    element.style.height = '200px';
    container.children.add(element);
    document.body.children.add(container);

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

    test('.html table', () {
      // http://developers.whatwg.org/tabular-data.html#tabular-data
      var node = new Element.html('''
<table>
 <caption>Characteristics with positive and negative sides</caption>
 <thead>
  <tr>
   <th id="n"> Negative
   <th> Characteristic
   <th> Positive
 <tbody>
  <tr>
   <td headers="n r1"> Sad
   <th id="r1"> Mood
   <td> Happy
  <tr>
   <td headers="n r2"> Failing
   <th id="r2"> Grade
   <td> Passing
</table>''');
      expect(node, predicate((x) => x is TableElement, 'is a TableElement'));
      expect(node.tagName, 'TABLE');
      expect(node.parent, isNull);
      expect(node.caption.innerHtml,
          'Characteristics with positive and negative sides');
      expect(node.tHead.rows.length, 1);
      expect(node.tHead.rows[0].cells.length, 3);
      expect(node.tBodies.length, 1);
      expect(node.tBodies[0].rows.length, 2);
      expect(node.tBodies[0].rows[1].cells.mappedBy((c) => c.innerHtml),
          [' Failing\n   ', ' Grade\n   ', ' Passing\n']);
    });

    test('.html caption', () {
      var node = new Element.html('<caption><p>Table 1.');
      expect(node, predicate((x) => x is TableCaptionElement,
          'is a TableCaptionElement'));
      expect(node.tagName, 'CAPTION');
      expect(node.parent, isNull);
      expect(node.innerHtml, '<p>Table 1.</p>');
    });

    test('.html colgroup', () {
      var node = new Element.html('<colgroup> <col> <col> <col>');
      expect(node, predicate((x) => x is TableColElement,
          'is a TableColElement'));
      expect(node.tagName, 'COLGROUP');
      expect(node.parent, isNull);
      expect(node.innerHtml, ' <col> <col> <col>');
    });

    test('.html col', () {
      var node = new Element.html('<col span="2">');
      expect(node, predicate((x) => x is TableColElement,
          'is a TableColElement'));
      expect(node.tagName, 'COL');
      expect(node.parent, isNull);
      expect(node.outerHtml, '<col span="2">');
    });

    test('.html tbody', () {
      var innerHtml = '<tr><td headers="n r1">Sad</td><td>Happy</td></tr>';
      var node = new Element.html('<tbody>$innerHtml');
      expect(node, predicate((x) => x is TableSectionElement,
          'is a TableSectionElement'));
      expect(node.tagName, 'TBODY');
      expect(node.parent, isNull);
      expect(node.rows.length, 1);
      expect(node.rows[0].cells.length, 2);
      expect(node.innerHtml, innerHtml);
    });

    test('.html thead', () {
      var innerHtml = '<tr><th id="n">Negative</th><th>Positive</th></tr>';
      var node = new Element.html('<thead>$innerHtml');
      expect(node, predicate((x) => x is TableSectionElement,
          'is a TableSectionElement'));
      expect(node.tagName, 'THEAD');
      expect(node.parent, isNull);
      expect(node.rows.length, 1);
      expect(node.rows[0].cells.length, 2);
      expect(node.innerHtml, innerHtml);
    });

    test('.html tfoot', () {
      var innerHtml = '<tr><th>percentage</th><td>34.3%</td></tr>';
      var node = new Element.html('<tfoot>$innerHtml');
      expect(node, predicate((x) => x is TableSectionElement,
          'is a TableSectionElement'));
      expect(node.tagName, 'TFOOT');
      expect(node.parent, isNull);
      expect(node.rows.length, 1);
      expect(node.rows[0].cells.length, 2);
      expect(node.innerHtml, innerHtml);
    });

    test('.html tr', () {
      var node = new Element.html('<tr><td>foo<td>bar');
      expect(node, predicate((x) => x is TableRowElement,
          'is a TableRowElement'));
      expect(node.tagName, 'TR');
      expect(node.parent, isNull);
      expect(node.cells.mappedBy((c) => c.innerHtml), ['foo', 'bar']);
    });

    test('.html td', () {
      var node = new Element.html('<td>foobar');
      expect(node, predicate((x) => x is TableCellElement,
          'is a TableCellElement'));
      expect(node.tagName, 'TD');
      expect(node.parent, isNull);
      expect(node.innerHtml, 'foobar');
    });

    test('.html th', () {
      var node = new Element.html('<th>foobar');
      expect(node, predicate((x) => x is TableCellElement,
          'is a TableCellElement'));
      expect(node.tagName, 'TH');
      expect(node.parent, isNull);
      expect(node.innerHtml, 'foobar');
    });
  });

  group('eventListening', () {
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
      testEventHelper(on.transitionEnd, 'webkitTransitionEnd');
      testEventHelper(on.fullscreenChange, 'webkitfullscreenchange',
          (listener) => Testing.addEventListener(element,
             'webkitfullscreenchange', listener, true));
    });
  });

  group('click', () {
    test('clickEvent', () {
      var e = new DivElement();
      var firedEvent = false;
      e.on.click.add((event) {
        firedEvent = true;
      });
      expect(firedEvent, false);
      e.click();
      expect(firedEvent, true);
    });
  });

  group('attributes', () {
      test('coercion', () {
        final element = new Element.tag('div');
        element.attributes['foo'] = 42;
        element.attributes['bar'] = 3.1;
        expect(element.attributes['foo'], '42');
        expect(element.attributes['bar'], '3.1');
      });
      test('manipulation', () {
        final element = new Element.html(
            '''<div class="foo" style="overflow: hidden" data-foo="bar"
                   data-foo2="bar2" dir="rtl">
               </div>''');
        final attributes = element.attributes;
        expect(attributes['class'], 'foo');
        expect(attributes['style'], startsWith('overflow: hidden'));
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

      test('namespaces', () {
        var element = new svg.SvgElement.svg(
          '''<svg xmlns="http://www.w3.org/2000/svg"
                  xmlns:xlink="http://www.w3.org/1999/xlink">
            <image xlink:href="foo" data-foo="bar"/>
          </svg>''').children[0];

        var attributes = element.attributes;
        expect(attributes.length, 1);
        expect(attributes['data-foo'], 'bar');

        var xlinkAttrs =
            element.getNamespacedAttributes('http://www.w3.org/1999/xlink');
        expect(xlinkAttrs.length, 1);
        expect(xlinkAttrs['href'], 'foo');

        xlinkAttrs.remove('href');
        expect(xlinkAttrs.length, 0);

        xlinkAttrs['href'] = 'bar';
        expect(xlinkAttrs['href'], 'bar');

        var randomAttrs = element.getNamespacedAttributes('http://example.com');
        expect(randomAttrs.length, 0);
        randomAttrs['href'] = 'bar';
        expect(randomAttrs.length, 1);
      });
  });

  group('children', () {
    test('is a subset of nodes', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      expect(el.nodes.length, 3);
      expect(el.children.length, 2);
      expect(el.nodes[1], el.children[0]);
      expect(el.nodes[2], el.children[1]);
    });

    test('changes when an element is added to nodes', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      el.nodes.add(new Element.tag('hr'));
      expect(el.children.length, 3);
      expect(el.children[2], isHRElement);
      expect(el.nodes[3], el.children[2]);
    });

    test('changes nodes when an element is added', () {
      var el = new Element.html("<div>Foo<br/><img/></div>");
      el.children.add(new Element.tag('hr'));
      expect(el.nodes.length, 4);
      expect(el.nodes[3], isHRElement);
      expect(el.children[2], el.nodes[3]);
    });

    test('last', () {
      var el = makeElementWithChildren();
      expect(el.children.last, isInputElement);
    });

    test('forEach', () {
      var els = [];
      var el = makeElementWithChildren();
      el.children.forEach((n) => els.add(n));
      expect(els[0], isBRElement);
      expect(els[1], isImageElement);
      expect(els[2], isInputElement);
    });

    test('where', () {
      var filtered = makeElementWithChildren().children.
        where((n) => n is ImageElement);
      expect(1, filtered.length);
      expect(filtered.first, isImageElement);
      expect(filtered, isElementIterable);
    });

    test('every', () {
      var el = makeElementWithChildren();
      expect(el.children.every((n) => n is Element), isTrue);
      expect(el.children.every((n) => n is InputElement), isFalse);
    });

    test('any', () {
      var el = makeElementWithChildren();
      expect(el.children.any((n) => n is InputElement), isTrue);
      expect(el.children.any((n) => n is svg.SvgElement), isFalse);
    });

    test('isEmpty', () {
      expect(makeElement().children.isEmpty, isTrue);
      expect(makeElementWithChildren().children.isEmpty, isFalse);
    });

    test('length', () {
      expect(makeElement().children.length, 0);
      expect(makeElementWithChildren().children.length, 3);
    });

    test('[]', () {
      var el = makeElementWithChildren();
      expect(el.children[0], isBRElement);
      expect(el.children[1], isImageElement);
      expect(el.children[2], isInputElement);
    });

    test('[]=', () {
      var el = makeElementWithChildren();
      el.children[1] = new Element.tag('hr');
      expect(el.children[0], isBRElement);
      expect(el.children[1], isHRElement);
      expect(el.children[2], isInputElement);
    });

    test('add', () {
      var el = makeElement();
      el.children.add(new Element.tag('hr'));
      expect(el.children.last, isHRElement);
    });

    test('addLast', () {
      var el = makeElement();
      el.children.addLast(new Element.tag('hr'));
      expect(el.children.last, isHRElement);
    });

    test('iterator', () {
      var els = [];
      var el = makeElementWithChildren();
      for (var subel in el.children) {
        els.add(subel);
      }
      expect(els[0], isBRElement);
      expect(els[1], isImageElement);
      expect(els[2], isInputElement);
    });

    test('addAll', () {
      var el = makeElementWithChildren();
      el.children.addAll([
        new Element.tag('span'),
        new Element.tag('a'),
        new Element.tag('h1')
      ]);
      expect(el.children[0], isBRElement);
      expect(el.children[1], isImageElement);
      expect(el.children[2], isInputElement);
      expect(el.children[3], isSpanElement);
      expect(el.children[4], isAnchorElement);
      expect(el.children[5], isHeadingElement);
    });

    test('clear', () {
      var el = makeElementWithChildren();
      el.children.clear();
      expect(el.children, equals([]));
    });

    test('removeLast', () {
      var el = makeElementWithChildren();
      expect(el.children.removeLast(), isInputElement);
      expect(el.children.length, 2);
      expect(el.children.removeLast(), isImageElement);
      expect(el.children.length, 1);
    });

    test('getRange', () {
      var el = makeElementWithChildren();
      expect(el.children.getRange(1, 1), isElementList);
    });
  });

  group('supported_matches', () {
    test('supported', () {
      expect(Element.supportsMatches, true);
    });
  });

  group('matches', () {
    test('matches', () {
      var expectation = Element.supportsMatches ? returnsNormally : throws;
      expect(() {
        var element = new DivElement();
        element.classes.add('test');

        expect(element.matches('div'), true);
        expect(element.matches('span'), false);
        expect(element.matches('.test'), true);
      }, expectation);
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

    test('mappedBy', () {
      var texts = getQueryAll().mappedBy((el) => el.text).toList();
      expect(texts, equals(['Dart!', 'Hello', '']));
    });

    test('where', () {
      var filtered = getQueryAll().where((n) => n is SpanElement).toList();
      expect(filtered.length, 1);
      expect(filtered[0], isSpanElement);
      expect(filtered, isElementList);
    });

    test('every', () {
      var el = getQueryAll();
      expect(el.every((n) => n is Element), isTrue);
      expect(el.every((n) => n is SpanElement), isFalse);
    });

    test('any', () {
      var el = getQueryAll();
      expect(el.any((n) => n is SpanElement), isTrue);
      expect(el.any((n) => n is svg.SvgElement), isFalse);
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
    List<Element> makeElList() => makeElementWithChildren().children;

    test('where', () {
      var filtered = makeElList().where((n) => n is ImageElement);
      expect(filtered.length, 1);
      expect(filtered.first, isImageElement);
      expect(filtered, isElementIterable);
    });

    test('getRange', () {
      var range = makeElList().getRange(1, 2);
      expect(range, isElementList);
      expect(range[0], isImageElement);
      expect(range[1], isInputElement);
    });
  });
}
