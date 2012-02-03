#library('XHRTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  asyncTest('XHR', 1, () {
    XMLHttpRequest xhr = new XMLHttpRequest();
    xhr.open('GET', 'XHR.html', true);
    xhr.addEventListener('readystatechange', (event) {
      if (xhr.readyState == 4)
        if (xhr.status == 200 || xhr.status == 0) {
          Expect.notEquals(-1, xhr.responseText.indexOf('XHR.dart', 0));
          callbackDone();
        }
    }, true);
    xhr.send();
  });
}
