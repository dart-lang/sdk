/*member: main:[null|powerset={null}]*/
void main() {
  testList();
  testClosure1();
}

/*member: testList:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: null, powerset: {I})*/
testList() {
  dynamic list = [];
  final rec = (list, 3);
  final myList =
      rec. /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: null, powerset: {I}), [exact=JSUInt31|powerset={I}]], powerset: {N})]*/ $1;
  myList
      . /*invoke: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: null, powerset: {I})*/ add(
        1,
      );
  return list;
}

/*member: testClosure1:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 2, powerset: {I})*/
testClosure1() {
  return getRecord()
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 2, powerset: {I}), [exact=JSUInt31|powerset={I}]], powerset: {N})]*/ $1;
}

/*member: getRecord:[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 2, powerset: {I}), [exact=JSUInt31|powerset={I}]], powerset: {N})]*/
getRecord() {
  return ([1, 2], 3);
}
