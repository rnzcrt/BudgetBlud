import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import 'main_navigation_screen.dart'; // ← Change this import

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int step = 1;
  final _formKey = GlobalKey<FormState>();
  final budgetController = TextEditingController();

  void _nextStep() {
    if (step == 1) {
      setState(() {
        step = 2;
      });
    } else if (step == 2) {
      if (_formKey.currentState!.validate()) {
        double budget = double.parse(budgetController.text.replaceAll(",", ""));
        Provider.of<BudgetProvider>(context, listen: false).setBudget(budget);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ), // ← Change this line
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: step == 1
                    ? Column(
                        children: [
                          const Text(
                            "Welcome!\nLet's setup\nyour BudgetBlud",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1C1E),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Image.asset("images/set1.png", height: 200),
                        ],
                      )
                    : Column(
                        children: [
                          const Text(
                            "Monthly Budget\nSetup",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1C1E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "What's your monthly budget?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TextInputFormatter.withFunction((
                                  oldValue,
                                  newValue,
                                ) {
                                  if (newValue.text.isEmpty) {
                                    return newValue;
                                  }
                                  final value = newValue.text.replaceAll(
                                    ',',
                                    '',
                                  );
                                  final formatter = NumberFormat('#,###');
                                  final newText = formatter.format(
                                    int.parse(value),
                                  );
                                  return newValue.copyWith(
                                    text: newText,
                                    selection: TextSelection.collapsed(
                                      offset: newText.length,
                                    ),
                                  );
                                }),
                              ],
                              decoration: InputDecoration(
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 8),
                                  child: Text(
                                    "₱",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),
                                hintText: "24,500",
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your budget";
                                }
                                final parsed = double.tryParse(
                                  value.replaceAll(",", ""),
                                );
                                if (parsed == null) {
                                  return "Enter a valid number";
                                }
                                if (parsed <= 0) {
                                  return "Budget must be greater than 0";
                                }
                                if (parsed > 9999999) {
                                  return "Budget must not exceed ₱9,999,999";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Image.asset("images/set2.png", height: 220),
                        ],
                      ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    step == 1 ? "Next" : "Finish Setup",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
