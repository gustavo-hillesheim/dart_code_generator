import 'dart:async';

/// Component to debounce execution of functions.
class Debouncer {
  final Duration debounceTime;
  Timer? _timer;

  Debouncer(this.debounceTime);

  dispose() {
    _timer?.cancel();
  }

  void run(void Function() fn) {
    final timer = _timer;
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
    _timer = Timer(debounceTime, fn);
  }
}
