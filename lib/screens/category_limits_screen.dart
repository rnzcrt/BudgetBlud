import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/budget_provider.dart';
import 'main_navigation_screen.dart';

class CategoryLimitsScreen extends StatefulWidget {
  final bool isRenewal;

  const CategoryLimitsScreen({super.key, this.isRenewal = false});

  @override
  State<CategoryLimitsScreen> createState() => _CategoryLimitsScreenState();
}

class _CategoryLimitsScreenState extends State<CategoryLimitsScreen> {
  final _formKey = GlobalKey<FormState>();
  final foodsController = TextEditingController();
  final transportationController = TextEditingController();
  final shoppingController = TextEditingController();
  final billsController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    // Add listeners to update UI when any field changes
    foodsController.addListener(_updateUI);
    transportationController.addListener(_updateUI);
    shoppingController.addListener(_updateUI);
    billsController.addListener(_updateUI);
  }

  Future<void> _initialize() async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);

    // Wait until provider is loaded
    int attempts = 0;
    while (!provider.isLoaded && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    // Additional safety delay
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });

      // Debug check
      print('Budget loaded: ${provider.totalBudget}');
    }
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  void dispose() {
    foodsController.dispose();
    transportationController.dispose();
    shoppingController.dispose();
    billsController.dispose();
    super.dispose();
  }

  double _parseAmount(String text) {
    if (text.isEmpty) return 0.0;
    return double.parse(text.replaceAll(",", ""));
  }

  double get _totalAllocated {
    return _parseAmount(foodsController.text) +
        _parseAmount(transportationController.text) +
        _parseAmount(shoppingController.text) +
        _parseAmount(billsController.text);
  }

  void _finishSetup() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      final totalBudget = provider.totalBudget;

      // Final check before saving
      if (_totalAllocated > totalBudget) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total category limits (₱${NumberFormat('#,###').format(_totalAllocated)}) exceed your budget (₱${NumberFormat('#,###').format(totalBudget)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save category limits
      await provider.setCategoryLimits(
        foods: _parseAmount(foodsController.text),
        transportation: _parseAmount(transportationController.text),
        shopping: _parseAmount(shoppingController.text),
        bills: _parseAmount(billsController.text),
      );

      // Mark setup as complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_complete', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  Widget _buildCategoryField(String label, TextEditingController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : const Color(0xFF1E3A5F),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) {
                    return newValue;
                  }
                  final value = newValue.text.replaceAll(',', '');
                  final formatter = NumberFormat('#,###');
                  final newText = formatter.format(int.parse(value));
                  return newValue.copyWith(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }),
              ],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6, top: 1),
                  child: Text(
                    "₱",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: "0",
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white38 : Colors.grey[400],
                  fontSize: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                final amount = _parseAmount(value ?? "");
                if (amount < 0) {
                  return "Cannot be negative";
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show loading until initialized
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    final totalBudget = Provider.of<BudgetProvider>(context).totalBudget;
    final remaining = totalBudget - _totalAllocated;
    final isOverBudget = remaining < 0;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
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
                      "Divide your budget",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Title
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.isRenewal
                            ? "Renew Category Limits"
                            : "Set Category Limits",
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
                        "How much will you spend on each category?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Budget Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? Colors.red[50]
                        : (isDarkMode
                              ? const Color(0xFF1E3A5F).withOpacity(0.3)
                              : Colors.blue[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverBudget
                          ? Colors.red[200]!
                          : (isDarkMode
                                ? const Color(0xFF2563EB)
                                : Colors.blue[200]!),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Budget:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E3A5F),
                            ),
                          ),
                          Text(
                            "₱${NumberFormat('#,###').format(totalBudget)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Allocated:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E3A5F),
                            ),
                          ),
                          Text(
                            "₱${NumberFormat('#,###').format(_totalAllocated)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isOverBudget
                                  ? Colors.red[700]
                                  : (isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF1E3A5F)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOverBudget ? "Over Budget:" : "Remaining:",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isOverBudget
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                          ),
                          Text(
                            "₱${NumberFormat('#,###').format(remaining.abs())}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isOverBudget
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      if (isOverBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "You've exceeded your budget! Please adjust.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Category Fields
                _buildCategoryField("Foods", foodsController),
                _buildCategoryField("Transportation", transportationController),
                _buildCategoryField("Shopping", shoppingController),
                _buildCategoryField("Bills", billsController),
                const SizedBox(height: 16),
                // Illustration
                Center(child: Image.asset("images/set3.png", height: 200)),
                const Spacer(),
                // Finish Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOverBudget
                          ? Colors.grey
                          : const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isOverBudget ? null : _finishSetup,
                    child: Text(
                      widget.isRenewal ? "Complete Renewal" : "Finish Setup",
                      style: const TextStyle(
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
}
