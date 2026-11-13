import 'package:flutter/material.dart';

void main() {
  runApp(const TallyPrimeMobileApp());
}

class TallyPrimeMobileApp extends StatelessWidget {
  const TallyPrimeMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TallyPrime Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A4D80), // Tally Blue Theme
        scaffoldBackgroundColor: const Color(0xFFF2F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A4D80),
          foregroundColor: Colors.white,
        ),
      ),
      home: const GatewayOfTallyScreen(),
    );
  }
}

// ડેટા સ્ટોર કરવા માટેના મોડલ્સ
class Ledger {
  String name;
  String group;
  double balance;
  Ledger({required this.name, required this.group, this.balance = 0.0});
}

class Voucher {
  String voucherNo;
  String type; // Sales, Purchase, Receipt, Payment
  String partyName;
  double amount;
  double gstPercent;
  double totalAmount;
  DateTime date;

  Voucher({
    required this.voucherNo,
    required this.type,
    required this.partyName,
    required this.amount,
    required this.gstPercent,
    required this.totalAmount,
    required this.date,
  });
}

class GatewayOfTallyScreen extends StatefulWidget {
  const GatewayOfTallyScreen({super.key});

  @override
  State<GatewayOfTallyScreen> createState() => _GatewayOfTallyScreenState();
}

class _GatewayOfTallyScreenState extends State<GatewayOfTallyScreen> {
  // શરૂઆતના ખાતા (Default Ledgers)
  List<Ledger> ledgers = [
    Ledger(name: 'Cash', group: 'Cash-in-Hand', balance: 25000),
    Ledger(name: 'State Bank of India', group: 'Bank Accounts', balance: 150000),
    Ledger(name: 'Ramesh Traders', group: 'Sundry Debtors', balance: 0),
    Ledger(name: 'Mahesh Enterprise', group: 'Sundry Creditors', balance: 0),
  ];

  List<Voucher> vouchers = [];

  double get totalSales => vouchers
      .where((v) => v.type == 'Sales')
      .fold(0, (sum, item) => sum + item.totalAmount);

  double get totalPurchase => vouchers
      .where((v) => v.type == 'Purchase')
      .fold(0, (sum, item) => sum + item.totalAmount);

  // નવું ખાતું (Ledger) બનાવવાનું ફોર્મ
  void _showCreateLedgerDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedGroup = 'Sundry Debtors';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ledger Creation (ખાતું બનાવો)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Party / Ledger Name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedGroup,
              decoration: const InputDecoration(labelText: 'Under Group'),
              items: [
                'Sundry Debtors',
                'Sundry Creditors',
                'Bank Accounts',
                'Cash-in-Hand',
                'Sales Accounts',
                'Purchase Accounts',
                'Direct Expenses',
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => selectedGroup = val!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Opening Balance (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  ledgers.add(Ledger(
                    name: nameController.text,
                    group: selectedGroup,
                    balance: double.tryParse(balanceController.text) ?? 0.0,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save (Accept)'),
          ),
        ],
      ),
    );
  }

  // નવી વાઉચર એન્ટ્રી (Sales / Purchase / Receipt / Payment)
  void _showVoucherEntryDialog() {
    String voucherType = 'Sales';
    String selectedParty = ledgers.first.name;
    final amountController = TextEditingController();
    double gstRate = 18.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double baseAmt = double.tryParse(amountController.text) ?? 0;
          double gstAmt = (voucherType == 'Sales' || voucherType == 'Purchase')
              ? (baseAmt * gstRate / 100)
              : 0;
          double totalAmt = baseAmt + gstAmt;

          return AlertDialog(
            title: const Text('Accounting Voucher Creation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: voucherType,
                    decoration: const InputDecoration(labelText: 'Voucher Type'),
                    items: ['Sales', 'Purchase', 'Receipt', 'Payment']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => voucherType = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedParty,
                    decoration: const InputDecoration(labelText: 'Party A/c Name'),
                    items: ledgers
                        .map((l) => DropdownMenuItem(value: l.name, child: Text(l.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedParty = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (voucherType == 'Sales' || voucherType == 'Purchase') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<double>(
                      value: gstRate,
                      decoration: const InputDecoration(labelText: 'GST %'),
                      items: [0.0, 5.0, 12.0, 18.0, 28.0]
                          .map((r) => DropdownMenuItem(value: r, child: Text('$r%')))
                          .toList(),
                      onChanged: (val) => setDialogState(() => gstRate = val!),
                    ),
                  ],
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.blue.shade50,
                    child: Column(
                      children: [
                        Text('GST Amount: ₹${gstAmt.toStringAsFixed(2)}'),
                        Text(
                          'Total Bill: ₹${totalAmt.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (baseAmt > 0) {
                    setState(() {
                      vouchers.add(Voucher(
                        voucherNo: 'VCH-${vouchers.length + 1}',
                        type: voucherType,
                        partyName: selectedParty,
                        amount: baseAmt,
                        gstPercent: gstRate,
                        totalAmount: totalAmt,
                        date: DateTime.now(),
                      ));

                      // પાર્ટીનું બેલેન્સ અપડેટ કરો
                      final ledger = ledgers.firstWhere((l) => l.name == selectedParty);
                      if (voucherType == 'Sales' || voucherType == 'Payment') {
                        ledger.balance += totalAmt;
                      } else {
                        ledger.balance -= totalAmt;
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Voucher'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gateway of Tally'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ટોપ સમરી કાર્ડ્સ
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Total Sales', style: TextStyle(color: Colors.white70)),
                          Text('₹${totalSales.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Total Purchase', style: TextStyle(color: Colors.white70)),
                          Text('₹${totalPurchase.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Tally Menu Buttons
            const Text('MASTERS & TRANSACTIONS',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreateLedgerDialog,
                    icon: const Icon(Icons.account_balance),
                    label: const Text('Create Ledger'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showVoucherEntryDialog,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Vouchers (F8/F9)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Ledgers & Day Book Tabs
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Color(0xFF1A4D80),
                      tabs: [
                        Tab(text: 'Day Book (રોજમેળ)'),
                        Tab(text: 'Ledgers (ખાતાવહી)'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Day Book
                          vouchers.isEmpty
                              ? const Center(child: Text('હજુ સુધી કોઈ વાઉચર એન્ટ્રી નથી.'))
                              : ListView.builder(
                                  itemCount: vouchers.length,
                                  itemBuilder: (ctx, i) {
                                    final v = vouchers[i];
                                    return Card(
                                      child: ListTile(
                                        title: Text('${v.partyName} (${v.type})'),
                                        subtitle: Text('${v.voucherNo} | GST: ${v.gstPercent}%'),
                                        trailing: Text(
                                          '₹${v.totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                          // Tab 2: Ledgers List
                          ListView.builder(
                            itemCount: ledgers.length,
                            itemBuilder: (ctx, i) {
                              final l = ledgers[i];
                              return Card(
                                child: ListTile(
                                  title: Text(l.name),
                                  subtitle: Text(l.group),
                                  trailing: Text(
                                    '₹${l.balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: l.balance >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
