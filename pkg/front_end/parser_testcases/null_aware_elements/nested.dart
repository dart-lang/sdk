test1(List list, bool Function(dynamic) p, int? a) {
  return {
    for (var element in list)
      if (p(element))
        ?a
  };
}

test2(List list, bool Function(dynamic) p, int? a, int? b) {
  return {
    for (var element in list)
      if (p(element))
        ?a
      else
        ?b
  };
}

test3(List list, bool t, int? a) {
  return {
    if (t)
      for (var element in list)
        ?a
  };
}

test4(List list, bool t, int? a, int? b) {
  return {
    if (t)
      for (var element in list)
        ?a
    else
      for (var element in list)
        ?b
  };
}

test5(List list, bool Function(dynamic) p, int? a) {
  return {
    for (var element in list)
      if (p(element))
        ?a: "value"
  };
}

test6(List list, bool Function(dynamic) p, int? a, int? b) {
  return {
    for (var element in list)
      if (p(element))
        ?a: "value"
      else
        ?b: "value"
  };
}

test7(List list, bool t, int? a) {
  return {
    if (t)
      for (var element in list)
        ?a: "value"
  };
}

test8(List list, bool t, int? a, int? b) {
  return {
    if (t)
      for (var element in list)
        ?a: "value"
    else
      for (var element in list)
        ?b: "value"
  };
}

test9(List list, bool Function(dynamic) p, int? a) {
  return {
    for (var element in list)
      if (p(element))
        "key": ?a
  };
}

test10(List list, bool Function(dynamic) p, int? a, int? b) {
  return {
    for (var element in list)
      if (p(element))
        "key": ?a
      else
        "key": ?b
  };
}

test11(List list, bool t, int? a) {
  return {
    if (t)
      for (var element in list)
        "key": ?a
  };
}

test12(List list, bool t, int? a, int? b) {
  return {
    if (t)
      for (var element in list)
        "key": ?a
    else
      for (var element in list)
        "key": ?b
  };
}
