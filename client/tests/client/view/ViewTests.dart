// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Unit tests for the [View] class. */
class ViewTests extends UnitTestSuite {
  ViewTests() : super() {
  }

  void setUpTestSuite() {
    test('does not render immediately', () {
      final view = new TestView();
      expect(view.isRendered) == false;

      view.addToDocument(document.body);
      expect(view.isRendered) == true;
    });

    group('addToDocument()', () {
      test('causes view to render', () {
        final view = new TestView();
        view.addToDocument(document.body);
        expect(view.isRendered) == true;
      });

      test('calls afterRender()', () {
        var result = '';
        final view = new TestView();
        view.renderFn = () {
          result += 'render';
          return new Element.html('<div class="test"></div>');
        };

        view.afterRenderFn = (node) { result += 'after'; };


        view.addToDocument(document.body);
        expect(result) == 'renderafter';
      });

      test('calls enterDocument()', () {
        final view = new TestView();
        bool entered = false;
        view.enterDocumentFn = () { entered = true; };

        view.addToDocument(document.body);
        expect(entered) == true;
      });
    });

    group('afterRender()', () {
      test('passes rendered node', () {
        final rendered = new Element.html('<div class="node"></div>');
        final view = new TestView();
        view.renderFn = () => rendered;
        view.afterRenderFn = (node) { expect(node) == rendered; };

        view.addToDocument(document.body);
      });
    });

    group('childViewAdded()', () {
      test('calls enterDocument() if parent is in document', () {
        final parent = new TestView();
        parent.addToDocument(document.body);

        bool entered = false;
        final child = new TestView();
        child.enterDocumentFn = () { entered = true; };

        // Add the child.
        parent.childViews = [child];
        parent.childViewAdded(child);

        expect(entered) == true;
      });

      test('does not call enterDocument() if parent is not in document', () {
        final parent = new TestView();

        bool entered = false;
        final child = new TestView();
        child.enterDocumentFn = () { entered = true; };

        // Add the child.
        parent.childViews = [child];
        parent.childViewAdded(child);

        expect(entered) == false;
      });

      test('calls enterDocument() each time added', () {
        final parent = new TestView();
        parent.addToDocument(document.body);

        var entered = 0;
        final child = new TestView();
        child.enterDocumentFn = () { entered++; };

        // Add the child.
        parent.childViews = [child];
        parent.childViewAdded(child);
        parent.childViewRemoved(child);
        parent.childViewAdded(child);
        parent.childViewRemoved(child);
        parent.childViewAdded(child);
        parent.childViewRemoved(child);

        expect(entered) == 3;
      });
    });

    group('childViewRemoved()', () {
      test('calls exitDocument() if parent is in document', () {
        final parent = new TestView();
        parent.addToDocument(document.body);

        bool exited = false;
        final child = new TestView();
        child.exitDocumentFn = () { exited = true; };

        // Remove the child.
        parent.childViews = [];
        parent.childViewRemoved(child);

        expect(exited) == true;
      });

      test('does not call exitDocument() if parent is not in document', () {
        final parent = new TestView();

        bool exited = false;
        final child = new TestView();
        child.exitDocumentFn = () { exited = true; };

        // Remove the child.
        parent.childViews = [];
        parent.childViewRemoved(child);

        expect(exited) == false;
      });

      test('calls exitDocument() each time removed', () {
        final parent = new TestView();
        parent.addToDocument(document.body);

        var exited = 0;
        final child = new TestView();
        child.exitDocumentFn = () { exited++; };

        // Add the child.
        parent.childViews = [child];
        parent.childViewAdded(child);
        parent.childViewRemoved(child);
        parent.childViewAdded(child);
        parent.childViewRemoved(child);
        parent.childViewAdded(child);
        parent.childViewRemoved(child);

        expect(exited) == 3;
      });
    });

    group('enterDocument()', () {
      test('children are called before parents', () {
        var result = '';

        final parent = new TestView();
        parent.enterDocumentFn = () { result += 'parent'; };

        final child = new TestView();
        child.enterDocumentFn = () { result += 'child'; };

        parent.childViews = [child];

        parent.addToDocument(document.body);
        expect(result) == 'childparent';
      });
    });
  }
}

class TestView extends View {
  Function renderFn;
  Function afterRenderFn;
  Function enterDocumentFn;
  Function exitDocumentFn;
  List<View> childViews;

  TestView() : super(), childViews = [] {
    // Default behavior.
    renderFn = () => new Element.html('<div class="test"></div>');
    afterRenderFn = (node) {};
    enterDocumentFn = () {};
    exitDocumentFn = () {};
  }

  Element render() => renderFn();
  void afterRender(Element node) { afterRenderFn(node); }
  void enterDocument() { enterDocumentFn(); }
  void exitDocument() { exitDocumentFn(); }
}
