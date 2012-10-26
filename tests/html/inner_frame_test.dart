#library('InnerFrameTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  if (window != window.top) {
    // Child frame.

    // The child's frame should not be able to access its parent's
    // document.

    window.on.message.add((Event e) {
      switch (e.data) {
      case 'frameElement': {
        // Check window.frameElement.
        try {
          var parentDocument = window.frameElement.document;
          var div = parentDocument.$dom_createElement("div");
          div.id = "illegalFrameElement";
          parentDocument.body.nodes.add(div);
          expect(false, isTrue, reason: 'Should not reach here.');
        } on NoSuchMethodError catch (e) {
          // Expected.
          window.top.postMessage('pass_frameElement', '*');
        } catch (e) {
          window.top.postMessage('fail_frameElement', '*');
        }
        return;
      }
      case 'top': {
        // Check window.top.
        try {
          final top = window.top;
          var parentDocument = top.document;
          var div = parentDocument.$dom_createElement("div");
          div.id = "illegalTop";
          parentDocument.body.nodes.add(div);
          expect(false, isTrue, reason: 'Should not reach here.');
        } on NoSuchMethodError catch (e) {
          // Expected.
          window.top.postMessage('pass_top', '*');
        } catch (e) {
          window.top.postMessage('fail_top', '*');
        }
        return;
      }
      case 'parent': {
        // Check window.parent.
        try {
          final parent = window.parent;
          var parentDocument = parent.document;
          var div = parentDocument.$dom_createElement("div");
          div.id = "illegalParent";
          parentDocument.body.nodes.add(div);
          expect(false, isTrue, reason: 'Should not reach here.');
        } on NoSuchMethodError catch (e) {
          // Expected.
          window.top.postMessage('pass_parent', '*');
        } catch (e) {
          window.top.postMessage('fail_parent', '*');
        }
        return;
      }
      }
      });
  }

  // Parent / test frame
  useHtmlConfiguration();

  final iframe = new Element.tag('iframe');
  iframe.src = window.location.href;
  var child;

  test('prepare', () {
      iframe.on.load.add(expectAsync1((e) { child = iframe.contentWindow;}));
      document.body.nodes.add(iframe);
    });

  final validate = (testName, verify) {
    final expectedVerify = expectAsync0(verify);
    window.on.message.add((e) {
      guardAsync(() {
          if (e.data == 'pass_$testName') {
            expectedVerify();
          }
          expect(e.data, isNot(equals('fail_$testName')));
        });
      });
    child.postMessage(testName, '*');
  };

  test('frameElement', () {
      validate('frameElement', () {
        var div = document.query('#illegalFrameElement');

        // Ensure that this parent frame was not modified by its child.
        expect(div, isNull);
      });
    });

  test('top', () {
      validate('top', () {
        var div = document.query('#illegalTop');

        // Ensure that this parent frame was not modified by its child.
        expect(div, isNull);
      });
    });

  test('parent', () {
      validate('parent', () {
        var div = document.query('#illegalParent');

        // Ensure that this parent frame was not modified by its child.
        expect(div, isNull);
      });
    });
}
