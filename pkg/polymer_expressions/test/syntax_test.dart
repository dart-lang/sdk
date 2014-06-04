// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // make test smaller.
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:polymer_expressions/eval.dart';
import 'package:template_binding/template_binding.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'package:smoke/mirrors.dart' as smoke;

class TestScopeFactory implements ScopeFactory {
  int scopeCount = 0;

  modelScope({Object model, Map<String, Object> variables}) {
    scopeCount++;
    return new Scope(model: model, variables: variables);
  }

  childScope(Scope parent, String name, Object value) {
    scopeCount++;
    return parent.childScope(name, value);
  }
}

main() {
  useHtmlConfiguration();
  smoke.useMirrors();

  group('PolymerExpressions', () {
    DivElement testDiv;
    TestScopeFactory testScopeFactory;

    setUp(() {
      document.body.append(testDiv = new DivElement());
      testScopeFactory = new TestScopeFactory();
    });

    tearDown(() {
      testDiv.children.clear();
      testDiv = null;
    });

    Future<Element> setUpTest(String html, {model, Map globals}) {
      var tag = new Element.html(html,
          treeSanitizer: new NullNodeTreeSanitizer());

      // make sure templates behave in the polyfill
      TemplateBindExtension.bootstrap(tag);

      templateBind(tag)
        ..bindingDelegate = new PolymerExpressions(globals: globals,
            scopeFactory: testScopeFactory)
        ..model = model;
      testDiv.children.clear();
      testDiv.append(tag);
      return waitForChange(testDiv);
    }

    group('scope creation', () {
      // These tests are sensitive to some internals of the implementation that
      // might not be visible to applications, but are useful for verifying that
      // that we're not creating too many Scopes.

      // The reason that we create two Scopes in the cases with one binding is
      // that <template bind> has one scope for the context to evaluate the bind
      // binding in, and another scope for the bindings inside the template.

      // We could try to optimize the outer scope away in cases where the
      // expression is empty, but there are a lot of special cases in the
      // syntax code already.
      test('should create one scope for a single binding', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].text, 'a');
          expect(testScopeFactory.scopeCount, 1);
        }));

      test('should only create a single scope for two bindings', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
              <div>{{ data }}</div>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 3);
          expect(testDiv.children[1].text, 'a');
          expect(testDiv.children[2].text, 'a');
          expect(testScopeFactory.scopeCount, 1);
        }));

      test('should create a new scope for a bind/as binding', () {
        return setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
              <template bind="{{ data as a }}" id="inner">
                <div>{{ a }}</div>
                <div>{{ data }}</div>
              </template>
            </template>''',
            model: new Model('foo'))
        .then((_) {
          expect(testDiv.children.length, 5);
          expect(testDiv.children[1].text, 'foo');
          expect(testDiv.children[3].text, 'foo');
          expect(testDiv.children[4].text, 'foo');
          expect(testScopeFactory.scopeCount, 2);
        });
      });

      test('should create scopes for a repeat/in binding', () {
        return setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
              <template repeat="{{ i in items }}" id="inner">
                <div>{{ i }}</div>
                <div>{{ data }}</div>
              </template>
            </template>''',
            model: new Model('foo'), globals: {'items': ['a', 'b', 'c']})
        .then((_) {
          expect(testDiv.children.length, 9);
          expect(testDiv.children[1].text, 'foo');
          expect(testDiv.children[3].text, 'a');
          expect(testDiv.children[4].text, 'foo');
          expect(testDiv.children[5].text, 'b');
          expect(testDiv.children[6].text, 'foo');
          expect(testDiv.children[7].text, 'c');
          expect(testDiv.children[8].text, 'foo');
          // 1 scopes for <template bind>, 1 for each repeat
          expect(testScopeFactory.scopeCount, 4);
        });
      });


    });

    group('with template bind', () {

      test('should show a simple binding on the model', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].text, 'a');
        }));

      test('should handle an empty binding on the model', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ }}</div>
            </template>''',
            model: 'a')
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].text, 'a');
        }));

      test('should show a simple binding to a global', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ a }}</div>
            </template>''',
            globals: {'a': '123'})
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].text, '123');
        }));

      test('should show an expression binding', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ data + 'b' }}</div>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].text, 'ab');
        }));

      test('should handle an expression in the bind attribute', () =>
        setUpTest('''
            <template id="test" bind="{{ data }}">
              <div>{{ this }}</div>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].text, 'a');
        }));

      test('should handle a nested template with an expression in the bind '
          'attribute', () =>
        setUpTest('''
            <template id="test" bind>
              <template id="inner" bind="{{ data }}">
                <div>{{ this }}</div>
              </template>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 3);
          expect(testDiv.children[2].text, 'a');
        }));


      test('should handle an "as" expression in the bind attribute', () =>
        setUpTest('''
            <template id="test" bind="{{ data as a }}">
              <div>{{ data }}b</div>
              <div>{{ a }}c</div>
            </template>''',
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children.length, 3);
          expect(testDiv.children[1].text, 'ab');
          expect(testDiv.children[2].text, 'ac');
        }));

      // passes safari
      test('should not resolve names in the outer template from within a nested'
          ' template with a bind binding', () {
        var completer = new Completer();
        var bindingErrorHappened = false;
        var templateRendered = false;
        maybeComplete() {
          if (bindingErrorHappened && templateRendered) {
            completer.complete(true);
          }
        }
        runZoned(() {
          setUpTest('''
              <template id="test" bind>
                <div>{{ data }}</div>
                <div>{{ b }}</div>
                <template id="inner" bind="{{ b }}">
                  <div>{{ data }}</div>
                  <div>{{ b }}</div>
                  <div>{{ this }}</div>
                </template>
              </template>''',
              model: new Model('foo'), globals: {'b': 'bbb'})
          .then((_) {
            expect(testDiv.children[0].text, '');
            expect(testDiv.children[1].text, 'foo');
            expect(testDiv.children[2].text, 'bbb');
            // Something very strage is happening in the template bindings
            // polyfill, and the template is being stamped out, inside the
            // template tag (which shouldn't happen), and outside the template
            //expect(testDiv.children[3].text, '');
            expect(testDiv.children[3].tagName.toLowerCase(), 'template');
            expect(testDiv.children[4].text, '');
            expect(testDiv.children[5].text, 'bbb');
            expect(testDiv.children[6].text, 'bbb');
            templateRendered = true;
            maybeComplete();
          });
        }, onError: (e, s) {
          expect('$e', contains('data'));
          bindingErrorHappened = true;
          maybeComplete();
        });
        return completer.future;
      });

      // passes safari
      test('should shadow names in the outer template from within a nested '
          'template', () =>
          setUpTest('''
            <template id="test" bind>
              <div>{{ a }}</div>
              <div>{{ b }}</div>
              <template bind="{{ b as a }}">
                <div>{{ a }}</div>
                <div>{{ b }}</div>
              </template>
            </template>''',
            globals: {'a': 'aaa', 'b': 'bbb'})
        .then((_) {
          expect(testDiv.children[0].text, '');
          expect(testDiv.children[1].text, 'aaa');
          expect(testDiv.children[2].text, 'bbb');
          expect(testDiv.children[3].tagName.toLowerCase(), 'template');
          expect(testDiv.children[4].text, 'bbb');
          expect(testDiv.children[5].text, 'bbb');
        }));

    });

    group('with template repeat', () {

      // passes safari
      test('should not resolve names in the outer template from within a nested'
          ' template with a repeat binding', () {
        var completer = new Completer();
        var bindingErrorHappened = false;
        var templateRendered = false;
        maybeComplete() {
          if (bindingErrorHappened && templateRendered) {
            completer.complete(true);
          }
        }
        runZoned(() {
          setUpTest('''
              <template id="test" bind>
                <div>{{ data }}</div>
                <template repeat="{{ items }}">
                  <div>{{ }}{{ data }}</div>
                </template>
              </template>''',
              globals: {'items': [1, 2, 3]},
              model: new Model('a'))
          .then((_) {
            expect(testDiv.children[0].text, '');
            expect(testDiv.children[1].text, 'a');
            expect(testDiv.children[2].tagName.toLowerCase(), 'template');
            expect(testDiv.children[3].text, '1');
            expect(testDiv.children[4].text, '2');
            expect(testDiv.children[5].text, '3');
            templateRendered = true;
            maybeComplete();
          });
        }, onError: (e, s) {
          expect('$e', contains('data'));
          bindingErrorHappened = true;
          maybeComplete();
        });
        return completer.future;
      });

      test('should handle repeat/in bindings', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
              <template repeat="{{ item in items }}">
                <div>{{ item }}{{ data }}</div>
              </template>
            </template>''',
            globals: {'items': [1, 2, 3]},
            model: new Model('a'))
        .then((_) {
          // expect 6 children: two templates, a div and three instances
          expect(testDiv.children[0].text, '');
          expect(testDiv.children[1].text, 'a');
          expect(testDiv.children[2].tagName.toLowerCase(), 'template');
          expect(testDiv.children[3].text, '1a');
          expect(testDiv.children[4].text, '2a');
          expect(testDiv.children[5].text, '3a');
//          expect(testDiv.children.map((c) => c.text),
//              ['', 'a', '', '1a', '2a', '3a']);
        }));

      test('should observe changes to lists in repeat bindings', () {
        var items = new ObservableList.from([1, 2, 3]);
        return setUpTest('''
            <template id="test" bind>
              <template repeat="{{ items }}">
                <div>{{ }}</div>
              </template>
            </template>''',
            globals: {'items': items},
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children[0].text, '');
          expect(testDiv.children[1].tagName.toLowerCase(), 'template');
          expect(testDiv.children[2].text, '1');
          expect(testDiv.children[3].text, '2');
          expect(testDiv.children[4].text, '3');
//          expect(testDiv.children.map((c) => c.text),
//              ['', '', '1', '2', '3']);
          items.add(4);
          return waitForChange(testDiv);
        }).then((_) {
          expect(testDiv.children[0].text, '');
          expect(testDiv.children[1].tagName.toLowerCase(), 'template');
          expect(testDiv.children[2].text, '1');
          expect(testDiv.children[3].text, '2');
          expect(testDiv.children[4].text, '3');
          expect(testDiv.children[5].text, '4');
//          expect(testDiv.children.map((c) => c.text),
//              ['', '', '1', '2', '3', '4']);
        });
      });

      test('should observe changes to lists in repeat/in bindings', () {
        var items = new ObservableList.from([1, 2, 3]);
        return setUpTest('''
            <template id="test" bind>
              <template repeat="{{ item in items }}">
                <div>{{ item }}</div>
              </template>
            </template>''',
            globals: {'items': items},
            model: new Model('a'))
        .then((_) {
          expect(testDiv.children[0].text, '');
          expect(testDiv.children[1].tagName.toLowerCase(), 'template');
          expect(testDiv.children[2].text, '1');
          expect(testDiv.children[3].text, '2');
          expect(testDiv.children[4].text, '3');
//          expect(testDiv.children.map((c) => c.text),
//              ['', '', '1', '2', '3']);
          items.add(4);
          return waitForChange(testDiv);
        }).then((_) {
          expect(testDiv.children[0].text, '');
          expect(testDiv.children[1].tagName.toLowerCase(), 'template');
          expect(testDiv.children[2].text, '1');
          expect(testDiv.children[3].text, '2');
          expect(testDiv.children[4].text, '3');
          expect(testDiv.children[5].text, '4');
//          expect(testDiv.children.map((c) => c.text),
//              ['', '', '1', '2', '3', '4']);
        });
      });
    });

    group('with template if', () {

      Future doTest(value, bool shouldRender) =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ data }}</div>
              <template if="{{ show }}">
                <div>{{ data }}</div>
              </template>
            </template>''',
            globals: {'show': value},
            model: new Model('a'))
        .then((_) {
          if (shouldRender) {
            expect(testDiv.children.length, 4);
            expect(testDiv.children[1].text, 'a');
            expect(testDiv.children[3].text, 'a');
          } else {
            expect(testDiv.children.length, 3);
            expect(testDiv.children[1].text, 'a');
          }
        });

      test('should render for a true expression',
          () => doTest(true, true));

      test('should treat a non-null expression as truthy',
          () => doTest('a', true));

      test('should treat an empty list as truthy',
          () => doTest([], true));

      test('should handle a false expression',
          () => doTest(false, false));

      test('should treat null as falsey',
          () => doTest(null, false));
    });

    group('error handling', () {

      test('should silently handle bad variable names', () {
        var completer = new Completer();
        runZoned(() {
          testDiv.nodes.add(new Element.html('''
              <template id="test" bind>{{ foo }}</template>'''));
          templateBind(query('#test'))
              ..bindingDelegate = new PolymerExpressions()
              ..model = [];
          return new Future(() {});
        }, onError: (e, s) {
          expect('$e', contains('foo'));
          completer.complete(true);
        });
        return completer.future;
      });

      test('should handle null collections in "in" expressions', () =>
        setUpTest('''
            <template id="test" bind>
              <template repeat="{{ item in items }}">
                {{ item }}
              </template>
            </template>''',
            globals: {'items': null})
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[0].id, 'test');
        }));

    });

    group('special bindings', () {

      test('should handle class attributes with lists', ()  =>
        setUpTest('''
            <template id="test" bind>
              <div class="{{ classes }}">
            </template>''',
            globals: {'classes': ['a', 'b']})
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].attributes['class'], 'a b');
          expect(testDiv.children[1].classes, ['a', 'b']);
        }));

      test('should handle class attributes with maps', ()  =>
        setUpTest('''
            <template id="test" bind>
              <div class="{{ classes }}">
            </template>''',
            globals: {'classes': {'a': true, 'b': false, 'c': true}})
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].attributes['class'], 'a c');
          expect(testDiv.children[1].classes, ['a', 'c']);
        }));

      test('should handle style attributes with lists', () =>
        setUpTest('''
            <template id="test" bind>
              <div style="{{ styles }}">
            </template>''',
            globals: {'styles': ['display: none', 'color: black']})
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].attributes['style'],
              'display: none;color: black');
        }));

      test('should handle style attributes with maps', ()  =>
        setUpTest('''
            <template id="test" bind>
              <div style="{{ styles }}">
            </template>''',
            globals: {'styles': {'display': 'none', 'color': 'black'}})
        .then((_) {
          expect(testDiv.children.length, 2);
          expect(testDiv.children[1].attributes['style'],
              'display: none;color: black');
        }));
    });

    group('regression tests', () {

      test('should bind to literals', () =>
        setUpTest('''
            <template id="test" bind>
              <div>{{ 123 }}</div>
              <div>{{ 123.456 }}</div>
              <div>{{ "abc" }}</div>
              <div>{{ true }}</div>
              <div>{{ null }}</div>
            </template>''',
            globals: {'items': null})
        .then((_) {
          expect(testDiv.children.length, 6);
          expect(testDiv.children[1].text, '123');
          expect(testDiv.children[2].text, '123.456');
          expect(testDiv.children[3].text, 'abc');
          expect(testDiv.children[4].text, 'true');
          expect(testDiv.children[5].text, '');
        }));

      });

  });
}

Future<Element> waitForChange(Element e) {
  var completer = new Completer<Element>();
  new MutationObserver((mutations, observer) {
    observer.disconnect();
    completer.complete(e);
  }).observe(e, childList: true);
  return completer.future.timeout(new Duration(seconds: 1));
}

@reflectable
class Model extends ChangeNotifier {
  String _data;

  Model(this._data);

  String get data => _data;

  void set data(String value) {
    _data = notifyPropertyChange(#data, _data, value);
  }

  String toString() => "Model(data: $_data)";
}

class NullNodeTreeSanitizer implements NodeTreeSanitizer {

  @override
  void sanitizeTree(Node node) {}
}