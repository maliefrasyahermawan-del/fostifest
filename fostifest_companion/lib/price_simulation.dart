import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'laras_api.dart';

/// Independent scenario snapshots; never writes inventory or supplier records.
class SimulationMaterial {
  SimulationMaterial({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.materialId,
    this.supplierId,
    this.supplierName,
  }) {
    if (name.trim().isEmpty ||
        unit.trim().isEmpty ||
        !quantity.isFinite ||
        quantity <= 0 ||
        quantity > 1000000 ||
        unitPrice < 0 ||
        unitPrice > 1000000000 ||
        quantity * unitPrice > 1000000000) {
      throw ArgumentError('Bahan atau biaya tidak valid.');
    }
  }
  final String name, unit;
  final double quantity;
  final int unitPrice;
  final String? materialId, supplierId, supplierName;
  double get subtotal => quantity * unitPrice;
  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'materialId': materialId,
        'supplierId': supplierId,
        'supplierName': supplierName,
      };
  factory SimulationMaterial.fromJson(Map<String, dynamic> j) =>
      SimulationMaterial(
        name: j['name'] as String,
        unit: j['unit'] as String,
        quantity: (j['quantity'] as num).toDouble(),
        unitPrice: j['unitPrice'] as int,
        materialId: j['materialId'] as String?,
        supplierId: j['supplierId'] as String?,
        supplierName: j['supplierName'] as String?,
      );
}

class SimulationCost {
  SimulationCost({
    Iterable<SimulationMaterial> materials = const [],
    this.labor = 0,
    this.overhead = 0,
  }) : materials = List.unmodifiable(materials) {
    if (labor < 0 || overhead < 0 || total > 1000000000) {
      throw ArgumentError('Biaya produksi maksimal Rp1 miliar per produk.');
    }
  }
  final List<SimulationMaterial> materials;
  final int labor, overhead;
  double get materialTotal => materials.fold(0.0, (sum, m) => sum + m.subtotal);
  int get total => (materialTotal + labor + overhead).round();
  bool get isDefined => materials.isNotEmpty || labor > 0 || overhead > 0;
  Map<String, dynamic> toJson() => {
        'materials': materials.map((m) => m.toJson()).toList(),
        'labor': labor,
        'overhead': overhead,
      };
  factory SimulationCost.fromJson(Map<String, dynamic> j) => SimulationCost(
        materials: (j['materials'] as List).map(
          (m) =>
              SimulationMaterial.fromJson(Map<String, dynamic>.from(m as Map)),
        ),
        labor: j['labor'] as int,
        overhead: j['overhead'] as int,
      );

  factory SimulationCost.fromProduct(
    Map<String, dynamic> product,
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> suppliers,
  ) {
    final recipe = (product['recipe'] as List?) ?? [];
    if (product['costMode'] != 'resep' || recipe.isEmpty) {
      return SimulationCost(
        materials: [
          SimulationMaterial(
            name: 'Modal per produk',
            unit: 'produk',
            quantity: 1,
            unitPrice: (product['cost'] as num? ?? 0).round(),
          ),
        ],
      );
    }
    return SimulationCost(
      labor: (product['labor'] as num? ?? 0).round(),
      overhead: (product['overhead'] as num? ?? 0).round(),
      materials: recipe.map((line) {
        final matches = materials.where((m) => m['id'] == line['materialId']);
        final current = matches.isEmpty ? null : matches.first;
        final source = suppliers.where(
          (s) => s['id'] == current?['supplierId'],
        );
        return SimulationMaterial(
          name: '${current?['name'] ?? line['name']}',
          unit: '${current?['unit'] ?? line['unit'] ?? 'unit'}',
          quantity: (line['qty'] as num).toDouble(),
          unitPrice: (current?['pricePerUnit'] as num? ??
                  line['unitPrice'] as num? ??
                  0)
              .round(),
          materialId: current?['id'] as String?,
          supplierId: current?['supplierId'] as String?,
          supplierName: source.isEmpty ? null : '${source.first['name']}',
        );
      }),
    );
  }
}

class PriceSimulation {
  PriceSimulation({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.cost,
    required this.savedAt,
  }) {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        price < 0 ||
        price > maxPrice ||
        quantity < 1 ||
        quantity > maxQuantity ||
        !cost.isDefined) {
      throw ArgumentError('Simulasi tidak valid.');
    }
  }
  static const maxPrice = 10000000;
  static const maxQuantity = 1000000;
  final String id, name;
  final int price, quantity;
  final SimulationCost cost;
  final DateTime savedAt;
  int get profitPerUnit => price - cost.total;
  int get totalProfit => profitPerUnit * quantity;
  double? get margin => price == 0 ? null : profitPerUnit * 100 / price;
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'cost': cost.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };
  factory PriceSimulation.fromJson(Map<String, dynamic> j) => PriceSimulation(
        id: j['id'] as String,
        name: j['name'] as String,
        price: j['price'] as int,
        quantity: j['quantity'] as int,
        cost: SimulationCost.fromJson(
            Map<String, dynamic>.from(j['cost'] as Map)),
        savedAt: DateTime.parse(j['savedAt'] as String),
      );
}

class SimulationLimitException implements Exception {}

class SimulationReadException implements Exception {}

class PriceSimulationRepository {
  PriceSimulationRepository({LarasApi? api, bool? useServer})
      : _api = api ?? LarasApi(),
        _useServer = useServer ?? LarasApi.enabled;
  final LarasApi _api;
  final bool _useServer;
  static const storageKey = 'laras_price_simulations_v1';
  static const capacity = 10;
  // Serialize all instances, including two fast taps or two open routes.
  static Future<void>? _pending;
  Future<T> _mutate<T>(Future<T> Function() action) async {
    final previous = _pending;
    final lock = Completer<void>();
    _pending = lock.future;
    try {
      if (previous != null) {
        await previous;
      }
      return await action();
    } finally {
      lock.complete();
      if (identical(_pending, lock.future)) {
        _pending = null;
      }
    }
  }

  Future<List<PriceSimulation>> read() async {
    if (_useServer) {
      final data = await _api.request('GET', 'simulations');
      return (data['simulations'] as List)
          .map(
            (j) =>
                PriceSimulation.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      final result = (jsonDecode(raw) as List)
          .map(
            (j) =>
                PriceSimulation.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList();
      if (result.length > capacity ||
          result.map((s) => s.id).toSet().length != result.length) {
        throw const FormatException('Invalid simulation list');
      }
      return result;
    } catch (_) {
      throw SimulationReadException();
    }
  }

  Future<void> save(PriceSimulation simulation) => _mutate(() async {
        if (_useServer) {
          try {
            await _api.request('POST', 'simulations',
                body: simulation.toJson());
          } on LarasApiException catch (e) {
            if (e.code == 'simulation_limit') throw SimulationLimitException();
            rethrow;
          }
          return;
        }
        final values = await read();
        if (values.length >= capacity) throw SimulationLimitException();
        if (values.any((s) => s.id == simulation.id)) {
          throw StateError('ID sudah ada');
        }
        await _write([simulation, ...values]);
      });
  Future<void> delete(String id) => _mutate(() async {
        if (_useServer) {
          await _api.request(
              'DELETE', 'simulations/${Uri.encodeComponent(id)}');
          return;
        }
        final values = await read();
        await _write(values.where((s) => s.id != id).toList());
      });
  Future<void> _write(List<PriceSimulation> values) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      storageKey,
      jsonEncode(values.map((s) => s.toJson()).toList()),
    )) {
      throw StateError('Penyimpanan gagal');
    }
  }
}
