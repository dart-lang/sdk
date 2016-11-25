void main(List<String> args) {
  var x = args.length;
  switch (x) {
    case 3:
      x = 4;
    case 5:
      break;
    case 6:
    case 7:
      if (args[0] == '') {
        break;
      } else {
        return;
      }
    case 4:
  }
}
