import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDmskTQzdtZyr539OBRe7x6-sAHheB3Gq4",
        authDomain: "taxease-ac6ca.firebaseapp.com",
        projectId: "taxease-ac6ca",
        storageBucket: "taxease-ac6ca.firebasestorage.app",
        messagingSenderId: "398490907644",
        appId: "1:398490907644:web:fdc6267be4ff9742a7b879",
        measurementId: "G-NX3WN0T9KB"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaxEase - Tax Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF4CAF50),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        drawerTheme: const DrawerThemeData(
          elevation: 2,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
          displayMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E88E5),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF333333),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF666666),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E88E5)),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF4CAF50),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return const TaxCalculatorPage(); // User is logged in
          }
          
          return const LoginPage(); // User is not logged in
        },
      ),
    );
  }
}

class TaxCalculatorPage extends StatefulWidget {
  const TaxCalculatorPage({super.key});

  @override
  State<TaxCalculatorPage> createState() => _TaxCalculatorPageState();
}

class _TaxCalculatorPageState extends State<TaxCalculatorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _hraController = TextEditingController();
  final TextEditingController _section80cController = TextEditingController();
  final TextEditingController _section80dController = TextEditingController();
  final TextEditingController _section80eController = TextEditingController();
  final TextEditingController _section80gController = TextEditingController();
  final TextEditingController _ltaController = TextEditingController();
  final TextEditingController _standardDeductionController = TextEditingController();
  
  double _taxAmount = 0.0;
  double _effectiveTaxRate = 0.0;
  double _totalDeductions = 0.0;
  double _taxableIncome = 0.0;
  bool _isNewRegime = true;
  String _selectedYear = '2024-25';
  double _surcharge = 0.0;
  double _healthAndEducationCess = 0.0;
  double _totalTaxLiability = 0.0;
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomeController.dispose();
    _hraController.dispose();
    _section80cController.dispose();
    _section80dController.dispose();
    _section80eController.dispose();
    _section80gController.dispose();
    _ltaController.dispose();
    _standardDeductionController.dispose();
    super.dispose();
  }

  void _calculateTax() {
    if (_incomeController.text.isEmpty) return;
    
    double income = double.parse(_incomeController.text);
    double hra = _hraController.text.isEmpty ? 0 : double.parse(_hraController.text);
    double section80c = _section80cController.text.isEmpty ? 0 : double.parse(_section80cController.text);
    double section80d = _section80dController.text.isEmpty ? 0 : double.parse(_section80dController.text);
    double section80e = _section80eController.text.isEmpty ? 0 : double.parse(_section80eController.text);
    double section80g = _section80gController.text.isEmpty ? 0 : double.parse(_section80gController.text);
    double lta = _ltaController.text.isEmpty ? 0 : double.parse(_ltaController.text);
    double standardDeduction = _standardDeductionController.text.isEmpty ? 0 : double.parse(_standardDeductionController.text);

    _totalDeductions = hra + section80c + section80d + section80e + section80g + lta + standardDeduction;
    _taxableIncome = income - _totalDeductions;
    
    double tax = 0.0;

    if (_isNewRegime) {
      // New tax regime rates
      if (_taxableIncome <= 300000) {
        tax = 0;
      } else if (_taxableIncome <= 600000) {
        tax = (_taxableIncome - 300000) * 0.05;
      } else if (_taxableIncome <= 900000) {
        tax = 15000 + (_taxableIncome - 600000) * 0.10;
      } else if (_taxableIncome <= 1200000) {
        tax = 45000 + (_taxableIncome - 900000) * 0.15;
      } else if (_taxableIncome <= 1500000) {
        tax = 90000 + (_taxableIncome - 1200000) * 0.20;
      } else {
        tax = 150000 + (_taxableIncome - 1500000) * 0.30;
      }
    } else {
      // Old tax regime rates
      if (_taxableIncome <= 250000) {
        tax = 0;
      } else if (_taxableIncome <= 500000) {
        tax = (_taxableIncome - 250000) * 0.05;
      } else if (_taxableIncome <= 1000000) {
        tax = 12500 + (_taxableIncome - 500000) * 0.20;
      } else {
        tax = 112500 + (_taxableIncome - 1000000) * 0.30;
      }
    }

    // Calculate surcharge
    if (_taxableIncome > 5000000 && _taxableIncome <= 10000000) {
      _surcharge = tax * 0.10;
    } else if (_taxableIncome > 10000000 && _taxableIncome <= 20000000) {
      _surcharge = tax * 0.15;
    } else if (_taxableIncome > 20000000 && _taxableIncome <= 50000000) {
      _surcharge = tax * 0.25;
    } else if (_taxableIncome > 50000000) {
      _surcharge = tax * 0.37;
    }

    // Calculate health and education cess
    _healthAndEducationCess = (tax + _surcharge) * 0.04;

    setState(() {
      _taxAmount = tax;
      _effectiveTaxRate = (tax / income) * 100;
      _totalTaxLiability = tax + _surcharge + _healthAndEducationCess;
    });
  }

  // Add this method to generate PDF
  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final formatter = NumberFormat("#,##,###");

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Tax Calculation Summary',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Basic Information
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Assessment Year: $_selectedYear',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Tax Regime: ${_isNewRegime ? "New" : "Old"}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Generated on: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Income Details
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Income Details',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildPDFRow('Total Income', formatter.format(double.parse(_incomeController.text.isEmpty ? '0' : _incomeController.text))),
                ],
              ),
            ),
            
            // Deductions
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Deductions',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildPDFRow('HRA', formatter.format(double.parse(_hraController.text.isEmpty ? '0' : _hraController.text))),
                  _buildPDFRow('Section 80C', formatter.format(double.parse(_section80cController.text.isEmpty ? '0' : _section80cController.text))),
                  _buildPDFRow('Section 80D', formatter.format(double.parse(_section80dController.text.isEmpty ? '0' : _section80dController.text))),
                  _buildPDFRow('Section 80E', formatter.format(double.parse(_section80eController.text.isEmpty ? '0' : _section80eController.text))),
                  _buildPDFRow('Section 80G', formatter.format(double.parse(_section80gController.text.isEmpty ? '0' : _section80gController.text))),
                  _buildPDFRow('LTA', formatter.format(double.parse(_ltaController.text.isEmpty ? '0' : _ltaController.text))),
                  _buildPDFRow('Standard Deduction', formatter.format(double.parse(_standardDeductionController.text.isEmpty ? '0' : _standardDeductionController.text))),
                  pw.Divider(color: PdfColors.grey),
                  _buildPDFRow('Total Deductions', formatter.format(_totalDeductions), isBold: true),
                ],
              ),
            ),

            // Tax Calculation
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tax Calculation',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildPDFRow('Taxable Income', formatter.format(_taxableIncome)),
                  _buildPDFRow('Income Tax', formatter.format(_taxAmount)),
                  _buildPDFRow('Surcharge', formatter.format(_surcharge)),
                  _buildPDFRow('Health & Education Cess', formatter.format(_healthAndEducationCess)),
                  pw.Divider(color: PdfColors.grey),
                  _buildPDFRow('Total Tax Liability', formatter.format(_totalTaxLiability), isBold: true),
                  _buildPDFRow('Effective Tax Rate', '${_effectiveTaxRate.toStringAsFixed(2)}%', isBold: true),
                ],
              ),
            ),

            // Disclaimer
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Text(
                'Disclaimer: This is a computer-generated document and serves as an estimate only. Please consult with a tax professional for final tax calculations.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    // Handle web platform
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    } 
    // Handle mobile/desktop platforms
    else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tax_calculation_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }
  }

  pw.Widget _buildPDFRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Rs. $value',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation will be handled automatically by the StreamBuilder in MyApp
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF4CAF50),
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF4CAF50),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calculate_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                'TaxEase Calculator',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: 'Toggle theme',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                // TODO: Show help dialog
              },
              tooltip: 'Help',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'signOut') {
                  _signOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 8),
                      Text(FirebaseAuth.instance.currentUser?.email ?? 'Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'signOut',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.calculate),
                text: 'Calculator',
              ),
              Tab(
                icon: Icon(Icons.receipt_long),
                text: 'Deductions',
              ),
              Tab(
                icon: Icon(Icons.summarize),
                text: 'Summary',
              ),
            ],
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        drawer: NavigationDrawer(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              _tabController.animateTo(index);
            });
            Navigator.pop(context);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                'TaxEase',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Divider(),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.calculate),
              label: const Text('Tax Calculator'),
              selectedIcon: Icon(
                Icons.calculate,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Deductions'),
              selectedIcon: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.summarize),
              label: const Text('Summary'),
              selectedIcon: Icon(
                Icons.summarize,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Text(
                'Tools',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.history),
              label: const Text('Calculation History'),
              selectedIcon: Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Regime Comparison'),
              selectedIcon: Icon(
                Icons.compare_arrows,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.tips_and_updates),
              label: const Text('Tax Saving Tips'),
              selectedIcon: Icon(
                Icons.tips_and_updates,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Text(
                'Support',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.help_outline),
              label: const Text('Help & FAQ'),
              selectedIcon: Icon(
                Icons.help,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.info_outline),
              label: const Text('About'),
              selectedIcon: Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCalculatorTab(),
            _buildDeductionsTab(),
            _buildSummaryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _generatePDF,
          icon: const Icon(Icons.save),
          label: const Text('Save as PDF'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement save draft
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Draft'),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement share
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement compare
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tax Calculator ${_selectedYear}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Calculate your income tax liability and plan your taxes efficiently',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tax Year and Regime Selection
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Assessment Year',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '2024-25', child: Text('2024-25')),
                    DropdownMenuItem(value: '2023-24', child: Text('2023-24')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Regime',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('New Regime'),
                              selected: _isNewRegime,
                              selectedColor: Theme.of(context).colorScheme.primary,
                              onSelected: (selected) {
                                setState(() {
                                  _isNewRegime = selected;
                                });
                                _calculateTax();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Old Regime'),
                              selected: !_isNewRegime,
                              selectedColor: Theme.of(context).colorScheme.primary,
                              onSelected: (selected) {
                                setState(() {
                                  _isNewRegime = !selected;
                                });
                                _calculateTax();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Income Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Details',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Annual Income (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    onChanged: (_) => _calculateTax(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deductions',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showDeductionsInfo(context),
                        tooltip: 'Learn about deductions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDeductionField(
                    controller: _hraController,
                    label: 'HRA (House Rent Allowance)',
                    icon: Icons.home,
                    info: 'Tax benefit for those paying rent. Maximum deduction depends on your basic salary, actual rent paid, and city of residence.',
                  ),
                  const SizedBox(height: 8),
                  _buildDeductionField(
                    controller: _section80cController,
                    label: 'Section 80C',
                    icon: Icons.savings,
                    info: 'Investments in PPF, ELSS, life insurance, EPF, etc. Maximum deduction of ₹1.5 lakhs per year.',
                  ),
                  const SizedBox(height: 8),
                  _buildDeductionField(
                    controller: _section80dController,
                    label: 'Section 80D (Health Insurance)',
                    icon: Icons.medical_services,
                    info: 'Health insurance premiums for self, family & parents. Maximum ₹25,000 for self/family and additional ₹25,000 for parents.',
                  ),
                  const SizedBox(height: 8),
                  _buildDeductionField(
                    controller: _section80eController,
                    label: 'Section 80E (Education Loan)',
                    icon: Icons.school,
                    info: 'Interest paid on education loan. No maximum limit. Principal repayment not covered.',
                  ),
                  const SizedBox(height: 8),
                  _buildDeductionField(
                    controller: _section80gController,
                    label: 'Section 80G (Donations)',
                    icon: Icons.favorite,
                    info: 'Donations to approved charitable institutions. Deduction varies from 50% to 100% depending on the institution.',
                  ),
                  const SizedBox(height: 8),
                  _buildDeductionField(
                    controller: _ltaController,
                    label: 'LTA (Leave Travel Allowance)',
                    icon: Icons.flight,
                    info: 'Tax benefit for travel within India. Available for 2 journeys in a block of 4 years.',
                  ),
                  const SizedBox(height: 8),
                  _buildDeductionField(
                    controller: _standardDeductionController,
                    label: 'Standard Deduction',
                    icon: Icons.receipt,
                    info: 'Flat deduction of ₹50,000 available to all salaried employees without any conditions.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String info,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                ),
                onChanged: (_) => _calculateTax(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => _showDeductionInfo(context, label, info),
              tooltip: 'Learn more about $label',
            ),
          ],
        ),
      ],
    );
  }

  void _showDeductionInfo(BuildContext context, String title, String info) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showDeductionsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Tax Deductions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tax deductions reduce your taxable income, which in turn reduces your tax liability. Here\'s a quick overview:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoPoint('HRA', 'For those paying house rent'),
                _buildInfoPoint('Section 80C', 'Investments & insurance premiums'),
                _buildInfoPoint('Section 80D', 'Health insurance premiums'),
                _buildInfoPoint('Section 80E', 'Education loan interest'),
                _buildInfoPoint('Section 80G', 'Charitable donations'),
                _buildInfoPoint('LTA', 'Travel allowance benefits'),
                _buildInfoPoint('Standard Deduction', 'Fixed amount for salaried persons'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Summary',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total Income', '₹${_incomeController.text.isEmpty ? '0' : _incomeController.text}'),
                  _buildSummaryRow('Total Deductions', '₹${_totalDeductions.toStringAsFixed(2)}'),
                  _buildSummaryRow('Taxable Income', '₹${_taxableIncome.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildSummaryRow('Income Tax', '₹${_taxAmount.toStringAsFixed(2)}'),
                  _buildSummaryRow('Surcharge', '₹${_surcharge.toStringAsFixed(2)}'),
                  _buildSummaryRow('Health & Education Cess', '₹${_healthAndEducationCess.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total Tax Liability',
                    '₹${_totalTaxLiability.toStringAsFixed(2)}',
                    isHighlighted: true,
                  ),
                  _buildSummaryRow(
                    'Effective Tax Rate',
                    '${_effectiveTaxRate.toStringAsFixed(2)}%',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Saving Tips',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    Icons.savings,
                    'Maximize Section 80C',
                    'Invest in PPF, ELSS, or life insurance to maximize your 80C deductions.',
                  ),
                  _buildTipItem(
                    Icons.medical_services,
                    'Health Insurance',
                    'Consider health insurance under Section 80D for additional deductions.',
                  ),
                  _buildTipItem(
                    Icons.home,
                    'HRA Benefits',
                    'If you\'re paying rent, ensure you claim HRA benefits properly.',
                  ),
                  _buildTipItem(
                    Icons.school,
                    'Education Loan',
                    'Interest paid on education loans is eligible for deduction under Section 80E.',
                  ),
                  _buildTipItem(
                    Icons.favorite,
                    'Charitable Donations',
                    'Donations to approved charitable institutions are eligible for deduction under Section 80G.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
