import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;

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

    // Get current count of invoices
    final invoicesCollection = firestore.collection('invoices');
    final invoicesSnapshot = await invoicesCollection.get();
    final currentInvoiceCount = invoicesSnapshot.docs.length;

    // Prepare invoices with numeric IDs
    final invoiceData = [
      {
        'invoiceId': (currentInvoiceCount + 1).toString(),
        'clientId': userId,
        'amount': 1000.0,
        'status': 'unpaid',
        'dueDate': now.add(const Duration(days: 15)),
        'createdAt': now.subtract(const Duration(days: 30)),
        'updatedAt': now.subtract(const Duration(days: 1)),
        'totalPaid': 0.0,
      },
      {
        'invoiceId': (currentInvoiceCount + 2).toString(),
        'clientId': userId,
        'amount': 750.0,
        'status': 'paid',
        'dueDate': now.subtract(const Duration(days: 10)),
        'createdAt': now.subtract(const Duration(days: 40)),
        'updatedAt': now.subtract(const Duration(days: 5)),
        'totalPaid': 750,
      },
      {
        'invoiceId': (currentInvoiceCount + 3).toString(),
        'clientId': userId,
        'amount': 500.0,
        'status': 'overdue',
        'dueDate': now.subtract(const Duration(days: 5)),
        'createdAt': now.subtract(const Duration(days: 20)),
        'updatedAt': now.subtract(const Duration(days: 2)),
        'totalPaid': 0.0,
      },
    ];

    for (var invoice in invoiceData) {
      await invoicesCollection
          .doc(invoice['invoiceId'] as String?)
          .set(invoice);
    }

    // Get current count of payments
    final paymentsCollection = firestore.collection('payments');
    final paymentsSnapshot = await paymentsCollection.get();
    final currentPaymentCount = paymentsSnapshot.docs.length;

    final receiptsCollection = firestore.collection('receipts');
    final paymentHistoryCollection =
        firestore.collection('invoicePaymentHistory');

    // Prepare payments with numeric IDs
    final paymentsData = [
      {
        'paymentId': (currentPaymentCount + 1).toString(),
        'invoiceId': (currentInvoiceCount + 1).toString(),
        'clientId': userId,
        'amount': 300.0,
        'method': 'cash',
        'paidAt': now.subtract(const Duration(days: 10)),
      },
      {
        'paymentId': (currentPaymentCount + 2).toString(),
        'invoiceId': (currentInvoiceCount + 1).toString(),
        'clientId': userId,
        'amount': 200.0,
        'method': 'credit',
        'paidAt': now.subtract(const Duration(days: 7)),
      },
      {
        'paymentId': (currentPaymentCount + 3).toString(),
        'invoiceId': (currentInvoiceCount + 2).toString(),
        'clientId': userId,
        'amount': 750.0,
        'method': 'bank transfer',
        'paidAt': now.subtract(const Duration(days: 15)),
      },
      {
        'paymentId': (currentPaymentCount + 4).toString(),
        'invoiceId': (currentInvoiceCount + 3).toString(),
        'clientId': userId,
        'amount': 100.0,
        'method': 'cash',
        'paidAt': now.subtract(const Duration(days: 4)),
      },
    ];

    for (var payment in paymentsData) {
      await paymentsCollection
          .doc(payment['paymentId'] as String?)
          .set(payment);

      await receiptsCollection.doc('receipt_${payment['paymentId']}').set({
        'invoiceId': payment['invoiceId'],
        'paymentId': payment['paymentId'],
        'generatedAt': now,
      });

      final invoicePaymentHistoryDoc =
          paymentHistoryCollection.doc(payment['invoiceId'] as String?);
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

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty || phone.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await createSampleUserData(
        userId: uid,
        userName: name,
        userEmail: email,
        userPhone: phone,
      );

      Fluttertoast.showToast(msg: "Account created successfully!");

      if (mounted) {
        Navigator.pop(context); // Go back to login page
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Registration failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  final TextStyle boldBlackText = const TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Register", style: boldBlackText.copyWith(fontSize: 32)),
                  const SizedBox(height: 30),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: boldBlackText,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    style: boldBlackText,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: boldBlackText,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: boldBlackText,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
