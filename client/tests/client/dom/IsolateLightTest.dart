#library('IsolateLightTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');
#import('dart:json');
#import('dart:isolate');

var _isolateId;

class TestIsolate extends Isolate {
  TestIsolate() : super.light();

  void main() {
    _isolateId = 1;
    final div = document.getElementById('testid');

    // These events fire in the main isolate.  Note, dispatchEvent is
    // handled synchronously.
    Event event = document.createEvent('Event');
    event.initEvent('test', true, false);
    div.dispatchEvent(event);

    Expect.equals(1, _isolateId);
    event = document.createEvent('Event');
    event.initEvent('done', true, false);
    div.dispatchEvent(event);
  }
}

main() {
  _isolateId = 0;
  asyncTest('IsolatedStatic', 1, () {
    final div = document.createElement('div');
    div.id = 'testid';
    document.body.appendChild(div);
    div.addEventListener('test', (e) => Expect.equals(0, _isolateId), false);
    div.addEventListener('done', (e) => callbackDone(), false);
    new TestIsolate().spawn();
  });
}
