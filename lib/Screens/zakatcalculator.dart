import 'package:flutter/material.dart';
import 'package:muslim_daily/Screens/home.dart';

class ZakatCalculator extends StatelessWidget {
  const ZakatCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zakat Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.green[800]!,
          secondary: Colors.green[400]!,
        ),
        useMaterial3: true,
      ),
      home: const ZakatCalculatorScreen(),
    );
  }
}

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController goldCtrl = TextEditingController();
  final TextEditingController silverCtrl = TextEditingController();
  final TextEditingController businessCtrl = TextEditingController();
  final TextEditingController investmentsCtrl = TextEditingController();
  final TextEditingController receivablesCtrl = TextEditingController();
  final TextEditingController liabilitiesCtrl = TextEditingController();
  final TextEditingController nisabCtrl = TextEditingController();

  double zakatAmount = 0.0;
  double netWealth = 0.0;
  double nisabValue = 160000.0; // default nisab
  String zakatMessage = "";
  bool calculated = false;

  void calculateZakat() {
    double cash = double.tryParse(cashCtrl.text.trim()) ?? 0.0;
    double gold = double.tryParse(goldCtrl.text.trim()) ?? 0.0;
    double silver = double.tryParse(silverCtrl.text.trim()) ?? 0.0;
    double business = double.tryParse(businessCtrl.text.trim()) ?? 0.0;
    double investments = double.tryParse(investmentsCtrl.text.trim()) ?? 0.0;
    double receivables = double.tryParse(receivablesCtrl.text.trim()) ?? 0.0;
    double liabilities = double.tryParse(liabilitiesCtrl.text.trim()) ?? 0.0;
    double nisab = double.tryParse(nisabCtrl.text.trim()) ?? 160000.0;

    setState(() {
      netWealth = cash + gold + silver + business + investments + receivables - liabilities;
      nisabValue = nisab;
      calculated = true;

      if (netWealth <= 0) {
        zakatAmount = 0.0;
        if (netWealth < 0) {
          zakatMessage =
          "Your liabilities exceed your assets. Zakat is not obligatory.";
        } else {
          zakatMessage =
          "Your net wealth is zero. Zakat is not due.";
        }
      } else if (netWealth < nisabValue) {
        zakatAmount = 0.0;
        zakatMessage =
        "Your net wealth is below the Nisab (${nisabValue.toStringAsFixed(2)} PKR). Zakat is not obligatory.";
      } else {
        zakatAmount = netWealth * 0.025;
        zakatMessage = "Zakat is obligatory and calculated below.";
      }
    });
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? hint,
    Color? color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: color ?? Colors.green[800]) : null,
        filled: true,
        fillColor: Colors.green[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text(
          "Zakat Calculator",
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 2,
        toolbarHeight: 44,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage())),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Assets",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Cash (PKR)",
                        controller: cashCtrl,
                        icon: Icons.money,
                        hint: "e.g. 50000"),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Gold Value (PKR)",
                        controller: goldCtrl,
                        icon: Icons.circle_outlined,
                        hint: "e.g. 120000"),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Silver Value (PKR)",
                        controller: silverCtrl,
                        icon: Icons.circle,
                        hint: "e.g. 15000"),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Business Assets (PKR)",
                        controller: businessCtrl,
                        icon: Icons.business_center,
                        hint: "e.g. 200000"),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Investments (PKR)",
                        controller: investmentsCtrl,
                        icon: Icons.trending_up,
                        hint: "e.g. 100000"),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Receivables (PKR)",
                        controller: receivablesCtrl,
                        icon: Icons.payments,
                        hint: "e.g. 30000"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Liabilities & Nisab",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Liabilities (PKR)",
                        controller: liabilitiesCtrl,
                        icon: Icons.remove_circle,
                        hint: "e.g. 50000",
                        color: Colors.red),
                    const SizedBox(height: 10),
                    buildTextField(
                        label: "Nisab Value (Default 160,000 PKR)",
                        controller: nisabCtrl,
                        icon: Icons.stars,
                        hint: "e.g. 160000"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: calculateZakat,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 53),
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calculate,color: Colors.white),
              label: const Text(
                "Calculate Zakat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            if (calculated)
              Card(
                elevation: 5,
                color: zakatAmount > 0 ? Colors.green[50] : Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        zakatMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: zakatAmount > 0 ? Colors.green[900] : Colors.red[800],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Net Wealth: PKR ${netWealth.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Nisab Used: PKR ${nisabValue.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      zakatAmount > 0
                          ? Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 35),
                          const SizedBox(height: 6),
                          Text(
                            "Zakat Due: PKR ${zakatAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            "No Zakat is obligatory at this time.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[800],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
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