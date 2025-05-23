import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createSampleUserData({
  required String userId,
  required String userName,
  required String userEmail,
  required String userPhone,
}) async {
  final now = DateTime.now();
  final firestore = FirebaseFirestore.instance;

  final clientDocRef = firestore.collection('clients').doc(userId);

  await clientDocRef.set({
    'name': userName,
    'email': userEmail,
    'phone': userPhone,
    'createdAt': now,
  });

  final invoicesCollection = firestore.collection('invoices');

  // Manually assigning invoice IDs from 1 to 100 for this example
  final invoiceIds = [1, 2, 3]; // <-- Only numbers as required

  final invoiceData = [
    {
      'invoiceId': invoiceIds[0],
      'clientId': userId,
      'amount': 1000.0,
      'status': 'unpaid',
      'dueDate': now.add(const Duration(days: 15)),
      'createdAt': now.subtract(const Duration(days: 30)),
      'updatedAt': now.subtract(const Duration(days: 1)),
    },
    {
      'invoiceId': invoiceIds[1],
      'clientId': userId,
      'amount': 750.0,
      'status': 'paid',
      'dueDate': now.subtract(const Duration(days: 10)),
      'createdAt': now.subtract(const Duration(days: 40)),
      'updatedAt': now.subtract(const Duration(days: 5)),
    },
    {
      'invoiceId': invoiceIds[2],
      'clientId': userId,
      'amount': 500.0,
      'status': 'overdue',
      'dueDate': now.subtract(const Duration(days: 5)),
      'createdAt': now.subtract(const Duration(days: 20)),
      'updatedAt': now.subtract(const Duration(days: 2)),
    },
  ];

  for (var invoice in invoiceData) {
    await invoicesCollection.doc(invoice['invoiceId'].toString()).set(invoice);
  }

  final paymentsCollection = firestore.collection('payments');
  final receiptsCollection = firestore.collection('receipts');
  final paymentHistoryCollection =
      firestore.collection('invoicePaymentHistory');

  final paymentsData = [
    {
      'paymentId': 'payment_${invoiceIds[0]}_1',
      'invoiceId': invoiceIds[0],
      'clientId': userId,
      'amount': 300.0,
      'method': 'cash',
      'paidAt': now.subtract(const Duration(days: 10)),
    },
    {
      'paymentId': 'payment_${invoiceIds[0]}_2',
      'invoiceId': invoiceIds[0],
      'clientId': userId,
      'amount': 200.0,
      'method': 'credit',
      'paidAt': now.subtract(const Duration(days: 7)),
    },
    {
      'paymentId': 'payment_${invoiceIds[1]}_1',
      'invoiceId': invoiceIds[1],
      'clientId': userId,
      'amount': 750.0,
      'method': 'bank transfer',
      'paidAt': now.subtract(const Duration(days: 15)),
    },
    {
      'paymentId': 'payment_${invoiceIds[2]}_1',
      'invoiceId': invoiceIds[2],
      'clientId': userId,
      'amount': 100.0,
      'method': 'cash',
      'paidAt': now.subtract(const Duration(days: 4)),
    },
  ];

  for (var payment in paymentsData) {
    await paymentsCollection.doc(payment['paymentId'] as String).set(payment);

    await receiptsCollection.doc('receipt_${payment['paymentId']}').set({
      'invoiceId': payment['invoiceId'],
      'paymentId': payment['paymentId'],
      'generatedAt': now,
    });

    final invoicePaymentHistoryDoc =
        paymentHistoryCollection.doc(payment['invoiceId'].toString());

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(invoicePaymentHistoryDoc);
      List<dynamic> payments = [];
      if (snapshot.exists && snapshot.data() != null) {
        payments = List<dynamic>.from(snapshot.get('payments') ?? []);
      }
      payments.add({
        'paymentId': payment['paymentId'],
        'amount': payment['amount'],
        'method': payment['method'],
        'paidAt': payment['paidAt'],
      });
      transaction.set(invoicePaymentHistoryDoc, {'payments': payments});
    });
  }
}
