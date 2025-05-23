import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allInvoices = [];
  List<Map<String, dynamic>> _filteredInvoices = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';

  Future<void> fetchAllInvoices(String clientId) async {
    _isLoading = true;
    _allInvoices = [];
    _filteredInvoices = [];

    try {
      final clientDoc =
          await _firestore.collection('clients').doc(clientId).get();
      if (!clientDoc.exists) {
        _resetInvoices();
        return;
      }

      final clientData = clientDoc.data();
      final clientName = clientData?['name'] ?? 'Unknown Client';

      final invoicesSnap = await _firestore
          .collection('invoices')
          .where('clientId', isEqualTo: clientId)
          .get();

      if (invoicesSnap.docs.isEmpty) {
        _resetInvoices();
        return;
      }

      for (final invoiceDoc in invoicesSnap.docs) {
        final invoiceId = invoiceDoc.id;
        final data = invoiceDoc.data();

        final amount = (data['amount'] ?? 0).toDouble();
        final dueDate = data['dueDate'] as Timestamp?;
        final createdAt = data['createdAt'] as Timestamp?;
        final updatedAt = data['updatedAt'] as Timestamp?;
        final totalPaid = (data['totalPaid'] ?? 0).toDouble();

        final status = data['status'] ?? 'unpaid';

        final remaining = (amount - totalPaid).clamp(0, amount);

        _allInvoices.add({
          'invoiceId': invoiceId,
          'clientName': clientName,
          'amount': amount,
          'status': status,
          'dueDate': dueDate,
          'createdAt': createdAt,
          'updatedAt': updatedAt,
          'remaining': remaining,
        });
      }

      applyFilterLocally(_selectedStatus, filterInvoiceId: null);
    } catch (e) {
      print('Error fetching all invoices: $e');
      _resetInvoices();
    } finally {
      _isLoading = false;
    }
  }

  void applyFilterLocally(String status, {String? filterInvoiceId}) {
    _selectedStatus = status.toLowerCase();

    _filteredInvoices = _allInvoices.where((invoice) {
      final matchesStatus =
          (_selectedStatus == 'all' || invoice['status'] == _selectedStatus);
      final matchesInvoiceId = (filterInvoiceId == null ||
          filterInvoiceId.isEmpty ||
          invoice['invoiceId'] == filterInvoiceId);

      return matchesStatus && matchesInvoiceId;
    }).toList();
  }

  void _resetInvoices() {
    _allInvoices = [];
    _filteredInvoices = [];
    _isLoading = false;
  }

  List<Map<String, dynamic>> get filteredInvoices => _filteredInvoices;
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
}
