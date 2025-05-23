import 'package:cost_management/paymet_history.dart';
import 'package:flutter/material.dart';
import 'report.dart'; // Your report SDK and model
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceSummaryPage extends StatefulWidget {
  const InvoiceSummaryPage({Key? key}) : super(key: key);

  @override
  State<InvoiceSummaryPage> createState() => _InvoiceSummaryPageState();
}

class _InvoiceSummaryPageState extends State<InvoiceSummaryPage> {
  final InvoiceSummarySDK sdk = InvoiceSummarySDK();

  DateTime? startDate;
  DateTime? endDate;
  String? status;

  String get clientId => FirebaseAuth.instance.currentUser?.uid ?? '';

  late Future<InvoiceSummaryReport> _reportFuture;

  final _statusOptions = ['all', 'paid', 'unpaid', 'overdue'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = sdk.generateReport(
        startDate: startDate,
        endDate: endDate,
        status: (status == 'all') ? null : status,
        clientId: clientId,
      );
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
      _loadReport(); // Auto-refresh after picking start date
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
      _loadReport(); // Auto-refresh after picking end date
    }
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 249, 247, 247),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFilters() {
    if (status == 'history') {
      // Show only the status dropdown and the history log
      return Column(
        children: [
          _buildAnimatedCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(
                      color: Color(0xFFFF9800), fontWeight: FontWeight.bold),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
                value: status ?? 'all',
                items: _statusOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 5, 5, 5))),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => status = val);
                  _loadReport();
                },
              ),
            ),
          ),
          const PaymentHistoryLog(),
        ],
      );
    }
    return _buildAnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            labelStyle: const TextStyle(
                                color: Color(0xFFFF9800),
                                fontWeight: FontWeight.bold),
                            hintText: startDate == null
                                ? 'Select'
                                : '${startDate!.toLocal()}'.split(' ')[0],
                            suffixIcon: const Icon(Icons.calendar_today),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEndDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            labelStyle: const TextStyle(
                                color: Color(0xFFFF9800),
                                fontWeight: FontWeight.bold),
                            hintText: endDate == null
                                ? 'Select'
                                : '${endDate!.toLocal()}'.split(' ')[0],
                            suffixIcon: const Icon(Icons.calendar_today),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFFF9800), width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        labelStyle: TextStyle(
                            color: Color(0xFFFF9800),
                            fontWeight: FontWeight.bold),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFFF9800), width: 2),
                        ),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      value: status ?? 'all',
                      items: _statusOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 5, 5, 5))),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => status = val);
                        _loadReport(); // Auto-refresh after changing status
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text('Generate Report'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(InvoiceSummaryReport report) {
    // Always show only these statuses, in this order
    final List<String> statusOrder = ['paid', 'unpaid', 'overdue'];
    final Map<String, InvoiceSummary> summaryByStatus = {
      for (var s in statusOrder)
        s: report.summaries.firstWhere(
          (summary) => summary.status == s,
          orElse: () => InvoiceSummary(
            status: s,
            count: 0,
            totalAmount: 0,
            totalPaid: 0,
            totalRemaining: 0,
          ),
        )
    };
    final maxTotal = summaryByStatus.values
        .map((s) => s.totalAmount)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);
    const double chartMaxHeight = 100;
    const double minBarHeight = 12;

    return _buildAnimatedCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Invoice Totals by Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: statusOrder.map((status) {
                final summary = summaryByStatus[status]!;
                double barHeight = 0;
                if (summary.totalAmount > 0) {
                  barHeight = (summary.totalAmount / maxTotal) * chartMaxHeight;
                  if (barHeight < minBarHeight) barHeight = minBarHeight;
                }
                String displayStatus =
                    status[0].toUpperCase() + status.substring(1);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('EGP${summary.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      width: 20,
                      height: barHeight,
                      color: const Color(0xFF004D40),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(displayStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(InvoiceSummaryReport report) {
    final List<String> statusOrder = ['paid', 'unpaid', 'overdue'];
    final Map<String, InvoiceSummary> summaryByStatus = {
      for (var s in statusOrder)
        s: report.summaries.firstWhere(
          (summary) => summary.status == s,
          orElse: () => InvoiceSummary(
            status: s,
            count: 0,
            totalAmount: 0,
            totalPaid: 0,
            totalRemaining: 0,
          ),
        )
    };
    return _buildAnimatedCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(
                label: Text('Status',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black))),
            DataColumn(
                label: Text('Count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ))),
            DataColumn(
                label: Text('Total Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ))),
            DataColumn(
                label: Text('Total Paid',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ))),
            DataColumn(
                label: Text('Remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ))),
          ],
          rows: statusOrder.map((status) {
            final summary = summaryByStatus[status]!;
            String displayStatus =
                status[0].toUpperCase() + status.substring(1);
            return DataRow(cells: [
              DataCell(Text(displayStatus)),
              DataCell(Text(summary.count.toString())),
              DataCell(Text('EGP${summary.totalAmount.toStringAsFixed(2)}')),
              DataCell(Text('EGP${summary.totalPaid.toStringAsFixed(2)}')),
              DataCell(Text('EGP${summary.totalRemaining.toStringAsFixed(2)}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownStatuses = ['all', 'paid', 'unpaid', 'overdue'];
    if (status != null &&
        status!.isNotEmpty &&
        !knownStatuses.contains(status!.toLowerCase())) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 6,
          backgroundColor: Colors.green[900],
          title: const Text('Report Summary'),
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
        body: const Center(
          child: Text('No report available for this selection.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 6,
        backgroundColor: Colors.green[900],
        title: const Text('Report Summary'),
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
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<InvoiceSummaryReport>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final report = snapshot.data;
                if (report == null || report.summaries.isEmpty) {
                  return const Center(child: Text('No invoices found.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildBarChart(report),
                    const SizedBox(height: 20),
                    _buildTable(report),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
