import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' show normalize;

import 'generation_step.dart';
import 'generated_file.dart';
import 'generator.dart';
import 'package_analyzer.dart';
import 'file_watcher.dart';

export 'generated_file.dart';
export 'generation_step.dart';
export 'generator.dart';
export 'generator_result.dart';
export 'package_analyzer.dart';
export 'debouncer.dart';
export 'file_watcher.dart';

/// Analyzes a package and runs any registered generator that should generate for a given declaration.
class CodeGenerator {
  /// Project Generators used to generate code in [generateFor].
  final List<GeneratorForProject> _projectGenerators;

  /// Generators used to generate code in [generateFor].
  final List<Generator> _generators;

  /// Used to analyze the package given in [generateFor].
  final PackageAnalyzer _analyzer;

  /// Used in incremental generation to watch file changes.
  final FileWatcher _fileWatcher;

  const CodeGenerator({
    required List<Generator> generators,
    List<GeneratorForProject>? projectGenerators,
    PackageAnalyzer analyzer = const PackageAnalyzer(),
    FileWatcher fileWatcher = const FileWatcher(),
  })  : _projectGenerators = projectGenerators ?? const [],
        _generators = generators,
        _analyzer = analyzer,
        _fileWatcher = fileWatcher;

  /// Generates code for the source code inside [packageDirectory].
  ///
  /// Loops through every top-level member of every library inside [packageDirectory],
  /// passing each member and it's path to each [Generator] of [_generators].
  /// Use [overrideExisting] to override existing files with the generated content.
  ///
  /// Returns a [Stream] containing a [AnalyzingPackageStep], a [RunningGeneratorsStep]
  /// [RunningGeneratorStep]s for all generators ran and a final [CodeGenerationResult] for the result.
  /// The [Stream] can also contain [SavingError]s or [IgnoredExistingFile] events.
  Stream<GenerationStep> generateFor(
    Directory packageDirectory, {
    bool overrideExisting = false,
  }) async* {
    yield AnalyzingPackageStep();
    final libraries = await _analyzer.analyzeDirectory(packageDirectory);
    yield RunningGeneratorsStep();
    await for (final step in runGenerators(libraries)) {
      yield step;
      if (step is CodeGenerationResult) {
        yield* _saveFiles(step.files, overrideExisting: overrideExisting);
      }
    }
  }

  /// Generates code for the source code inside [packageDirectory], updating the
  /// generated files on source code changes.
  ///
  /// Loops through every top-level member of every library inside [packageDirectory],
  /// passing each member and it's path to each [Generator] of [_generators].
  /// Use [overrideExisting] to override existing files with the generated content.
  /// After generating the first batch of files, watches for file changes in
  /// [packageDirectory] and regenerates files affected by the change.
  ///
  /// Returns a [Stream] containing a [AnalyzingPackageStep], a [RunningGeneratorsStep]
  /// [RunningGeneratorStep]s for all generators ran and a final [CodeGenerationResult] for the result.
  /// The [Stream] can also contain [SavingError]s or [IgnoredExistingFile] events.
  Stream<GenerationStep> generateForIncrementally(
    Directory packageDirectory, {
    bool overrideExisting = true,
  }) async* {
    yield* generateFor(packageDirectory, overrideExisting: overrideExisting);
    await for (final changedFiles
        in _fileWatcher.watchFiles(packageDirectory)) {
      yield AnalyzingPackageStep();
      final libraries = await _analyzer.analyzeAll(changedFiles);
      yield RunningGeneratorsStep();
      await for (final step in runGenerators(libraries)) {
        yield step;
        if (step is CodeGenerationResult) {
          yield* _saveFiles(step.files, overrideExisting: overrideExisting);
        }
      }
    }
  }

  /// Executes the generators for the given libraries.
  ///
  /// Loops through every top-level declaration in every item of [libraries],
  /// passing them to each generator registered, and returning all files that would be generated.
  /// Returns a stream containing [RunningGeneratorStep] for all generators ran and a [CodeGenerationResult] for the final result.
  Stream<GenerationStep> runGenerators(
    List<ResolvedLibraryResult> libraries,
  ) async* {
    final files = <GeneratedFile>[];
    for (final projectGenerator in _projectGenerators) {
      yield RunningGeneratorStep(projectGenerator.description);
      files.addAll(projectGenerator.generate(libraries).files);
    }
    for (final library in libraries) {
      for (final unit in library.units) {
        for (final declaration in unit.unit.declarations) {
          for (final generator in _generators) {
            if (generator.acceptsType(declaration) &&
                generator.shouldGenerateFor(declaration, unit.path)) {
              yield RunningGeneratorStep(generator.description);
              final generatedFiles =
                  generator.generate(declaration, unit.path).files;
              files.addAll(generatedFiles);
            }
          }
        }
      }
    }
    yield CodeGenerationResult(files);
  }

  Stream<GenerationStep> _saveFiles(
    List<GeneratedFile> generatedFiles, {
    required bool overrideExisting,
  }) async* {
    for (final generatedFile in generatedFiles) {
      final file = File(generatedFile.path);
      final filePath = normalize(generatedFile.path);
      try {
        if (overrideExisting || !await file.exists()) {
          await file.create(recursive: true);
          await file.writeAsString(generatedFile.content);
        } else {
          yield IgnoredExistingFile(filePath);
        }
      } catch (e) {
        yield SavingError(e, filePath);
      }
    }
  }
}
