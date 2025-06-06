// // category_sync_service.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/adapters.dart';
// import 'package:productivity_suite_flutter/notes/data/note.dart';
// import 'package:productivity_suite_flutter/notes/repository/category_repository.dart';

// final categorySyncProvider = Provider((ref) {
//   final repository = ref.watch(categoryRepositoryProvider);
//   return CategorySyncService(repository);
// });

// class CategorySyncService {
//   final CategoryRepository _repository;
//   final Box<Category> _categoriesBox;

//   CategorySyncService(this._repository)
//     : _categoriesBox = Hive.box<Category>('categoriesBox');

//   Future<List<Category>> getCategories() async {
//     try {
//       final serverCategories = await _repository.getAllCategories();
//       final localCategories = _categoriesBox.values.toList();

//       // Filter out any local duplicates of server categories
//       final uniqueLocalCategories =
//           localCategories
//               .where(
//                 (local) =>
//                     !serverCategories.any((server) => server.id == local.id),
//               )
//               .toList();

//       // Combine server categories with unique local categories
//       final combined = [...serverCategories, ...uniqueLocalCategories];

//       // Update local storage (without duplicates)
//       await _categoriesBox.clear();
//       await _categoriesBox.addAll(combined);

//       return combined;
//     } catch (e) {
//       // Fallback to local data if server fails
//       return _categoriesBox.values.toList();
//     }
//   }

//   Future<void> syncCategories() async {
//     await getCategories();
//   }

//   Future<Category> createCategory(Category category) async {
//     try {
//       // 1. Create category on server
//       final createdCategory = await _repository.createCategory(category);

//       // 2. Get latest categories from server
//       final serverCategories = await _repository.getAllCategories();

//       // 3. Get current local categories that DON'T exist on server
//       final localOnlyCategories =
//           _categoriesBox.values
//               .where(
//                 (localCat) =>
//                     !serverCategories.any(
//                       (serverCat) => serverCat.id == localCat.id,
//                     ),
//               )
//               .toList();

//       // 4. Combine server categories with unique local-only categories
//       final combinedCategories = [...serverCategories, ...localOnlyCategories];

//       // 5. Update local storage
//       await _categoriesBox.clear();
//       await _categoriesBox.addAll(combinedCategories);

//       return createdCategory;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<Category> updateCategory(Category category) async {
//     try {
//       final serverCategory = await _repository.updateCategory(category);

//       // Update local copy if exists
//       final index = _categoriesBox.values.toList().indexWhere(
//         (c) => c.id == category.id,
//       );
//       if (index >= 0) {
//         await _categoriesBox.putAt(index, serverCategory);
//       }

//       return serverCategory;
//     } catch (e) {
//       // Update local copy even if server fails
//       final index = _categoriesBox.values.toList().indexWhere(
//         (c) => c.id == category.id,
//       );
//       if (index >= 0) {
//         await _categoriesBox.putAt(index, category);
//       }
//       rethrow;
//     }
//   }

//   Future<void> deleteCategory(String id) async {
//     try {
//       await _repository.deleteCategory(id);
//       final index = _categoriesBox.values.toList().indexWhere(
//         (c) => c.id == id,
//       );
//       if (index >= 0) await _categoriesBox.deleteAt(index);
//     } catch (e) {
//       // Still delete locally if server fails
//       final index = _categoriesBox.values.toList().indexWhere(
//         (c) => c.id == id,
//       );
//       if (index >= 0) await _categoriesBox.deleteAt(index);
//       rethrow;
//     }
//   }
// }
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/repository/category_repository.dart';

final categorySyncProvider = Provider((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategorySyncService(repository);
});

class CategorySyncService {
  final CategoryRepository _repository;

  CategorySyncService(this._repository);

  Future<List<Category>> getCategories() async {
    try {
      final serverCategories = await _repository.getAllCategories();
      return serverCategories;
    } catch (e) {
      //if server fail
      return [];
    }
  }

  Future<void> syncCategories() async {
    await getCategories();
  }

  Future<Category> createCategory(Category category) async {
    try {
      final createdCategory = await _repository.createCategory(category);
      return createdCategory;
    } catch (e) {
      rethrow;
    }
  }

  Future<Category> updateCategory(Category category) async {
    try {
      final serverCategory = await _repository.updateCategory(category);
      return serverCategory;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
    } catch (e) {
      rethrow;
    }
  }
}
