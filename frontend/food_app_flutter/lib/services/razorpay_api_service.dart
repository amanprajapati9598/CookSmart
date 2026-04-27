import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RazorpayApiService {
  // IMPORTANT: For production, NEVER store secrets in the client app!
  // This is strictly for demonstration/prototyping without a backend.
  static const String keyId = 'rzp_test_YOUR_KEY_HERE';
  static const String keySecret = 'YOUR_KEY_SECRET_HERE';
  
  static String get _basicAuth => 'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';

  /// Ensure a plan exists or creates one for the ₹299 monthly PRO subscription.
  Future<String> getOrCreatePlan() async {
    const url = 'https://api.razorpay.com/v1/plans';
    
    try {
      // 1. Fetch available plans first to avoid duplication
      final fetchRes = await http.get(Uri.parse(url), headers: {'Authorization': _basicAuth});
      if (fetchRes.statusCode == 200) {
        final data = jsonDecode(fetchRes.body);
        if (data['items'] != null) {
          for (var item in data['items']) {
            if (item['item'] != null && item['item']['amount'] == 29900) {
              return item['id']; // Found a matching ₹299 plan
            }
          }
        }
      }

      // 2. If not found, create a new Plan
      final createRes = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _basicAuth,
        },
        body: jsonEncode({
          "period": "monthly",
          "interval": 1,
          "item": {
            "name": "CookSmart PRO Autopay",
            "amount": 29900,
            "currency": "INR",
            "description": "Premium AI Recipe Generation Auto-Renewal"
          }
        }),
      );

      if (createRes.statusCode == 200) {
        final planData = jsonDecode(createRes.body);
        return planData['id'];
      } else {
        throw Exception('Failed to create Plan: ${createRes.body}');
      }
    } catch (e) {
      debugPrint('Razorpay Plan Error: $e');
      rethrow;
    }
  }

  /// Creates a subscription mapping to the Plan with an upfront charge of ₹5 for the 3-day Trial
  Future<String> createTrialSubscription(String planId) async {
    const url = 'https://api.razorpay.com/v1/subscriptions';
    
    // Calculate timestamp 3 days from now (start of recurring)
    // Razorpay requires this to be a UNIX epoch timestamp
    final startAt = DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000;

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _basicAuth,
        },
        body: jsonEncode({
          "plan_id": planId,
          "total_count": 12, // Subscribed for 1 year max before renewal req
          "customer_notify": 1,
          "quantity": 1,
          "start_at": startAt,
          "addons": [
            {
              "item": {
                "name": "3-Day Trial Period Charge",
                "amount": 500, // ₹5 in paise
                "currency": "INR"
              }
            }
          ]
        }),
      );

      if (res.statusCode == 200) {
        final subData = jsonDecode(res.body);
        return subData['id']; // Returns the sub_XXXXX ID
      } else {
        throw Exception('Failed to create Subscription: ${res.body}');
      }
    } catch (e) {
      debugPrint('Razorpay Subscription Error: $e');
      rethrow;
    }
  }
}
