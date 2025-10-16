import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import 'category_limits_screen.dart';
import 'main_navigation_screen.dart';

class SetupScreen extends StatefulWidget {
  final bool isRenewal;

  const SetupScreen({super.key, this.isRenewal = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int step = 1;
  final _formKey = GlobalKey<FormState>();
  final budgetController = TextEditingController();
  bool _isProcessing = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();

    // If renewal, skip directly to step 2
    if (widget.isRenewal) {
      step = 2;
    }

    // FIXED: Schedule the check after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingBudget();
    });
  }

  /// Check if user already has a budget set up
  Future<void> _checkExistingBudget() async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);

    // Wait for provider to load
    int attempts = 0;
    while (!provider.isLoaded && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (!mounted) return;

    // If budget exists and this is not a renewal, skip to home
    if (provider.totalBudget > 0 && !widget.isRenewal) {
      debugPrint(
        '✅ Budget already exists (₱${provider.totalBudget}), skipping setup',
      );

      // FIXED: Safe navigation after build is complete
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
      return;
    }

    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _nextStep() async {
    // Prevent multiple clicks
    if (_isProcessing) return;

    if (step == 1) {
      setState(() {
        step = 2;
      });
    } else if (step == 2) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isProcessing = true;
        });

        try {
          double budget = double.parse(
            budgetController.text.replaceAll(",", ""),
          );

          final provider = Provider.of<BudgetProvider>(context, listen: false);

          // Make sure to await the setBudget operation
          await provider.setBudget(budget);

          // Reload budget from SharedPreferences to ensure latest value
          await provider.reloadBudget();

          if (!mounted) return;

          // Verify the budget was actually set
          if (provider.totalBudget != budget) {
            throw Exception('Budget not set correctly');
          }

          debugPrint('✅ Budget set successfully: ₱$budget');

          // Navigate only after budget is confirmed to be set
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryLimitsScreen(isRenewal: widget.isRenewal),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error setting budget: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show loading while checking existing budget
    if (_isChecking) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isRenewal ? "Monthly Renewal" : "Getting started",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step == 1
                          ? "Let's get started!"
                          : "Input your monthly budget",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
                Center(
                  child: step == 1
                      ? Column(
                          children: [
                            Text(
                              "Welcome!\nLet's setup\nyour BudgetBlud",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1E3A5F),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Image.asset("images/set1.png", height: 300),
                          ],
                        )
                      : Column(
                          children: [
                            Text(
                              widget.isRenewal
                                  ? "Renew Your\nMonthly Budget"
                                  : "Monthly Budget\nSetup",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1E3A5F),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isRenewal
                                  ? "Set your budget for the new month"
                                  : "What's your budget for this month?",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Budget Label
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Budget for this month:",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1E3A5F),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: budgetController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^[\d,]*\.?\d{0,2}'),
                                  ),
                                  TextInputFormatter.withFunction((
                                    oldValue,
                                    newValue,
                                  ) {
                                    if (newValue.text.isEmpty) {
                                      return newValue;
                                    }

                                    String text = newValue.text;

                                    // Prevent multiple decimal points
                                    if (text.split('.').length > 2) {
                                      return oldValue;
                                    }

                                    // Format with commas
                                    if (text.contains('.')) {
                                      final parts = text.split('.');
                                      final intPart = parts[0].replaceAll(
                                        ',',
                                        '',
                                      );
                                      if (intPart.isEmpty) return newValue;

                                      final parsedInt = double.tryParse(
                                        intPart,
                                      );
                                      if (parsedInt == null) return oldValue;

                                      final formattedInt = parsedInt % 1 == 0
                                          ? NumberFormat(
                                              '#,###',
                                            ).format(parsedInt.toInt())
                                          : NumberFormat(
                                              '#,##0.00',
                                            ).format(parsedInt);
                                      final newText =
                                          '$formattedInt.${parts[1]}';

                                      return newValue.copyWith(
                                        text: newText,
                                        selection: TextSelection.collapsed(
                                          offset: newText.length,
                                        ),
                                      );
                                    } else {
                                      final value = text.replaceAll(',', '');
                                      if (value.isEmpty) return newValue;

                                      final parsed = double.tryParse(value);
                                      if (parsed == null) return oldValue;

                                      final newText = parsed % 1 == 0
                                          ? NumberFormat(
                                              '#,###',
                                            ).format(parsed.toInt())
                                          : NumberFormat(
                                              '#,##0.00',
                                            ).format(parsed);

                                      return newValue.copyWith(
                                        text: newText,
                                        selection: TextSelection.collapsed(
                                          offset: newText.length,
                                        ),
                                      );
                                    }
                                  }),
                                ],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 8,
                                      top: 1,
                                    ),
                                    child: Text(
                                      "₱",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                  hintText: "0",
                                  hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white38
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2563EB),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
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
                            const SizedBox(height: 32),
                            Image.asset("images/set2.png", height: 300),
                          ],
                        ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _nextStep,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Next",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }
}
