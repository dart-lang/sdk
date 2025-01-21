// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class State {
  const State._();
}

final class StateEmpty extends State {
  const StateEmpty() : super._();
}

final class StateWithBunchOfFields extends State {
  const StateWithBunchOfFields({
    this.value1,
    this.value2,
    this.value3,
    this.value4,
    this.value5,
    this.value6,
    this.value7,
    this.value8,
    this.value9,
    this.value10,
    this.value11,
    this.value12,
    this.value13,
    this.value14,
    this.value15,
    this.value16,
    this.value17,
    this.value18,
    this.value19,
    this.value20,
    this.value21,
    this.value22,
    this.value23,
    this.value24,
    this.value25,
    this.value26,
    this.value27,
    this.value28,
    this.value29,
    this.value30,
    this.value31,
  }) : super._();

  final String? value1;
  final String? value2;
  final String? value3;
  final String? value4;
  final String? value5;
  final String? value6;
  final String? value7;
  final String? value8;
  final String? value9;
  final String? value10;
  final String? value11;
  final String? value12;
  final String? value13;
  final String? value14;
  final String? value15;
  final String? value16;
  final String? value17;
  final String? value18;
  final String? value19;
  final String? value20;
  final String? value21;
  final String? value22;
  final String? value23;
  final String? value24;
  final String? value25;
  final String? value26;
  final String? value27;
  final String? value28;
  final String? value29;
  final String? value30;
  final String? value31;
}

void handleState(State state) {
  /*
   checkingOrder={State,StateEmpty,StateWithBunchOfFields},
   fields={value1:-,value10:-,value11:-,value12:-,value13:-,value14:-,value15:-,value16:-,value17:-,value18:-,value19:-,value2:-,value20:-,value21:-,value22:-,value23:-,value24:-,value25:-,value26:-,value27:-,value28:-,value29:-,value3:-,value30:-,value31:-,value4:-,value5:-,value6:-,value7:-,value8:-,value9:-},
   subtypes={StateEmpty,StateWithBunchOfFields},
   type=State
  */
  switch (state) {
    /*space=StateEmpty*/
    case StateEmpty():
      print("empty");

    /*space=StateWithBunchOfFields(value1: String?, value2: String?, value3: String?, value4: String?, value5: String?, value6: String?, value7: String?, value8: String?, value9: String?, value10: String?, value11: String?, value12: String?, value13: String?, value14: String?, value15: String?, value16: String?, value17: String?, value18: String?, value19: String?, value20: String?, value21: String?, value22: String?, value23: String?, value24: String?, value25: String?, value26: String?, value27: String?, value28: String?, value29: String?, value30: String?, value31: String?)*/
    case StateWithBunchOfFields(
      :var value1,
      :var value2,
      :var value3,
      :var value4,
      :var value5,
      :var value6,
      :var value7,
      :var value8,
      :var value9,
      :var value10,
      :var value11,
      :var value12,
      :var value13,
      :var value14,
      :var value15,
      :var value16,
      :var value17,
      :var value18,
      :var value19,
      :var value20,
      :var value21,
      :var value22,
      :var value23,
      :var value24,
      :var value25,
      :var value26,
      :var value27,
      :var value28,
      :var value29,
      :var value30,
      :var value31,
    ):
      print("many fields");
  }
}
