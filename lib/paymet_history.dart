import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cost_management/payment_generator.dart';
import 'package:flutter/material.dart';

class PaymentHistoryLog extends StatefulWidget {
  const PaymentHistoryLog({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryLog> createState() => _PaymentHistoryLogState();
}

class _PaymentHistoryLogState extends State<PaymentHistoryLog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _invoiceController =
      TextEditingController(text: '');
  List<Map<String, dynamic>> payments = [];
  bool loading = false;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  Timer? _debounce;

  final Color iconColor = Colors.orange;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // --- Payment Method Filter State ---
  String _selectedMethodFilter = 'all';
  final List<String> _methodFilters = [
    'all',
    'cash',
    'credit',
    'bank transfer'
  ];
  List<Map<String, dynamic>> get filteredPayments {
    if (_selectedMethodFilter == 'all') return payments;
    return payments
        .where(
            (p) => (p['method'] ?? '').toLowerCase() == _selectedMethodFilter)
        .toList();
  }
  // --- End Payment Method Filter State ---

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn);

    // Initial fetch: all payments for current user
    _fetchAllPaymentsForUser();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _animationController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onInvoiceIdChanged(String value) {
    // Debounce input by 500ms to avoid excessive Firestore calls
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final invoiceId = _invoiceController.text.trim();
      if (invoiceId.isEmpty) {
        _fetchAllPaymentsForUser();
      } else {
        _fetchPaymentsByInvoiceAndUser(invoiceId);
      }
    });
  }

  Future<void> _fetchAllPaymentsForUser() async {
    final userId = currentUserId;
    if (userId == null) {
      setState(() {
        loading = false;
      });
      debugPrint('User not logged in');
      return;
    }

    setState(() {
      loading = true;
      payments.clear();
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('clientId', isEqualTo: userId)
          .get();

      final fetchedPayments = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['paymentId'] = doc.id;
        return data;
      }).toList();

      payments = fetchedPayments;
      // Remove duplicates by paymentId
      final seen = <String>{};
      payments = payments.where((p) => seen.add(p['paymentId'])).toList();
      // Sort payments by paidAt from recent to older
      payments.sort((a, b) {
        final aPaidAt = a['paidAt'];
        final bPaidAt = b['paidAt'];
        if (aPaidAt is Timestamp && bPaidAt is Timestamp) {
          return bPaidAt.toDate().compareTo(aPaidAt.toDate());
        }
        return 0;
      });

      _animationController?.reset();
      _animationController?.forward();

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint('Error fetching all payments for user: $e');
    }
  }

  Future<void> _fetchPaymentsByInvoiceAndUser(String invoiceId) async {
    final userId = currentUserId;
    if (userId == null) {
      setState(() {
        loading = false;
      });
      debugPrint('User not logged in');
      return;
    }

    setState(() {
      loading = true;
      payments.clear();
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('invoiceId', isEqualTo: invoiceId)
          .where('clientId', isEqualTo: userId)
          .get();

      final fetchedPayments = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['paymentId'] = doc.id;
        return data;
      }).toList();

      payments = fetchedPayments;
      // Remove duplicates by paymentId
      final seen = <String>{};
      payments = payments.where((p) => seen.add(p['paymentId'])).toList();
      // Sort payments by paidAt from recent to older
      payments.sort((a, b) {
        final aPaidAt = a['paidAt'];
        final bPaidAt = b['paidAt'];
        if (aPaidAt is Timestamp && bPaidAt is Timestamp) {
          return bPaidAt.toDate().compareTo(aPaidAt.toDate());
        }
        return 0;
      });

      _animationController?.reset();
      _animationController?.forward();

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint('Error fetching payments by invoice and user: $e');
    }
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paymentGenerator = PaymentGenerator();
    final paidAt = (payment['paidAt'] as Timestamp?)?.toDate();
    final paidAtStr =
        paidAt != null ? '${paidAt.toLocal()}'.split(' ')[0] : 'N/A';

    final invoiceId = payment['invoiceId'] ?? 'Unknown';

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show Invoice ID in card
                  Text(
                    "Invoice ID: $invoiceId",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 12),

                  _iconTextRow(
                      Icons.attach_money, "Amount", '\$${payment['amount']}'),
                  SizedBox(height: 8),
                  _iconTextRow(Icons.credit_card, "Method", payment['method']),
                  SizedBox(height: 8),
                  _iconTextRow(Icons.calendar_today, "Paid At", paidAtStr),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final paymentId = payment['paymentId'];
                if (paymentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Payment ID not available.")),
                  );
                  return;
                }

                try {
                  await paymentGenerator.exportReceiptAsPdf(context, paymentId);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to export PDF: $e")),
                  );
                }
              },
              icon: Icon(Icons.download, color: Colors.white),
              label: Text(
                'PDF',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconTextRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: iconColor),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodFilterButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _methodFilters.map((filter) {
        final isSelected = _selectedMethodFilter == filter;
        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedMethodFilter = filter;
              _animationController?.reset();
              _animationController?.forward();
            });
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: isSelected ? Colors.white : Colors.black,
            backgroundColor:
                isSelected ? Colors.orange : Colors.orange.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: isSelected ? 4 : 0,
          ),
          child: Text(
            filter[0].toUpperCase() + filter.substring(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedPaymentCard(Map<String, dynamic> payment, int index) {
    return FadeTransition(
      opacity: _fadeAnimation!,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_fadeAnimation!),
        child: _buildPaymentCard(payment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 6,
        backgroundColor: Color(0xFF004D40),
        title: const Text('Log Payment'),
        titleTextStyle: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00796B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: TextField(
                  controller: _invoiceController,
                  decoration: InputDecoration(
                    labelText: "Enter Invoice ID",
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.orange),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          BorderSide(color: Colors.orange.shade200, width: 1),
                    ),
                  ),
                  cursorColor: Colors.orange,
                  style: TextStyle(color: Colors.black),
                  onChanged: _onInvoiceIdChanged,
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildMethodFilterButtons(),
            const SizedBox(height: 20),
            Expanded(
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.orange))
                  : filteredPayments.isEmpty
                      ? Center(child: Text('No payment history found'))
                      : FadeTransition(
                          opacity: _fadeAnimation!,
                          child: ListView.builder(
                            itemCount: filteredPayments.length,
                            itemBuilder: (_, index) =>
                                _buildAnimatedPaymentCard(
                                    filteredPayments[index], index),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
