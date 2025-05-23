import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentLoggingService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> logPayment({
    required String invoiceId,
    required double paymentAmount,
    required String paymentMethod,
  }) async {
    final invoiceRef = _firestore.collection('invoices').doc(invoiceId);

    final invoiceSnapshot = await invoiceRef.get();
    if (!invoiceSnapshot.exists) {
      throw Exception('Invoice does not exist.');
    }

    final invoiceData = invoiceSnapshot.data()!;
    final clientId = invoiceData['clientId'];
    final double currentPaid = invoiceData['totalPaid']?.toDouble() ?? 0.0;
    final double invoiceTotal = invoiceData['amount']?.toDouble() ?? 0.0;
    final DateTime dueDate = invoiceData['dueDate']?.toDate() ?? DateTime.now();

    final newPayment = {
      'invoiceId': invoiceId,
      'clientId': clientId,
      'amount': paymentAmount,
      'method': paymentMethod,
      'paidAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('payments').add(newPayment);

    final newTotalPaid = currentPaid + paymentAmount;
    String newStatus = 'Unpaid';
    print(
        "####################################################################################################################");

    print(newTotalPaid);
    print(
        "####################################################################################################################");
    if (newTotalPaid >= invoiceTotal) {
      newStatus = 'Paid';
    } else if (DateTime.now().isAfter(dueDate)) {
      newStatus = 'Overdue';
    }

    await invoiceRef.update({
      'totalPaid': newTotalPaid,
      'lastPaymentDate': FieldValue.serverTimestamp(),
      'status': newStatus,
    });
  }
}
