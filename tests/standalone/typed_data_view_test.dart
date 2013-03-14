import 'dart:typeddata';

validate(TypedData list, num expected) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(expected, list[i]);
  }
}

main() {
  var list = new Int8List(128);
  for (var i = 0; i < list.length; i++) {
    list[i] = 42;
  }
  var ba = list.buffer;

  var slist = new Int16List.view(ba, 0, 32);
  validate(slist, 10794);
  var uslist = new Uint16List.view(ba, 0, 32);
  validate(uslist, 10794);

  var ilist = new Int32List.view(ba, 0, 16);
  validate(ilist, 707406378);
  var uilist = new Uint32List.view(ba, 0, 16);
  validate(uilist, 707406378);

  var llist = new Int64List.view(ba, 0, 8);
  validate(llist, 3038287259199220266);
  var ullist = new Uint64List.view(ba, 0, 8);
  validate(ullist, 3038287259199220266);

  var flist = new Float32List.view(ba, 0, 16);
  validate(flist, 1.511366173271439e-13);
  var dlist = new Float64List.view(ba, 0, 8);
  validate(dlist, 1.4260258159703532e-105);
}
