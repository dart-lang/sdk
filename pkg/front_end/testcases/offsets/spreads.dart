void main(List<String> args) {
  Set<String> fooSet = {
    ...args,
    "hello",
    ...{"x": "y"}.keys,
    for (String s in args) ...{
      "$s",
      "${s}_2",
    },
    if (args.length == 42) ...{
      "length",
      "is",
      "42",
    },
  };
  print(fooSet);

  Set<String> fooSet2 = {
    ...args,
    ...{"x": "y"}.keys,
    for (String s in args) ...{
      "$s",
      "${s}_2",
    },
    if (args.length == 42) ...{
      "length",
      "is",
      "42",
    },
  };
  print(fooSet2);

  List<String> fooList = [
    ...args,
    "hello",
    ...{"x": "y"}.keys,
    for (String s in args) ...[
      "$s",
      "${s}_2",
    ],
    if (args.length == 42) ...[
      "length",
      "is",
      "42",
    ],
  ];
  print(fooList);

  Map<String, String> fooMap = {
    "hello": "world",
    for (String s in args) ...{
      "$s": "${s}_2",
    },
    if (args.length == 42) ...{
      "length": "42",
      "is": "42",
      "42": "!",
    },
  };
  print(fooMap);
}
