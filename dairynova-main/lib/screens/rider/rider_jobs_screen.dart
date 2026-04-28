import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/delivery_provider.dart';
import '../../utils/app_theme.dart';

class RiderJobsScreen extends StatefulWidget {
  const RiderJobsScreen({super.key});

  @override
  State<RiderJobsScreen> createState() => _RiderJobsScreenState();
}

class _RiderJobsScreenState extends State<RiderJobsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh "pending" orders when the screen opens
    Future.microtask(
      () => Provider.of<DeliveryProvider>(
        context,
        listen: false,
      ).fetchPendingOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Available Deliveries",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => Provider.of<DeliveryProvider>(
              context,
              listen: false,
            ).fetchPendingOrders(),
          ),
        ],
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          final availableJobs = provider.deliveries;

          // FIXED: Lowercase 'check_circle_outline' to resolve the error
          if (availableJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No new deliveries available right now.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: availableJobs.length,
            itemBuilder: (context, index) {
              final job = availableJobs[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: job.isEmergency
                          ? Colors.red[50]
                          : Colors.blue[50],
                      child: Icon(
                        Icons.local_shipping,
                        color: job.isEmergency ? Colors.red : Colors.blueAccent,
                      ),
                    ),
                    title: Text(
                      job.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.address),
                        if (job.isEmergency)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "URGENT DELIVERY",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          _showAcceptDialog(context, job.id, riderId!),
                      child: const Text("PICK UP"),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, String orderId, String riderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Accept Delivery?"),
        content: const Text(
          "By accepting, you agree to deliver this order as soon as possible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<DeliveryProvider>(
                  context,
                  listen: false,
                ).acceptOrder(orderId, riderId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Order accepted successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "YES, ACCEPT",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
