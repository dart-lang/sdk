part of dart.core;
 void print(Object object) {
  String line = "$object";
   if (printToZone == null) {
    printToConsole(line);
    }
   else {
    printToZone(line);
    }
  }
