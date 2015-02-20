part of dart._internal;

Function printToZone = null;
@patch void printToConsole(String line) {
  printString('$line');
}
