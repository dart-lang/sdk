// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ElementTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:async';
import 'dart:html';
import 'dart:svg' as svg;
import 'utils.dart';

expectLargeRect(Rectangle rect) {
  expect(rect.top, 0);
  expect(rect.left, 0);
  expect(rect.width, greaterThan(100));
  expect(rect.height, greaterThan(100));
  expect(rect.bottom, rect.top + rect.height);
  expect(rect.right, rect.left + rect.width);
}

void testUnsupported(String name, void f()) {
  test(name, () {
    expect(f, throwsUnsupportedError);
  });
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

  group('position', () {
    test('computedStyle', () {
      final element = document.body;
      var style = element.getComputedStyle();
      expect(style.getPropertyValue('left'), 'auto');
    });

    test('client position synchronous', () {
      final container = new Element.tag("div");
      container.style.position = 'absolute';
      container.style.top = '8px';
      container.style.left = '9px';
      final element = new Element.tag("div");
      element.style.width = '200px';
      element.style.height = '200px';
      container.children.add(element);
      document.body.children.add(container);

      expect(element.client.width, greaterThan(100));
      expect(element.client.height, greaterThan(100));
      expect(element.offset.width, greaterThan(100));
      expect(element.offset.height, greaterThan(100));
      expect(element.scrollWidth, greaterThan(100));
      expect(element.scrollHeight, greaterThan(100));
      expect(element.getBoundingClientRect().left, 9);
      expect(element.getBoundingClientRect().top, 8);

      expect(element.documentOffset.x, 9);
      expect(element.documentOffset.y, 8);
      container.remove();
    });
  });

  group('constructors', () {
    test('error', () {
      expect(() => new Element.html('<br/><br/>'), throwsStateError);
    });

    test('.html has no parent',
        () => expect(new Element.html('<br/>').parent, isNull));

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
      expect(node.tBodies[0].rows[1].cells.map((c) => c.innerHtml),
          [' Failing\n   ', ' Grade\n   ', ' Passing\n']);
    });

    test('.html caption', () {
      var table = new TableElement();
      var node = table.createFragment('<caption><p>Table 1.').nodes.single;
      expect(
          node,
          predicate(
              (x) => x is TableCaptionElement, 'is a TableCaptionElement'));
      expect(node.tagName, 'CAPTION');
      expect(node.parent, isNull);
      expect(node.innerHtml, '<p>Table 1.</p>');
    });

    test('.html colgroup', () {
      var table = new TableElement();
      var node =
          table.createFragment('<colgroup> <col> <col> <col>').nodes.single;
      expect(
          node, predicate((x) => x is TableColElement, 'is a TableColElement'));
      expect(node.tagName, 'COLGROUP');
      expect(node.parent, isNull);
      expect(node.innerHtml, ' <col> <col> <col>');
    });

    test('.html tbody', () {
      var innerHtml = '<tr><td headers="n r1">Sad</td><td>Happy</td></tr>';
      var table = new TableElement();
      var node = table.createFragment('<tbody>$innerHtml').nodes.single;
      expect(
          node,
          predicate(
              (x) => x is TableSectionElement, 'is a TableSectionElement'));
      expect(node.tagName, 'TBODY');
      expect(node.parent, isNull);
      expect(node.rows.length, 1);
      expect(node.rows[0].cells.length, 2);
      expect(node.innerHtml, innerHtml);
    });

    test('.html thead', () {
      var innerHtml = '<tr><th id="n">Negative</th><th>Positive</th></tr>';
      var table = new TableElement();
      var node = table.createFragment('<thead>$innerHtml').nodes.single;
      expect(
          node,
          predicate(
              (x) => x is TableSectionElement, 'is a TableSectionElement'));
      expect(node.tagName, 'THEAD');
      expect(node.parent, isNull);
      expect(node.rows.length, 1);
      expect(node.rows[0].cells.length, 2);
      expect(node.innerHtml, innerHtml);
    });

    test('.html tfoot', () {
      var innerHtml = '<tr><th>percentage</th><td>34.3%</td></tr>';
      var table = new TableElement();
      var node = table.createFragment('<tfoot>$innerHtml').nodes.single;
      expect(
          node,
          predicate(
              (x) => x is TableSectionElement, 'is a TableSectionElement'));
      expect(node.tagName, 'TFOOT');
      expect(node.parent, isNull);
      expect(node.rows.length, 1);
      expect(node.rows[0].cells.length, 2);
      expect(node.innerHtml, innerHtml);
    });

    test('.html tr', () {
      var table = new TableElement();
      document.body.append(table);
      var tBody = table.createTBody();
      var node = tBody.createFragment('<tr><td>foo<td>bar').nodes.single;
      expect(
          node, predicate((x) => x is TableRowElement, 'is a TableRowElement'));
      expect(node.tagName, 'TR');
      expect(node.parent, isNull);
      expect(node.cells.map((c) => c.innerHtml), ['foo', 'bar']);
    });

    test('.html td', () {
      var table = new TableElement();
      document.body.append(table);
      var tBody = table.createTBody();
      var tRow = tBody.addRow();
      var node = tRow.createFragment('<td>foobar').nodes.single;
      expect(node,
          predicate((x) => x is TableCellElement, 'is a TableCellElement'));
      expect(node.tagName, 'TD');
      expect(node.parent, isNull);
      expect(node.innerHtml, 'foobar');
    });

    test('.html th', () {
      var table = new TableElement();
      document.body.append(table);
      var tBody = table.createTBody();
      var tRow = tBody.addRow();
      var node = tRow.createFragment('<th>foobar').nodes.single;
      expect(node,
          predicate((x) => x is TableCellElement, 'is a TableCellElement'));
      expect(node.tagName, 'TH');
      expect(node.parent, isNull);
      expect(node.innerHtml, 'foobar');
    });

    test('.html can fire events', () {
      var e = new Element.html('<button>aha</button>');
      var gotEvent = false;
      e.onClick.listen((_) {
        gotEvent = true;
      });
      e.click();
      expect(gotEvent, isTrue, reason: 'click should have raised click event');
    });
  });

  group('eventListening', () {
    test('streams', () {
      final target = new TextAreaElement();

      void testEvent(Stream stream, String type, [createEvent(String type)]) {
        var firedOnEvent = false;
        stream.listen((e) {
          firedOnEvent = true;
        });
        expect(firedOnEvent, isFalse);
        var event = createEvent != null ? createEvent(type) : new Event(type);
        target.dispatchEvent(event);

        expect(firedOnEvent, isTrue);
      }

      testEvent(target.onAbort, 'abort');
      testEvent(target.onBeforeCopy, 'beforecopy');
      testEvent(target.onBeforeCut, 'beforecut');
      testEvent(target.onBeforePaste, 'beforepaste');
      testEvent(target.onBlur, 'blur');
      testEvent(target.onChange, 'change');
      testEvent(
          target.onContextMenu, 'contextmenu', (type) => new MouseEvent(type));
      // We cannot test dispatching a true ClipboardEvent as the DOM does not
      // provide a way to create a fake ClipboardEvent.
      testEvent(target.onCopy, 'copy');
      testEvent(target.onCut, 'cut');
      testEvent(target.onPaste, 'paste');

      testEvent(
          target.onDoubleClick, 'dblclick', (type) => new MouseEvent(type));
      testEvent(target.onDrag, 'drag', (type) => new MouseEvent(type));
      testEvent(target.onDragEnd, 'dragend', (type) => new MouseEvent(type));
      testEvent(
          target.onDragEnter, 'dragenter', (type) => new MouseEvent(type));
      testEvent(
          target.onDragLeave, 'dragleave', (type) => new MouseEvent(type));
      testEvent(target.onDragOver, 'dragover', (type) => new MouseEvent(type));
      testEvent(
          target.onDragStart, 'dragstart', (type) => new MouseEvent(type));
      testEvent(target.onDrop, 'drop', (type) => new MouseEvent(type));
      testEvent(target.onError, 'error');
      testEvent(target.onFocus, 'focus');
      testEvent(target.onFullscreenChange, 'webkitfullscreenchange');
      testEvent(target.onInput, 'input');
      testEvent(target.onInvalid, 'invalid');
      testEvent(target.onKeyDown, 'keydown', (type) => new KeyboardEvent(type));
      testEvent(
          target.onKeyPress, 'keypress', (type) => new KeyboardEvent(type));
      testEvent(target.onKeyUp, 'keyup', (type) => new KeyboardEvent(type));
      testEvent(target.onLoad, 'load');
      testEvent(
          target.onMouseDown, 'mousedown', (type) => new MouseEvent(type));
      testEvent(
          target.onMouseMove, 'mousemove', (type) => new MouseEvent(type));
      testEvent(target.onMouseOut, 'mouseout', (type) => new MouseEvent(type));
      testEvent(
          target.onMouseOver, 'mouseover', (type) => new MouseEvent(type));
      testEvent(target.onMouseUp, 'mouseup', (type) => new MouseEvent(type));
      testEvent(target.onReset, 'reset');
      testEvent(target.onScroll, 'scroll');
      testEvent(target.onSearch, 'search');
      testEvent(target.onSelect, 'select');
      testEvent(target.onSelectStart, 'selectstart');
      testEvent(target.onSubmit, 'submit');
      // We would prefer to create new touch events for this test via
      // new TouchEvent(null, null, null, type)
      // but that fails on desktop browsers as touch is not enabled.
      testEvent(target.onTouchCancel, 'touchcancel');
      testEvent(target.onTouchEnd, 'touchend');
      testEvent(target.onTouchLeave, 'touchleave');
      testEvent(target.onTouchMove, 'touchmove');
      testEvent(target.onTouchStart, 'touchstart');
    });
  });

  group('click', () {
    test('clickEvent', () {
      var e = new DivElement();
      var firedEvent = false;
      e.onClick.listen((event) {
        firedEvent = true;
      });
      expect(firedEvent, false);
      e.click();
      expect(firedEvent, true);

      var e2 = new DivElement();
      var firedEvent2 = false;
      e2.onClick.matches('.foo').listen((event) {
        firedEvent2 = true;
      });
      e2.click();
      expect(firedEvent2, false);
      e2.classes.add('foo');
      e2.click();
      expect(firedEvent2, true);
    });
  });

  group('attributes', () {
    test('manipulation', () {
      final element = new Element.html(
          '''<div class="foo" style="overflow: hidden" data-foo="bar"
                   data-foo2="bar2" dir="rtl">
               </div>''',
          treeSanitizer: new NullTreeSanitizer());
      final attributes = element.attributes;
      expect(attributes['class'], 'foo');
      expect(attributes['style'], startsWith('overflow: hidden'));
      expect(attributes['data-foo'], 'bar');
      expect(attributes['data-foo2'], 'bar2');
      expect(attributes.length, 5);
      expect(element.dataset.length, 2);
      element.dataset['foo'] = 'baz';
      expect(element.dataset['foo'], 'baz');
      expect(attributes['data-foo'], 'baz');
      attributes['data-foo2'] = 'baz2';
      expect(attributes['data-foo2'], 'baz2');
      expect(element.dataset['foo2'], 'baz2');
      expect(attributes['dir'], 'rtl');

      final dataset = element.dataset;
      dataset.remove('foo2');
      expect(attributes.length, 4);
      expect(dataset.length, 1);
      attributes.remove('style');
      expect(attributes.length, 3);
      dataset['foo3'] = 'baz3';
      expect(dataset.length, 2);
      expect(attributes.length, 4);
      attributes['style'] = 'width: 300px;';
      expect(attributes.length, 5);
    });

    test('namespaces', () {
      var element =
          new svg.SvgElement.svg('''<svg xmlns="http://www.w3.org/2000/svg"
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
      var filtered =
          makeElementWithChildren().children.where((n) => n is ImageElement);
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

    test('insert', () {
      var element = new DivElement();
      element.children.insert(0, new BRElement());
      expect(element.children[0], isBRElement);
      element.children.insert(0, new HRElement());
      expect(element.children[0], isHRElement);
      element.children.insert(1, new ImageElement());
      expect(element.children[1], isImageElement);
      element.children.insert(element.children.length, new InputElement());
      expect(element.children.last, isInputElement);
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

    test('sublist', () {
      var el = makeElementWithChildren();
      expect(el.children.sublist(1, 2), isElementList);
    });

    test('getRange', () {
      var el = makeElementWithChildren();
      expect(el.children.getRange(1, 2).length, 1);
    });

    test('retainWhere', () {
      var el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.retainWhere((e) => true);
      expect(el.children.length, 3);

      el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.retainWhere((e) => false);
      expect(el.children.length, 0);

      el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.retainWhere((e) => e.localName == 'input');
      expect(el.children.length, 1);

      el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.retainWhere((e) => e.localName == 'br');
      expect(el.children.length, 1);
    });

    test('removeWhere', () {
      var el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.removeWhere((e) => true);
      expect(el.children.length, 0);

      el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.removeWhere((e) => false);
      expect(el.children.length, 3);

      el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.removeWhere((e) => e.localName == 'input');
      expect(el.children.length, 2);

      el = makeElementWithChildren();
      expect(el.children.length, 3);
      el.children.removeWhere((e) => e.localName == 'br');
      expect(el.children.length, 2);
    });

    testUnsupported('sort', () {
      var l = makeElementWithChildren().children;
      l.sort();
    });

    testUnsupported('setRange', () {
      var l = makeElementWithChildren().children;
      l.setRange(0, 0, []);
    });

    testUnsupported('replaceRange', () {
      var l = makeElementWithChildren().children;
      l.replaceRange(0, 0, []);
    });

    testUnsupported('removeRange', () {
      var l = makeElementWithChildren().children;
      l.removeRange(0, 1);
    });

    testUnsupported('insertAll', () {
      var l = makeElementWithChildren().children;
      l.insertAll(0, []);
    });
  });

  group('matches', () {
    test('matches', () {
      var element = new DivElement();
      document.body.append(element);
      element.classes.add('test');

      expect(element.matches('div'), true);
      expect(element.matches('span'), false);
      expect(element.matches('.test'), true);
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
      var texts = getQueryAll().map((el) => el.text).toList();
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

    test('sublist', () {
      expect(getQueryAll().sublist(1, 2) is List<Element>, isTrue);
    });

    testUnsupported('[]=', () => getQueryAll()[1] = new Element.tag('br'));
    testUnsupported('add', () => getQueryAll().add(new Element.tag('br')));

    testUnsupported('addAll', () {
      getQueryAll().addAll([
        new Element.tag('span'),
        new Element.tag('a'),
        new Element.tag('h1')
      ]);
    });

    testUnsupported('sort', () => getQueryAll().sort((a1, a2) => true));

    testUnsupported('setRange', () {
      getQueryAll().setRange(0, 1, [new BRElement()]);
    });

    testUnsupported('removeRange', () => getQueryAll().removeRange(0, 1));

    testUnsupported('clear', () => getQueryAll().clear());

    testUnsupported('removeLast', () => getQueryAll().removeLast());
  });

  group('functional', () {
    test('toString', () {
      final elems = makeElementWithChildren().children;
      expect(elems.toString(), "[br, img, input]");
      final elem = makeElement().children;
      expect(elem.toString(), '[]');
    });

    test('scrollIntoView', () {
      var child = new DivElement();
      document.body.append(child);

      child.scrollIntoView(ScrollAlignment.TOP);
      child.scrollIntoView(ScrollAlignment.BOTTOM);
      child.scrollIntoView(ScrollAlignment.CENTER);
      child.scrollIntoView();
    });
  });

  group('_ElementList', () {
    List<Element> makeElList() => makeElementWithChildren().children;

    test('where', () {
      var filtered = makeElList().where((n) => n is ImageElement);
      expect(filtered.length, 1);
      expect(filtered.first, isImageElement);
      expect(filtered, isElementIterable);
    });

    test('sublist', () {
      var range = makeElList().sublist(1, 3);
      expect(range, isElementList);
      expect(range[0], isImageElement);
      expect(range[1], isInputElement);
    });
  });

  group('eventDelegation', () {
    test('matches', () {
      Element clickOne = new Element.a();
      Element selectorOne = new Element.div()
        ..classes.add('selector')
        ..children.add(clickOne);

      Element clickTwo = new Element.a();
      Element selectorTwo = new Element.div()
        ..classes.add('selector')
        ..children.add(clickTwo);
      document.body.append(selectorOne);
      document.body.append(selectorTwo);

      document.body.onClick
          .matches('.selector')
          .listen(expectAsync((Event event) {
        expect(event.currentTarget, document.body);
        expect(event.target, clickOne);
        expect(event.matchingTarget, selectorOne);
      }));

      selectorOne.onClick
          .matches('.selector')
          .listen(expectAsync((Event event) {
        expect(event.currentTarget, selectorOne);
        expect(event.target, clickOne);
        expect(event.matchingTarget, selectorOne);
      }));
      clickOne.click();

      Element elem = new Element.div()..classes.addAll(['a', 'b']);
      Element img = new Element.img()
        ..classes.addAll(['b', 'a', 'd'])
        ..id = 'cookie';
      Element input = new InputElement()..classes.addAll(['c', 'd']);
      var div = new Element.div()
        ..classes.add('a')
        ..id = 'wat';
      document.body.append(elem);
      document.body.append(img);
      document.body.append(input);
      document.body.append(div);

      Element elem4 = new Element.div()..classes.addAll(['i', 'j']);
      Element elem5 = new Element.div()
        ..classes.addAll(['g', 'h'])
        ..children.add(elem4);
      Element elem6 = new Element.div()
        ..classes.addAll(['e', 'f'])
        ..children.add(elem5);
      document.body.append(elem6);

      var firedEvent = false;
      var elems = queryAll('.a');
      queryAll('.a').onClick.listen((event) {
        firedEvent = true;
      });
      expect(firedEvent, false);
      query('.c').click();
      expect(firedEvent, false);
      query('#wat').click();
      expect(firedEvent, true);

      var firedEvent4 = false;
      queryAll('.a').onClick.matches('.d').listen((event) {
        firedEvent4 = true;
      });
      expect(firedEvent4, false);
      query('.c').click();
      expect(firedEvent4, false);
      query('#wat').click();
      expect(firedEvent4, false);
      query('#cookie').click();
      expect(firedEvent4, true);

      var firedEvent2 = false;
      queryAll('.a').onClick.listen((event) {
        firedEvent2 = true;
      });
      Element elem2 = new Element.html('<div class="a"><br/>');
      document.body.append(elem2);
      elem2.click();
      expect(firedEvent2, false);
      elem2.classes.add('a');
      elem2.click();
      expect(firedEvent2, false);

      var firedEvent3 = false;
      queryAll(':root').onClick.matches('.a').listen((event) {
        firedEvent3 = true;
      });
      Element elem3 = new Element.html('<div class="d"><br/>');
      document.body.append(elem3);
      elem3.click();
      expect(firedEvent3, false);
      elem3.classes.add('a');
      elem3.click();
      expect(firedEvent3, true);

      var firedEvent5 = false;
      queryAll(':root').onClick.matches('.e').listen((event) {
        firedEvent5 = true;
      });
      expect(firedEvent5, false);
      query('.i').click();
      expect(firedEvent5, true);
    });

    test('event ordering', () {
      var a = new DivElement();
      var b = new DivElement();
      a.append(b);
      var c = new DivElement();
      b.append(c);

      var eventOrder = [];

      a.on['custom_event'].listen((_) {
        eventOrder.add('a no-capture');
      });

      a.on['custom_event'].capture((_) {
        eventOrder.add('a capture');
      });

      b.on['custom_event'].listen((_) {
        eventOrder.add('b no-capture');
      });

      b.on['custom_event'].capture((_) {
        eventOrder.add('b capture');
      });

      document.body.append(a);

      var event = new Event('custom_event', canBubble: true);
      c.dispatchEvent(event);
      expect(eventOrder,
          ['a capture', 'b capture', 'b no-capture', 'a no-capture']);
    });
  });

  group('ElementList', () {
    // Tests for methods on the DOM class 'NodeList'.
    //
    // There are two interesting things that are checked here from the viewpoint
    // of the dart2js implementation of a 'native' class:
    //
    //   1. Some methods are implemented from by 'Object' or 'Interceptor';
    //      some of these tests simply check that a method can be called.
    //   2. Some methods are implemented by mixins.

    ElementList<Element> makeElementList() =>
        (new Element.html("<div>Foo<br/><!--baz--><br/><br/></div>"))
            .queryAll('br');

    test('hashCode', () {
      var nodes = makeElementList();
      var hash = nodes.hashCode;
      final int N = 1000;
      int matchCount = 0;
      for (int i = 0; i < N; i++) {
        if (makeElementList().hashCode == hash) matchCount++;
      }
      expect(matchCount, lessThan(N));
    });

    test('operator==', () {
      var a = [makeElementList(), makeElementList(), null];
      for (int i = 0; i < a.length; i++) {
        for (int j = 0; j < a.length; j++) {
          expect(i == j, a[i] == a[j]);
        }
      }
    });

    test('runtimeType', () {
      var nodes1 = makeElementList();
      var nodes2 = makeElementList();
      var type1 = nodes1.runtimeType;
      var type2 = nodes2.runtimeType;
      expect(type1 == type2, true);
      String name = '$type1';
      if (name.length > 3) {
        expect(name.contains('ElementList'), true);
      }
    });

    test('first', () {
      var nodes = makeElementList();
      expect(nodes.first, isBRElement);
    });

    test('last', () {
      var nodes = makeElementList();
      expect(nodes.last, isBRElement);
    });

    test('where', () {
      var filtered = makeElementList().where((n) => n is BRElement).toList();
      expect(filtered.length, 3);
      expect(filtered[0], isBRElement);
    });

    test('sublist', () {
      var range = makeElementList().sublist(1, 3);
      expect(range.length, 2);
      expect(range[0], isBRElement);
      expect(range[1], isBRElement);
    });
  });
}
