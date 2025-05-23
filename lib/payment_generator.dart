import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class PaymentGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> generateReceipt({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    final invoiceRef = _firestore.collection('invoices').doc(invoiceId);
    final invoiceSnapshot = await invoiceRef.get();

    if (!invoiceSnapshot.exists) {
      throw Exception("Invoice not found");
    }

    final invoiceData = invoiceSnapshot.data()!;
    final clientId = invoiceData['clientId'];

    final paymentRef = await _firestore.collection('payments').add({
      'invoiceId': invoiceId,
      'clientId': clientId,
      'amount': amount,
      'method': method,
      'paidAt': Timestamp.now(),
    });

    final paymentId = paymentRef.id;

    await _firestore.collection('receipts').add({
      'invoiceId': invoiceId,
      'paymentId': paymentId,
      'generatedAt': Timestamp.now(),
    });

    await invoiceRef.update({'status': 'paid', 'updatedAt': Timestamp.now()});

    final historyRef =
        _firestore.collection('invoicePaymentHistory').doc(invoiceId);
    await historyRef.set({
      'payments': FieldValue.arrayUnion([
        {
          'paymentId': paymentId,
          'amount': amount,
          'method': method,
          'paidAt': Timestamp.now(),
        }
      ])
    }, SetOptions(merge: true));

    return paymentId;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPaymentById(
      String paymentId) {
    return _firestore.collection('payments').doc(paymentId).get();
  }

  Future<void> exportReceiptAsPdf(
      BuildContext context, String paymentId) async {
    // Show dialog before requesting permission
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('To download PDF you must give permission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final paymentSnapshot =
        await _firestore.collection('payments').doc(paymentId).get();

    if (!paymentSnapshot.exists) {
      throw Exception('Payment not found');
    }

    final paymentData = paymentSnapshot.data()!;
    final pdf = pw.Document();

    final fontData = await rootBundle
        .load("assets/fonts/NotoSans_ExtraCondensed-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final paidAt = (paymentData['paidAt'] as Timestamp).toDate();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Al Ahly Momken Receipt",
                  style: pw.TextStyle(font: ttf, fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Text("Payment ID: $paymentId"),
              pw.Text("Invoice ID: ${paymentData['invoiceId']}"),
              pw.Text("Client ID: ${paymentData['clientId']}"),
              pw.Text("Amount: \$${paymentData['amount']}"),
              pw.Text("Method: ${paymentData['method']}"),
              pw.Text("Paid At: $paidAt"),
            ],
          ),
        ),
      ),
    );

    final hasPermission = await _handleStoragePermission();
    if (!hasPermission) {
      throw Exception("Storage permission not granted.");
    }

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final outputFile = File('${downloadsDir.path}/receipt_$paymentId.pdf');
    await outputFile.writeAsBytes(await pdf.save());

    await OpenFile.open(outputFile.path);
    print("✅ PDF saved and opened from: ${outputFile.path}");
  }

  Future<bool> _handleStoragePermission() async {
    // Check if permission is already granted
    if (await Permission.storage.isGranted) {
      return true;
    }

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      if (Platform.isAndroid) Permission.manageExternalStorage,
    ].request();

    bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
    bool manageGranted =
        statuses[Permission.manageExternalStorage]?.isGranted ?? false;

    if (!storageGranted && !manageGranted) {
      if (statuses[Permission.storage]?.isPermanentlyDenied ??
          false ||
              statuses[Permission.manageExternalStorage]!.isPermanentlyDenied ??
          false) {
        await openAppSettings();
      }
      return false;
    }
    return true;
  }
}
