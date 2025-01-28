import 'dart:async';

void main() {
  throw 'Unimplemented';
}

var _tickCount = 0;
Timer? _timer;

@pragma('vm:entry-point', 'call')
void startTimer(int millis) {
  if (_timer == null) {
    final period = Duration(milliseconds: millis);
    _timer = Timer.periodic(period, (_) {
      _tickCount++;
    });
    print('Started timer with period $period');
  }
}

@pragma('vm:entry-point', 'call')
void stopTimer() {
  _timer?.cancel();
  _timer = null;
}

@pragma('vm:entry-point', 'call')
void resetTimer() {
  _tickCount = 0;
}

@pragma('vm:entry-point', 'get')
int get ticks => _tickCount;
