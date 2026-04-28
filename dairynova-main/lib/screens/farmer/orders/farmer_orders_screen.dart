import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';

class FarmerOrdersScreen extends StatefulWidget {
  final String farmId;
  const FarmerOrdersScreen({super.key, required this.farmId});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Manage Orders",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('farmId', isEqualTo: widget.farmId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Filter docs safely
                var filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedFilter == 'All') return true;
                  return (data['status'] ?? '').toString().toLowerCase() ==
                      _selectedFilter.toLowerCase();
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No orders found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildManagementCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['All', 'Pending', 'Accepted', 'Shipped', 'Delivered'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: statuses
            .map(
              (status) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(status),
                  selected: _selectedFilter == status,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = status;
                    });
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildManagementCard(String id, Map<String, dynamic> data) {
    // FORCE SAFE VALUES TO PREVENT RED SCREEN
    final String customerName = (data['customerName'] ?? "Unknown").toString();
    final String status = (data['status'] ?? "Pending").toString();

    // This part fixes the 'totalAmount' crash specifically
    double displayAmount = 0.0;
    try {
      if (data['totalAmount'] != null) {
        displayAmount = double.parse(data['totalAmount'].toString());
      } else if (data['total'] != null) {
        displayAmount = double.parse(data['total'].toString());
      }
    } catch (e) {
      displayAmount = 0.0;
    }

    return Card(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        maintainState: true,
        title: Text(
          customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Status: $status | Rs. ${displayAmount.toStringAsFixed(2)}",
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📍 Address: ${data['deliveryAddress'] ?? data['address'] ?? 'N/A'}",
                ),
                const Divider(),
                ...?((data['items'] as List?)?.map(
                  (item) => Text("• ${item['name']} x${item['quantity']}"),
                )),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _updateButton(id, "Accepted", Colors.blue),
                    _updateButton(id, "Delivered", Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateButton(String id, String newStatus, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () => FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .update({'status': newStatus}),
      child: Text(newStatus, style: const TextStyle(color: Colors.white)),
    );
  }
}
