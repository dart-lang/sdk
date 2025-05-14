/*member: main:[null|powerset=1]*/
void main() {
  testList();
  testClosure1();
}

/*member: testList:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0)*/
testList() {
  dynamic list = [];
  final rec = (list, 3);
  final myList =
      rec. /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0), [exact=JSUInt31|powerset=0]], powerset: 0)]*/ $1;
  myList
      . /*invoke: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0)*/ add(
        1,
      );
  return list;
}

/*member: testClosure1:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
testClosure1() {
  return getRecord()
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0), [exact=JSUInt31|powerset=0]], powerset: 0)]*/ $1;
}

/*member: getRecord:[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0), [exact=JSUInt31|powerset=0]], powerset: 0)]*/
getRecord() {
  return ([1, 2], 3);
}
