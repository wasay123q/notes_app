import 'package:flutter/foundation.dart' as foundation;
import '../models/note.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class NotesProvider with foundation.ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Note> _notes = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  List<Note> get notes =>
      _selectedCategoryId == null
          ? _notes
          : _notes
              .where((note) => note.categoryId == _selectedCategoryId)
              .toList();

  List<Category> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotesProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _isLoading = true;
      notifyListeners();

      await loadCategories();
      await loadNotes();

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotes() async {
    try {
      _notes = await _dbHelper.getAllNotes();
      _error = null;
    } catch (e) {
      _error = 'Failed to load notes: $e';
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _dbHelper.getAllCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to load categories: $e';
    }
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    try {
      await _dbHelper.createNote(note);
      await loadNotes();
      _error = null;
    } catch (e) {
      _error = 'Failed to add note: $e';
    }
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    try {
      await _dbHelper.updateNote(note);
      await loadNotes();
      _error = null;
    } catch (e) {
      _error = 'Failed to update note: $e';
    }
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dbHelper.deleteNote(id);
      await loadNotes();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete note: $e';
    }
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    try {
      await _dbHelper.createCategory(category);
      await loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to add category: $e';
    }
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _dbHelper.updateCategory(category);
      await loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to update category: $e';
    }
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dbHelper.deleteCategory(id);
      await loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete category: $e';
    }
    notifyListeners();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }
}
