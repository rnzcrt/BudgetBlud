import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'settings_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final Expense? expense;
  const AddTransactionScreen({super.key, this.expense});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final otherCategoryController = TextEditingController();
  String? category;
  DateTime selectedDate = DateTime.now();
  bool isCategoryExpanded = false;
  List<String> filteredCustomCategories = [];
  bool showSuggestions = false;

  final List<String> categories = [
    'Foods',
    'Transportation',
    'Shopping',
    'Bills',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      amountController.text = NumberFormat(
        "#,###",
      ).format(widget.expense!.amount);
      noteController.text = widget.expense!.note ?? '';
      category = widget.expense!.category;
      if (!categories.contains(category)) {
        category = 'Others';
        otherCategoryController.text = widget.expense!.category;
      }
      selectedDate = widget.expense!.date;
    }

    otherCategoryController.addListener(_onCustomCategoryChanged);
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    otherCategoryController.removeListener(_onCustomCategoryChanged);
    otherCategoryController.dispose();
    super.dispose();
  }

  void _onCustomCategoryChanged() {
    final query = otherCategoryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        showSuggestions = false;
        filteredCustomCategories = [];
      });
      return;
    }

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final allCustomCategories = expenseProvider.getCustomCategories();

    final matches = allCustomCategories.where((cat) {
      return cat.toLowerCase().startsWith(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCustomCategories = matches;
      showSuggestions = matches.isNotEmpty;
    });
  }

  String _normalizeCategory(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      String clean = amountController.text.replaceAll(',', '').trim();
      String finalCategory;

      if (category == 'Others' && otherCategoryController.text.isNotEmpty) {
        finalCategory = _normalizeCategory(otherCategoryController.text.trim());
      } else {
        finalCategory = category!;
      }

      // FIX: Generate proper UUID instead of timestamp
      final expense = Expense(
        id: widget.expense?.id ?? const Uuid().v4(), // CHANGED THIS LINE
        title: noteController.text.isNotEmpty ? noteController.text : 'Expense',
        amount: double.parse(clean),
        category: finalCategory,
        date: selectedDate,
        note: noteController.text,
      );

      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (widget.expense == null) {
        provider.addExpense(expense);
      } else {
        provider.editExpense(expense);
      }
      Navigator.pop(context);
    }
  }

  // ... rest of your widget code remains the same ...
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.expense == null ? 'Add Expense' : 'Edit Expense',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF03314B),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.expense == null)
            IconButton(
              icon: Icon(
                Icons.settings,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Amount Field
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white70
                        : const Color(0xFF61738A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 0),
                    child: Text(
                      '₱',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter amount';
                  }
                  String clean = value
                      .replaceAll(',', '')
                      .replaceAll('₱', '')
                      .trim();
                  final parsed = double.tryParse(clean);
                  if (parsed == null) {
                    return 'Enter valid number';
                  }
                  if (parsed <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isCategoryExpanded = !isCategoryExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category ?? 'Pick an option',
                            style: TextStyle(
                              color: category != null
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : (isDarkMode
                                        ? Colors.white70
                                        : const Color(0xFF61738A)),
                              fontSize: 15,
                            ),
                          ),
                          Icon(
                            isCategoryExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF61738A),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isCategoryExpanded)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: categories.map((cat) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                category = cat;
                                isCategoryExpanded = false;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: cat != categories.last
                                    ? Border(
                                        bottom: BorderSide(
                                          color: isDarkMode
                                              ? Colors.grey[800]!
                                              : Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  if (category == null &&
                      _formKey.currentState?.validate() == false)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        'Select category',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                ],
              ),

              if (category == 'Others') ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: otherCategoryController,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Custom Category',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : const Color(0xFF61738A),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (category == 'Others' &&
                            (value == null || value.isEmpty)) {
                          return 'Enter custom category';
                        }
                        return null;
                      },
                    ),

                    if (showSuggestions && filteredCustomCategories.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Text(
                                'Suggestions:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            ...filteredCustomCategories.take(5).map((
                              suggestion,
                            ) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    otherCategoryController.text = suggestion;
                                    showSuggestions = false;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border:
                                        suggestion !=
                                            filteredCustomCategories.last
                                        ? Border(
                                            bottom: BorderSide(
                                              color: isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[300]!,
                                              width: 0.5,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 16,
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        suggestion,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Date Picker
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate:
                        selectedDate.isBefore(firstDayOfMonth) ||
                            selectedDate.isAfter(lastDayOfMonth)
                        ? now
                        : selectedDate,
                    firstDate: firstDayOfMonth,
                    lastDate: lastDayOfMonth,
                    builder: (context, child) {
                      return Theme(
                        data: isDarkMode
                            ? ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF2563EB),
                                  surface: Color(0xFF1E1E1E),
                                ),
                              )
                            : ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF2563EB),
                                ),
                              ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF61738A),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF61738A),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: noteController,
                maxLines: 3,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white70
                        : const Color(0xFF61738A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (category == null) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a category'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        _saveExpense();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.expense == null ? 'Save Expense' : 'Save Changes',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String clean = newValue.text.replaceAll(',', '');
    final parsed = int.tryParse(clean);
    if (parsed == null) return oldValue;

    final newString = NumberFormat("#,###").format(parsed);
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
