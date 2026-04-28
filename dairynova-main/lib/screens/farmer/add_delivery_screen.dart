import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDeliveryScreen extends StatefulWidget {
  final String farmId;

  const AddDeliveryScreen({super.key, required this.farmId});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController(text: "30.7258");
  final _lngController = TextEditingController(text: "72.6430");

  bool _isEmergency = false;
  bool _isLoading = false;
  String? _selectedRiderId;

  // Memory leak se bachne ke liye dispose lazmi hai
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRiderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rider first!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Data types ko handle karne ke liye tryParse behtar hai
      double lat = double.tryParse(_latController.text) ?? 0.0;
      double lng = double.tryParse(_lngController.text) ?? 0.0;

      await FirebaseFirestore.instance.collection('deliveries').add({
        'customerName': _nameController.text.trim(),
        'customerAddress': _addressController.text.trim(),
        'customerLat': lat,
        'customerLng': lng,
        'isEmergency': _isEmergency,
        'farmId': widget.farmId,
        'status': 'assigned',
        'riderId': _selectedRiderId,
        'riderLatitude': 0.0,
        'riderLongitude': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Delivery assigned successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assign New Delivery",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Select Rider",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Rider Selection
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No Users Found");
                  }

                  // Role check filter
                  var riders = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['role']?.toString().toLowerCase() == 'rider';
                  }).toList();

                  if (riders.isEmpty) return const Text("No Riders Found");

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Choose a rider"),
                    value: _selectedRiderId,
                    items: riders.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? "Unknown Rider"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedRiderId = val),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Customer Details
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Customer Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Enter name" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Enter address" : null,
              ),

              const SizedBox(height: 15),

              // Lat/Lng Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Emergency Switch
              SwitchListTile(
                title: const Text(
                  "Emergency Order?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Highlight for rider"),
                value: _isEmergency,
                activeColor: Colors.red,
                onChanged: (v) => setState(() => _isEmergency = v),
              ),

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _submitOrder,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SUBMIT ORDER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
