import 'package:code_generator/code_generator.dart';
import 'package:equatable/equatable.dart';

/// Represents a step of the generation process.
abstract class GenerationStep extends Equatable {
  String get message;
}

/// Step of the generation in which [CodeGenerator] is analyzing the package's
/// source code. It is the first step of generation.
class AnalyzingPackageStep extends GenerationStep {
  @override
  String get message => 'Analyzing package source code...';

  @override
  List<Object?> get props => [message];
}

/// Step of the generation right before running the generators. Occurs after [AnalyzingPackageStep].
class RunningGeneratorsStep extends GenerationStep {
  @override
  String get message => 'Running generators...';

  @override
  List<Object?> get props => [message];
}

/// Step of the generation in which [CodeGenerator] is running a specific generator.
/// Occurs after [RunningGeneratorsStep] and can be dispatched multiple times.
class RunningGeneratorStep extends GenerationStep {
  final String generatorDescription;

  RunningGeneratorStep(this.generatorDescription);

  @override
  String get message => 'Running $generatorDescription...';

  @override
  List<Object?> get props => [message];
}

/// Step of the generation in which [CodeGenerator] has finished running generators
/// and determined all files that should be generated. Occurs after all [RunningGeneratorStep]s have finished.
class CodeGenerationResult extends GenerationStep {
  final List<GeneratedFile> files;

  CodeGenerationResult(this.files);

  @override
  String get message =>
      'Finished code generation with ${files.length} generated files';

  @override
  List<Object?> get props => [files, message];
}

/// Step of the generation in which [CodeGenerator] had an error while saving a file.
/// Occurs after [CodeGenerationResult] and can be dispatched multiple times.
class SavingError extends GenerationStep {
  final Object error;
  final String filePath;

  SavingError(this.error, this.filePath);

  @override
  String get message =>
      'Error while saving generated file "$filePath": ${error.toString()}';

  @override
  List<Object?> get props => [error, filePath, message];
}

/// Step of the generation in which [CodeGenerator] ignored a generated file because it already exists.
/// Occurs after [CodeGenerationResult] and can be dispatched multiple times.
class IgnoredExistingFile extends GenerationStep {
  final String filePath;

  IgnoredExistingFile(this.filePath);

  @override
  String get message =>
      'Did not save generated file "$filePath" because it already exists';

  @override
  List<Object?> get props => [filePath, message];
}

class FinishedWritingFilesStep extends GenerationStep {
  @override
  String get message => 'Finished writing generated files to file system';

  @override
  List<Object?> get props => [message];
}
