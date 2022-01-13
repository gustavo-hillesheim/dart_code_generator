import 'generator.dart';

/// Represents a file that was generated from a [Generator] and should be
/// saved to the file system.
class GeneratedFile {
  final String path;
  final String content;

  GeneratedFile({
    required this.path,
    required this.content,
  });
}
