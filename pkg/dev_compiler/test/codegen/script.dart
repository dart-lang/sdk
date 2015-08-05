#!/usr/bin/env dart
void main(List<String> args) {
  String name = args.join(' ');
  if (name == '') name = 'world';
  print('hello $name');
}
