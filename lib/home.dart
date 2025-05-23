import 'package:cost_management/paymet_history.dart';
import 'package:flutter/material.dart';
import 'payment_page.dart';
import 'InvoiceStatusPage.dart';
import 'package:cost_management/reportPage.dart';

class HomeNavigation extends StatefulWidget {
  static final GlobalKey<_HomeNavigationState> homeNavKey =
      GlobalKey<_HomeNavigationState>();
  HomeNavigation({Key? key}) : super(key: homeNavKey);

  @override
  _HomeNavigationState createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 1;
  String _currentInvoiceId = '';

  void switchToPaymentTab(String invoiceId) {
    setState(() {
      _currentIndex = 0;
      _currentInvoiceId = invoiceId;
    });
  }

  List<Widget> get _pages => [
        PaymentPage(invoiceId: _currentInvoiceId),
        InvoiceStatusScreen(),
        PaymentHistoryLog(),
        InvoiceSummaryPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF004D39)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.orange, // Active tab color
          unselectedItemColor: Colors.white70, // Inactive tab color
          backgroundColor: Colors.transparent, // Allows gradient to show
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Invoice Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Payment History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Report',
            ),
          ],
        ),
      ),
    );
  }
}
