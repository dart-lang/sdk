#library('SerializedScriptValueTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');
#import('utils.dart');

serializationTest(name, value) => test(name, () {
      // To check how value is serialized and deserialized, we create a MessageEvent.
    final event = document.createEvent('MessageEvent');
    event.initMessageEvent('', false, false, value, '', '', window, []);
    verifyGraph(value, event.data);
});


main() {
  useDomConfiguration();

  serializationTest('null', null);
  serializationTest('int', 1);
  serializationTest('double', 2.39);
  serializationTest('string', 'hey!');

  final simpleMap = {'a': 100, 'b': 's'};
  final dagMap = { 'x': simpleMap, 'y': simpleMap };
  final cyclicMap = { 'b': dagMap };
  cyclicMap['a'] = cyclicMap;
  serializationTest('simple map', simpleMap);
  serializationTest('dag map', dagMap);
  serializationTest('cyclic map', cyclicMap);

  final simpleList = [ 100, 's'];
  final dagList = [ simpleList, simpleList ];
  final cyclicList = [ dagList ];
  cyclicList.add(cyclicList);
  serializationTest('simple list', simpleList);
  serializationTest('dag list', dagList);
  serializationTest('cyclic list', cyclicList);
}
