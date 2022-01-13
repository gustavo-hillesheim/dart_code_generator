import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';

import 'generated_file.dart';
import 'generator.dart';
import 'generator_result.dart';
import 'package_analyzer.dart';

class CodeGenerator {
  final List<Generator> _generators = [];
  final PackageAnalyzer _analyzer;

  CodeGenerator(this._analyzer);

  Future<void> generateFor(Directory packageDirectory) async {
    final libraries = await _analyzer.analyze(packageDirectory);
    final generatorResult = _runGenerator(libraries);
    await _saveFiles(generatorResult.files);
  }

  GeneratorResult _runGenerator(List<ResolvedLibraryResult> libraries) {
    final files = <GeneratedFile>[];
    for (final library in libraries) {
      for (final unit in library.units) {
        for (final declaration in unit.unit.declarations) {
          for (final generator in _generators) {
            if (generator.shouldGenerateFor(declaration)) {
              files.addAll(generator.generate(declaration).files);
            }
          }
        }
      }
    }
    return GeneratorResult(files);
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

  void registerGenerator(Generator generator) {
    _generators.add(generator);
  }
}
