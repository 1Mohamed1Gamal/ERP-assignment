import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import "invoice_status.dart";
import 'payment_page.dart';
import 'home.dart';

class InvoiceStatusScreen extends StatefulWidget {
  const InvoiceStatusScreen({super.key});

  @override
  State<InvoiceStatusScreen> createState() => _InvoiceStatusScreenState();
}

class _InvoiceStatusScreenState extends State<InvoiceStatusScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _invoiceIdController = TextEditingController();
  final InvoiceStatusService _logic = InvoiceStatusService();
  String? _userId;

  String _selectedStatusFilter = 'all';
  String? _message;

  final List<String> _statusFilters = ['all', 'paid', 'unpaid', 'overdue'];

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _fetchAllInvoicesOnce();
    } else {
      setState(() {
        _message = "No logged-in user found.";
        _isLoading = false;
      });
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always refresh invoices when the page is shown again
    if (_userId != null) {
      _fetchAllInvoicesOnce();
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllInvoicesOnce() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _logic.fetchAllInvoices(_userId!);
      _logic.applyFilterLocally(_selectedStatusFilter, filterInvoiceId: null);
      _animationController.forward();
    } catch (e) {
      _message = 'Failed to load invoices: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersLocally() {
    final invoiceId = _invoiceIdController.text.trim();

    setState(() {
      _message = null;
      _logic.applyFilterLocally(_selectedStatusFilter,
          filterInvoiceId: invoiceId.isEmpty ? null : invoiceId);
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _onFilterSelected(String status) async {
    setState(() {
      _selectedStatusFilter = status;
      _message = null;
    });
    _applyFiltersLocally();
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat.yMMMMd().add_jm().format(date);
  }

  Widget _buildInvoiceCard(Map<String, dynamic> data, int index) {
    final status = data['status'] ?? 'unknown';

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: Card(
          color: (status == 'unpaid' ||
                  status == 'overdue' ||
                  status == 'Unpaid' ||
                  status == 'Overdue')
              ? Colors.orange.shade50
              : Colors.green.shade50,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt, color: Colors.black),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Invoice ID: ${data['invoiceId']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Client: ${data['clientName']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${status[0].toUpperCase()}${status.substring(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'paid' || status == 'Paid'
                            ? Colors.green[900]
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (status == 'paid' || status == 'Paid') ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Paid At: ${formatDate(data['updatedAt'])}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ] else if (status == 'overdue' || status == 'Overdue') ...[
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final dueDate = data['dueDate'] as Timestamp?;
                          if (dueDate == null) {
                            return const Text('Due date not available',
                                style: TextStyle(color: Colors.red));
                          }
                          final now = DateTime.now();
                          final daysOverdue =
                              now.difference(dueDate.toDate()).inDays.abs();
                          return Text('Overdue by $daysOverdue days',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.money_off_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Remaining: EGP ${data['remaining'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ] else if (status == 'unpaid' || status == 'Unpaid') ...[
                  Row(
                    children: [
                      const Icon(Icons.money_off_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Remaining: EGP ${data['remaining'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        child: _buildDueDaysText(data['dueDate']),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (status == 'unpaid' ||
                    status == 'overdue' ||
                    status == 'Unpaid' ||
                    status == 'Overdue')
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HomeNavigation.homeNavKey.currentState
                            ?.switchToPaymentTab(data['invoiceId']);
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Make Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueDaysText(Timestamp? dueDateTimestamp) {
    if (dueDateTimestamp == null) {
      return const Text('Due date not available');
    }
    final dueDate = dueDateTimestamp.toDate();
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return const Text('Overdue by', style: TextStyle(color: Colors.red));
    } else if (difference == 0) {
      return const Text('Due today', style: TextStyle(color: Colors.orange));
    } else {
      return Text('$difference days remaining',
          style: const TextStyle(color: Colors.green));
    }
  }

  Widget _buildFilterButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _statusFilters.map((filter) {
        final isSelected = _selectedStatusFilter == filter;
        return ElevatedButton(
          onPressed: () => _onFilterSelected(filter),
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

  @override
  Widget build(BuildContext context) {
    final invoices = _logic.filteredInvoices;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 6,
        backgroundColor: Colors.green[900],
        title: const Text('User Invoice Viewer'),
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
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _invoiceIdController,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Invoice ID',
                labelStyle:
                    const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.orange.shade700),
                ),
              ),
              // Called whenever user types
              onChanged: (value) {
                _applyFiltersLocally();
              },
              // You can keep onSubmitted if you want
              onSubmitted: (_) => _applyFiltersLocally(),
            ),
            const SizedBox(height: 12),
            _buildFilterButtons(),
            const SizedBox(height: 12),
            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : invoices.isEmpty
                      ? const Center(child: Text('No invoices found'))
                      : ListView.builder(
                          itemCount: invoices.length,
                          itemBuilder: (context, index) =>
                              _buildInvoiceCard(invoices[index], index),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
