import 'package:flutter/material.dart';
import 'payment_generator.dart';
import 'payment_logging_service.dart';

class PaymentPage extends StatefulWidget {
  final String invoiceId;

  const PaymentPage({super.key, required this.invoiceId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  final _invoiceIdController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedMethod = 'cash';

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _invoiceIdController.text = widget.invoiceId;
  }

  @override
  void dispose() {
    _controller.dispose();
    _invoiceIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAnimatedDialog(String title, String message, Color color) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: color.withOpacity(0.95),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(scale: anim, child: child);
      },
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Payment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedMethod == 'credit') ...[
                _buildDialogField('Card Number', Icons.credit_card),
                _buildDialogField(
                    'Expiration Date (MM/YY)', Icons.calendar_today),
                _buildDialogField('CVV', Icons.lock),
              ] else if (_selectedMethod == 'bank transfer') ...[
                _buildDialogField('Account Number', Icons.account_balance),
                _buildDialogField(
                    'Routing Number', Icons.account_balance_wallet),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final invoiceId = _invoiceIdController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (invoiceId.isEmpty || amount == null || amount <= 0) {
      _showAnimatedDialog(
          'Invalid Input', 'Please enter valid data', Colors.red);
      return;
    }

    try {
      final generator = PaymentGenerator();
      final paymentId = await generator.generateReceipt(
        invoiceId: invoiceId,
        amount: amount,
        method: _selectedMethod,
      );
      final logger = PaymentLoggingService();
      await logger.logPayment(
        invoiceId: invoiceId,
        paymentAmount: amount,
        paymentMethod: _selectedMethod,
      );

      final paymentSnapshot = await generator.getPaymentById(paymentId);
      final paymentData = paymentSnapshot.data();

      if (paymentData != null) {
        final paidAt = paymentData['paidAt'].toDate();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Receipt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice ID: $invoiceId'),
                Text('Amount: \$${amount.toStringAsFixed(2)}'),
                Text('Method: $_selectedMethod'),
                Text('Paid At: ${paidAt.toLocal()}'),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await generator.exportReceiptAsPdf(context, paymentId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Import as PDF',
                      style: TextStyle(
                          color: Color.fromARGB(255, 251, 130, 1),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      _invoiceIdController.clear();
      _amountController.clear();
    } catch (e, stacktrace) {
      print("Error: $e");
      print("Stacktrace: $stacktrace");
      _showAnimatedDialog(
        'INVALID INVOICE_ID',
        'All Invoices_Id in invoice status page. Go to it from nav bar at bottom of page.',
        Colors.red,
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  BoxDecoration _shadowDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildRoundedImage() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/trustPay.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 6,
          backgroundColor: Colors.green[900],
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
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white),
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRoundedImage(),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: _shadowDecoration(),
                    child: TextField(
                      controller: _invoiceIdController,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('Invoice ID'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: _shadowDecoration(),
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('Amount'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: _shadowDecoration(),
                    child: DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('Payment Method'),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Row(children: [
                            Icon(Icons.money),
                            SizedBox(width: 8),
                            Text('Cash')
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'credit',
                          child: Row(children: [
                            Icon(Icons.credit_card),
                            SizedBox(width: 8),
                            Text('Credit')
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'bank transfer',
                          child: Row(children: [
                            Icon(Icons.account_balance),
                            SizedBox(width: 8),
                            Text('Bank Transfer')
                          ]),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                          if (_selectedMethod == 'credit' ||
                              _selectedMethod == 'bank transfer') {
                            _showPaymentDialog();
                          }
                        });
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[900],
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Submit Payment',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
