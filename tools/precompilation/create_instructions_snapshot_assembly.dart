import 'dart:io';

void main(List<String> args) {
  print(args[0]);
  print(args[1]);

  var bytes = new File(args[0]).readAsBytesSync();
  print(bytes.length);

  var out = new StringBuffer();
  out.writeln(".text");
  out.writeln("  .globl _kInstructionsSnapshot");
  out.writeln("_kInstructionsSnapshot:");
  out.writeln("  .balign 32, 0");
  for (var i = 0; i < bytes.length; i++) {
    var byte = bytes[i];
    out.writeln("  .byte $byte");
  }

  new File(args[1]).writeAsString(out.toString());
}
