#library('WindowOpenTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  evaluateJavaScript(code) {
    final scriptTag = document.createElement('script');
    scriptTag.innerHTML = code;
    document.body.appendChild(scriptTag);
  }
  evaluateJavaScript('layoutTestController.setCanOpenWindows()');

  useDomConfiguration();
  test('TwoArgumentVersion', () {
    Window win = window.open('../resources/pong.html', 'testWindow');
    closeWindow(win);
  });
  test('ThreeArgumentVersion', () {
    Window win = window.open("resources/pong.html", "testWindow", "scrollbars=yes,width=75,height=100");
    closeWindow(win);
  });
}

closeWindow(win) {
  win.close();
  doneHandler() {
    window.setTimeout(expectAsync0(() { if (!win.closed) doneHandler(); }), 1);
  }
  window.setTimeout(expectAsync0(doneHandler), 1);
}
