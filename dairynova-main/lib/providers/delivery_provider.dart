import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_model.dart';

class DeliveryProvider with ChangeNotifier {
  List<Delivery> _deliveries = [];
  List<Delivery> get deliveries => [..._deliveries];

  // 1. Fetch Orders (Farmer Dashboard ke liye)
  Future<void> fetchDeliveries() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();

      _deliveries = snapshot.docs.map((doc) {
        final data = doc.data();
        return Delivery(
          id: doc.id,
          customerName: data['customerName'] ?? 'Unknown',
          address: (data['address'] ?? 'No Address').toString(),
          status: (data['status'] ?? 'pending').toString(),
          isEmergency: data['isEmergency'] ?? false,
          lat: (data['lat'] as num? ?? 0.0).toDouble(),
          lng: (data['lng'] as num? ?? 0.0).toDouble(),
        );
      }).toList();
      notifyListeners();
    } catch (error) {
      debugPrint("Fetch Error: $error");
    }
  }

  // 2. Fetch Pending Orders (Rider Jobs Screen ka error yahan se theek hoga)
  Future<void> fetchPendingOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();

      _deliveries = snapshot.docs.map((doc) {
        final data = doc.data();
        return Delivery(
          id: doc.id,
          customerName: data['customerName'] ?? 'Unknown',
          address: (data['address'] ?? 'No Address').toString(),
          status: 'pending',
          isEmergency: data['isEmergency'] ?? false,
          lat: (data['lat'] as num? ?? 0.0).toDouble(),
          lng: (data['lng'] as num? ?? 0.0).toDouble(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Pending Orders Error: $e");
    }
  }

  // 3. Accept Order (Rider Jobs Screen ka accept button logic)
  Future<void> acceptOrder(String orderId, String riderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'accepted', 'riderId': riderId},
      );
      fetchPendingOrders(); // List refresh karne ke liye
    } catch (e) {
      debugPrint("Accept Order Error: $e");
      rethrow;
    }
  }

  // 4. Update Status (General Status Update)
  Future<void> updateDeliveryStatus(String id, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(id).update({
        'status': newStatus,
      });
      fetchDeliveries();
    } catch (e) {
      rethrow;
    }
  }

  // 5. Fetch My Deliveries (My Tasks Screen ke liye)
  Future<void> fetchMyDeliveries(String riderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .get();

      _deliveries = snapshot.docs.map((doc) {
        final data = doc.data();
        return Delivery(
          id: doc.id,
          customerName: data['customerName'] ?? 'Unknown',
          address: (data['address'] ?? 'No Address').toString(),
          status: (data['status'] ?? 'accepted').toString(),
          isEmergency: data['isEmergency'] ?? false,
          lat: (data['lat'] as num? ?? 0.0).toDouble(),
          lng: (data['lng'] as num? ?? 0.0).toDouble(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("My Deliveries Error: $e");
    }
  }
}
