import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/cart_model.dart';
import './farm_products_screen.dart';
import './customer_orders_screen.dart';
import './cart_screen.dart';
import './subscription_management_screen.dart';
import './customer_settings_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  String _selectedCategory = 'All';
  String _searchQuery = "";
  final List<String> _categories = [
    'All',
    'Milk',
    'Yogurt',
    'Cheese',
    'Butter',
    'Ghee',
  ];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Dairy Nova",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionManagementScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerOrdersScreen(),
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      cart.itemCount.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndWelcomeHeader(),
          _buildCategoryList(),
          Expanded(
            child: _FarmList(
              selectedCategory: _selectedCategory,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fresh from the Farm,",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Text(
            "Order Pure Dairy Today!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search dairy farms...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategory == _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(_categories[index]),
              selected: isSelected,
              onSelected: (val) =>
                  setState(() => _selectedCategory = _categories[index]),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FarmList extends StatelessWidget {
  final String selectedCategory;
  final String searchQuery;
  const _FarmList({required this.selectedCategory, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farms')
          .where('status', isEqualTo: 'verified')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No verified farms found."));
        }

        var farms = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          // FORCE toString() to avoid "Map" errors in searching
          String name = (data['farmName'] ?? "").toString().toLowerCase();
          return name.contains(searchQuery.toLowerCase());
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: farms.length,
          itemBuilder: (context, index) {
            var doc = farms[index];
            var farmData = doc.data() as Map<String, dynamic>;

            // --- CRITICAL FIX FOR RED SCREEN ---
            // We use .toString() on everything to prevent "LinkedMap" type errors
            String farmName = (farmData['farmName'] ?? "Dairy Farm").toString();

            // If location is stored as a Map, this .toString() prevents the crash
            String farmLocation = (farmData['location'] ?? "Location unknown")
                .toString();

            // Safe Image Logic
            String photoUrl = "";
            if (farmData['farmPhotos'] is List &&
                (farmData['farmPhotos'] as List).isNotEmpty) {
              photoUrl = farmData['farmPhotos'][0].toString();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmProductsScreen(
                      farmId: doc.id,
                      farmName: farmName,
                      categoryFilter: selectedCategory,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    if (photoUrl.isNotEmpty)
                      Image.network(
                        photoUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(),
                      )
                    else
                      _placeholder(),
                    ListTile(
                      title: Text(
                        farmName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        farmLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.storefront, size: 50, color: Colors.grey),
    );
  }
}
