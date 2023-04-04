/*member: main:[null]*/
void main() {
  testList();
  testClosure1();
}

/*member: testList:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
testList() {
  dynamic list = [];
  final rec = (list, 3);
  final myList = rec
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null), [exact=JSUInt31]])]*/ $1;
  myList
      . /*invoke: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/ add(
          1);
  return list;
}

/*member: testClosure1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/
testClosure1() {
  return getRecord()
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2), [exact=JSUInt31]])]*/ $1;
}

/*member: getRecord:[Record(RecordShape(2), [Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2), [exact=JSUInt31]])]*/
getRecord() {
  return ([1, 2], 3);
}
