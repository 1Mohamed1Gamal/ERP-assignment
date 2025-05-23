import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceSummary {
  final String status;
  final int count;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;

  InvoiceSummary({
    required this.status,
    required this.count,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
  });
}

class InvoiceSummaryReport {
  final List<InvoiceSummary> summaries;

  InvoiceSummaryReport(this.summaries);
}

class InvoiceSummarySDK {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<InvoiceSummaryReport> generateReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? clientId,
  }) async {
    Query invoicesQuery = _firestore.collection('invoices');

    if (startDate != null) {
      invoicesQuery =
          invoicesQuery.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      invoicesQuery =
          invoicesQuery.where('createdAt', isLessThanOrEqualTo: endDate);
    }
    if (status != null && status.isNotEmpty) {
      invoicesQuery = invoicesQuery.where('status', isEqualTo: status);
    }
    if (clientId != null && clientId.isNotEmpty) {
      invoicesQuery = invoicesQuery.where('clientId', isEqualTo: clientId);
    }

    final snapshot = await invoicesQuery.get();
    final Map<String, InvoiceSummary> summaryMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final s = (data['status'] ?? 'unknown').toString().toLowerCase();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final totalPaid = (data['totalPaid'] as num?)?.toDouble() ?? 0.0;
      final remaining = ((amount - totalPaid).clamp(0, amount)).toDouble();

      if (summaryMap.containsKey(s)) {
        final existing = summaryMap[s]!;
        summaryMap[s] = InvoiceSummary(
          status: s,
          count: existing.count + 1,
          totalAmount: existing.totalAmount + amount,
          totalPaid: existing.totalPaid + totalPaid,
          totalRemaining: existing.totalRemaining + remaining,
        );
      } else {
        summaryMap[s] = InvoiceSummary(
          status: s,
          count: 1,
          totalAmount: amount,
          totalPaid: totalPaid,
          totalRemaining: remaining,
        );
      }
    }

    return InvoiceSummaryReport(summaryMap.values.toList());
  }
}
