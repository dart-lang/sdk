void f(x) {
  switch (x) {
    case [...== null]:
    case [...!= null]:
    case [...< 0]:
    case [...> 0]:
    case [...<= 0]:
    case [...>= 0]:
    case [...0]:
    case [...0.0]:
    case [...0x0]:
    case [...null]:
    case [...false]:
    case [...true]:
    case [...'foo']:
    case [...x]:
    case [...const List()]:
    case [...var x]:
    case [...final x]:
    case [...List x]:
    case [..._]:
    case [...(_)]:
    case [...[_]]:
    case [...[]]:
    case [...<int>[]]:
    case [...{}]:
    case [...List()]:
      break;
  }
}
