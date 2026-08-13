/*member: main:[null|powerset={null}]*/
void main() {
  testList();
  testClosure1();
}

/*member: testList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/
testList() {
  dynamic list = [];
  final rec = (list, 3);
  final myList = rec
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M}), [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/ $1;
  myList
      . /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/ add(
        1,
      );
  return list;
}

/*member: testClosure1:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/
testClosure1() {
  return getRecord()
      . /*[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M}), [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/ $1;
}

/*member: getRecord:[Record(RecordShape(2), [Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M}), [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/
getRecord() {
  return ([1, 2], 3);
}
