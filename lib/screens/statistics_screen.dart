import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('조사 통계'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<InventoryModel>(
        builder: (context, inventoryModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsCard(inventoryModel),
                const SizedBox(height: 20),
                _buildProgressChart(inventoryModel),
                const SizedBox(height: 20),
                _buildQuantityDistribution(inventoryModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(InventoryModel inventoryModel) {
    final completedItems = inventoryModel.entries.where((entry) => entry.quantity != null).length;
    final totalItems = inventoryModel.entries.length;
    final completionRate = totalItems > 0 ? (completedItems / totalItems * 100) : 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '재고조사 진행 현황',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('전체 상품', '$totalItems개', Colors.blue),
                ),
                Expanded(
                  child: _buildStatItem('완료', '$completedItems개', Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('미완료', '${totalItems - completedItems}개', Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('완료율', '${completionRate.toStringAsFixed(1)}%', Colors.purple),
                ),
                Expanded(
                  child: _buildStatItem('총 수량', '${_getTotalQuantity(inventoryModel)}개', Colors.teal),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(InventoryModel inventoryModel) {
    final completedItems = inventoryModel.entries.where((entry) => entry.quantity != null).length;
    final totalItems = inventoryModel.entries.length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '진행률',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% 완료 ($completedItems / $totalItems)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityDistribution(InventoryModel inventoryModel) {
    final Map<int, int> distribution = {};

    for (final entry in inventoryModel.entries) {
      if (entry.quantity != null) {
        distribution[entry.quantity!] = (distribution[entry.quantity!] ?? 0) + 1;
      }
    }

    final sortedKeys = distribution.keys.toList()..sort();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수량별 분포',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (distribution.isEmpty)
              const Text(
                '입력된 수량 데이터가 없습니다.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...sortedKeys.map((quantity) {
                final count = distribution[quantity]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _getQuantityColor(quantity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getQuantityColor(quantity).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getQuantityColor(quantity),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('$count개 상품'),
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getQuantityColor(quantity),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  int _getTotalQuantity(InventoryModel inventoryModel) {
    int total = 0;
    for (final entry in inventoryModel.entries) {
      total += entry.quantity ?? 0;
    }
    return total;
  }

  Color _getQuantityColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity <= 2) return Colors.orange;
    if (quantity <= 5) return Colors.blue;
    return Colors.green;
  }
}