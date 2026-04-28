import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/delivery_provider.dart';
import '../../utils/app_theme.dart';

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId != null) {
      Future.microtask(
        () => Provider.of<DeliveryProvider>(
          context,
          listen: false,
        ).fetchMyDeliveries(riderId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "My Active Tasks",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          final myJobs = provider.deliveries;

          if (myJobs.isEmpty) {
            return const Center(child: Text("You have no active deliveries."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: myJobs.length,
            itemBuilder: (context, index) {
              final job = myJobs[index];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.directions_bike,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        job.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(job.address),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Navigation Button (Placeholder for now)
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Navigation starting..."),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text("MAP"),
                          ),
                          // Complete Delivery Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () => _confirmDelivery(context, job.id),
                            child: const Text(
                              "MARK DELIVERED",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelivery(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delivery"),
        content: const Text("Are you sure this order has been delivered?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("NO"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<DeliveryProvider>(
                context,
                listen: false,
              ).updateDeliveryStatus(orderId, 'delivered');
              _refreshData(); // Refresh list after updating
            },
            child: const Text("YES"),
          ),
        ],
      ),
    );
  }
}
