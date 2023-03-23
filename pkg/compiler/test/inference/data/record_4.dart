/*member: main:[null]*/
void main() {
  testList();
  testClosure1();
}

/*member: testList:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
testList() {
  dynamic list = [];
  final rec = (list, 3);
  final myList = rec
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), [exact=JSUInt31]])]*/ $1;
  myList
      . /*invoke: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/ add(
          1);
  return list;
}

/*member: testClosure1:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
testClosure1() {
  return getRecord()
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), [exact=JSUInt31]])]*/ $1;
}

/*member: getRecord:[Record(RecordShape(2), [Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), [exact=JSUInt31]])]*/
getRecord() {
  return ([1, 2], 3);
}
