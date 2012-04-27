#library('WindowOpenTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  evaluateJavaScript(code) {
    final scriptTag = new Element.tag('script');
    scriptTag.innerHTML = code;
    document.body.nodes.add(scriptTag);
  }
  evaluateJavaScript('layoutTestController.setCanOpenWindows()');

  useHtmlConfiguration();
  asyncTest('TwoArgumentVersion', 1, () {
    Window win = window.open('../resources/pong.html', 'testWindow');
    closeWindow(win);
  });
  asyncTest('ThreeArgumentVersion', 1, () {
    Window win = window.open("resources/pong.html", "testWindow", "scrollbars=yes,width=75,height=100");
    closeWindow(win);
  });
}

closeWindow(win) {
  win.close();
  doneHandler() {
    window.setTimeout(win.closed ? callbackDone : doneHandler, 1);
  }
  window.setTimeout(doneHandler, 1);
}
