import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';

import 'generation_step.dart';
import 'generated_file.dart';
import 'generator.dart';
import 'package_analyzer.dart';

export 'generated_file.dart';
export 'generator.dart';
export 'generator_result.dart';
export 'package_analyzer.dart';

/// Analyzes a package and runs any registered generator that should generate for a given declaration.
class CodeGenerator {
  /// Generators used to generate code in [generateFor].
  final List<Generator> _generators;

  /// Used to analyze the package given in [generateFor].
  final PackageAnalyzer _analyzer;

  const CodeGenerator({
    required List<Generator> generators,
    PackageAnalyzer analyzer = const PackageAnalyzer(),
  })  : _generators = generators,
        _analyzer = analyzer;

  /// Generates code for the source code inside [packageDirectory].
  ///
  /// Loops through every top-level member of every library inside [packageDirectory],
  /// passing each member and it's path to each [Generator] of [_generators].
  /// Returns a stream containing a [AnalyzingPackageStep], a [RunningGeneratorsStep]
  /// and [RunningGeneratorStep] for all generators ran.
  Stream<GenerationStep> generateFor(Directory packageDirectory) async* {
    yield AnalyzingPackageStep();
    final libraries = await _analyzer.analyze(packageDirectory);
    yield RunningGeneratorsStep();
    await for (final step in runGenerators(libraries)) {
      if (step is CodeGenerationResult) {
        await _saveFiles(step.files);
      }
    }
  }

  /// Executes the generators for the given libraries.
  ///
  /// Loops through every top-level declaration in every item of [libraries],
  /// passing them to each generators registered, and returning all files that would be generated.
  /// Returns a stream containing [RunningGeneratorStep] for all generators ran and a [CodeGenerationResult] for the final result.
  Stream<GenerationStep> runGenerators(
    List<ResolvedLibraryResult> libraries,
  ) async* {
    final files = <GeneratedFile>[];
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

  Future<void> _saveFiles(List<GeneratedFile> generatedFiles) async {
    for (final generatedFile in generatedFiles) {
      final file = File(generatedFile.path);
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(generatedFile.content);
      }
    }
  }
}
