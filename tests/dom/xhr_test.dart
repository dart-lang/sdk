#library('XHRTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  asyncTest('XHR', 1, () {
    XMLHttpRequest xhr = new XMLHttpRequest();
    // TODO: figure out how to place a resource file with fixed name alongside
    // the .html file.
    xhr.open('GET', 'MISSING-FILE', true);
    xhr.on.readyStateChange.add((event) {
        if (xhr.readyState == 4) {
          Expect.equals(0, xhr.status);
          Expect.stringEquals('', xhr.responseText);
          callbackDone();
        }
      }, true);
    xhr.send();
  });
}
