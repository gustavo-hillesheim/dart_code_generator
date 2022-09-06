import 'dart:io';
import 'dart:async';

import 'debouncer.dart';

/// Component to watch file changes.
class FileWatcher {
  const FileWatcher();

  Stream<List<String>> watchFiles(Directory directory) {
    final streamController = StreamController<List<String>>();
    final debouncer = Debouncer(const Duration(seconds: 1));
    final changedFiles = <String>[];
    directory.watch(recursive: true).listen((event) {
      changedFiles.add(event.path);
      debouncer.run(() {
        streamController.sink.add(List.from(changedFiles, growable: false));
        changedFiles.clear();
      });
    });
    return streamController.stream;
  }
}
