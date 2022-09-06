import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// Analyzes a given package and returns all libraries resolved.
class PackageAnalyzer {
  const PackageAnalyzer();

  Future<List<ResolvedLibraryResult>> analyzeDirectory(Directory directory) {
    final collection =
        _createAnalysisContextCollectionForPaths([directory.absolute.path]);
    return _readLibraries(collection);
  }

  Future<List<ResolvedLibraryResult>> analyzeAll(List<String> filePaths) {
    final collection = _createAnalysisContextCollectionForPaths(filePaths);
    return _readLibraries(collection);
  }

  AnalysisContextCollection _createAnalysisContextCollectionForPaths(
      List<String> paths) {
    return AnalysisContextCollection(
      includedPaths: paths,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
  }

  Future<List<ResolvedLibraryResult>> _readLibraries(
      AnalysisContextCollection collection) async {
    final result = <ResolvedLibraryResult>[];
    for (final context in collection.contexts) {
      for (final filePath in context.contextRoot.analyzedFiles()) {
        if (!filePath.endsWith('.dart')) {
          continue;
        }
        final parsedLibrary =
            await context.currentSession.getResolvedLibrary(filePath);
        if (parsedLibrary is ResolvedLibraryResult) {
          result.add(parsedLibrary);
        }
      }
    }
    return result;
  }
}
