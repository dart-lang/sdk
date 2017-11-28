import 'dart:html';

import 'package:expect/minitest.dart';

import 'utils.dart';

serializationTest(name, value) {
  test(name, () {
    // To check how value is serialized and deserialized, we create a
    // MessageEvent.
    final event =
        new MessageEvent('', data: value, origin: '', lastEventId: '');
    verifyGraph(value, event.data);
  });
}

main() {
  serializationTest('null', null);
  serializationTest('int', 1);
  serializationTest('double', 2.39);
  serializationTest('string', 'hey!');

  final simpleMap = {'a': 100, 'b': 's'};
  final dagMap = {'x': simpleMap, 'y': simpleMap};
  final cyclicMap = {'b': dagMap};
  cyclicMap['a'] = cyclicMap;
  serializationTest('simple map', simpleMap);
  serializationTest('dag map', dagMap);
  serializationTest('cyclic map', cyclicMap);

  final simpleList = [100, 's'];
  final dagList = [simpleList, simpleList];
  final cyclicList = [dagList];
  cyclicList.add(cyclicList);
  serializationTest('simple list', simpleList);
  serializationTest('dag list', dagList);
  serializationTest('cyclic list', cyclicList);

  serializationTest('datetime', [new DateTime.now()]);

  var blob = new Blob(
      ['Indescribable... Indestructible! Nothing can stop it!'], 'text/plain');
  serializationTest('blob', [blob]);

  var canvas = new CanvasElement();
  canvas.width = 100;
  canvas.height = 100;
  var imageData = canvas.context2D.getImageData(0, 0, 1, 1);
  serializationTest('imagedata', [imageData]);
}
