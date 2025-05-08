/*member: main:[null|powerset={null}]*/
void main() {
  testList();
  testClosure1();
}

/*member: testList:Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: null, powerset: {I}{G})*/
testList() {
  dynamic list = [];
  final rec = (list, 3);
  final myList =
      rec. /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: null, powerset: {I}{G}), [exact=JSUInt31|powerset={I}{O}]], powerset: {N}{O})]*/ $1;
  myList
      . /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: null, powerset: {I}{G})*/ add(
        1,
      );
  return list;
}

/*member: testClosure1:Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G})*/
testClosure1() {
  return getRecord()
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G}), [exact=JSUInt31|powerset={I}{O}]], powerset: {N}{O})]*/ $1;
}

/*member: getRecord:[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G}), [exact=JSUInt31|powerset={I}{O}]], powerset: {N}{O})]*/
getRecord() {
  return ([1, 2], 3);
}
