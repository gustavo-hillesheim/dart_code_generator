import 'generated_file.dart';
import 'generator.dart';

/// Represents the result of a [Generator].
class GeneratorResult {
  /// List of files that were generated and should be saved to the file system.
  final List<GeneratedFile> files;

  GeneratorResult(this.files);

  GeneratorResult.single({required String path, required String content})
      : files = [GeneratedFile(path: path, content: content)];
}
