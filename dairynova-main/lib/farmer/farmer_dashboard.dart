import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_screen.dart';
import './products/product_management_screen.dart';
import './orders/farmer_orders_screen.dart';
import './orders/daily_delivery_list.dart';
import './add_delivery_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/farmer_waiting_screen.dart';
import '../widgets/farmer_rejected_screen.dart';
import '../widgets/farmer_stat_card.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  final bool _isUploading = false;
  final String _imgBBKey = "35a63ea828f028776d7fb98b32f08d10";

  // --- STOCK ALERT ---
  Widget _buildStockAlertBanner(String farmId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('farmId', isEqualTo: farmId)
          .where('stock', isEqualTo: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Action Required: ${snapshot.data!.docs.length} products Out of Stock!",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text("RESTOCK"),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- STATS BUILDERS (CRITICAL FIXES HERE) ---

  Widget _buildEarningsStat(String farmId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('farmId', isEqualTo: farmId)
          .where('status', isEqualTo: 'Delivered')
          .snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            // FIXED: Use a safe map check to prevent "field does not exist" crash
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('totalAmount')) {
              total += (data['totalAmount'] ?? 0).toDouble();
            } else if (data.containsKey('total')) {
              total += (data['total'] ?? 0).toDouble();
            }
          }
        }
        return FarmerStatCard(
          title: "Total Earnings",
          value: "Rs. ${total.toStringAsFixed(0)}",
          icon: Icons.payments_outlined,
          color: Colors.green,
        );
      },
    );
  }

  Widget _buildNewOrdersStat(String farmId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('farmId', isEqualTo: farmId)
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return FarmerStatCard(
          title: "New Orders",
          value: count.toString().padLeft(2, '0'),
          icon: Icons.pending_actions,
          color: Colors.orange,
        );
      },
    );
  }

  Widget _buildActiveProductsStat(String farmId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('farmId', isEqualTo: farmId)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return FarmerStatCard(
          title: "Active Products",
          value: count.toString().padLeft(2, '0'),
          icon: Icons.grass,
          color: Colors.blue,
        );
      },
    );
  }

  Widget _buildRatingStat(String farmId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('farmId', isEqualTo: farmId)
          .snapshots(),
      builder: (context, snapshot) {
        double totalStars = 0;
        int reviewCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('rating') && data['rating'] != null) {
              totalStars += (data['rating'] as num).toDouble();
              reviewCount++;
            }
          }
        }
        double average = reviewCount == 0 ? 0.0 : totalStars / reviewCount;
        return FarmerStatCard(
          title: "Profile Rating",
          value: average == 0.0 ? "N/A" : average.toStringAsFixed(1),
          icon: Icons.star_rate_rounded,
          color: Colors.amber,
        );
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farms')
          .where('ownerId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(body: Center(child: Text("No farm found.")));
        }

        var doc = snapshot.data!.docs.first;
        var farmData = doc.data() as Map<String, dynamic>;
        String farmId = doc.id;
        String status = farmData['status'] ?? 'pending';

        if (status == 'pending') {
          return Scaffold(
            body: FarmerWaitingScreen(
              farmName: farmData['farmName'] ?? "Farmer",
            ),
          );
        }
        if (status == 'rejected') {
          return Scaffold(body: FarmerRejectedScreen(farmData: farmData));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              _getAppBarTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _logout,
              ),
            ],
          ),
          body: _getScreen(farmId, farmData),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded),
                label: "Products",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                label: "Orders",
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 1) return "Product Management";
    if (_selectedIndex == 2) return "Customer Orders";
    return "Farmer Dashboard";
  }

  Widget _getScreen(String farmId, Map<String, dynamic> farmData) {
    if (_selectedIndex == 1) return ProductManagementScreen(farmId: farmId);
    if (_selectedIndex == 2) return FarmerOrdersScreen(farmId: farmId);
    return _buildHomeTab(farmId, farmData);
  }

  Widget _buildHomeTab(String farmId, Map<String, dynamic> farm) {
    String? farmPhoto =
        (farm['farmPhotos'] != null && (farm['farmPhotos'] as List).isNotEmpty)
        ? farm['farmPhotos'][0]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(farm, farmPhoto),
          const SizedBox(height: 24),
          _buildStockAlertBanner(farmId),
          const Text(
            "Delivery Management",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 55),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyDeliveryList(farmId: farmId),
              ),
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text(
              "View Daily Delivery List",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddDeliveryScreen(farmId: farmId),
              ),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text(
              "Assign New Delivery",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Live Performance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(farmId),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> farm, String? farmPhoto) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary,
            backgroundImage: farmPhoto != null ? NetworkImage(farmPhoto) : null,
            child: farmPhoto == null
                ? const Icon(Icons.storefront, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm['farmName'] ?? "My Farm",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Verified Partner",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String farmId) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildNewOrdersStat(farmId),
        _buildEarningsStat(farmId),
        _buildActiveProductsStat(farmId),
        _buildRatingStat(farmId),
      ],
    );
  }
}
