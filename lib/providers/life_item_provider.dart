import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/life_item.dart';
import '../services/database_service.dart';

class LifeItemProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<LifeItem> _items = [];
  List<LifeItem> get items => _items;

  Future<void> loadItems() async {
    _items = await _db.getLifeItems();
    notifyListeners();
  }

  Future<void> addItem(String title) async {
    await _db.insertLifeItem(
      LifeItem(id: _uuid.v4(), title: title, createdAt: DateTime.now()),
    );
    await loadItems();
  }

  Future<void> updateItem(LifeItem item, String title) async {
    await _db.updateLifeItem(item.copyWith(title: title));
    await loadItems();
  }

  Future<void> completeItem(String id) async {
    await _db.deleteLifeItem(id);
    await loadItems();
  }
}
